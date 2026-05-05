-- ============================================================================
-- InspectExport.lua  v5.0
-- MekTown Recruit — Ascension Inspect Character Export
--
-- Auto-clicks Build tab + Mystic side-tab before harvesting.
-- Targets specific sub-frames:
--   Build   → InspectBuildPanelBuildScrollChild (abilities + N/N talents)
--   Mythics → InspectMysticEnchantPanel (names + xN stacks, either order)
--   Gear    → GetInventoryItemLink (API)
--
-- Usage:
--   /mek inspect              — scan target, open export window
--   /mek inspect history      — browse saved reports
--   /mek inspect clear [n]    — wipe saved reports
-- ============================================================================
local MTR = MekTownRecruit

local IE = {}
MTR.InspectExport = IE

-- ============================================================================
-- CONSTANTS
-- ============================================================================
local MAX_HISTORY_PER_PLAYER = 10

local GEAR_SLOTS = {
    {1,"Head"},{2,"Neck"},{3,"Shoulder"},{4,"Shirt"},
    {5,"Chest"},{6,"Waist"},{7,"Legs"},{8,"Feet"},
    {9,"Wrist"},{10,"Hands"},{11,"Ring1"},{12,"Ring2"},
    {13,"Trinket1"},{14,"Trinket2"},{15,"Back"},
    {16,"MainHand"},{17,"OffHand"},{18,"Ranged"},{19,"Tabard"},
}

local ARCHETYPE_KEYWORDS = {
    "Compound Power","Strikes","Ranger","Archmage","Warden","Templar",
    "Druid","Shaman","Necromancer","Berserker","Shadowblade","Champion",
    "Warmaster","Sentinel","Vindicator",
}

local BUILD_NOISE = {
    ["Primary Stat: Agility"]=true, ["Primary Stat: Strength"]=true,
    ["Primary Stat: Intellect"]=true, ["Primary Stat: Spirit"]=true,
    ["Primary Stat: Stamina"]=true,
}

-- ============================================================================
-- DB HELPERS
-- ============================================================================
local function EnsureDB()
    if type(MekTownRecruitDB)~="table" then MekTownRecruitDB={} end
    if type(MekTownRecruitDB.inspectReports)~="table" then
        MekTownRecruitDB.inspectReports={}
    end
    return MekTownRecruitDB.inspectReports
end

function IE.SaveReport(playerName, report)
    if not playerName or playerName=="" then return end
    local db=EnsureDB()
    db[playerName]=db[playerName] or {}
    table.insert(db[playerName], 1, {timestamp=date("%Y-%m-%d %H:%M"), report=report})
    while #db[playerName]>MAX_HISTORY_PER_PLAYER do table.remove(db[playerName]) end
end

function IE.GetReports(playerName)
    local db=EnsureDB()
    if not playerName then return db end
    return db[playerName] or {}
end

function IE.ClearReports(playerName)
    local db=EnsureDB()
    if playerName and playerName~="" then
        db[playerName]=nil
        MTR.MP("Cleared inspect history for |cffffff00"..playerName.."|r")
    else
        MekTownRecruitDB.inspectReports={}
        MTR.MP("Cleared ALL inspect history.")
    end
end

-- ============================================================================
-- TEXT HELPERS
-- ============================================================================
local function CleanText(t)
    if not t then return "" end
    t = tostring(t)
    t = t:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    t = t:gsub("^%s+", ""):gsub("%s+$", "")
    return t
end

local function SplitLines(text)
    local lines = {}
    for l in text:gmatch("[^\n\r]+") do
        local cl = CleanText(l)
        if cl ~= "" and #cl > 1 then
            lines[#lines+1] = cl
        end
    end
    return lines
end

-- ============================================================================
-- DEEP HARVEST
-- ============================================================================
local function DeepHarvest(root)
    local out = {}
    if not root then return out end

    local function Recurse(obj)
        if not obj then return end
        local regions = {obj:GetRegions()}
        for _, r in ipairs(regions) do
            if r:IsObjectType("FontString") then
                local raw = r:GetText()
                if raw and raw ~= "" then
                    local lines = SplitLines(raw)
                    for _, t in ipairs(lines) do
                        out[#out + 1] = t
                    end
                end
            end
        end
        local children = {obj:GetChildren()}
        for _, c in ipairs(children) do
            Recurse(c)
        end
    end

    Recurse(root)
    return out
end

-- ============================================================================
-- TAB CLICKING — find and click Build tab + Mystic side-tab
-- ============================================================================
local function ClickBuildTab()
    local frame = _G["AscensionInspectFrame"]
    if not frame then return false end

    if _G["InspectBuildPanel"] and _G["InspectBuildPanel"]:IsVisible() then
        return true
    end

    local children = {frame:GetChildren()}
    for _, c in ipairs(children) do
        local name = c:GetName() or ""
        if name:find("TabTemplate") then
            for _, r in ipairs({c:GetRegions()}) do
                if r:IsObjectType("FontString") then
                    local txt = CleanText(r:GetText())
                    if txt == "Build" then
                        c:Click()
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function ClickMysticSideTab()
    local rightInset = _G["AscensionInspectFrameRightInset"]
    if not rightInset then return false end

    if _G["InspectMysticEnchantPanel"] and _G["InspectMysticEnchantPanel"]:IsVisible() then
        return true
    end

    local children = {rightInset:GetChildren()}
    for _, c in ipairs(children) do
        local name = c:GetName() or ""
        if name:find("SideTab") then
            for _, r in ipairs({c:GetRegions()}) do
                if r:IsObjectType("FontString") then
                    local txt = CleanText(r:GetText())
                    if txt:find("Enchant") or txt:find("Mystic") then
                        c:Click()
                        return true
                    end
                end
            end
        end
    end

    for _, c in ipairs(children) do
        local name = c:GetName() or ""
        if name:find("SideTab") then
            c:Click()
            if _G["InspectMysticEnchantPanel"] and _G["InspectMysticEnchantPanel"]:IsVisible() then
                return true
            end
        end
    end

    return false
end

-- ============================================================================
-- BUILD HARVEST — InspectBuildPanelBuildScrollChild
-- ============================================================================
local function HarvestBuild()
    local talents, abilities = {}, {}
    local scrollChild = _G["InspectBuildPanelBuildScrollChild"]
    if not scrollChild then return talents, abilities end

    local raw = DeepHarvest(scrollChild)
    local i = 1
    while i <= #raw do
        local t = raw[i]
        if t:match("^%d+/%d+$") then
            if #talents > 0 then
                talents[#talents] = talents[#talents] .. " (" .. t .. ")"
            end
        elseif BUILD_NOISE[t] then
            -- skip
        else
            if i < #raw and raw[i+1]:match("^%d+/%d+$") then
                talents[#talents+1] = t
            else
                abilities[#abilities+1] = t
            end
        end
        i = i + 1
    end

    return talents, abilities
end

-- ============================================================================
-- MYTHICS HARVEST — InspectMysticEnchantPanel
-- Handles xN either before or after the enchant name.
-- ============================================================================
local function HarvestMythics()
    local mythics = {}
    local panel = _G["InspectMysticEnchantPanel"]
    if not panel then return mythics end

    local raw = DeepHarvest(panel)
    local pending = nil

    for i, t in ipairs(raw) do
        local stack = t:match("^x(%d+)$")
        if stack then
            if pending then
                mythics[#mythics+1] = pending .. " [x" .. stack .. "]"
                pending = nil
            else
                local nxt = raw[i+1]
                if nxt and #nxt > 2 and not nxt:match("^x%d+$") and not nxt:match("^%d+$") then
                    mythics[#mythics+1] = nxt .. " [x" .. stack .. "]"
                end
            end
        elseif #t > 2 and not t:match("^%d+$") and not t:match("^%d+%.%d+$") then
            local nxt = raw[i+1]
            if nxt and nxt:match("^x(%d+)$") then
                -- xN follows — will be caught by the stack branch
            elseif pending then
                mythics[#mythics+1] = pending .. " [x1]"
                pending = t
            else
                pending = t
            end
        end
    end

    if pending then
        mythics[#mythics+1] = pending .. " [x1]"
    end

    return mythics
end

-- ============================================================================
-- ARCHETYPE DETECTION
-- ============================================================================
local function DetectArchetype()
    local frame = _G["AscensionInspectFrame"]
    if not frame then return "Unknown" end

    local raw = DeepHarvest(frame)
    for _, t in ipairs(raw) do
        for _, kw in ipairs(ARCHETYPE_KEYWORDS) do
            if t:find(kw, 1, true) and not t:match("^Level %d") and not t:match("^Specialization:") then
                return t
            end
        end
    end

    return "Unknown"
end

-- ============================================================================
-- GEAR SCAN
-- ============================================================================
local function ScanGear()
    local gear = {}
    for _, slot in ipairs(GEAR_SLOTS) do
        local link = GetInventoryItemLink("target", slot[1])
        if link then
            local name = GetItemInfo(link) or MTR.ItemLinkToName(link) or "Loading..."
            gear[#gear+1] = slot[2] .. ": " .. name
        end
    end
    return gear
end

-- ============================================================================
-- FULL SCAN (async — clicks tabs, waits, then harvests)
-- ============================================================================
function IE.ScanTarget(callback)
    local name = UnitName("target")
    if not name then
        MTR.MPE("No target to inspect.")
        return nil
    end

    local frame = _G["AscensionInspectFrame"]
    if not (frame and frame:IsVisible()) then
        MTR.MPE("Ascension inspect frame not open. Right-click a player and choose Inspect first.")
        return nil
    end

    ClickBuildTab()
    ClickMysticSideTab()

    MTR.After(0.3, function()
        local level = UnitLevel("target") or 0
        local _, class = UnitClass("target")
        local _, race = UnitRace("target")
        local guild = GetGuildInfo("target")
        local archetype = DetectArchetype()
        local talents, abilities = HarvestBuild()
        local mythics = HarvestMythics()
        local gear = ScanGear()

        MTR.dprint("InspectExport: talents="..#talents.." abilities="..#abilities.." mythics="..#mythics.." gear="..#gear)

        local data = {
            name = name,
            archetype = archetype,
            talents = talents,
            abilities = abilities,
            mythics = mythics,
            gear = gear,
        }

        data.header = string.format(
            "PLAYER: %s | LEVEL: %d %s %s | ARCHETYPE: %s | GUILD: %s",
            name, level, race or "", class or "", archetype, guild or "(none)"
        )

        if callback then
            callback(data)
        end
    end)

    return true
end

-- ============================================================================
-- FORMAT REPORT
-- ============================================================================
function IE.FormatReport(data)
    if not data then return "" end
    local line = "------------------------------------------"
    local r = data.header .. "\n\n"

    r = r .. "SECTION 1: BUILD INFO (TALENTS & ABILITIES)\n" .. line .. "\n"
    for _, v in ipairs(data.talents) do
        r = r .. "[TALENT] " .. v .. "\n"
    end
    for _, v in ipairs(data.abilities) do
        r = r .. "[ABILITY] " .. v .. "\n"
    end

    r = r .. "\nSECTION 2: EQUIPMENT (GEAR)\n" .. line .. "\n"
    for _, v in ipairs(data.gear) do
        r = r .. "[ITEM] " .. v .. "\n"
    end

    r = r .. "\nSECTION 3: MYTHIC ENCHANTS (SIDE-PANEL)\n" .. line .. "\n"
    for _, v in ipairs(data.mythics) do
        r = r .. "[MYTHIC] " .. v .. "\n"
    end

    return r
end

-- ============================================================================
-- AUTO-BUTTON ON INSPECT FRAME
-- ============================================================================
local inspectBtn = nil

local function CreateInspectButton()
    if inspectBtn then return inspectBtn end
    inspectBtn = CreateFrame("Button", "MekTownInspectExportBtn", UIParent, "UIPanelButtonTemplate")
    inspectBtn:SetSize(80, 22)
    inspectBtn:SetText("Export")
    inspectBtn:SetFrameStrata("HIGH")
    inspectBtn:SetScript("OnClick", function()
        IE.ScanTarget(function(data)
            local report = IE.FormatReport(data)
            IE.SaveReport(data.name, report)
            if MTR.OpenInspectExport then
                MTR.OpenInspectExport(report, data.name)
            end
        end)
    end)
    inspectBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("MekTown: Export inspect data")
        GameTooltip:Show()
    end)
    inspectBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return inspectBtn
end

local function PositionInspectButton()
    local f = _G["AscensionInspectFrame"]
    if not f then return end
    local btn = CreateInspectButton()
    btn:ClearAllPoints()
    btn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -40, -12)
end

local inspectWatch = CreateFrame("Frame")
inspectWatch:RegisterEvent("PLAYER_TARGET_CHANGED")
inspectWatch:SetScript("OnEvent", function()
    MTR.After(0.3, function()
        local f = _G["AscensionInspectFrame"]
        if f and f:IsVisible() then
            PositionInspectButton()
            if inspectBtn then inspectBtn:Show() end
        elseif inspectBtn then
            inspectBtn:Hide()
        end
    end)
end)

MTR.After(3, function()
    local f = _G["AscensionInspectFrame"]
    if f then
        local orig = f:GetScript("OnShow")
        f:SetScript("OnShow", function(self, ...)
            if orig then orig(self, ...) end
            PositionInspectButton()
            if inspectBtn then inspectBtn:Show() end
        end)
    end
end)

-- ============================================================================
-- RIGHT-CLICK MENU INTEGRATION
-- ============================================================================
MTR.After(5, function()
    if not UnitPopupButtons then return end

    UnitPopupButtons["MEKTOWN_INSPECT"] = { text = "MekTown Inspect", dist = 0 }

    local menus = {"SELF","PLAYER","RAID_PLAYER","FRIEND","RAID","TARGET"}
    for _, menu in ipairs(menus) do
        if UnitPopupMenus[menu] then
            local inserted = false
            for idx, btn in ipairs(UnitPopupMenus[menu]) do
                if btn == "INSPECT" then
                    table.insert(UnitPopupMenus[menu], idx + 1, "MEKTOWN_INSPECT")
                    inserted = true
                    break
                end
            end
            if not inserted then
                table.insert(UnitPopupMenus[menu], #UnitPopupMenus[menu], "MEKTOWN_INSPECT")
            end
        end
    end

    hooksecurefunc("UnitPopup_OnClick", function(self)
        if self.value ~= "MEKTOWN_INSPECT" then return end
        local dropdownFrame = UIDROPDOWNMENU_INIT_MENU
        if not dropdownFrame then return end
        local unit = dropdownFrame.unit
        if not unit then return end

        if not CheckInteractDistance(unit, 1) then
            MTR.MPE("Target is too far away to inspect.")
            return
        end

        local targetName = UnitName(unit)
        if not targetName then return end

        MTR.MP("Inspecting |cffffff00"..targetName.."|r — opening inspect frame...")

        if InspectUnit then
            InspectUnit(unit)
        end

        MTR.After(1.5, function()
            local f = _G["AscensionInspectFrame"]
            if not (f and f:IsVisible()) then
                MTR.MPE("Inspect frame did not open. Try right-click -> Inspect first, then /mek inspect.")
                return
            end
            IE.ScanTarget(function(data)
                local report = IE.FormatReport(data)
                IE.SaveReport(data.name, report)
                if MTR.OpenInspectExport then
                    MTR.OpenInspectExport(report, data.name)
                end
            end)
        end)
    end)
end)

-- ============================================================================
-- DIAGNOSTIC DUMP
-- ============================================================================
function IE.DumpRaw()
    local frame = _G["AscensionInspectFrame"]
    if not frame or not frame:IsVisible() then
        MTR.MPE("Ascension inspect frame not open.")
        return
    end

    MTR.MP("=== BUILD (BuildScrollChild) ===")
    local ab = DeepHarvest(_G["InspectBuildPanelBuildScrollChild"])
    for i, t in ipairs(ab) do
        DEFAULT_CHAT_FRAME:AddMessage(i..": ["..t.."]", 0.5, 1, 0.5)
    end

    MTR.MP("=== MYTHICS (MysticEnchantPanel) ===")
    local my = DeepHarvest(_G["InspectMysticEnchantPanel"])
    for i, t in ipairs(my) do
        DEFAULT_CHAT_FRAME:AddMessage(i..": ["..t.."]", 0.5, 0.7, 1)
    end

    MTR.MP("=== DUMP COMPLETE ("..#ab.." build, "..#my.." mythic) ===")
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================
function IE.RunScanAndShow()
    IE.ScanTarget(function(data)
        local report = IE.FormatReport(data)
        IE.SaveReport(data.name, report)
        if MTR.OpenInspectExport then
            MTR.OpenInspectExport(report, data.name)
        else
            MTR.MPE("Inspect export UI not loaded yet.")
        end
    end)
end

print("|cff00c0ff[MekTown Recruit]|r InspectExport v5.0 loaded.")

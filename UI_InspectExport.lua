-- ============================================================================
-- UI_InspectExport.lua  v1.0
-- MekTown Recruit — Inspect Export Window
--
-- Multi-line EditBox window for copying formatted inspect reports.
-- History dropdown to browse past reports per player.
-- MekTown visual style: dark-red backdrop, parchment header, rivet line.
-- ============================================================================
local MTR = MekTownRecruit

local exportWin = nil
local EXPORT_W, EXPORT_H = 750, 650

-- ============================================================================
-- CREATE WINDOW
-- ============================================================================
local function CreateExportWindow()
    if exportWin then return exportWin end

    exportWin = CreateFrame("Frame", "MekTownInspectExportWindow", UIParent)
    exportWin:SetSize(EXPORT_W, EXPORT_H)
    exportWin:SetPoint("CENTER")
    exportWin:SetFrameStrata("HIGH")
    exportWin:SetMovable(true)
    exportWin:EnableMouse(true)
    exportWin:RegisterForDrag("LeftButton")
    exportWin:SetScript("OnDragStart", exportWin.StartMoving)
    exportWin:SetScript("OnDragStop", exportWin.StopMovingOrSizing)
    exportWin:Hide()

    -- Backdrop (3.3.5a compatible)
    exportWin:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, tileSize = 0, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4},
    })
    exportWin:SetBackdropColor(0.04, 0.01, 0.01, 0.98)
    exportWin:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    -- Title bar background
    local titleBar = exportWin:CreateTexture(nil, "OVERLAY")
    titleBar:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    titleBar:SetTexCoord(0, 1, 0.2, 0.8)
    titleBar:SetVertexColor(0.55, 0.03, 0.03, 1.0)
    titleBar:SetHeight(26)
    titleBar:SetPoint("TOPLEFT", exportWin, "TOPLEFT", 9, -2)
    titleBar:SetPoint("TOPRIGHT", exportWin, "TOPRIGHT", -9, -2)

    local titleEdge = exportWin:CreateTexture(nil, "OVERLAY")
    titleEdge:SetTexture("Interface\\Buttons\\WHITE8x8")
    titleEdge:SetVertexColor(0.80, 0.12, 0.02, 1.0)
    titleEdge:SetHeight(2)
    titleEdge:SetPoint("TOPLEFT", exportWin, "TOPLEFT", 9, -26)
    titleEdge:SetPoint("TOPRIGHT", exportWin, "TOPRIGHT", -9, -26)

    local titleText = exportWin:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("TOPLEFT", exportWin, "TOPLEFT", 14, -6)
    titleText:SetText("|cffff2020MekTown|r |cffd4af37Inspect Export|r")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, exportWin, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", exportWin, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() exportWin:Hide() end)

    -- Player name label
    local nameLbl = exportWin:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameLbl:SetPoint("TOPLEFT", exportWin, "TOPLEFT", 14, -36)
    nameLbl:SetText("|cffaaaaaaPlayer:|r |cffffff00Unknown|r")
    exportWin._nameLbl = nameLbl

    -- History dropdown
    local dd = CreateFrame("Frame", "MekInspectHistoryDD", exportWin, "UIDropDownMenuTemplate")
    dd:SetPoint("LEFT", nameLbl, "RIGHT", 12, -2)
    UIDropDownMenu_SetWidth(dd, 220)
    exportWin._historyDD = dd

    -- Refresh / Rescan button
    local rescanBtn = CreateFrame("Button", nil, exportWin, "UIPanelButtonTemplate")
    rescanBtn:SetSize(90, 22)
    rescanBtn:SetPoint("TOPRIGHT", exportWin, "TOPRIGHT", -14, -36)
    rescanBtn:SetText("Rescan")
    rescanBtn:SetScript("OnClick", function()
        if MTR.InspectExport and MTR.InspectExport.RunScanAndShow then
            MTR.InspectExport.RunScanAndShow()
        end
    end)

    -- ScrollFrame + EditBox
    local scroll = CreateFrame("ScrollFrame", "MekInspectExportScroll", exportWin, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", exportWin, "TOPLEFT", 14, -64)
    scroll:SetPoint("BOTTOMRIGHT", exportWin, "BOTTOMRIGHT", -34, 56)

    local editBox = CreateFrame("EditBox", "MekInspectExportEditBox", scroll)
    editBox:SetMultiLine(true)
    editBox:SetMaxLetters(99999)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetWidth(EXPORT_W - 60)
    editBox:SetAutoFocus(false)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    scroll:SetScrollChild(editBox)
    exportWin._editBox = editBox

    -- Hint text below editbox
    local hint = exportWin:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("BOTTOMLEFT", exportWin, "BOTTOMLEFT", 14, 36)
    hint:SetPoint("BOTTOMRIGHT", exportWin, "BOTTOMRIGHT", -14, 36)
    hint:SetJustifyH("CENTER")
    hint:SetText("|cffaaaaaaClick the box above, press Ctrl+A then Ctrl+C to copy.|r")

    -- Bottom buttons
    local copyBtn = CreateFrame("Button", nil, exportWin, "UIPanelButtonTemplate")
    copyBtn:SetSize(120, 24)
    copyBtn:SetPoint("BOTTOM", exportWin, "BOTTOM", -70, 8)
    copyBtn:SetText("Select All")
    copyBtn:SetScript("OnClick", function()
        if exportWin._editBox then
            exportWin._editBox:SetFocus()
            exportWin._editBox:HighlightText()
        end
    end)

    local closeBtn2 = CreateFrame("Button", nil, exportWin, "UIPanelButtonTemplate")
    closeBtn2:SetSize(120, 24)
    closeBtn2:SetPoint("BOTTOM", exportWin, "BOTTOM", 70, 8)
    closeBtn2:SetText("Close")
    closeBtn2:SetScript("OnClick", function() exportWin:Hide() end)

    -- Populate history dropdown
    function exportWin:PopulateHistory(playerName)
        local reports = MTR.InspectExport and MTR.InspectExport.GetReports(playerName) or {}
        local dd2 = exportWin._historyDD
        UIDropDownMenu_Initialize(dd2, function()
            for i, entry in ipairs(reports) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = (entry.timestamp or "?") .. "  #" .. i
                info.func = function()
                    UIDropDownMenu_SetSelectedValue(dd2, i)
                    if exportWin._editBox and entry.report then
                        exportWin._editBox:SetText(entry.report)
                        exportWin._editBox:SetFocus()
                        exportWin._editBox:HighlightText()
                    end
                end
                info.value = i
                UIDropDownMenu_AddButton(info)
            end
            if #reports == 0 then
                local info = UIDropDownMenu_CreateInfo()
                info.text = "No history"
                info.notClickable = true
                UIDropDownMenu_AddButton(info)
            end
        end)
    end

    return exportWin
end

-- ============================================================================
-- PUBLIC OPEN FUNCTION
-- ============================================================================
function MTR.OpenInspectExport(reportText, playerName)
    local win = CreateExportWindow()
    win:Show()

    if playerName then
        win._nameLbl:SetText("|cffaaaaaaPlayer:|r |cffffff00" .. playerName .. "|r")
        win:PopulateHistory(playerName)
    end

    if reportText and win._editBox then
        win._editBox:SetText(reportText)
        win._editBox:SetFocus()
        win._editBox:HighlightText()
    end
end

print("|cff00c0ff[MekTown Recruit]|r UI_InspectExport v1.0 loaded.")

local MTR = MekTownRecruit

MTR.Settings = MTR.Settings or {}

local Settings = MTR.Settings

local function normalizeChecked(v)
    return v == true or v == 1
end

local function splitPath(path)
    local out = {}
    for part in string.gmatch(path or "", "[^%.]+") do
        out[#out + 1] = part
    end
    return out
end

local function deepCopy(v)
    if type(v) ~= "table" then return v end
    local out = {}
    for k, vv in pairs(v) do out[k] = deepCopy(vv) end
    return out
end

function Settings.Get(path, default)
    if MTR.GetProfilePath then return MTR.GetProfilePath(path, default) end
    return default
end

function Settings.Set(path, value)
    if MTR.SetProfilePath then return MTR.SetProfilePath(path, value) end
    return value
end

function Settings.SetBoolean(path, value)
    if MTR.SetProfilePathBoolean then return MTR.SetProfilePathBoolean(path, normalizeChecked(value)) end
    return normalizeChecked(value)
end

function Settings.Bind(win, binding)
    if not win then return binding end
    win._settingBindings = win._settingBindings or {}
    win._settingBindings[#win._settingBindings + 1] = binding
    return binding
end

function Settings.BindCheck(win, widget, path)
    return Settings.Bind(win, {
        kind = "check", widget = widget, path = path,
        load = function(self)
            if self.widget and self.widget.SetChecked then
                self.widget:SetChecked(Settings.Get(self.path, false) == true)
            end
        end,
        save = function(self)
            if self.widget and self.widget.GetChecked then
                Settings.SetBoolean(self.path, self.widget:GetChecked())
            end
        end,
    })
end

function Settings.BindEdit(win, widget, path, opts)
    opts = opts or {}
    return Settings.Bind(win, {
        kind = "edit", widget = widget, path = path,
        load = function(self)
            if self.widget and self.widget.SetText then
                self.widget:SetText(tostring(Settings.Get(self.path, opts.default or "") or ""))
            end
        end,
        save = function(self)
            if self.widget and self.widget.GetText then
                local val = self.widget:GetText() or ""
                if opts.trim and MTR.TrimString then val = MTR.TrimString(val) end
                Settings.Set(self.path, tostring(val))
            end
        end,
    })
end

function Settings.BindSlider(win, widget, path, opts)
    opts = opts or {}
    local default = opts.default or 0
    local step = opts.step
    return Settings.Bind(win, {
        kind = "slider", widget = widget, path = path,
        load = function(self)
            if self.widget and self.widget.SetValue then
                self.widget:SetValue(tonumber(Settings.Get(self.path, default)) or default)
            end
        end,
        save = function(self)
            if self.widget and self.widget.GetValue then
                local val = tonumber(self.widget:GetValue()) or default
                if step and step > 0 then
                    val = math.floor(val / step) * step
                elseif opts.floor then
                    val = math.floor(val)
                end
                Settings.Set(self.path, val)
            end
        end,
    })
end

function Settings.BindCustom(win, loadFn, saveFn, key)
    return Settings.Bind(win, {
        kind = "custom", key = key,
        load = loadFn,
        save = saveFn,
    })
end

function Settings.LoadWindow(win)
    if not win or not win._settingBindings then return end
    win._refreshing = true
    for _, binding in ipairs(win._settingBindings) do
        if binding.load then binding.load(binding) end
    end
    win._refreshing = false
end

function Settings.SaveWindow(win)
    if not win or not win._settingBindings then return end
    for _, binding in ipairs(win._settingBindings) do
        if binding.save then binding.save(binding) end
    end
    if MTR.FlushActiveProfile then MTR.FlushActiveProfile() end
end

function Settings.CloneTable(value)
    return deepCopy(value)
end

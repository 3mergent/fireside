-- Dashboard Manager
-- Manages all Fireside applets

Fireside = Fireside or {}
Fireside.Dashboard = {
    applets = {},
    locked = false
}

-- Register an applet with the dashboard
function Fireside.Dashboard:RegisterApplet(applet)
    if not applet or not applet.name then
        return false
    end

    self.applets[applet.name] = applet
    return true
end

-- Initialize all registered applets
function Fireside.Dashboard:Initialize()
    -- Load global lock state
    if FiresideDB.locked ~= nil then
        self.locked = FiresideDB.locked
    end

    -- Initialize enabled applets
    for name, applet in pairs(self.applets) do
        if applet:IsEnabled() then
            applet:Initialize()
            applet:Show()

            if self.locked then
                applet:Lock()
            else
                applet:Unlock()
            end
        end
    end
end

-- Show all enabled applets
function Fireside.Dashboard:ShowAll()
    for name, applet in pairs(self.applets) do
        if applet:IsEnabled() then
            applet:Show()
        end
    end
end

-- Hide all applets
function Fireside.Dashboard:HideAll()
    for name, applet in pairs(self.applets) do
        applet:Hide()
    end
end

-- Toggle visibility of all applets
function Fireside.Dashboard:ToggleAll()
    local anyVisible = false

    for name, applet in pairs(self.applets) do
        if applet:IsEnabled() and applet.frame and applet.frame:IsShown() then
            anyVisible = true
            break
        end
    end

    if anyVisible then
        self:HideAll()
    else
        self:ShowAll()
    end
end

-- Lock all applets
function Fireside.Dashboard:LockAll()
    self.locked = true
    FiresideDB.locked = true

    for name, applet in pairs(self.applets) do
        applet:Lock()
    end

    DEFAULT_CHAT_FRAME:AddMessage("Fireside: All applets locked.", 1, 1, 0)
end

-- Unlock all applets
function Fireside.Dashboard:UnlockAll()
    self.locked = false
    FiresideDB.locked = false

    for name, applet in pairs(self.applets) do
        applet:Unlock()
    end

    DEFAULT_CHAT_FRAME:AddMessage("Fireside: All applets unlocked. Drag to reposition.", 1, 1, 0)
end

-- Check if dashboard is locked
function Fireside.Dashboard:IsLocked()
    return self.locked
end

-- Reset all applet positions
function Fireside.Dashboard:ResetAllPositions()
    for name, applet in pairs(self.applets) do
        applet:ResetPosition()
    end

    DEFAULT_CHAT_FRAME:AddMessage("Fireside: All positions reset.", 1, 1, 0)
end

-- Get an applet by name
function Fireside.Dashboard:GetApplet(name)
    return self.applets[name]
end

-- Enable an applet
function Fireside.Dashboard:EnableApplet(name)
    local applet = self.applets[name]
    if applet then
        applet:SetEnabled(true)
        DEFAULT_CHAT_FRAME:AddMessage("Fireside: " .. name .. " enabled.", 1, 1, 0)
    end
end

-- Disable an applet
function Fireside.Dashboard:DisableApplet(name)
    local applet = self.applets[name]
    if applet then
        applet:SetEnabled(false)
        DEFAULT_CHAT_FRAME:AddMessage("Fireside: " .. name .. " disabled.", 1, 1, 0)
    end
end

-- List all registered applets
function Fireside.Dashboard:ListApplets()
    DEFAULT_CHAT_FRAME:AddMessage("Fireside Applets:", 1, 1, 0)
    for name, applet in pairs(self.applets) do
        local status = applet:IsEnabled() and "enabled" or "disabled"
        DEFAULT_CHAT_FRAME:AddMessage("  " .. name .. " (" .. status .. ")", 1, 1, 1)
    end
end

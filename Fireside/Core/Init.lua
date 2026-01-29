-- Core Initialization
-- Main entry point for Fireside addon

Fireside = Fireside or {}

-- Initialize SavedVariables
local function InitializeSavedVariables()
    if not FiresideDB then
        FiresideDB = {
            applets = {},
            locked = false
        }
    end

    if not FiresideDB.applets then
        FiresideDB.applets = {}
    end

    if FiresideDB.locked == nil then
        FiresideDB.locked = false
    end
end

-- Event handler function - first param is frame, second is event name
local function OnEvent(self, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
    if event == "ADDON_LOADED" and arg1 == "Fireside" then
        InitializeSavedVariables()
        DEFAULT_CHAT_FRAME:AddMessage("Fireside loaded. Type /fireside help for commands.", 0, 1, 0)
    elseif event == "PLAYER_LOGIN" then
        if Fireside.Dashboard and Fireside.Dashboard.Initialize then
            Fireside.Dashboard:Initialize()
        end
        if Fireside.MinimapIcon and Fireside.MinimapIcon.Initialize then
            Fireside.MinimapIcon:Initialize()
        end
    end
end

-- Event handler frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", OnEvent)

-- Slash command handler
local function SlashCommandHandler(msg)
    local command, arg = string.match(msg, "^(%S+)%s*(.-)$")
    if not command then
        command = msg
    end
    command = string.lower(command or "")

    if command == "" then
        -- Open dashboard on /fireside with no arguments
        if Fireside.Settings then
            Fireside.Settings:Show()
        else
            DEFAULT_CHAT_FRAME:AddMessage("Fireside: Dashboard not available.", 1, 0, 0)
        end

    elseif command == "help" then
        DEFAULT_CHAT_FRAME:AddMessage("Fireside Commands:", 1, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage("/fireside - Open dashboard", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/fireside toggle - Show/hide all applets", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/fireside lock - Lock all applets", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/fireside unlock - Unlock all applets", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/fireside reset - Reset all positions", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/fireside list - List all applets", 1, 1, 1)

    elseif command == "toggle" then
        Fireside.Dashboard:ToggleAll()

    elseif command == "lock" then
        Fireside.Dashboard:LockAll()

    elseif command == "unlock" then
        Fireside.Dashboard:UnlockAll()

    elseif command == "settings" or command == "config" then
        if Fireside.Settings then
            Fireside.Settings:Toggle()
        else
            DEFAULT_CHAT_FRAME:AddMessage("Fireside: Settings panel not available.", 1, 0, 0)
        end

    elseif command == "reset" then
        Fireside.Dashboard:ResetAllPositions()

    elseif command == "list" then
        DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Dashboard type: " .. type(Fireside.Dashboard), 1, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Dashboard.applets type: " .. type(Fireside.Dashboard.applets), 1, 1, 0)
        local count = 0
        for k, v in pairs(Fireside.Dashboard.applets) do
            count = count + 1
            DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Found applet in table: " .. tostring(k), 1, 1, 0)
        end
        DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Total applets in table: " .. count, 1, 1, 0)
        Fireside.Dashboard:ListApplets()

    elseif command == "enable" and arg and arg ~= "" then
        Fireside.Dashboard:EnableApplet(arg)

    elseif command == "disable" and arg and arg ~= "" then
        Fireside.Dashboard:DisableApplet(arg)

    elseif command == "debug" then
        DEFAULT_CHAT_FRAME:AddMessage("=== FIRESIDE DEBUG INFO ===", 1, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage("Dashboard exists: " .. tostring(Fireside.Dashboard ~= nil), 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("Dashboard.applets type: " .. type(Fireside.Dashboard.applets), 1, 1, 1)
        local count = 0
        for k, v in pairs(Fireside.Dashboard.applets) do
            count = count + 1
            DEFAULT_CHAT_FRAME:AddMessage("  Applet: " .. tostring(k) .. " = " .. tostring(v), 1, 1, 1)
        end
        DEFAULT_CHAT_FRAME:AddMessage("Total applets: " .. count, 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("FiresideDB exists: " .. tostring(FiresideDB ~= nil), 1, 1, 1)

    elseif command == "init" then
        DEFAULT_CHAT_FRAME:AddMessage("Manually triggering Dashboard:Initialize()...", 1, 1, 0)
        Fireside.Dashboard:Initialize()

    else
        DEFAULT_CHAT_FRAME:AddMessage("Fireside: Unknown command. Type /fireside help for commands.", 1, 0, 0)
    end
end

-- Register slash commands
SLASH_FIRESIDE1 = "/fireside"
SLASH_FIRESIDE2 = "/fs"
SlashCmdList["FIRESIDE"] = SlashCommandHandler

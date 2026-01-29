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

-- Event handler function - receives event info as parameters
local function OnEvent(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
    DEFAULT_CHAT_FRAME:AddMessage("DEBUG: OnEvent called with params!", 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("DEBUG: event=" .. tostring(event) .. ", arg1=" .. tostring(arg1), 1, 0.5, 1)

    if event == "ADDON_LOADED" and arg1 == "Fireside" then
        DEFAULT_CHAT_FRAME:AddMessage("DEBUG: ADDON_LOADED for Fireside detected!", 0, 1, 1)
        InitializeSavedVariables()
        DEFAULT_CHAT_FRAME:AddMessage("Fireside loaded. Type /fireside help for commands.", 0, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Dashboard exists: " .. tostring(Fireside.Dashboard ~= nil), 1, 1, 0)
    elseif event == "PLAYER_LOGIN" then
        DEFAULT_CHAT_FRAME:AddMessage("DEBUG: PLAYER_LOGIN fired, initializing Dashboard...", 1, 1, 0)
        if Fireside.Dashboard and Fireside.Dashboard.Initialize then
            Fireside.Dashboard:Initialize()
            DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Dashboard initialized", 1, 1, 0)
        else
            DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Dashboard.Initialize not found!", 1, 0, 0)
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

    if command == "" or command == "help" then
        DEFAULT_CHAT_FRAME:AddMessage("Fireside Commands:", 1, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage("/fireside toggle - Show/hide all applets", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/fireside lock - Lock all applets", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/fireside unlock - Unlock all applets", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/fireside settings - Open settings panel", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/fireside config - Open settings panel", 1, 1, 1)
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

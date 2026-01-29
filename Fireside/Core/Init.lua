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

-- Event handler frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "Fireside" then
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
end)

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
        Fireside.Dashboard:ListApplets()

    elseif command == "enable" and arg and arg ~= "" then
        Fireside.Dashboard:EnableApplet(arg)

    elseif command == "disable" and arg and arg ~= "" then
        Fireside.Dashboard:DisableApplet(arg)

    else
        DEFAULT_CHAT_FRAME:AddMessage("Fireside: Unknown command. Type /fireside help for commands.", 1, 0, 0)
    end
end

-- Register slash commands
SLASH_FIRESIDE1 = "/fireside"
SLASH_FIRESIDE2 = "/fs"
SlashCmdList["FIRESIDE"] = SlashCommandHandler

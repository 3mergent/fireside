-- Base Applet System
-- Provides common functionality for all Fireside applets

Fireside = Fireside or {}
Fireside.Applet = {}
Fireside.Applet.__index = Fireside.Applet

-- Create a new applet instance
function Fireside.Applet:New(name, width, height)
    local applet = setmetatable({}, self)
    applet.name = name
    applet.width = width or 200
    applet.height = height or 100
    applet.frame = nil
    applet.initialized = false
    return applet
end

-- Initialize the applet frame
function Fireside.Applet:Initialize()
    if self.initialized then
        DEFAULT_CHAT_FRAME:AddMessage("DEBUG: " .. self.name .. " already initialized", 1, 0.5, 0)
        return
    end

    DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Creating frame for " .. self.name, 1, 1, 0)

    -- Create main frame
    self.frame = CreateFrame("Frame", "Fireside" .. self.name .. "Frame", UIParent)
    DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Frame created: " .. tostring(self.frame ~= nil), 1, 1, 0)

    DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Setting frame properties...", 1, 1, 0)
    self.frame:SetWidth(self.width)
    self.frame:SetHeight(self.height)
    self.frame:SetFrameStrata("MEDIUM")
    self.frame:SetMovable(true)
    self.frame:EnableMouse(true)
    self.frame:RegisterForDrag("LeftButton")
    DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Frame properties set", 1, 1, 0)

    -- Set up backdrop (background and border)
    DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Setting backdrop...", 1, 1, 0)
    self.frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Backdrop set, setting colors...", 1, 1, 0)
    self.frame:SetBackdropColor(0, 0, 0, 0.8)
    self.frame:SetBackdropBorderColor(0, 0, 0, 1.0)
    DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Backdrop colors set", 1, 1, 0)

    -- Add a bright test texture to make the frame visible
    DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Creating test texture...", 1, 1, 0)
    local testTexture = self.frame:CreateTexture(nil, "BACKGROUND")
    testTexture:SetAllPoints(self.frame)
    testTexture:SetColorTexture(1, 0, 0, 0.5)  -- Bright red, semi-transparent
    DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Added red test texture to frame", 1, 1, 0)

    -- Dragging functionality
    DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Setting up drag handlers...", 1, 1, 0)
    local applet = self  -- Capture self for closures

    self.frame:SetScript("OnDragStart", function()
        if not applet:IsLocked() then
            this:StartMoving()
        end
    end)

    self.frame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        applet:SavePosition()
    end)
    DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Drag handlers set", 1, 1, 0)

    -- Load saved position or center on screen
    DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Loading position...", 1, 1, 0)
    self:LoadPosition()
    DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Position loaded", 1, 1, 0)

    self.initialized = true
    DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Calling OnInitialize...", 1, 1, 0)
    self:OnInitialize()
    DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Applet initialization complete!", 0, 1, 0)
end

-- Override this in child classes for custom initialization
function Fireside.Applet:OnInitialize()
end

-- Show the applet
function Fireside.Applet:Show()
    if not self.initialized then
        self:Initialize()
    end
    if self.frame then
        self.frame:Show()
    end
end

-- Hide the applet
function Fireside.Applet:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

-- Toggle visibility
function Fireside.Applet:Toggle()
    if self.frame and self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

-- Lock the applet (prevent dragging)
function Fireside.Applet:Lock()
    if self.frame then
        self.frame:RegisterForDrag()
    end
end

-- Unlock the applet (allow dragging)
function Fireside.Applet:Unlock()
    if self.frame then
        self.frame:RegisterForDrag("LeftButton")
    end
end

-- Check if applet is locked
function Fireside.Applet:IsLocked()
    return Fireside.Dashboard:IsLocked()
end

-- Save current position to SavedVariables
function Fireside.Applet:SavePosition()
    if not self.frame then return end

    local point, _, relativePoint, xOfs, yOfs = self.frame:GetPoint()

    if not FiresideDB.applets[self.name] then
        FiresideDB.applets[self.name] = {}
    end

    FiresideDB.applets[self.name].position = {
        point = point,
        relativePoint = relativePoint,
        x = xOfs,
        y = yOfs
    }
end

-- Load position from SavedVariables
function Fireside.Applet:LoadPosition()
    if not self.frame then return end

    local saved = FiresideDB.applets[self.name]
    if saved and saved.position then
        local pos = saved.position
        self.frame:ClearAllPoints()
        self.frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    else
        -- Default to center of screen
        self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

-- Reset position to center of screen
function Fireside.Applet:ResetPosition()
    if not self.frame then return end

    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    self:SavePosition()
end

-- Register an event
function Fireside.Applet:RegisterEvent(event, handler)
    if not self.frame then return end

    self.frame:RegisterEvent(event)

    local oldHandler = self.frame:GetScript("OnEvent")
    self.frame:SetScript("OnEvent", function()
        if oldHandler then oldHandler() end
        if event == arg1 or not arg1 then
            handler(self)
        end
    end)
end

-- Set OnUpdate handler
function Fireside.Applet:SetOnUpdate(handler, elapsed)
    if not self.frame then return end

    local timeSinceLastUpdate = 0
    self.frame:SetScript("OnUpdate", function()
        timeSinceLastUpdate = timeSinceLastUpdate + arg1
        if timeSinceLastUpdate >= (elapsed or 0) then
            handler(self, timeSinceLastUpdate)
            timeSinceLastUpdate = 0
        end
    end)
end

-- Create a font string (text label)
function Fireside.Applet:CreateFontString(name, layer, size, justifyH, justifyV)
    if not self.frame then return nil end

    local fs = self.frame:CreateFontString(name, layer or "OVERLAY")
    fs:SetFont("Fonts\\FRIZQT__.TTF", size or 12, "OUTLINE")
    fs:SetJustifyH(justifyH or "LEFT")
    fs:SetJustifyV(justifyV or "TOP")
    fs:SetTextColor(1, 1, 1, 1)

    return fs
end

-- Check if applet is enabled
function Fireside.Applet:IsEnabled()
    local saved = FiresideDB.applets[self.name]
    if saved and saved.enabled ~= nil then
        return saved.enabled
    end
    return true
end

-- Set enabled state
function Fireside.Applet:SetEnabled(enabled)
    if not FiresideDB.applets[self.name] then
        FiresideDB.applets[self.name] = {}
    end

    FiresideDB.applets[self.name].enabled = enabled

    if enabled then
        self:Show()
    else
        self:Hide()
    end
end

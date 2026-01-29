-- Base Applet System
-- Provides common functionality for all Fireside applets

Fireside = Fireside or {}
Fireside.Applet = {}
Fireside.Applet.__index = Fireside.Applet

-- Create a new applet instance
function Fireside.Applet:New(name, width, height, minWidth, maxWidth, minHeight, maxHeight)
    local applet = setmetatable({}, self)
    applet.name = name
    applet.width = width or 200
    applet.height = height or 100
    applet.minWidth = minWidth or 200
    applet.maxWidth = maxWidth or 400
    applet.minHeight = minHeight or 150
    applet.maxHeight = maxHeight or 300
    applet.frame = nil
    applet.resizeHandle = nil
    applet.initialized = false
    return applet
end

-- Initialize the applet frame
function Fireside.Applet:Initialize()
    if self.initialized then
        return
    end

    -- Create main frame
    self.frame = CreateFrame("Frame", "Fireside" .. self.name .. "Frame", UIParent)
    self.frame:SetWidth(self.width)
    self.frame:SetHeight(self.height)
    self.frame:SetFrameStrata("MEDIUM")
    self.frame:SetMovable(true)
    self.frame:EnableMouse(true)
    self.frame:RegisterForDrag("LeftButton")

    -- Create background texture (SetBackdrop doesn't work in TBC Anniversary)
    local bg = self.frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(self.frame)
    bg:SetColorTexture(0, 0, 0, 0.5)  -- Black with 50% opacity (more transparent)

    -- Create border texture
    local border = self.frame:CreateTexture(nil, "BORDER")
    border:SetAllPoints(self.frame)
    border:SetColorTexture(0, 0, 0, 1.0)  -- Black border, fully opaque

    DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Creating resize handle...", 1, 1, 0)
    -- Create resize handle in bottom right corner
    self.resizeHandle = CreateFrame("Frame", nil, self.frame)
    self.resizeHandle:SetWidth(16)
    self.resizeHandle:SetHeight(16)
    self.resizeHandle:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 0, 0)
    self.resizeHandle:EnableMouse(true)
    self.resizeHandle:SetFrameLevel(self.frame:GetFrameLevel() + 1)

    -- Resize handle texture (small arrow/grip)
    local resizeTexture = self.resizeHandle:CreateTexture(nil, "OVERLAY")
    resizeTexture:SetAllPoints(self.resizeHandle)
    resizeTexture:SetColorTexture(0.5, 0.5, 0.5, 0.8)  -- Gray, semi-transparent
    DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Resize handle created", 1, 1, 0)

    -- Dragging functionality
    local applet = self  -- Capture self for closures

    self.frame:SetScript("OnDragStart", function(self)
        if not applet:IsLocked() then
            self:StartMoving()
        end
    end)

    self.frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        applet:SavePosition()
    end)

    -- Resize handle drag handlers
    self.resizeHandle:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and not applet:IsLocked() then
            applet.frame:StartSizing("BOTTOMRIGHT")
            applet.isResizing = true
        end
    end)

    self.resizeHandle:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and applet.isResizing then
            applet.frame:StopMovingOrSizing()
            applet.isResizing = false

            -- Clamp size to min/max
            local width = applet.frame:GetWidth()
            local height = applet.frame:GetHeight()

            if width < applet.minWidth then width = applet.minWidth end
            if width > applet.maxWidth then width = applet.maxWidth end
            if height < applet.minHeight then height = applet.minHeight end
            if height > applet.maxHeight then height = applet.maxHeight end

            applet.frame:SetWidth(width)
            applet.frame:SetHeight(height)
            applet.width = width
            applet.height = height

            applet:SaveSize()
            applet:OnResize(width, height)
        end
    end)

    -- Enable resizing
    DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Setting up resize constraints...", 1, 1, 0)
    self.frame:SetResizable(true)
    self.frame:SetMinResize(self.minWidth, self.minHeight)
    self.frame:SetMaxResize(self.maxWidth, self.maxHeight)
    DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Resize constraints set", 1, 1, 0)

    -- Load saved position or center on screen
    self:LoadPosition()
    self:LoadSize()

    -- Hide resize handle initially (will be shown on unlock)
    DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Hiding resize handle...", 1, 1, 0)
    if self.resizeHandle then
        self.resizeHandle:Hide()
    end

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
    DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Show() called for " .. self.name, 1, 1, 0)
    if not self.initialized then
        self:Initialize()
    end
    if self.frame then
        DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Calling frame:Show()...", 1, 1, 0)
        self.frame:Show()
        DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Frame shown, IsShown=" .. tostring(self.frame:IsShown()), 0, 1, 0)
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

-- Lock the applet (prevent dragging and hide resize handle)
function Fireside.Applet:Lock()
    if self.frame then
        self.frame:RegisterForDrag()
    end
    if self.resizeHandle then
        self.resizeHandle:Hide()
    end
end

-- Unlock the applet (allow dragging and show resize handle)
function Fireside.Applet:Unlock()
    if self.frame then
        self.frame:RegisterForDrag("LeftButton")
    end
    if self.resizeHandle then
        self.resizeHandle:Show()
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

-- Save current size to SavedVariables
function Fireside.Applet:SaveSize()
    if not self.frame then return end

    if not FiresideDB.applets[self.name] then
        FiresideDB.applets[self.name] = {}
    end

    FiresideDB.applets[self.name].size = {
        width = self.width,
        height = self.height
    }
end

-- Load size from SavedVariables
function Fireside.Applet:LoadSize()
    if not self.frame then return end

    local saved = FiresideDB.applets[self.name]
    if saved and saved.size then
        local width = saved.size.width
        local height = saved.size.height

        -- Clamp to min/max
        if width < self.minWidth then width = self.minWidth end
        if width > self.maxWidth then width = self.maxWidth end
        if height < self.minHeight then height = self.minHeight end
        if height > self.maxHeight then height = self.maxHeight end

        self.frame:SetWidth(width)
        self.frame:SetHeight(height)
        self.width = width
        self.height = height
    end
end

-- Override this in child classes to handle resize events
function Fireside.Applet:OnResize(width, height)
    -- Child classes can override this to reposition UI elements
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
    fs:SetFont("Interface\\AddOns\\Fireside\\Fonts\\Accidental Presidency.ttf", size or 12, "OUTLINE")
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

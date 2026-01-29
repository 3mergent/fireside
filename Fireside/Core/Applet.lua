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
    bg:SetColorTexture(0, 0, 0, 0.8)  -- Black with 80% opacity

    -- Create border texture
    local border = self.frame:CreateTexture(nil, "BORDER")
    border:SetAllPoints(self.frame)
    border:SetColorTexture(0, 0, 0, 1.0)  -- Black border, fully opaque

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

    -- Load saved position or center on screen
    self:LoadPosition()

    self.initialized = true
    self:OnInitialize()
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

-- Minimap Icon
-- Creates a clickable minimap button for Fireside

Fireside = Fireside or {}
Fireside.MinimapIcon = {}

local minimapButton = nil

-- Create the minimap button
local function CreateMinimapButton()
    if minimapButton then return minimapButton end

    -- Create button
    minimapButton = CreateFrame("Button", "FiresideMinimapButton", Minimap)
    minimapButton:SetWidth(32)
    minimapButton:SetHeight(32)
    minimapButton:SetFrameStrata("MEDIUM")
    minimapButton:SetFrameLevel(8)
    minimapButton:SetMovable(true)
    minimapButton:EnableMouse(true)
    minimapButton:RegisterForDrag("LeftButton")
    minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    -- Set the icon texture (Hearthstone Bronze)
    local icon = minimapButton:CreateTexture(nil, "BACKGROUND")
    icon:SetWidth(20)
    icon:SetHeight(20)
    icon:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)
    icon:SetTexture("Interface\\Icons\\INV_Hearthstone_Bronze")

    -- Create border/background
    local overlay = minimapButton:CreateTexture(nil, "OVERLAY")
    overlay:SetWidth(32)
    overlay:SetHeight(32)
    overlay:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    -- Position on minimap (default position)
    local savedPosition = 45  -- degrees around minimap
    if FiresideDB and FiresideDB.minimapPosition then
        savedPosition = FiresideDB.minimapPosition
    end

    local function UpdatePosition(angle)
        local x = 80 * math.cos(angle)
        local y = 80 * math.sin(angle)
        minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end

    UpdatePosition(savedPosition)

    -- Dragging functionality
    minimapButton:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self.isDragging = true
    end)

    minimapButton:SetScript("OnDragStop", function(self)
        self:UnlockHighlight()
        self.isDragging = false
    end)

    minimapButton:SetScript("OnUpdate", function(self)
        if self.isDragging then
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            px, py = px / scale, py / scale

            local angle = math.atan2(py - my, px - mx)
            local x = 80 * math.cos(angle)
            local y = 80 * math.sin(angle)

            self:ClearAllPoints()
            self:SetPoint("CENTER", Minimap, "CENTER", x, y)

            -- Save position
            if not FiresideDB then FiresideDB = {} end
            FiresideDB.minimapPosition = angle
        end
    end)

    -- Click handlers
    minimapButton:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            -- Left click: Open dashboard
            if Fireside.Settings then
                Fireside.Settings:Toggle()
            end
        elseif button == "RightButton" then
            -- Right click: Toggle all applets
            if Fireside.Dashboard then
                Fireside.Dashboard:ToggleAll()
            end
        end
    end)

    -- Tooltip
    minimapButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Fireside", 1, 0.82, 0, 1)
        GameTooltip:AddLine("Left-click: Open Dashboard", 1, 1, 1)
        GameTooltip:AddLine("Right-click: Toggle Applets", 1, 1, 1)
        GameTooltip:AddLine("Drag to move", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)

    minimapButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    return minimapButton
end

-- Initialize minimap icon
function Fireside.MinimapIcon:Initialize()
    CreateMinimapButton()
end

-- Show minimap icon
function Fireside.MinimapIcon:Show()
    local button = CreateMinimapButton()
    button:Show()
end

-- Hide minimap icon
function Fireside.MinimapIcon:Hide()
    if minimapButton then
        minimapButton:Hide()
    end
end

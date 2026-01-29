-- Dashboard UI
-- Control panel for managing Fireside applets

Fireside = Fireside or {}
Fireside.Settings = {}

local dashboardFrame = nil

-- Create the dashboard frame
local function CreateDashboardFrame()
    if dashboardFrame then return dashboardFrame end

    -- Main frame (400x300)
    dashboardFrame = CreateFrame("Frame", "FiresideDashboardFrame", UIParent)
    dashboardFrame:SetWidth(400)
    dashboardFrame:SetHeight(300)
    dashboardFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    dashboardFrame:SetFrameStrata("DIALOG")
    dashboardFrame:SetMovable(true)
    dashboardFrame:EnableMouse(true)
    dashboardFrame:RegisterForDrag("LeftButton")
    dashboardFrame:Hide()

    -- Create background texture
    local bg = dashboardFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(dashboardFrame)
    bg:SetColorTexture(0, 0, 0, 0.8)  -- Black with 80% opacity

    -- Create 1px border edges (#ff4000 orange)
    local borderTop = dashboardFrame:CreateTexture(nil, "BORDER")
    borderTop:SetHeight(1)
    borderTop:SetColorTexture(1.0, 0.251, 0.0, 1.0)
    borderTop:SetPoint("TOPLEFT", dashboardFrame, "TOPLEFT")
    borderTop:SetPoint("TOPRIGHT", dashboardFrame, "TOPRIGHT")

    local borderBottom = dashboardFrame:CreateTexture(nil, "BORDER")
    borderBottom:SetHeight(1)
    borderBottom:SetColorTexture(1.0, 0.251, 0.0, 1.0)
    borderBottom:SetPoint("BOTTOMLEFT", dashboardFrame, "BOTTOMLEFT")
    borderBottom:SetPoint("BOTTOMRIGHT", dashboardFrame, "BOTTOMRIGHT")

    local borderLeft = dashboardFrame:CreateTexture(nil, "BORDER")
    borderLeft:SetWidth(1)
    borderLeft:SetColorTexture(1.0, 0.251, 0.0, 1.0)
    borderLeft:SetPoint("TOPLEFT", dashboardFrame, "TOPLEFT")
    borderLeft:SetPoint("BOTTOMLEFT", dashboardFrame, "BOTTOMLEFT")

    local borderRight = dashboardFrame:CreateTexture(nil, "BORDER")
    borderRight:SetWidth(1)
    borderRight:SetColorTexture(1.0, 0.251, 0.0, 1.0)
    borderRight:SetPoint("TOPRIGHT", dashboardFrame, "TOPRIGHT")
    borderRight:SetPoint("BOTTOMRIGHT", dashboardFrame, "BOTTOMRIGHT")

    -- Dragging functionality
    dashboardFrame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)

    dashboardFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    -- Title
    local title = dashboardFrame:CreateFontString(nil, "OVERLAY")
    title:SetFont("Interface\\AddOns\\Fireside\\Fonts\\Accidental Presidency.ttf", 18, "OUTLINE")
    title:SetPoint("TOP", dashboardFrame, "TOP", 0, -15)
    title:SetText("Fireside Dashboard")
    title:SetTextColor(1, 0.82, 0, 1)

    -- Helper function to create a bordered card
    local function CreateBorderedCard(parent, width, height)
        local card = CreateFrame("Frame", nil, parent)
        card:SetFrameLevel(parent:GetFrameLevel() + 2)
        card:SetWidth(width)
        card:SetHeight(height)

        -- Create 4 border edges
        local borderTop = card:CreateTexture(nil, "OVERLAY")
        borderTop:SetHeight(1)
        borderTop:SetColorTexture(0.2, 0.2, 0.2, 1)
        borderTop:SetPoint("TOPLEFT", card, "TOPLEFT")
        borderTop:SetPoint("TOPRIGHT", card, "TOPRIGHT")

        local borderBottom = card:CreateTexture(nil, "OVERLAY")
        borderBottom:SetHeight(1)
        borderBottom:SetColorTexture(0.2, 0.2, 0.2, 1)
        borderBottom:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT")
        borderBottom:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT")

        local borderLeft = card:CreateTexture(nil, "OVERLAY")
        borderLeft:SetWidth(1)
        borderLeft:SetColorTexture(0.2, 0.2, 0.2, 1)
        borderLeft:SetPoint("TOPLEFT", card, "TOPLEFT")
        borderLeft:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT")

        local borderRight = card:CreateTexture(nil, "OVERLAY")
        borderRight:SetWidth(1)
        borderRight:SetColorTexture(0.2, 0.2, 0.2, 1)
        borderRight:SetPoint("TOPRIGHT", card, "TOPRIGHT")
        borderRight:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT")

        return card
    end

    -- XP Tracker card
    local xpTrackerCard = CreateBorderedCard(dashboardFrame, 360, 60)
    xpTrackerCard:SetPoint("TOP", dashboardFrame, "TOP", 0, -55)

    -- XP Tracker label
    local xpTrackerLabel = dashboardFrame:CreateFontString(nil, "OVERLAY")
    xpTrackerLabel:SetFont("Interface\\AddOns\\Fireside\\Fonts\\Accidental Presidency.ttf", 16, "OUTLINE")
    xpTrackerLabel:SetPoint("LEFT", xpTrackerCard, "LEFT", 15, 0)
    xpTrackerLabel:SetText("XP Tracker")
    xpTrackerLabel:SetTextColor(1, 1, 1, 1)

    -- XP Tracker open button
    local xpTrackerButton = CreateFrame("Button", nil, xpTrackerCard)
    xpTrackerButton:SetWidth(80)
    xpTrackerButton:SetHeight(30)
    xpTrackerButton:SetPoint("RIGHT", xpTrackerCard, "RIGHT", -15, 0)

    -- Button background
    local buttonBg = xpTrackerButton:CreateTexture(nil, "BACKGROUND")
    buttonBg:SetAllPoints(xpTrackerButton)
    buttonBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

    -- Button border
    local buttonBorderTop = xpTrackerButton:CreateTexture(nil, "BORDER")
    buttonBorderTop:SetHeight(1)
    buttonBorderTop:SetColorTexture(0.4, 0.4, 0.4, 1)
    buttonBorderTop:SetPoint("TOPLEFT", xpTrackerButton, "TOPLEFT")
    buttonBorderTop:SetPoint("TOPRIGHT", xpTrackerButton, "TOPRIGHT")

    local buttonBorderBottom = xpTrackerButton:CreateTexture(nil, "BORDER")
    buttonBorderBottom:SetHeight(1)
    buttonBorderBottom:SetColorTexture(0.4, 0.4, 0.4, 1)
    buttonBorderBottom:SetPoint("BOTTOMLEFT", xpTrackerButton, "BOTTOMLEFT")
    buttonBorderBottom:SetPoint("BOTTOMRIGHT", xpTrackerButton, "BOTTOMRIGHT")

    local buttonBorderLeft = xpTrackerButton:CreateTexture(nil, "BORDER")
    buttonBorderLeft:SetWidth(1)
    buttonBorderLeft:SetColorTexture(0.4, 0.4, 0.4, 1)
    buttonBorderLeft:SetPoint("TOPLEFT", xpTrackerButton, "TOPLEFT")
    buttonBorderLeft:SetPoint("BOTTOMLEFT", xpTrackerButton, "BOTTOMLEFT")

    local buttonBorderRight = xpTrackerButton:CreateTexture(nil, "BORDER")
    buttonBorderRight:SetWidth(1)
    buttonBorderRight:SetColorTexture(0.4, 0.4, 0.4, 1)
    buttonBorderRight:SetPoint("TOPRIGHT", xpTrackerButton, "TOPRIGHT")
    buttonBorderRight:SetPoint("BOTTOMRIGHT", xpTrackerButton, "BOTTOMRIGHT")

    -- Button text
    local buttonText = xpTrackerButton:CreateFontString(nil, "OVERLAY")
    buttonText:SetFont("Interface\\AddOns\\Fireside\\Fonts\\Accidental Presidency.ttf", 13, "OUTLINE")
    buttonText:SetPoint("CENTER", xpTrackerButton, "CENTER", 0, 0)
    buttonText:SetText("Open")
    buttonText:SetTextColor(1, 1, 1, 1)

    -- Button hover effect
    xpTrackerButton:SetScript("OnEnter", function(self)
        buttonBg:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    end)

    xpTrackerButton:SetScript("OnLeave", function(self)
        buttonBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    end)

    -- Button click
    xpTrackerButton:SetScript("OnClick", function(self)
        local xpTracker = Fireside.Dashboard:GetApplet("XPTracker")
        if xpTracker then
            xpTracker:Show()
        end
    end)

    -- Close button (X in top right)
    local closeButton = CreateFrame("Button", nil, dashboardFrame)
    closeButton:SetWidth(20)
    closeButton:SetHeight(20)
    closeButton:SetPoint("TOPRIGHT", dashboardFrame, "TOPRIGHT", -10, -10)

    local closeText = closeButton:CreateFontString(nil, "OVERLAY")
    closeText:SetFont("Interface\\AddOns\\Fireside\\Fonts\\Accidental Presidency.ttf", 16, "OUTLINE")
    closeText:SetPoint("CENTER", closeButton, "CENTER", 0, 0)
    closeText:SetText("X")
    closeText:SetTextColor(1, 1, 1, 1)

    closeButton:SetScript("OnEnter", function(self)
        closeText:SetTextColor(1, 0.2, 0.2, 1)
    end)

    closeButton:SetScript("OnLeave", function(self)
        closeText:SetTextColor(1, 1, 1, 1)
    end)

    closeButton:SetScript("OnClick", function(self)
        dashboardFrame:Hide()
    end)

    return dashboardFrame
end

-- Show dashboard
function Fireside.Settings:Show()
    local frame = CreateDashboardFrame()
    frame:Show()
end

-- Hide dashboard
function Fireside.Settings:Hide()
    if dashboardFrame then
        dashboardFrame:Hide()
    end
end

-- Toggle dashboard
function Fireside.Settings:Toggle()
    local frame = CreateDashboardFrame()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

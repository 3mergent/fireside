-- Settings UI
-- Configuration panel for Fireside addon

Fireside = Fireside or {}
Fireside.Settings = {}

local settingsFrame = nil
local checkboxes = {}

-- Create the settings frame
local function CreateSettingsFrame()
    if settingsFrame then return settingsFrame end

    -- Main frame
    settingsFrame = CreateFrame("Frame", "FiresideSettingsFrame", UIParent)
    settingsFrame:SetWidth(400)
    settingsFrame:SetHeight(300)
    settingsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    settingsFrame:SetFrameStrata("DIALOG")
    settingsFrame:SetMovable(true)
    settingsFrame:EnableMouse(true)
    settingsFrame:RegisterForDrag("LeftButton")
    settingsFrame:Hide()

    -- Backdrop
    settingsFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    settingsFrame:SetBackdropColor(0, 0, 0, 0.95)

    -- Dragging
    settingsFrame:SetScript("OnDragStart", function()
        this:StartMoving()
    end)
    settingsFrame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
    end)

    -- Title
    local title = settingsFrame:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    title:SetPoint("TOP", settingsFrame, "TOP", 0, -20)
    title:SetText("Fireside Settings")
    title:SetTextColor(1, 0.82, 0, 1)

    -- Close button
    local closeButton = CreateFrame("Button", nil, settingsFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", settingsFrame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        settingsFrame:Hide()
    end)

    -- Applet checkboxes section
    local appletLabel = settingsFrame:CreateFontString(nil, "OVERLAY")
    appletLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    appletLabel:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 20, -60)
    appletLabel:SetText("Applets:")
    appletLabel:SetTextColor(1, 1, 1, 1)

    local yOffset = -85
    for name, applet in pairs(Fireside.Dashboard.applets) do
        local checkbox = CreateFrame("CheckButton", "FiresideSettings" .. name .. "Checkbox", settingsFrame, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 20, yOffset)
        checkbox:SetWidth(24)
        checkbox:SetHeight(24)

        local label = settingsFrame:CreateFontString(nil, "OVERLAY")
        label:SetFont("Fonts\\FRIZQT__.TTF", 11)
        label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        label:SetText(name)
        label:SetTextColor(1, 1, 1, 1)

        checkbox:SetChecked(applet:IsEnabled())

        checkbox:SetScript("OnClick", function()
            if this:GetChecked() then
                Fireside.Dashboard:EnableApplet(name)
            else
                Fireside.Dashboard:DisableApplet(name)
            end
        end)

        checkboxes[name] = checkbox
        yOffset = yOffset - 30
    end

    -- Lock/Unlock button
    local lockButton = CreateFrame("Button", "FiresideLockButton", settingsFrame, "UIPanelButtonTemplate")
    lockButton:SetWidth(120)
    lockButton:SetHeight(25)
    lockButton:SetPoint("BOTTOMLEFT", settingsFrame, "BOTTOMLEFT", 20, 60)
    lockButton:SetText("Lock All")

    lockButton:SetScript("OnClick", function()
        if Fireside.Dashboard:IsLocked() then
            Fireside.Dashboard:UnlockAll()
            this:SetText("Lock All")
        else
            Fireside.Dashboard:LockAll()
            this:SetText("Unlock All")
        end
    end)

    -- Update button text based on current state
    local function UpdateLockButton()
        if Fireside.Dashboard:IsLocked() then
            lockButton:SetText("Unlock All")
        else
            lockButton:SetText("Lock All")
        end
    end

    settingsFrame:SetScript("OnShow", UpdateLockButton)

    -- Reset all positions button
    local resetButton = CreateFrame("Button", "FiresideResetButton", settingsFrame, "UIPanelButtonTemplate")
    resetButton:SetWidth(150)
    resetButton:SetHeight(25)
    resetButton:SetPoint("BOTTOMLEFT", settingsFrame, "BOTTOMLEFT", 150, 60)
    resetButton:SetText("Reset All Positions")

    resetButton:SetScript("OnClick", function()
        Fireside.Dashboard:ResetAllPositions()
    end)

    -- Close button at bottom
    local closeBottomButton = CreateFrame("Button", "FiresideCloseButton", settingsFrame, "UIPanelButtonTemplate")
    closeBottomButton:SetWidth(80)
    closeBottomButton:SetHeight(25)
    closeBottomButton:SetPoint("BOTTOM", settingsFrame, "BOTTOM", 0, 20)
    closeBottomButton:SetText("Close")

    closeBottomButton:SetScript("OnClick", function()
        settingsFrame:Hide()
    end)

    return settingsFrame
end

-- Show settings panel
function Fireside.Settings:Show()
    local frame = CreateSettingsFrame()
    frame:Show()
end

-- Hide settings panel
function Fireside.Settings:Hide()
    if settingsFrame then
        settingsFrame:Hide()
    end
end

-- Toggle settings panel
function Fireside.Settings:Toggle()
    local frame = CreateSettingsFrame()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

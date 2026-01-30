-- Item Tracker Applet
-- Tracks items gained in session or displays total counts

Fireside = Fireside or {}

-- Create Item Tracker applet instance
local ItemTracker = Fireside.Applet:New("ItemTracker", 220, 180, 180, 320, 140, 400)

-- UI Elements
local logoTexture
local titleText
local itemsContainer
local itemFrames = {}  -- Store item display frames
local toggleButton
local modeLabel
local settingsButton

-- Data
local trackedItems = {}  -- List of item IDs to track
local sessionCounts = {}  -- Count of items gained in current session
local sessionBaseline = {}  -- Starting counts when session began
local currentMode = "total"  -- "session" or "total"

-- Settings Panel
local settingsPanel = nil

-- Initialize UI
function ItemTracker:OnInitialize()
    -- Load saved data
    local saved = FiresideDB.applets[self.name]
    if saved and saved.data then
        trackedItems = saved.data.trackedItems or {}
        sessionCounts = saved.data.sessionCounts or {}
        sessionBaseline = saved.data.sessionBaseline or {}
        currentMode = saved.data.mode or "total"
    end

    -- Logo (treasure chest icon)
    local logoSize = math.floor(self.width * 0.36)
    logoTexture = self.frame:CreateTexture(nil, "ARTWORK")
    logoTexture:SetTexture("Interface\\Icons\\INV_Box_02")  -- Treasure chest icon
    logoTexture:SetWidth(logoSize)
    logoTexture:SetHeight(logoSize)
    local logoXOffset = 10 - math.floor(logoSize * 0.25)
    local logoYOffset = math.floor(logoSize / 2) - 5
    logoTexture:SetPoint("TOPLEFT", self.frame, "TOPLEFT", logoXOffset, logoYOffset)

    -- Title
    titleText = self:CreateFontString(nil, "OVERLAY", 11, "RIGHT", "TOP")
    titleText:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -5, -8)
    titleText:SetText("Fireside Item Tracker")
    titleText:SetTextColor(1, 0.82, 0, 1)

    -- Make heading clickable for settings
    local headingButton = CreateFrame("Button", nil, self.frame)
    headingButton:SetAllPoints(titleText)
    headingButton:RegisterForClicks("LeftButtonUp")
    headingButton:SetScript("OnClick", function()
        self:ToggleSettings()
    end)

    -- Items container (scrollable area for item display)
    itemsContainer = CreateFrame("Frame", nil, self.frame)
    itemsContainer:SetFrameLevel(self.frame:GetFrameLevel() + 2)

    -- Mode label
    modeLabel = self:CreateFontString(nil, "OVERLAY", 11, "CENTER", "BOTTOM")
    modeLabel:SetTextColor(0.7, 0.7, 0.7, 1)

    -- Toggle button for Session/Total
    toggleButton = CreateFrame("Button", nil, self.frame)
    toggleButton:SetWidth(80)
    toggleButton:SetHeight(20)
    toggleButton:SetFrameLevel(self.frame:GetFrameLevel() + 3)

    -- Toggle button background
    local toggleBg = toggleButton:CreateTexture(nil, "BACKGROUND")
    toggleBg:SetAllPoints(toggleButton)
    toggleBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

    -- Toggle button border
    local toggleBorder = toggleButton:CreateTexture(nil, "BORDER")
    toggleBorder:SetAllPoints(toggleButton)
    toggleBorder:SetColorTexture(0.4, 0.4, 0.4, 1.0)

    -- Toggle button text
    local toggleText = toggleButton:CreateFontString(nil, "OVERLAY")
    toggleText:SetFont("Interface\\AddOns\\Fireside\\Fonts\\Accidental Presidency.ttf", 10, "OUTLINE")
    toggleText:SetPoint("CENTER", toggleButton, "CENTER", 0, 0)
    toggleText:SetTextColor(1, 1, 1, 1)

    toggleButton.text = toggleText
    toggleButton:SetScript("OnClick", function()
        self:ToggleMode()
    end)

    -- Enable right-click on frame to open settings
    self.frame:RegisterForClicks("RightButtonUp")
    self.frame:SetScript("OnMouseUp", function(frame, button)
        if button == "RightButton" then
            self:ToggleSettings()
        end
    end)

    -- Register bag update events to track item gains
    self.frame:RegisterEvent("BAG_UPDATE")
    self.frame:SetScript("OnEvent", function()
        if event == "BAG_UPDATE" then
            self:OnBagUpdate()
        end
    end)

    -- Initial layout and data update
    self:UpdateLayout()
    self:UpdateToggleButton()
    self:UpdateItemDisplay()
end

-- Update layout when resizing
function ItemTracker:OnResize(width, height)
    self:UpdateLayout()
end

-- Update layout positions
function ItemTracker:UpdateLayout()
    local cardPadding = 8

    -- Position items container
    itemsContainer:ClearAllPoints()
    itemsContainer:SetPoint("TOPLEFT", self.frame, "TOPLEFT", cardPadding, -45)
    itemsContainer:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -cardPadding, -45)
    itemsContainer:SetHeight(self.height - 110)  -- Leave room for toggle at bottom

    -- Position toggle button at bottom
    toggleButton:ClearAllPoints()
    toggleButton:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, cardPadding + 15)

    -- Position mode label below toggle
    modeLabel:ClearAllPoints()
    modeLabel:SetPoint("TOP", toggleButton, "BOTTOM", 0, -2)

    self:UpdateItemDisplay()
end

-- Toggle between Session and Total modes
function ItemTracker:ToggleMode()
    if currentMode == "total" then
        -- Switch to Session mode - start new session
        currentMode = "session"
        self:StartNewSession()
    else
        -- Switch to Total mode
        currentMode = "total"
    end

    self:SaveData()
    self:UpdateToggleButton()
    self:UpdateItemDisplay()
end

-- Update toggle button text and appearance
function ItemTracker:UpdateToggleButton()
    if currentMode == "session" then
        toggleButton.text:SetText("SESSION")
        toggleButton.text:SetTextColor(0.3, 0.8, 0.3, 1)  -- Green
        modeLabel:SetText("(tracking items gained)")
    else
        toggleButton.text:SetText("TOTAL")
        toggleButton.text:SetTextColor(0.3, 0.5, 0.9, 1)  -- Blue
        modeLabel:SetText("(current inventory)")
    end
end

-- Start a new session
function ItemTracker:StartNewSession()
    sessionCounts = {}
    sessionBaseline = {}

    -- Record current counts as baseline
    for _, itemID in ipairs(trackedItems) do
        local count = GetItemCount(itemID, true)  -- true = include bank
        sessionBaseline[itemID] = count
    end

    self:SaveData()
end

-- Get display count for an item based on current mode
function ItemTracker:GetItemDisplayCount(itemID)
    if currentMode == "session" then
        -- Return items gained since session start
        return sessionCounts[itemID] or 0
    else
        -- Return total count in inventory
        return GetItemCount(itemID, true)  -- true = include bank
    end
end

-- Update item display
function ItemTracker:UpdateItemDisplay()
    -- Clear existing item frames
    for _, frame in ipairs(itemFrames) do
        frame:Hide()
    end
    itemFrames = {}

    local numItems = table.getn(trackedItems)
    if numItems == 0 then
        -- Show a message when no items are tracked
        -- (optional - could add this later)
        return
    end

    -- Calculate layout
    local iconSize = 36
    local spacing = 8
    local maxPerRow = 5
    local numRows = math.ceil(numItems / maxPerRow)

    local containerWidth = itemsContainer:GetWidth()
    local containerHeight = itemsContainer:GetHeight()

    local row = 0
    local col = 0

    for i, itemID in ipairs(trackedItems) do
        -- Get item info
        local itemName, itemLink, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemID)
        if not itemTexture then
            itemTexture = "Interface\\Icons\\INV_Misc_QuestionMark"
        end

        -- Create item frame
        local itemFrame = CreateFrame("Frame", nil, itemsContainer)
        itemFrame:SetWidth(iconSize + 10)
        itemFrame:SetHeight(iconSize + 20)

        -- Item icon
        local icon = itemFrame:CreateTexture(nil, "ARTWORK")
        icon:SetTexture(itemTexture)
        icon:SetWidth(iconSize)
        icon:SetHeight(iconSize)
        icon:SetPoint("TOP", itemFrame, "TOP", 0, 0)

        -- Item count text
        local countText = itemFrame:CreateFontString(nil, "OVERLAY")
        countText:SetFont("Interface\\AddOns\\Fireside\\Fonts\\Accidental Presidency.ttf", 13, "OUTLINE")
        countText:SetPoint("TOP", icon, "BOTTOM", 0, -2)
        countText:SetTextColor(1, 1, 1, 1)

        local count = self:GetItemDisplayCount(itemID)
        countText:SetText(tostring(count))

        -- Calculate position
        local itemsInRow = math.min(numItems - (row * maxPerRow), maxPerRow)
        local rowWidth = (itemsInRow * (iconSize + 10)) + ((itemsInRow - 1) * spacing)
        local startX = (containerWidth - rowWidth) / 2

        local x = startX + (col * (iconSize + 10 + spacing))
        local y = -10 - (row * (iconSize + 30))

        -- Special case: single item - center vertically too
        if numItems == 1 then
            y = -(containerHeight - (iconSize + 20)) / 2
        end

        itemFrame:SetPoint("TOPLEFT", itemsContainer, "TOPLEFT", x, y)

        table.insert(itemFrames, itemFrame)

        -- Move to next position
        col = col + 1
        if col >= maxPerRow then
            col = 0
            row = row + 1
        end
    end
end

-- Handle bag updates to track item gains
function ItemTracker:OnBagUpdate()
    if currentMode ~= "session" then
        -- Only track in session mode
        if currentMode == "total" then
            -- Just update display for total mode
            self:UpdateItemDisplay()
        end
        return
    end

    -- Check each tracked item
    for _, itemID in ipairs(trackedItems) do
        local currentCount = GetItemCount(itemID, true)
        local baseline = sessionBaseline[itemID] or 0
        local previousTotal = baseline + (sessionCounts[itemID] or 0)

        if currentCount > previousTotal then
            -- Item was gained!
            local gained = currentCount - previousTotal
            sessionCounts[itemID] = (sessionCounts[itemID] or 0) + gained
            sessionBaseline[itemID] = currentCount - sessionCounts[itemID]
        elseif currentCount < previousTotal then
            -- Item was lost (used, sold, etc)
            -- Update baseline to reflect new total, but keep session count
            local sessionCount = sessionCounts[itemID] or 0
            sessionBaseline[itemID] = currentCount - sessionCount

            -- If session count goes negative, reset it
            if sessionBaseline[itemID] < 0 then
                sessionBaseline[itemID] = currentCount
                sessionCounts[itemID] = 0
            end
        end
    end

    self:SaveData()
    self:UpdateItemDisplay()
end

-- Save data to SavedVariables
function ItemTracker:SaveData()
    if not FiresideDB.applets[self.name] then
        FiresideDB.applets[self.name] = {}
    end

    FiresideDB.applets[self.name].data = {
        trackedItems = trackedItems,
        sessionCounts = sessionCounts,
        sessionBaseline = sessionBaseline,
        mode = currentMode
    }
end

-- Add an item to track
function ItemTracker:AddItem(itemID)
    -- Check if already tracked
    for _, id in ipairs(trackedItems) do
        if id == itemID then
            return false
        end
    end

    table.insert(trackedItems, itemID)

    -- Initialize session data for this item
    if currentMode == "session" then
        sessionBaseline[itemID] = GetItemCount(itemID, true)
        sessionCounts[itemID] = 0
    end

    self:SaveData()
    self:UpdateItemDisplay()
    return true
end

-- Remove an item from tracking
function ItemTracker:RemoveItem(itemID)
    for i, id in ipairs(trackedItems) do
        if id == itemID then
            table.remove(trackedItems, i)
            sessionCounts[itemID] = nil
            sessionBaseline[itemID] = nil
            self:SaveData()
            self:UpdateItemDisplay()
            return true
        end
    end
    return false
end

-- Toggle settings panel
function ItemTracker:ToggleSettings()
    if not settingsPanel then
        self:CreateSettingsPanel()
    end

    if settingsPanel:IsShown() then
        settingsPanel:Hide()
    else
        settingsPanel:Show()
        self:UpdateSettingsPanel()
    end
end

-- Create settings panel UI
function ItemTracker:CreateSettingsPanel()
    settingsPanel = CreateFrame("Frame", "FiresideItemTrackerSettings", UIParent)
    settingsPanel:SetWidth(300)
    settingsPanel:SetHeight(400)
    settingsPanel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    settingsPanel:SetFrameStrata("DIALOG")
    settingsPanel:SetMovable(true)
    settingsPanel:EnableMouse(true)
    settingsPanel:RegisterForDrag("LeftButton")

    -- Background
    local bg = settingsPanel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(settingsPanel)
    bg:SetColorTexture(0, 0, 0, 0.9)

    -- Border
    local borderTop = settingsPanel:CreateTexture(nil, "BORDER")
    borderTop:SetHeight(1)
    borderTop:SetColorTexture(1.0, 0.251, 0.0, 1.0)
    borderTop:SetPoint("TOPLEFT", settingsPanel, "TOPLEFT")
    borderTop:SetPoint("TOPRIGHT", settingsPanel, "TOPRIGHT")

    local borderBottom = settingsPanel:CreateTexture(nil, "BORDER")
    borderBottom:SetHeight(1)
    borderBottom:SetColorTexture(1.0, 0.251, 0.0, 1.0)
    borderBottom:SetPoint("BOTTOMLEFT", settingsPanel, "BOTTOMLEFT")
    borderBottom:SetPoint("BOTTOMRIGHT", settingsPanel, "BOTTOMRIGHT")

    local borderLeft = settingsPanel:CreateTexture(nil, "BORDER")
    borderLeft:SetWidth(1)
    borderLeft:SetColorTexture(1.0, 0.251, 0.0, 1.0)
    borderLeft:SetPoint("TOPLEFT", settingsPanel, "TOPLEFT")
    borderLeft:SetPoint("BOTTOMLEFT", settingsPanel, "BOTTOMLEFT")

    local borderRight = settingsPanel:CreateTexture(nil, "BORDER")
    borderRight:SetWidth(1)
    borderRight:SetColorTexture(1.0, 0.251, 0.0, 1.0)
    borderRight:SetPoint("TOPRIGHT", settingsPanel, "TOPRIGHT")
    borderRight:SetPoint("BOTTOMRIGHT", settingsPanel, "BOTTOMRIGHT")

    -- Dragging
    settingsPanel:SetScript("OnDragStart", function()
        settingsPanel:StartMoving()
    end)
    settingsPanel:SetScript("OnDragStop", function()
        settingsPanel:StopMovingOrSizing()
    end)

    -- Title
    local title = settingsPanel:CreateFontString(nil, "OVERLAY")
    title:SetFont("Interface\\AddOns\\Fireside\\Fonts\\Accidental Presidency.ttf", 14, "OUTLINE")
    title:SetPoint("TOP", settingsPanel, "TOP", 0, -10)
    title:SetText("Item Tracker Settings")
    title:SetTextColor(1, 0.82, 0, 1)

    -- Close button
    local closeButton = CreateFrame("Button", nil, settingsPanel)
    closeButton:SetWidth(20)
    closeButton:SetHeight(20)
    closeButton:SetPoint("TOPRIGHT", settingsPanel, "TOPRIGHT", -5, -5)
    closeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    closeButton:SetScript("OnClick", function()
        settingsPanel:Hide()
    end)

    -- Add Item section
    local addLabel = settingsPanel:CreateFontString(nil, "OVERLAY")
    addLabel:SetFont("Interface\\AddOns\\Fireside\\Fonts\\Accidental Presidency.ttf", 12, "OUTLINE")
    addLabel:SetPoint("TOPLEFT", settingsPanel, "TOPLEFT", 10, -40)
    addLabel:SetText("Add Item (enter Item ID):")
    addLabel:SetTextColor(1, 1, 1, 1)

    -- Input box for item ID
    local inputBox = CreateFrame("EditBox", nil, settingsPanel)
    inputBox:SetWidth(200)
    inputBox:SetHeight(25)
    inputBox:SetPoint("TOPLEFT", addLabel, "BOTTOMLEFT", 0, -5)
    inputBox:SetAutoFocus(false)
    inputBox:SetFont("Interface\\AddOns\\Fireside\\Fonts\\Accidental Presidency.ttf", 11, "OUTLINE")
    inputBox:SetTextColor(1, 1, 1, 1)
    inputBox:SetMaxLetters(20)

    -- Input box background
    local inputBg = inputBox:CreateTexture(nil, "BACKGROUND")
    inputBg:SetAllPoints(inputBox)
    inputBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)

    -- Input box border
    local inputBorder = CreateFrame("Frame", nil, inputBox)
    inputBorder:SetAllPoints(inputBox)
    local inputBorderTex = inputBorder:CreateTexture(nil, "BORDER")
    inputBorderTex:SetAllPoints(inputBorder)
    inputBorderTex:SetColorTexture(0.4, 0.4, 0.4, 1)

    inputBox:SetScript("OnEscapePressed", function()
        inputBox:ClearFocus()
    end)

    -- Add button
    local addButton = CreateFrame("Button", nil, settingsPanel)
    addButton:SetWidth(60)
    addButton:SetHeight(25)
    addButton:SetPoint("LEFT", inputBox, "RIGHT", 5, 0)

    local addBg = addButton:CreateTexture(nil, "BACKGROUND")
    addBg:SetAllPoints(addButton)
    addBg:SetColorTexture(0.2, 0.6, 0.2, 0.8)

    local addText = addButton:CreateFontString(nil, "OVERLAY")
    addText:SetFont("Interface\\AddOns\\Fireside\\Fonts\\Accidental Presidency.ttf", 10, "OUTLINE")
    addText:SetPoint("CENTER", addButton, "CENTER", 0, 0)
    addText:SetText("Add")
    addText:SetTextColor(1, 1, 1, 1)

    addButton:SetScript("OnClick", function()
        local itemID = tonumber(inputBox:GetText())
        if itemID then
            if self:AddItem(itemID) then
                DEFAULT_CHAT_FRAME:AddMessage("Item Tracker: Added item " .. itemID, 0, 1, 0)
                inputBox:SetText("")
                self:UpdateSettingsPanel()
            else
                DEFAULT_CHAT_FRAME:AddMessage("Item Tracker: Item already tracked!", 1, 0, 0)
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("Item Tracker: Invalid item ID!", 1, 0, 0)
        end
    end)

    -- Tracked items list
    local listLabel = settingsPanel:CreateFontString(nil, "OVERLAY")
    listLabel:SetFont("Interface\\AddOns\\Fireside\\Fonts\\Accidental Presidency.ttf", 12, "OUTLINE")
    listLabel:SetPoint("TOPLEFT", inputBox, "BOTTOMLEFT", 0, -20)
    listLabel:SetText("Tracked Items:")
    listLabel:SetTextColor(1, 1, 1, 1)

    -- Scroll frame for tracked items
    local scrollFrame = CreateFrame("ScrollFrame", nil, settingsPanel)
    scrollFrame:SetWidth(280)
    scrollFrame:SetHeight(250)
    scrollFrame:SetPoint("TOPLEFT", listLabel, "BOTTOMLEFT", 0, -5)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(280)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

    settingsPanel.scrollChild = scrollChild

    settingsPanel:Hide()
end

-- Update settings panel with current tracked items
function ItemTracker:UpdateSettingsPanel()
    if not settingsPanel or not settingsPanel.scrollChild then
        return
    end

    -- Clear existing item entries
    local children = { settingsPanel.scrollChild:GetChildren() }
    for _, child in ipairs(children) do
        child:Hide()
    end

    -- Create entry for each tracked item
    local yOffset = 0
    for i, itemID in ipairs(trackedItems) do
        local itemName, itemLink, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemID)
        if not itemName then
            itemName = "Item " .. itemID
        end
        if not itemTexture then
            itemTexture = "Interface\\Icons\\INV_Misc_QuestionMark"
        end

        local entry = CreateFrame("Frame", nil, settingsPanel.scrollChild)
        entry:SetWidth(280)
        entry:SetHeight(30)
        entry:SetPoint("TOPLEFT", settingsPanel.scrollChild, "TOPLEFT", 0, yOffset)

        -- Item icon
        local icon = entry:CreateTexture(nil, "ARTWORK")
        icon:SetTexture(itemTexture)
        icon:SetWidth(24)
        icon:SetHeight(24)
        icon:SetPoint("LEFT", entry, "LEFT", 5, 0)

        -- Item name
        local nameText = entry:CreateFontString(nil, "OVERLAY")
        nameText:SetFont("Interface\\AddOns\\Fireside\\Fonts\\Accidental Presidency.ttf", 10, "OUTLINE")
        nameText:SetPoint("LEFT", icon, "RIGHT", 5, 0)
        nameText:SetText(itemName)
        nameText:SetTextColor(1, 1, 1, 1)

        -- Remove button
        local removeButton = CreateFrame("Button", nil, entry)
        removeButton:SetWidth(50)
        removeButton:SetHeight(20)
        removeButton:SetPoint("RIGHT", entry, "RIGHT", -5, 0)

        local removeBg = removeButton:CreateTexture(nil, "BACKGROUND")
        removeBg:SetAllPoints(removeButton)
        removeBg:SetColorTexture(0.6, 0.2, 0.2, 0.8)

        local removeText = removeButton:CreateFontString(nil, "OVERLAY")
        removeText:SetFont("Interface\\AddOns\\Fireside\\Fonts\\Accidental Presidency.ttf", 9, "OUTLINE")
        removeText:SetPoint("CENTER", removeButton, "CENTER", 0, 0)
        removeText:SetText("Remove")
        removeText:SetTextColor(1, 1, 1, 1)

        removeButton:SetScript("OnClick", function()
            self:RemoveItem(itemID)
            self:UpdateSettingsPanel()
            DEFAULT_CHAT_FRAME:AddMessage("Item Tracker: Removed " .. itemName, 1, 1, 0)
        end)

        yOffset = yOffset - 30
    end

    settingsPanel.scrollChild:SetHeight(math.abs(yOffset))
end

-- Register applet with dashboard
Fireside.Dashboard:RegisterApplet(ItemTracker)

-- Slash commands
SLASH_ITEMTRACKER1 = "/itemtracker"
SLASH_ITEMTRACKER2 = "/itemtrack"
SlashCmdList["ITEMTRACKER"] = function(msg)
    local command, arg = string.match(msg, "^(%S+)%s*(.-)$")
    if not command then
        command = msg
    end
    command = string.lower(command or "")

    if command == "" or command == "settings" or command == "config" then
        ItemTracker:ToggleSettings()
    elseif command == "add" and arg and arg ~= "" then
        local itemID = tonumber(arg)
        if itemID then
            if ItemTracker:AddItem(itemID) then
                DEFAULT_CHAT_FRAME:AddMessage("Item Tracker: Added item " .. itemID, 0, 1, 0)
            else
                DEFAULT_CHAT_FRAME:AddMessage("Item Tracker: Item already tracked!", 1, 0, 0)
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("Item Tracker: Invalid item ID!", 1, 0, 0)
        end
    elseif command == "remove" and arg and arg ~= "" then
        local itemID = tonumber(arg)
        if itemID then
            if ItemTracker:RemoveItem(itemID) then
                DEFAULT_CHAT_FRAME:AddMessage("Item Tracker: Removed item " .. itemID, 1, 1, 0)
            else
                DEFAULT_CHAT_FRAME:AddMessage("Item Tracker: Item not tracked!", 1, 0, 0)
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("Item Tracker: Invalid item ID!", 1, 0, 0)
        end
    elseif command == "reset" then
        ItemTracker:StartNewSession()
        DEFAULT_CHAT_FRAME:AddMessage("Item Tracker: Session reset!", 1, 1, 0)
    else
        DEFAULT_CHAT_FRAME:AddMessage("Item Tracker Commands:", 1, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage("/itemtrack - Open settings", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/itemtrack add <itemID> - Add item to track", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/itemtrack remove <itemID> - Remove item", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/itemtrack reset - Reset session counts", 1, 1, 1)
    end
end

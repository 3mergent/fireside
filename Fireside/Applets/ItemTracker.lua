-- Item Tracker Applet
-- Tracks items gained in session or displays total counts

DEFAULT_CHAT_FRAME:AddMessage("Item Tracker: File loading...", 1, 0, 1)

Fireside = Fireside or {}

DEFAULT_CHAT_FRAME:AddMessage("Item Tracker: Creating applet instance...", 1, 0, 1)

-- Create Item Tracker applet instance
local ItemTracker = Fireside.Applet:New("ItemTracker", 220, 180, 180, 320, 140, 400)

DEFAULT_CHAT_FRAME:AddMessage("Item Tracker: Applet instance created", 1, 0, 1)

-- UI Elements
local logoTexture
local titleText
local itemsContainer
local itemFrames = {}  -- Store item display frames
local toggleButton
local modeLabel
local settingsButton

-- Data
local trackedItems = {}  -- List of item objects: {name, itemID, price, priority}
local sessionCounts = {}  -- Count of items gained in current session (keyed by itemID)
local sessionBaseline = {}  -- Starting counts when session began (keyed by itemID)
local currentMode = "total"  -- "session" or "total"

-- Settings Panel
local settingsPanel = nil
local settingsTextBox = nil

-- Initialize UI
function ItemTracker:OnInitialize()
    DEFAULT_CHAT_FRAME:AddMessage("Item Tracker: OnInitialize called", 0, 1, 1)

    -- Capture self for use in pcall
    local applet = self

    -- Wrap in pcall for error handling
    local success, err = pcall(function()
        -- Load saved data
        DEFAULT_CHAT_FRAME:AddMessage("Item Tracker: Loading saved data", 0, 1, 1)
        local saved = FiresideDB.applets[applet.name]
        if saved and saved.data then
            trackedItems = saved.data.trackedItems or {}
            sessionCounts = saved.data.sessionCounts or {}
            sessionBaseline = saved.data.sessionBaseline or {}
            currentMode = saved.data.mode or "total"

            DEFAULT_CHAT_FRAME:AddMessage("Item Tracker: Loaded " .. table.getn(trackedItems) .. " items", 0, 1, 1)

            -- Migrate old format (array of item IDs) to new format (array of item objects)
            if table.getn(trackedItems) > 0 then
                local firstItem = trackedItems[1]
                if type(firstItem) == "number" then
                    -- Old format detected - convert to new format
                    DEFAULT_CHAT_FRAME:AddMessage("Item Tracker: Migrating old format", 1, 1, 0)
                    local oldItems = trackedItems
                    trackedItems = {}
                    for _, itemID in ipairs(oldItems) do
                        local itemName = GetItemInfo(itemID) or ("Item " .. itemID)
                        table.insert(trackedItems, {
                            name = itemName,
                            itemID = itemID,
                            price = 0,
                            priority = 999
                        })
                    end
                    DEFAULT_CHAT_FRAME:AddMessage("Item Tracker: Migrated " .. table.getn(oldItems) .. " items to new format", 0, 1, 0)
                end
            end
        end

        -- Logo (treasure chest icon)
        DEFAULT_CHAT_FRAME:AddMessage("Item Tracker: Creating UI elements", 0, 1, 1)
        local logoSize = math.floor(applet.width * 0.36)
        logoTexture = applet.frame:CreateTexture(nil, "ARTWORK")
        logoTexture:SetTexture("Interface\\Icons\\INV_Box_02")
        logoTexture:SetWidth(logoSize)
        logoTexture:SetHeight(logoSize)
        local logoXOffset = 10 - math.floor(logoSize * 0.25)
        local logoYOffset = math.floor(logoSize / 2) - 5
        logoTexture:SetPoint("TOPLEFT", applet.frame, "TOPLEFT", logoXOffset, logoYOffset)

        -- Title
        titleText = applet:CreateFontString(nil, "OVERLAY", 11, "RIGHT", "TOP")
        titleText:SetPoint("TOPRIGHT", applet.frame, "TOPRIGHT", -30, -8)
        titleText:SetText("Fireside Item Tracker")
        titleText:SetTextColor(1, 0.82, 0, 1)

        -- Settings button (gear icon)
        settingsButton = CreateFrame("Button", nil, applet.frame)
        settingsButton:SetWidth(20)
        settingsButton:SetHeight(20)
        settingsButton:SetPoint("TOPRIGHT", applet.frame, "TOPRIGHT", -5, -5)
        settingsButton:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
        settingsButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        settingsButton:SetScript("OnClick", function()
            applet:ToggleSettings()
        end)

        -- Items container
        itemsContainer = CreateFrame("Frame", nil, applet.frame)
        itemsContainer:SetFrameLevel(applet.frame:GetFrameLevel() + 2)

        -- Mode label
        modeLabel = applet:CreateFontString(nil, "OVERLAY", 11, "CENTER", "BOTTOM")
        modeLabel:SetTextColor(0.7, 0.7, 0.7, 1)

        -- Toggle button for Session/Total
        toggleButton = CreateFrame("Button", nil, applet.frame)
        toggleButton:SetWidth(80)
        toggleButton:SetHeight(20)
        toggleButton:SetFrameLevel(applet.frame:GetFrameLevel() + 3)

        local toggleBg = toggleButton:CreateTexture(nil, "BACKGROUND")
        toggleBg:SetAllPoints(toggleButton)
        toggleBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

        local toggleBorder = toggleButton:CreateTexture(nil, "BORDER")
        toggleBorder:SetAllPoints(toggleButton)
        toggleBorder:SetColorTexture(0.4, 0.4, 0.4, 1.0)

        local toggleText = toggleButton:CreateFontString(nil, "OVERLAY")
        toggleText:SetFont("Interface\\AddOns\\Fireside\\Fonts\\Accidental Presidency.ttf", 10, "OUTLINE")
        toggleText:SetPoint("CENTER", toggleButton, "CENTER", 0, 0)
        toggleText:SetTextColor(1, 1, 1, 1)

        toggleButton.text = toggleText
        toggleButton:SetScript("OnClick", function()
            applet:ToggleMode()
        end)

        -- Enable right-click on frame to open settings
        applet.frame:RegisterForClicks("RightButtonUp")
        applet.frame:SetScript("OnMouseUp", function(frame, button)
            if button == "RightButton" then
                applet:ToggleSettings()
            end
        end)

        -- Register bag update events to track item gains
        DEFAULT_CHAT_FRAME:AddMessage("Item Tracker: Registering events", 0, 1, 1)
        applet.frame:RegisterEvent("BAG_UPDATE")
        applet.frame:SetScript("OnEvent", function()
            if event == "BAG_UPDATE" then
                applet:OnBagUpdate()
            end
        end)

        -- Initial layout and data update
        DEFAULT_CHAT_FRAME:AddMessage("Item Tracker: Updating layout", 0, 1, 1)
        applet:UpdateLayout()
        applet:UpdateToggleButton()
        applet:UpdateItemDisplay()

        DEFAULT_CHAT_FRAME:AddMessage("Item Tracker: Initialization complete", 0, 1, 0)
    end)

    if not success then
        DEFAULT_CHAT_FRAME:AddMessage("Item Tracker ERROR: " .. tostring(err), 1, 0, 0)
    end
end

DEFAULT_CHAT_FRAME:AddMessage("Item Tracker: OnInitialize function defined", 1, 0, 1)

-- Update layout when resizing
function ItemTracker:OnResize(width, height)
    self:UpdateLayout()
end

-- Update layout positions
function ItemTracker:UpdateLayout()
    DEFAULT_CHAT_FRAME:AddMessage("Item Tracker: UpdateLayout called", 0, 1, 1)
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
    for _, item in ipairs(trackedItems) do
        if type(item) == "table" and item.itemID then
            local count = GetItemCount(item.itemID, true)  -- true = include bank
            sessionBaseline[item.itemID] = count
        end
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

-- Get sorted items by priority (lower priority number = higher in list)
function ItemTracker:GetSortedItems()
    local sorted = {}
    for _, item in ipairs(trackedItems) do
        -- Skip invalid items
        if type(item) == "table" and item.name then
            table.insert(sorted, item)
        end
    end

    -- Sort by priority (ascending)
    table.sort(sorted, function(a, b)
        return (a.priority or 999) < (b.priority or 999)
    end)

    return sorted
end

-- Update item display
function ItemTracker:UpdateItemDisplay()
    DEFAULT_CHAT_FRAME:AddMessage("Item Tracker: UpdateItemDisplay called", 0, 1, 1)

    -- Clear existing item frames
    for _, frame in ipairs(itemFrames) do
        frame:Hide()
    end
    itemFrames = {}

    local sortedItems = self:GetSortedItems()
    local numItems = table.getn(sortedItems)
    DEFAULT_CHAT_FRAME:AddMessage("Item Tracker: Displaying " .. numItems .. " items", 0, 1, 1)

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

    for i, item in ipairs(sortedItems) do
        if not item.itemID then
            -- Skip items that haven't been resolved yet
            goto continue
        end

        -- Get item info
        local itemName, itemLink, _, _, _, _, _, _, _, itemTexture = GetItemInfo(item.itemID)
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

        local count = self:GetItemDisplayCount(item.itemID)
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

        ::continue::
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
    for _, item in ipairs(trackedItems) do
        if type(item) == "table" and item.itemID then
            local currentCount = GetItemCount(item.itemID, true)
            local baseline = sessionBaseline[item.itemID] or 0
            local previousTotal = baseline + (sessionCounts[item.itemID] or 0)

            if currentCount > previousTotal then
                -- Item was gained!
                local gained = currentCount - previousTotal
                sessionCounts[item.itemID] = (sessionCounts[item.itemID] or 0) + gained
                sessionBaseline[item.itemID] = currentCount - sessionCounts[item.itemID]
            elseif currentCount < previousTotal then
                -- Item was lost (used, sold, etc)
                -- Update baseline to reflect new total, but keep session count
                local sessionCount = sessionCounts[item.itemID] or 0
                sessionBaseline[item.itemID] = currentCount - sessionCount

                -- If session count goes negative, reset it
                if sessionBaseline[item.itemID] < 0 then
                    sessionBaseline[item.itemID] = currentCount
                    sessionCounts[item.itemID] = 0
                end
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

-- Parse items from text format
-- Format: ItemName|price|priority (one per line)
function ItemTracker:ParseItemsFromText(text)
    local items = {}
    local lines = {}

    -- Split text into lines
    for line in string.gmatch(text, "[^\r\n]+") do
        table.insert(lines, line)
    end

    -- Parse each line
    for _, line in ipairs(lines) do
        local trimmed = string.gsub(line, "^%s*(.-)%s*$", "%1")  -- Trim whitespace
        if trimmed ~= "" then
            local parts = {}
            for part in string.gmatch(trimmed, "[^|]+") do
                table.insert(parts, part)
            end

            if table.getn(parts) >= 3 then
                local itemName = string.gsub(parts[1], "^%s*(.-)%s*$", "%1")
                local price = tonumber(parts[2])
                local priority = tonumber(parts[3])

                if itemName and price and priority then
                    table.insert(items, {
                        name = itemName,
                        itemID = nil,  -- Will be resolved
                        price = price,
                        priority = priority
                    })
                end
            end
        end
    end

    return items
end

-- Convert items to text format
function ItemTracker:ItemsToText()
    local lines = {}
    for _, item in ipairs(trackedItems) do
        if type(item) == "table" and item.name then
            local line = string.format("%s|%s|%s", item.name, tostring(item.price or 0), tostring(item.priority or 999))
            table.insert(lines, line)
        end
    end
    return table.concat(lines, "\n")
end

-- Resolve item names to item IDs
function ItemTracker:ResolveItemIDs()
    for _, item in ipairs(trackedItems) do
        if type(item) == "table" and not item.itemID and item.name then
            -- Try to get item ID from name
            local itemLink = GetItemInfo(item.name)
            if itemLink then
                local itemID = tonumber(string.match(itemLink, "item:(%d+)"))
                if itemID then
                    item.itemID = itemID
                end
            end
        end
    end
    self:SaveData()
end

-- Apply items from settings text box
function ItemTracker:ApplySettings()
    if not settingsTextBox then
        return
    end

    local text = settingsTextBox:GetText()
    local newItems = self:ParseItemsFromText(text)

    -- Replace tracked items
    trackedItems = newItems

    -- Resolve item IDs
    self:ResolveItemIDs()

    -- Reset session data for new items
    if currentMode == "session" then
        sessionCounts = {}
        sessionBaseline = {}
        for _, item in ipairs(trackedItems) do
            if type(item) == "table" and item.itemID then
                sessionBaseline[item.itemID] = GetItemCount(item.itemID, true)
                sessionCounts[item.itemID] = 0
            end
        end
    end

    self:SaveData()
    self:UpdateItemDisplay()

    DEFAULT_CHAT_FRAME:AddMessage("Item Tracker: Settings applied!", 0, 1, 0)
end

-- Toggle settings panel
function ItemTracker:ToggleSettings()
    if not settingsPanel then
        self:CreateSettingsPanel()
    end

    if settingsPanel:IsShown() then
        settingsPanel:Hide()
    else
        -- Update text box with current items
        if settingsTextBox then
            settingsTextBox:SetText(self:ItemsToText())
        end
        settingsPanel:Show()
    end
end

-- Create settings panel UI
function ItemTracker:CreateSettingsPanel()
    settingsPanel = CreateFrame("Frame", "FiresideItemTrackerSettings", UIParent)
    settingsPanel:SetWidth(500)
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

    -- Instructions
    local instructions = settingsPanel:CreateFontString(nil, "OVERLAY")
    instructions:SetFont("Interface\\AddOns\\Fireside\\Fonts\\Accidental Presidency.ttf", 10, "OUTLINE")
    instructions:SetPoint("TOPLEFT", settingsPanel, "TOPLEFT", 10, -35)
    instructions:SetText("Format: ItemName|price|priority (one per line)")
    instructions:SetTextColor(0.8, 0.8, 0.8, 1)

    -- Example
    local example = settingsPanel:CreateFontString(nil, "OVERLAY")
    example:SetFont("Interface\\AddOns\\Fireside\\Fonts\\Accidental Presidency.ttf", 9, "OUTLINE")
    example:SetPoint("TOPLEFT", instructions, "BOTTOMLEFT", 0, -3)
    example:SetText("Example: Linen Cloth|0.2|2")
    example:SetTextColor(0.6, 0.6, 0.6, 1)

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

    -- Scroll frame for text box
    local scrollFrame = CreateFrame("ScrollFrame", nil, settingsPanel)
    scrollFrame:SetWidth(480)
    scrollFrame:SetHeight(280)
    scrollFrame:SetPoint("TOPLEFT", example, "BOTTOMLEFT", 0, -10)

    -- Text box (EditBox with multi-line)
    settingsTextBox = CreateFrame("EditBox", nil, scrollFrame)
    settingsTextBox:SetWidth(480)
    settingsTextBox:SetHeight(280)
    settingsTextBox:SetMultiLine(true)
    settingsTextBox:SetAutoFocus(false)
    settingsTextBox:SetFont("Interface\\AddOns\\Fireside\\Fonts\\Accidental Presidency.ttf", 10, "OUTLINE")
    settingsTextBox:SetTextColor(1, 1, 1, 1)
    settingsTextBox:SetMaxLetters(0)

    scrollFrame:SetScrollChild(settingsTextBox)

    -- Text box background
    local textBg = scrollFrame:CreateTexture(nil, "BACKGROUND")
    textBg:SetAllPoints(scrollFrame)
    textBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)

    -- Text box border
    local textBorder = CreateFrame("Frame", nil, scrollFrame)
    textBorder:SetAllPoints(scrollFrame)
    local textBorderTop = textBorder:CreateTexture(nil, "BORDER")
    textBorderTop:SetHeight(1)
    textBorderTop:SetColorTexture(0.4, 0.4, 0.4, 1)
    textBorderTop:SetPoint("TOPLEFT", textBorder, "TOPLEFT")
    textBorderTop:SetPoint("TOPRIGHT", textBorder, "TOPRIGHT")

    local textBorderBottom = textBorder:CreateTexture(nil, "BORDER")
    textBorderBottom:SetHeight(1)
    textBorderBottom:SetColorTexture(0.4, 0.4, 0.4, 1)
    textBorderBottom:SetPoint("BOTTOMLEFT", textBorder, "BOTTOMLEFT")
    textBorderBottom:SetPoint("BOTTOMRIGHT", textBorder, "BOTTOMRIGHT")

    local textBorderLeft = textBorder:CreateTexture(nil, "BORDER")
    textBorderLeft:SetWidth(1)
    textBorderLeft:SetColorTexture(0.4, 0.4, 0.4, 1)
    textBorderLeft:SetPoint("TOPLEFT", textBorder, "TOPLEFT")
    textBorderLeft:SetPoint("BOTTOMLEFT", textBorder, "BOTTOMLEFT")

    local textBorderRight = textBorder:CreateTexture(nil, "BORDER")
    textBorderRight:SetWidth(1)
    textBorderRight:SetColorTexture(0.4, 0.4, 0.4, 1)
    textBorderRight:SetPoint("TOPRIGHT", textBorder, "TOPRIGHT")
    textBorderRight:SetPoint("BOTTOMRIGHT", textBorder, "BOTTOMRIGHT")

    settingsTextBox:SetScript("OnEscapePressed", function()
        settingsTextBox:ClearFocus()
    end)

    -- Apply button
    local applyButton = CreateFrame("Button", nil, settingsPanel)
    applyButton:SetWidth(100)
    applyButton:SetHeight(30)
    applyButton:SetPoint("BOTTOM", settingsPanel, "BOTTOM", 0, 10)

    local applyBg = applyButton:CreateTexture(nil, "BACKGROUND")
    applyBg:SetAllPoints(applyButton)
    applyBg:SetColorTexture(0.2, 0.6, 0.2, 0.8)

    local applyText = applyButton:CreateFontString(nil, "OVERLAY")
    applyText:SetFont("Interface\\AddOns\\Fireside\\Fonts\\Accidental Presidency.ttf", 12, "OUTLINE")
    applyText:SetPoint("CENTER", applyButton, "CENTER", 0, 0)
    applyText:SetText("Apply")
    applyText:SetTextColor(1, 1, 1, 1)

    applyButton:SetScript("OnClick", function()
        self:ApplySettings()
    end)

    settingsPanel:Hide()
end

-- Register applet with dashboard
Fireside.Dashboard:RegisterApplet(ItemTracker)

-- Slash commands
SLASH_ITEMTRACKER1 = "/itemtracker"
SLASH_ITEMTRACKER2 = "/itemtrack"
SlashCmdList["ITEMTRACKER"] = function(msg)
    local command = string.lower(msg or "")

    if command == "" or command == "settings" or command == "config" then
        ItemTracker:ToggleSettings()
    elseif command == "reset" then
        ItemTracker:StartNewSession()
        DEFAULT_CHAT_FRAME:AddMessage("Item Tracker: Session reset!", 1, 1, 0)
    else
        DEFAULT_CHAT_FRAME:AddMessage("Item Tracker Commands:", 1, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage("/itemtrack - Open settings", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/itemtrack reset - Reset session counts", 1, 1, 1)
    end
end

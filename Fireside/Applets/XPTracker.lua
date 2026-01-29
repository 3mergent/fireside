-- XP Tracker Applet
-- Tracks experience gain, XP/hour, kills to level, and time remaining

Fireside = Fireside or {}

-- Create XP Tracker applet instance (name, width, height, minWidth, maxWidth, minHeight, maxHeight)
-- Compact width, flexible height range (added 15px for XP bar, reduced 5px top padding)
local XPTracker = Fireside.Applet:New("XPTracker", 168, 266, 150, 240, 266, 394)

-- UI Elements
local logoTexture
local titleText
local currentXPText
local currentXPLabel
local currentXPCard
local currentXPCardBorders  -- Table to store border textures
local currentXPCardCelebrationBg
local xpBarBg
local xpBarRested
local xpBarFg
local xpPerHourCard
local killsCard
local nextLevelCard
local timeCard
local xpPerHourText
local xpPerHourLabel
local killsToLevelText
local killsToLevelLabel
local nextLevelText
local nextLevelLabel
local timeToLevelText
local timeToLevelLabel

-- Data tracking
local xpSamples = {}
local lastKillXP = 0
local maxSamples = 60
local updateInterval = 1.0
local levelUpTime = 0  -- Timestamp of last level up (whole seconds)
local levelUpTimeHiRes = 0  -- High-resolution timestamp for smooth fade animation
local levelUpDuration = 300  -- 5 minutes in seconds
local levelUpTestMode = false  -- Test mode flag
local levelUpTestDuration = 60  -- 1 minute for test mode

-- Initialize UI
function XPTracker:OnInitialize()
    -- Load saved session data
    local saved = FiresideDB.applets[self.name]
    if saved and saved.sessionData then
        xpSamples = saved.sessionData.xpSamples or {}
        lastKillXP = saved.sessionData.lastKillXP or 0
        levelUpTime = saved.sessionData.levelUpTime or 0
    end

    -- Logo on the left (36% of frame width, increased by 20%, floats over edge)
    local logoSize = math.floor(self.width * 0.36)
    logoTexture = self.frame:CreateTexture(nil, "ARTWORK")
    logoTexture:SetTexture("Interface\\AddOns\\Fireside\\Images\\fireside-logo.png")
    logoTexture:SetWidth(logoSize)
    logoTexture:SetHeight(logoSize)
    -- Position to float up by half its height and moved right 5px
    local logoXOffset = 10 - math.floor(logoSize * 0.25)
    local logoYOffset = math.floor(logoSize / 2) - 5
    logoTexture:SetPoint("TOPLEFT", self.frame, "TOPLEFT", logoXOffset, logoYOffset)

    -- Title: Fireside XP Tracker heading (right side, reduced by 20%: 14pt → 11pt)
    titleText = self:CreateFontString(nil, "OVERLAY", 11, "RIGHT", "TOP")
    titleText:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -5, -8)
    titleText:SetText("Fireside XP Tracker")
    titleText:SetTextColor(1, 0.82, 0, 1)

    -- Current XP Section (centered, large)
    -- XP percentage number (38pt increased by 15% → 44pt)
    currentXPText = self:CreateFontString(nil, "OVERLAY", 44, "CENTER", "TOP")
    currentXPText:SetPoint("TOP", self.frame, "TOP", 0, -10)
    currentXPText:SetTextColor(1, 1, 0, 1)  -- Yellow

    -- "CURRENT XP" label (15pt, 25% larger than original 12pt)
    currentXPLabel = self:CreateFontString(nil, "OVERLAY", 15, "CENTER", "TOP")
    currentXPLabel:SetPoint("TOP", currentXPText, "BOTTOM", 0, 2)  -- Reduced gap by 4px (was -2, now +2)
    currentXPLabel:SetText("CURRENT XP")

    -- Helper function to create a bordered card
    local function CreateBorderedCard(parent)
        local card = CreateFrame("Frame", nil, parent)
        card:SetFrameLevel(parent:GetFrameLevel() + 2)

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

    -- Create bordered cards for each stat section
    -- CurrentXPCard created manually to allow border color changes during celebration
    currentXPCard = CreateFrame("Frame", nil, self.frame)
    currentXPCard:SetFrameLevel(self.frame:GetFrameLevel() + 2)

    currentXPCardBorders = {}
    currentXPCardBorders.top = currentXPCard:CreateTexture(nil, "OVERLAY")
    currentXPCardBorders.top:SetHeight(1)
    currentXPCardBorders.top:SetColorTexture(0.2, 0.2, 0.2, 1)
    currentXPCardBorders.top:SetPoint("TOPLEFT", currentXPCard, "TOPLEFT")
    currentXPCardBorders.top:SetPoint("TOPRIGHT", currentXPCard, "TOPRIGHT")

    currentXPCardBorders.bottom = currentXPCard:CreateTexture(nil, "OVERLAY")
    currentXPCardBorders.bottom:SetHeight(1)
    currentXPCardBorders.bottom:SetColorTexture(0.2, 0.2, 0.2, 1)
    currentXPCardBorders.bottom:SetPoint("BOTTOMLEFT", currentXPCard, "BOTTOMLEFT")
    currentXPCardBorders.bottom:SetPoint("BOTTOMRIGHT", currentXPCard, "BOTTOMRIGHT")

    currentXPCardBorders.left = currentXPCard:CreateTexture(nil, "OVERLAY")
    currentXPCardBorders.left:SetWidth(1)
    currentXPCardBorders.left:SetColorTexture(0.2, 0.2, 0.2, 1)
    currentXPCardBorders.left:SetPoint("TOPLEFT", currentXPCard, "TOPLEFT")
    currentXPCardBorders.left:SetPoint("BOTTOMLEFT", currentXPCard, "BOTTOMLEFT")

    currentXPCardBorders.right = currentXPCard:CreateTexture(nil, "OVERLAY")
    currentXPCardBorders.right:SetWidth(1)
    currentXPCardBorders.right:SetColorTexture(0.2, 0.2, 0.2, 1)
    currentXPCardBorders.right:SetPoint("TOPRIGHT", currentXPCard, "TOPRIGHT")
    currentXPCardBorders.right:SetPoint("BOTTOMRIGHT", currentXPCard, "BOTTOMRIGHT")

    xpPerHourCard = CreateBorderedCard(self.frame)
    killsCard = CreateBorderedCard(self.frame)
    nextLevelCard = CreateBorderedCard(self.frame)
    timeCard = CreateBorderedCard(self.frame)

    -- Create celebration background (green, fades from 50% to 0% over 5 seconds)
    currentXPCardCelebrationBg = currentXPCard:CreateTexture(nil, "BACKGROUND")
    currentXPCardCelebrationBg:SetAllPoints(currentXPCard)
    currentXPCardCelebrationBg:SetColorTexture(0, 1, 0, 0.5)  -- Green, 50% opacity initial
    currentXPCardCelebrationBg:Hide()

    -- Create XP bar (background - darker blue, static)
    xpBarBg = currentXPCard:CreateTexture(nil, "BORDER")
    xpBarBg:SetColorTexture(0.05, 0.05, 0.3, 1.0)  -- Darker blue
    xpBarBg:SetHeight(10)

    -- Create rested XP bar (middle layer - light blue at 25% opacity, rested XP percentage)
    xpBarRested = currentXPCard:CreateTexture(nil, "ARTWORK")
    xpBarRested:SetColorTexture(0.3, 0.5, 0.9, 0.25)  -- Light blue, 25% opacity
    xpBarRested:SetHeight(10)

    -- Create current XP bar (foreground - light blue, current XP percentage)
    xpBarFg = currentXPCard:CreateTexture(nil, "OVERLAY")
    xpBarFg:SetColorTexture(0.3, 0.5, 0.9, 1.0)  -- Light blue, full opacity
    xpBarFg:SetHeight(10)

    -- Stats Grid (2x2): XP/HR, KILLS on top row; NEXT, TIME on bottom row
    local statNumberSize = 29  -- Reduced by 20% from 36pt
    local statLabelSize = 13   -- Keep subheading size unchanged

    -- XP/HR (top left)
    xpPerHourText = self:CreateFontString(nil, "OVERLAY", statNumberSize, "CENTER", "TOP")
    xpPerHourLabel = self:CreateFontString(nil, "OVERLAY", statLabelSize, "CENTER", "TOP")
    xpPerHourLabel:SetPoint("TOP", xpPerHourText, "BOTTOM", 0, -2)
    xpPerHourLabel:SetText("XP/HR")

    -- KILLS (top right)
    killsToLevelText = self:CreateFontString(nil, "OVERLAY", statNumberSize, "CENTER", "TOP")
    killsToLevelLabel = self:CreateFontString(nil, "OVERLAY", statLabelSize, "CENTER", "TOP")
    killsToLevelLabel:SetPoint("TOP", killsToLevelText, "BOTTOM", 0, -2)
    killsToLevelLabel:SetText("KILLS")

    -- NEXT (bottom left)
    nextLevelText = self:CreateFontString(nil, "OVERLAY", statNumberSize, "CENTER", "TOP")
    nextLevelLabel = self:CreateFontString(nil, "OVERLAY", statLabelSize, "CENTER", "TOP")
    nextLevelLabel:SetPoint("TOP", nextLevelText, "BOTTOM", 0, -2)
    nextLevelLabel:SetText("NEXT")

    -- TIME (bottom right)
    timeToLevelText = self:CreateFontString(nil, "OVERLAY", statNumberSize, "CENTER", "TOP")
    timeToLevelLabel = self:CreateFontString(nil, "OVERLAY", statLabelSize, "CENTER", "TOP")
    timeToLevelLabel:SetPoint("TOP", timeToLevelText, "BOTTOM", 0, -2)
    timeToLevelLabel:SetText("TIME")

    -- Apply initial layout
    self:UpdateLayout()

    -- Register events
    self.frame:RegisterEvent("PLAYER_XP_UPDATE")
    self.frame:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
    self.frame:RegisterEvent("PLAYER_LEVEL_UP")

    -- Event handler: first param is frame, second is event name
    local function OnEvent(self, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
        if event == "PLAYER_XP_UPDATE" then
            XPTracker:UpdateCurrentXP()
            XPTracker:UpdateKillsToLevel()
            XPTracker:UpdateTimeToLevel()
        elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
            XPTracker:ParseCombatXP(arg1)
        elseif event == "PLAYER_LEVEL_UP" then
            XPTracker:OnLevelUp()
        end
    end
    self.frame:SetScript("OnEvent", OnEvent)

    -- Set up OnUpdate for XP/hr tracking and level-up timer
    local timeSinceLastUpdate = 0
    local function OnUpdate(self, elapsed)
        -- Update fade animation every frame for smooth transition (using GetTime for sub-second precision)
        if levelUpTimeHiRes > 0 then
            local timeSinceLevelUp = GetTime() - levelUpTimeHiRes
            local fadeTime = 5  -- 5 seconds
            if timeSinceLevelUp <= fadeTime then
                local alpha = 0.5 * (1 - (timeSinceLevelUp / fadeTime))
                currentXPCardCelebrationBg:SetColorTexture(0, 1, 0, alpha)
                if not currentXPCardCelebrationBg:IsShown() then
                    currentXPCardCelebrationBg:Show()
                end
            elseif currentXPCardCelebrationBg:IsShown() then
                currentXPCardCelebrationBg:Hide()
                levelUpTimeHiRes = 0  -- Clear hi-res timer after fade completes
            end
        end

        -- Update XP tracking every second
        timeSinceLastUpdate = timeSinceLastUpdate + elapsed
        if timeSinceLastUpdate >= updateInterval then
            XPTracker:RecordXPSample()
            XPTracker:UpdateXPPerHour()
            XPTracker:UpdateTimeToLevel()
            XPTracker:UpdateCurrentXP()  -- Check level-up timer and update display
            timeSinceLastUpdate = 0
        end
    end
    self.frame:SetScript("OnUpdate", OnUpdate)

    -- Initial update
    self:UpdateCurrentXP()
    self:UpdateNextLevel()
    self:UpdateKillsToLevel()
    self:UpdateXPPerHour()
    self:UpdateTimeToLevel()
end

-- Update layout based on current frame size (responsive layout)
function XPTracker:UpdateLayout()
    local width = self.width
    local height = self.height
    local padding = 5  -- Uniform 5px spacing everywhere
    local cardPadding = 5

    -- Update logo size and position (36% of frame width, increased by 20%, floats over edges)
    local logoSize = math.floor(width * 0.36)
    if logoTexture then
        logoTexture:SetWidth(logoSize)
        logoTexture:SetHeight(logoSize)
        -- Reposition to float up by half its height and moved right 5px
        local logoXOffset = 10 - math.floor(logoSize * 0.25)
        local logoYOffset = math.floor(logoSize / 2) - 5
        logoTexture:ClearAllPoints()
        logoTexture:SetPoint("TOPLEFT", self.frame, "TOPLEFT", logoXOffset, logoYOffset)
    end

    -- Calculate responsive positions
    local titleAreaHeight = 30
    local currentXPHeight = 80

    -- Current XP card (full width, at top) with 5px padding top and bottom, plus space for XP bar
    local currentXPCardY = titleAreaHeight + 5
    local currentXPCardHeight = currentXPHeight + 5 + 10 + 5  -- 5px top padding + 10px bar + 5px bar padding
    currentXPCard:ClearAllPoints()
    currentXPCard:SetPoint("TOPLEFT", self.frame, "TOPLEFT", padding, -currentXPCardY)
    currentXPCard:SetWidth(width - (padding * 2))
    currentXPCard:SetHeight(currentXPCardHeight)

    -- Position XP bars at bottom of current XP card
    xpBarBg:ClearAllPoints()
    xpBarBg:SetPoint("BOTTOMLEFT", currentXPCard, "BOTTOMLEFT", cardPadding, cardPadding)
    xpBarBg:SetPoint("BOTTOMRIGHT", currentXPCard, "BOTTOMRIGHT", -cardPadding, cardPadding)

    xpBarRested:ClearAllPoints()
    xpBarRested:SetPoint("BOTTOMLEFT", currentXPCard, "BOTTOMLEFT", cardPadding, cardPadding)

    xpBarFg:ClearAllPoints()
    xpBarFg:SetPoint("BOTTOMLEFT", currentXPCard, "BOTTOMLEFT", cardPadding, cardPadding)

    -- Calculate stat card dimensions (2x2 grid) - 5px gap from Current XP card
    local currentXPCardEndY = currentXPCardY + currentXPCardHeight
    local statCardsStartY = currentXPCardEndY + 5  -- 5px gap between cards
    local remainingHeight = height - statCardsStartY - padding  -- Calculate based on actual start position
    local statCardWidth = (width - (padding * 3)) / 2
    local statCardHeight = (remainingHeight - cardPadding) / 2

    -- XP/HR card (top left)
    xpPerHourCard:ClearAllPoints()
    xpPerHourCard:SetPoint("TOPLEFT", self.frame, "TOPLEFT", padding, -statCardsStartY)
    xpPerHourCard:SetWidth(statCardWidth)
    xpPerHourCard:SetHeight(statCardHeight)

    -- KILLS card (top right)
    killsCard:ClearAllPoints()
    killsCard:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -padding, -statCardsStartY)
    killsCard:SetWidth(statCardWidth)
    killsCard:SetHeight(statCardHeight)

    -- NEXT card (bottom left)
    nextLevelCard:ClearAllPoints()
    nextLevelCard:SetPoint("TOPLEFT", self.frame, "TOPLEFT", padding, -(statCardsStartY + statCardHeight + cardPadding))
    nextLevelCard:SetWidth(statCardWidth)
    nextLevelCard:SetHeight(statCardHeight)

    -- TIME card (bottom right)
    timeCard:ClearAllPoints()
    timeCard:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -padding, -(statCardsStartY + statCardHeight + cardPadding))
    timeCard:SetWidth(statCardWidth)
    timeCard:SetHeight(statCardHeight)

    -- Reposition stat text (visually centered accounting for font weight)
    -- Offset UP to reduce top padding and balance the 4:1 ratio

    -- Current XP number - positioned near top with reduced spacing
    currentXPText:ClearAllPoints()
    currentXPText:SetPoint("TOP", currentXPCard, "TOP", 0, -15)

    -- XP/HR number - offset up for visual balance
    xpPerHourText:ClearAllPoints()
    xpPerHourText:SetPoint("CENTER", xpPerHourCard, "CENTER", 0, 8)

    -- KILLS number - offset up for visual balance
    killsToLevelText:ClearAllPoints()
    killsToLevelText:SetPoint("CENTER", killsCard, "CENTER", 0, 8)

    -- NEXT number - offset up for visual balance
    nextLevelText:ClearAllPoints()
    nextLevelText:SetPoint("CENTER", nextLevelCard, "CENTER", 0, 8)

    -- TIME number - offset up for visual balance
    timeToLevelText:ClearAllPoints()
    timeToLevelText:SetPoint("CENTER", timeCard, "CENTER", 0, 8)

    -- Update XP bar widths when frame is resized
    local currentXP = UnitXP("player")
    local maxXP = UnitXPMax("player")
    if maxXP > 0 then
        local availableWidth = currentXPCard:GetWidth() - (cardPadding * 2)

        -- Current XP bar
        local percentage = (currentXP / maxXP) * 100
        local currentBarWidth = availableWidth * (percentage / 100)
        xpBarFg:SetWidth(currentBarWidth)

        -- Rested XP bar
        local restedXP = GetXPExhaustion() or 0
        local restedPercentage = ((currentXP + restedXP) / maxXP) * 100
        if restedPercentage > 100 then restedPercentage = 100 end
        local restedBarWidth = availableWidth * (restedPercentage / 100)
        xpBarRested:SetWidth(restedBarWidth)
    end
end

-- Handle frame resize
function XPTracker:OnResize(width, height)
    self:UpdateLayout()
end

-- Update current XP percentage
function XPTracker:UpdateCurrentXP()
    local currentXP = UnitXP("player")
    local maxXP = UnitXPMax("player")
    local percentage = 0

    if maxXP > 0 then
        percentage = (currentXP / maxXP) * 100
    end

    currentXPText:SetText(string.format("%.1f%%", percentage))

    -- Check if we recently leveled up (use test duration if in test mode)
    local timeSinceLevelUp = time() - levelUpTime
    local duration = levelUpTestMode and levelUpTestDuration or levelUpDuration
    local isRecentLevelUp = levelUpTime > 0 and timeSinceLevelUp < duration

    if isRecentLevelUp then
        -- Level up celebration mode (background fade handled in OnUpdate for smoothness)
        currentXPText:SetTextColor(0, 1, 0, 1)  -- Green
        currentXPLabel:SetText("LEVELED UP!")
        currentXPLabel:SetTextColor(0, 1, 0, 1)  -- Green

        -- Change card borders to green
        for _, border in pairs(currentXPCardBorders) do
            border:SetColorTexture(0, 1, 0, 1)
        end
    else
        -- Normal mode
        currentXPText:SetTextColor(1, 1, 0, 1)  -- Yellow
        currentXPLabel:SetText("CURRENT XP")
        currentXPLabel:SetTextColor(1, 1, 1, 1)  -- White
        currentXPCardCelebrationBg:Hide()  -- Hide green background

        -- Revert card borders to gray
        for _, border in pairs(currentXPCardBorders) do
            border:SetColorTexture(0.2, 0.2, 0.2, 1)
        end

        -- Clear timer when celebration expires (both test and real)
        if levelUpTime > 0 then
            levelUpTime = 0
            if levelUpTestMode then
                levelUpTestMode = false
            end
        end
    end

    -- Update XP bar widths
    local cardPadding = 5
    local availableWidth = currentXPCard:GetWidth() - (cardPadding * 2)

    -- Current XP bar width
    local currentBarWidth = availableWidth * (percentage / 100)
    xpBarFg:SetWidth(currentBarWidth)

    -- Rested XP bar width
    local restedXP = GetXPExhaustion() or 0
    local restedPercentage = 0
    if maxXP > 0 then
        restedPercentage = ((currentXP + restedXP) / maxXP) * 100
        if restedPercentage > 100 then restedPercentage = 100 end
    end
    local restedBarWidth = availableWidth * (restedPercentage / 100)
    xpBarRested:SetWidth(restedBarWidth)
end

-- Record XP sample for rate calculation
function XPTracker:RecordXPSample()
    local currentTime = time()
    local currentXP = UnitXP("player")

    table.insert(xpSamples, {
        time = currentTime,
        xp = currentXP
    })

    -- Keep only last maxSamples
    while table.getn(xpSamples) > maxSamples do
        table.remove(xpSamples, 1)
    end

    -- Save to SavedVariables
    self:SaveSessionData()
end

-- Calculate and update XP per hour
function XPTracker:UpdateXPPerHour()
    if table.getn(xpSamples) < 2 then
        xpPerHourText:SetText("---")
        return
    end

    local oldest = xpSamples[1]
    local newest = xpSamples[table.getn(xpSamples)]

    local timeDiff = newest.time - oldest.time
    local xpDiff = newest.xp - oldest.xp

    if timeDiff > 0 and xpDiff >= 0 then
        local xpPerSecond = xpDiff / timeDiff
        local xpPerHour = xpPerSecond * 3600

        if xpPerHour >= 1000 then
            xpPerHourText:SetText(string.format("%.1fk", xpPerHour / 1000))
        else
            xpPerHourText:SetText(string.format("%.0f", xpPerHour))
        end
    else
        xpPerHourText:SetText("---")
    end
end

-- Parse combat XP gain message
function XPTracker:ParseCombatXP(message)
    if not message then return end

    -- Pattern: "You gain X experience."
    local xp = string.match(message, "(%d+)")
    if xp then
        lastKillXP = tonumber(xp)
        self:UpdateKillsToLevel()
        self:SaveSessionData()
    end
end

-- Update kills to level
function XPTracker:UpdateKillsToLevel()
    if lastKillXP > 0 then
        local currentXP = UnitXP("player")
        local maxXP = UnitXPMax("player")
        local remaining = maxXP - currentXP

        local kills = math.ceil(remaining / lastKillXP)
        killsToLevelText:SetText(tostring(kills))
    else
        killsToLevelText:SetText("---")
    end
end

-- Update next level display
function XPTracker:UpdateNextLevel()
    local currentLevel = UnitLevel("player")
    nextLevelText:SetText(tostring(currentLevel + 1))
end

-- Update time to level
function XPTracker:UpdateTimeToLevel()
    if table.getn(xpSamples) < 2 then
        timeToLevelText:SetText("---")
        return
    end

    local oldest = xpSamples[1]
    local newest = xpSamples[table.getn(xpSamples)]

    local timeDiff = newest.time - oldest.time
    local xpDiff = newest.xp - oldest.xp

    if timeDiff <= 0 or xpDiff <= 0 then
        timeToLevelText:SetText("---")
        return
    end

    local xpPerSecond = xpDiff / timeDiff
    local currentXP = UnitXP("player")
    local maxXP = UnitXPMax("player")
    local remaining = maxXP - currentXP

    local secondsToLevel = remaining / xpPerSecond
    local minutesToLevel = secondsToLevel / 60
    local hoursToLevel = minutesToLevel / 60

    if hoursToLevel >= 1 then
        local hours = math.floor(hoursToLevel)
        local minutes = math.floor((hoursToLevel - hours) * 60)
        timeToLevelText:SetText(string.format("%dh %dm", hours, minutes))
    else
        timeToLevelText:SetText(string.format("%dm", math.floor(minutesToLevel)))
    end
end

-- Handle level up
function XPTracker:OnLevelUp()
    -- Clear XP samples on level up
    xpSamples = {}
    lastKillXP = 0

    -- Record level up time for celebration display
    levelUpTime = time()
    levelUpTimeHiRes = GetTime()  -- High-resolution timestamp for smooth fade

    self:UpdateNextLevel()
    self:UpdateCurrentXP()
    self:UpdateKillsToLevel()
    self:UpdateTimeToLevel()
    self:SaveSessionData()
end

-- Test level up (for testing, expires after 1 minute)
function XPTracker:TestLevelUp()
    levelUpTime = time()
    levelUpTimeHiRes = GetTime()  -- High-resolution timestamp for smooth fade
    levelUpTestMode = true
    self:UpdateCurrentXP()
    DEFAULT_CHAT_FRAME:AddMessage("Fireside: Test level-up activated (1 minute)", 0, 1, 0)
end

-- Save session data to SavedVariables
function XPTracker:SaveSessionData()
    if not FiresideDB.applets[self.name] then
        FiresideDB.applets[self.name] = {}
    end

    FiresideDB.applets[self.name].sessionData = {
        xpSamples = xpSamples,
        lastKillXP = lastKillXP,
        levelUpTime = levelUpTime
    }
end

-- Register with dashboard
Fireside.Dashboard:RegisterApplet(XPTracker)

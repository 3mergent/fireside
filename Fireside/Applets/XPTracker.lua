-- XP Tracker Applet
-- Tracks experience gain, XP/hour, kills to level, and time remaining

Fireside = Fireside or {}

-- Create XP Tracker applet instance (name, width, height, minWidth, maxWidth, minHeight, maxHeight)
local XPTracker = Fireside.Applet:New("XPTracker", 280, 230, 250, 400, 200, 350)

-- UI Elements
local titleText
local currentXPText
local currentXPLabel
local currentXPCard
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

-- Initialize UI
function XPTracker:OnInitialize()
    -- Load saved session data
    local saved = FiresideDB.applets[self.name]
    if saved and saved.sessionData then
        xpSamples = saved.sessionData.xpSamples or {}
        lastKillXP = saved.sessionData.lastKillXP or 0
    end

    -- Title: Fireside heading
    titleText = self:CreateFontString(nil, "OVERLAY", 14, "CENTER", "TOP")
    titleText:SetPoint("TOP", self.frame, "TOP", 0, -8)
    titleText:SetText("Fireside")
    titleText:SetTextColor(1, 0.82, 0, 1)

    -- Current XP Section (centered, large)
    -- XP percentage number (doubled size: 48pt)
    currentXPText = self:CreateFontString(nil, "OVERLAY", 48, "CENTER", "TOP")
    currentXPText:SetPoint("TOP", self.frame, "TOP", 0, -30)
    currentXPText:SetTextColor(1, 1, 0, 1)  -- Yellow

    -- "CURRENT XP" label (15pt, 25% larger than original 12pt)
    currentXPLabel = self:CreateFontString(nil, "OVERLAY", 15, "CENTER", "TOP")
    currentXPLabel:SetPoint("TOP", currentXPText, "BOTTOM", 0, -2)
    currentXPLabel:SetText("CURRENT XP")

    -- Helper function to create a bordered card
    local function CreateBorderedCard(parent)
        local card = CreateFrame("Frame", nil, parent)
        card:SetFrameLevel(parent:GetFrameLevel() + 2)

        -- Create 4 border edges
        local borderTop = card:CreateTexture(nil, "OVERLAY")
        borderTop:SetHeight(1)
        borderTop:SetColorTexture(0.4, 0.4, 0.4, 1)
        borderTop:SetPoint("TOPLEFT", card, "TOPLEFT")
        borderTop:SetPoint("TOPRIGHT", card, "TOPRIGHT")

        local borderBottom = card:CreateTexture(nil, "OVERLAY")
        borderBottom:SetHeight(1)
        borderBottom:SetColorTexture(0.4, 0.4, 0.4, 1)
        borderBottom:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT")
        borderBottom:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT")

        local borderLeft = card:CreateTexture(nil, "OVERLAY")
        borderLeft:SetWidth(1)
        borderLeft:SetColorTexture(0.4, 0.4, 0.4, 1)
        borderLeft:SetPoint("TOPLEFT", card, "TOPLEFT")
        borderLeft:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT")

        local borderRight = card:CreateTexture(nil, "OVERLAY")
        borderRight:SetWidth(1)
        borderRight:SetColorTexture(0.4, 0.4, 0.4, 1)
        borderRight:SetPoint("TOPRIGHT", card, "TOPRIGHT")
        borderRight:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT")

        return card
    end

    -- Create bordered cards for each stat section
    currentXPCard = CreateBorderedCard(self.frame)
    xpPerHourCard = CreateBorderedCard(self.frame)
    killsCard = CreateBorderedCard(self.frame)
    nextLevelCard = CreateBorderedCard(self.frame)
    timeCard = CreateBorderedCard(self.frame)


    -- Stats Grid (2x2): XP/HR, KILLS on top row; NEXT, TIME on bottom row
    local statNumberSize = 36  -- 50% larger (was 24, now 36)
    local statLabelSize = 13   -- 25% larger (was 10, now 12.5, rounded to 13)

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

    -- Set up OnUpdate for XP/hr tracking
    local timeSinceLastUpdate = 0
    local function OnUpdate(self, elapsed)
        timeSinceLastUpdate = timeSinceLastUpdate + elapsed
        if timeSinceLastUpdate >= updateInterval then
            XPTracker:RecordXPSample()
            XPTracker:UpdateXPPerHour()
            XPTracker:UpdateTimeToLevel()
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
    local padding = 8
    local cardPadding = 5

    -- Calculate responsive positions
    local titleAreaHeight = 30
    local currentXPHeight = 80
    local remainingHeight = height - titleAreaHeight - currentXPHeight - (padding * 2)

    -- Current XP card (full width, at top)
    local currentXPCardY = titleAreaHeight + 5
    local currentXPCardHeight = currentXPHeight - 10
    currentXPCard:ClearAllPoints()
    currentXPCard:SetPoint("TOPLEFT", self.frame, "TOPLEFT", padding, -currentXPCardY)
    currentXPCard:SetWidth(width - (padding * 2))
    currentXPCard:SetHeight(currentXPCardHeight)

    -- Calculate stat card dimensions (2x2 grid)
    local statCardWidth = (width - (padding * 3)) / 2
    local statCardHeight = (remainingHeight - cardPadding) / 2
    local statCardsStartY = titleAreaHeight + currentXPHeight + 5

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

    -- Current XP number - offset up to balance visual weight
    currentXPText:ClearAllPoints()
    currentXPText:SetPoint("CENTER", currentXPCard, "CENTER", 0, 5)

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
    self:UpdateNextLevel()
    self:UpdateCurrentXP()
    self:UpdateKillsToLevel()
    self:UpdateTimeToLevel()
    self:SaveSessionData()
end

-- Save session data to SavedVariables
function XPTracker:SaveSessionData()
    if not FiresideDB.applets[self.name] then
        FiresideDB.applets[self.name] = {}
    end

    FiresideDB.applets[self.name].sessionData = {
        xpSamples = xpSamples,
        lastKillXP = lastKillXP
    }
end

-- Register with dashboard
Fireside.Dashboard:RegisterApplet(XPTracker)

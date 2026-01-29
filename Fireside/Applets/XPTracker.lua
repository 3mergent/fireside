-- XP Tracker Applet
-- Tracks experience gain, XP/hour, kills to level, and time remaining

Fireside = Fireside or {}

-- Create XP Tracker applet instance (name, width, height, minWidth, maxWidth, minHeight, maxHeight)
local XPTracker = Fireside.Applet:New("XPTracker", 280, 230, 250, 400, 200, 350)

-- UI Elements
local titleText
local currentXPText
local currentXPLabel
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

    -- Calculate responsive column positions (50% width each)
    local columnWidth = width / 2
    local leftX = -columnWidth / 2
    local rightX = columnWidth / 2

    -- Calculate responsive row positions based on height
    -- Distribute vertical space: title area + current XP + 2 stat rows + padding
    local titleAreaHeight = 30
    local currentXPHeight = 80
    local remainingHeight = height - titleAreaHeight - currentXPHeight
    local statRowSpacing = remainingHeight / 2.5

    local row2Y = -(titleAreaHeight + currentXPHeight)
    local row3Y = row2Y - statRowSpacing

    -- Reposition stat numbers
    xpPerHourText:ClearAllPoints()
    xpPerHourText:SetPoint("TOP", self.frame, "TOP", leftX, row2Y)

    killsToLevelText:ClearAllPoints()
    killsToLevelText:SetPoint("TOP", self.frame, "TOP", rightX, row2Y)

    nextLevelText:ClearAllPoints()
    nextLevelText:SetPoint("TOP", self.frame, "TOP", leftX, row3Y)

    timeToLevelText:ClearAllPoints()
    timeToLevelText:SetPoint("TOP", self.frame, "TOP", rightX, row3Y)
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

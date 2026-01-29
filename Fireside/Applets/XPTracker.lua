-- XP Tracker Applet
-- Tracks experience gain, XP/hour, kills to level, and time remaining

Fireside = Fireside or {}

-- Create XP Tracker applet instance
local XPTracker = Fireside.Applet:New("XPTracker", 280, 140)

-- UI Elements
local titleText
local currentXPText
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

    -- Row 1: Current XP (large, centered, spans full width)
    currentXPText = self:CreateFontString(nil, "OVERLAY", 24, "CENTER", "TOP")
    currentXPText:SetPoint("TOP", self.frame, "TOP", 0, -30)
    currentXPText:SetWidth(self.width - 20)
    currentXPText:SetTextColor(1, 1, 0, 1)

    -- Row 2: XP/hr (left) and Kills (right)
    xpPerHourLabel = self:CreateFontString(nil, "OVERLAY", 10, "LEFT", "TOP")
    xpPerHourLabel:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, -65)
    xpPerHourLabel:SetText("XP/hr:")

    xpPerHourText = self:CreateFontString(nil, "OVERLAY", 14, "RIGHT", "TOP")
    xpPerHourText:SetPoint("TOPRIGHT", self.frame, "TOP", -5, -65)
    xpPerHourText:SetWidth((self.width / 2) - 15)

    killsToLevelLabel = self:CreateFontString(nil, "OVERLAY", 10, "LEFT", "TOP")
    killsToLevelLabel:SetPoint("TOPLEFT", self.frame, "TOP", 5, -65)
    killsToLevelLabel:SetText("Kills:")

    killsToLevelText = self:CreateFontString(nil, "OVERLAY", 14, "RIGHT", "TOP")
    killsToLevelText:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -10, -65)
    killsToLevelText:SetWidth((self.width / 2) - 15)

    -- Row 3: Next level (left) and Time to level (right)
    nextLevelLabel = self:CreateFontString(nil, "OVERLAY", 10, "LEFT", "TOP")
    nextLevelLabel:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, -95)
    nextLevelLabel:SetText("Next:")

    nextLevelText = self:CreateFontString(nil, "OVERLAY", 14, "RIGHT", "TOP")
    nextLevelText:SetPoint("TOPRIGHT", self.frame, "TOP", -5, -95)
    nextLevelText:SetWidth((self.width / 2) - 15)

    timeToLevelLabel = self:CreateFontString(nil, "OVERLAY", 10, "LEFT", "TOP")
    timeToLevelLabel:SetPoint("TOPLEFT", self.frame, "TOP", 5, -95)
    timeToLevelLabel:SetText("Time:")

    timeToLevelText = self:CreateFontString(nil, "OVERLAY", 14, "RIGHT", "TOP")
    timeToLevelText:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -10, -95)
    timeToLevelText:SetWidth((self.width / 2) - 15)

    -- Register events
    self.frame:RegisterEvent("PLAYER_XP_UPDATE")
    self.frame:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
    self.frame:RegisterEvent("PLAYER_LEVEL_UP")

    self.frame:SetScript("OnEvent", function()
        if event == "PLAYER_XP_UPDATE" then
            XPTracker:UpdateCurrentXP()
            XPTracker:UpdateKillsToLevel()
            XPTracker:UpdateTimeToLevel()
        elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
            XPTracker:ParseCombatXP(arg1)
        elseif event == "PLAYER_LEVEL_UP" then
            XPTracker:OnLevelUp()
        end
    end)

    -- Set up OnUpdate for XP/hr tracking
    local timeSinceLastUpdate = 0
    self.frame:SetScript("OnUpdate", function()
        timeSinceLastUpdate = timeSinceLastUpdate + arg1
        if timeSinceLastUpdate >= updateInterval then
            XPTracker:RecordXPSample()
            XPTracker:UpdateXPPerHour()
            XPTracker:UpdateTimeToLevel()
            timeSinceLastUpdate = 0
        end
    end)

    -- Initial update
    self:UpdateCurrentXP()
    self:UpdateNextLevel()
    self:UpdateKillsToLevel()
    self:UpdateXPPerHour()
    self:UpdateTimeToLevel()
end

-- Update current XP percentage
function XPTracker:UpdateCurrentXP()
    local currentXP = UnitXP("player")
    local maxXP = UnitXPMax("player")
    local percentage = 0

    if maxXP > 0 then
        percentage = (currentXP / maxXP) * 100
    end

    currentXPText:SetText(string.format("Current XP: %.1f%%", percentage))
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

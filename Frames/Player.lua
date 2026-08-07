local addonName, BFUF = ...

local INDICATOR_ANCHORS = {
    combat = { point = "TOPLEFT", relativePoint = "TOPLEFT" },
    resting = { point = "TOPLEFT", relativePoint = "TOPLEFT" },
    leader = { point = "TOPRIGHT", relativePoint = "TOP" },
    assistant = { point = "TOPLEFT", relativePoint = "TOP" },
    pvp = { point = "BOTTOMLEFT", relativePoint = "BOTTOMLEFT" },
    afk = { point = "BOTTOMLEFT", relativePoint = "BOTTOMLEFT" },
    dnd = { point = "BOTTOMLEFT", relativePoint = "BOTTOMLEFT" },
}

local PERCENT_TO_HUNDRED_CURVE = C_CurveUtil.CreateCurve()
PERCENT_TO_HUNDRED_CURVE:SetType(Enum.LuaCurveType.Linear)
PERCENT_TO_HUNDRED_CURVE:AddPoint(0.0, 0)
PERCENT_TO_HUNDRED_CURVE:AddPoint(1.0, 100)

local HEALTH_TEXT_FORMAT = "currentMaxPercent"
local POWER_TEXT_FORMAT = "currentMaxPercent"
local SUPPORTED_POWER_TYPES = {
    MANA = true, RAGE = true, ENERGY = true, FOCUS = true, RUNIC_POWER = true,
    MAELSTROM = true, INSANITY = true, ESSENCE = true, FURY = true, LUNAR_POWER = true,
}

BFUF.Frames = BFUF.Frames or {}
local Player = {}
BFUF.Frames.Player = Player

local function formatStatusText(currentValue, maxValue, percentValue, format)
    if format == "current" then
        return string.format("%d", currentValue)
    elseif format == "currentMax" then
        return string.format("%d / %d", currentValue, maxValue)
    elseif format == "percent" then
        return string.format("%.0f%%", percentValue)
    elseif format == "currentPercent" then
        return string.format("%d (%.0f%%)", currentValue, percentValue)
    end

    return string.format("%d / %d (%.0f%%)", currentValue, maxValue, percentValue)
end

function Player:UpdatePortrait(frame)
    frame = frame or BFUF.Framework.Registry:GetFrame("player")
    if frame then
        self:UpdateLayout(frame)
    end
end

-- Apply every Player Frame layout value through one path.
function Player:UpdateLayout(frame)
    frame = frame or BFUF.Framework.Registry:GetFrame("player")
    if not frame then
        return
    end

    local settings = BFUF.DB:Get("Player")
    local portraitSettings = settings.portrait
    local healthSettings = settings.health
    local powerSettings = settings.power

    frame:SetSize(settings.width, settings.height)
    frame:SetScale(settings.scale)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", settings.positionX, settings.positionY)

    frame.portrait:ClearAllPoints()
    frame.portrait:SetSize(portraitSettings.width, portraitSettings.height)
    frame.portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", portraitSettings.offsetX, portraitSettings.offsetY)
    frame.portrait:SetShown(portraitSettings.show)

    local contentLeft = healthSettings.offsetX
    if portraitSettings.show then
        contentLeft = portraitSettings.offsetX + portraitSettings.width + healthSettings.offsetX
    end

    frame.healthBar:ClearAllPoints()
    frame.healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", contentLeft, healthSettings.offsetY)
    frame.healthBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -healthSettings.offsetX, healthSettings.offsetY)
    frame.healthBar:SetHeight(healthSettings.height)

    frame.powerBar:ClearAllPoints()
    frame.powerBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", contentLeft, powerSettings.offsetY)
    frame.powerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -powerSettings.offsetX, powerSettings.offsetY)
    frame.powerBar:SetHeight(powerSettings.height)

    local textSettings = settings.texts
    local name = frame.nameText
    name:ClearAllPoints()
    name:SetPoint("LEFT", frame.healthBar, "LEFT", textSettings.name.offsetX, textSettings.name.offsetY)
    name:SetFont(STANDARD_TEXT_FONT, textSettings.name.fontSize)
    name:SetShown(textSettings.name.show)

    local healthText = frame.healthText
    healthText:ClearAllPoints()
    healthText:SetPoint("RIGHT", frame.healthBar, "RIGHT", textSettings.health.offsetX, textSettings.health.offsetY)
    healthText:SetFont(STANDARD_TEXT_FONT, textSettings.health.fontSize)
    healthText:SetShown(textSettings.health.show)

    local powerText = frame.powerText
    powerText:ClearAllPoints()
    powerText:SetPoint("RIGHT", frame.powerBar, "RIGHT", textSettings.power.offsetX, textSettings.power.offsetY)
    powerText:SetFont(STANDARD_TEXT_FONT, textSettings.power.fontSize)
    powerText:SetShown(textSettings.power.show)

    for name, indicator in pairs(frame.indicators) do
        local indicatorSettings = settings.indicators[name]
        local anchor = INDICATOR_ANCHORS[name]
        indicator:ClearAllPoints()
        indicator:SetSize(indicatorSettings.size, indicatorSettings.size)
        indicator:SetPoint(anchor.point, frame, anchor.relativePoint, indicatorSettings.offsetX, indicatorSettings.offsetY)
        indicator:Update()
    end

    frame.healthBar:UpdateStyle()
    frame.powerBar:UpdateStyle()
end

function Player:SavePosition(frame)
    local centerX, centerY = frame:GetCenter()
    local parentX, parentY = UIParent:GetCenter()
    if not centerX or not parentX then
        return
    end

    local scale = UIParent:GetEffectiveScale()
    local settings = BFUF.DB:Get("Player")
    settings.positionX = math.floor((centerX - parentX) / scale + 0.5)
    settings.positionY = math.floor((centerY - parentY) / scale + 0.5)
    BFUF.Config.Player:RefreshLayoutControls()
end

function Player:SetLayoutUnlocked(unlocked)
    local frame = BFUF.Framework.Registry:GetFrame("player")
    if not frame then
        return
    end

    frame.layoutUnlocked = unlocked
    frame:SetMovable(unlocked)
    frame:EnableMouse(unlocked)
end

function Player:Create()
    local registry = BFUF.Framework.Registry
    local existingFrame = registry:GetFrame("player")
    if existingFrame then
        return existingFrame
    end

    local frame = BFUF.Framework.Factory:CreateUnitFrame("player")
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if self.layoutUnlocked then
            self.isDragging = true
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        if self.isDragging then
            self:StopMovingOrSizing()
            self.isDragging = false
            Player:SavePosition(self)
            Player:UpdateLayout(self)
        end
    end)
    frame:SetScript("OnUpdate", function(self)
        if self.isDragging then
            Player:SavePosition(self)
        end
    end)

    local background = BFUF.Framework.Factory:CreateTexture(frame)
    background:SetDrawLayer("BACKGROUND")
    background:SetAllPoints(frame)
    background:SetColorTexture(0, 0, 0, 0.8)
    frame.background = background

    local portrait = BFUF.Elements.Portrait:Create(frame, BFUF.Elements.Portrait.Types.TEXTURE)
    portrait:SetUnit("player")
    portrait:Update()
    frame.portrait = portrait

    frame.healthBar = BFUF.Elements.Health:Create(frame)
    frame.healthBar:SetUnit("player")

    frame.powerBar = BFUF.Elements.Power:Create(frame)
    frame.powerBar:SetUnit("player")

    frame.nameText = BFUF.Elements.Text:Create(frame.healthBar, {
        font = STANDARD_TEXT_FONT, size = 12, justifyH = "LEFT", justifyV = "MIDDLE",
    })
    frame.healthText = BFUF.Elements.Text:Create(frame.healthBar, {
        font = STANDARD_TEXT_FONT, size = 12, justifyH = "RIGHT", justifyV = "MIDDLE",
    })
    frame.powerText = BFUF.Elements.Text:Create(frame.powerBar, {
        font = STANDARD_TEXT_FONT, size = 12, justifyH = "RIGHT", justifyV = "MIDDLE",
    })

    local defaults = BFUF.Defaults.profile.Player.indicators
    frame.indicators = {
        combat = BFUF.Elements.Indicators.Combat:Create(frame, { point = "TOPLEFT", relativePoint = "TOPLEFT", offsetX = defaults.combat.offsetX, offsetY = defaults.combat.offsetY, size = defaults.combat.size }),
        resting = BFUF.Elements.Indicators.Resting:Create(frame, { point = "TOPLEFT", relativePoint = "TOPLEFT", offsetX = defaults.resting.offsetX, offsetY = defaults.resting.offsetY, size = defaults.resting.size }),
        leader = BFUF.Elements.Indicators.Leader:Create(frame, { point = "TOPRIGHT", relativePoint = "TOP", offsetX = defaults.leader.offsetX, offsetY = defaults.leader.offsetY, size = defaults.leader.size }),
        assistant = BFUF.Elements.Indicators.Assistant:Create(frame, { point = "TOPLEFT", relativePoint = "TOP", offsetX = defaults.assistant.offsetX, offsetY = defaults.assistant.offsetY, size = defaults.assistant.size }),
        pvp = BFUF.Elements.Indicators.PvP:Create(frame, { point = "BOTTOMLEFT", relativePoint = "BOTTOMLEFT", offsetX = defaults.pvp.offsetX, offsetY = defaults.pvp.offsetY, size = defaults.pvp.size }),
        afk = BFUF.Elements.Indicators.AFK:Create(frame, { point = "BOTTOMLEFT", relativePoint = "BOTTOMLEFT", offsetX = defaults.afk.offsetX, offsetY = defaults.afk.offsetY, size = defaults.afk.size }),
        dnd = BFUF.Elements.Indicators.DND:Create(frame, { point = "BOTTOMLEFT", relativePoint = "BOTTOMLEFT", offsetX = defaults.dnd.offsetX, offsetY = defaults.dnd.offsetY, size = defaults.dnd.size }),
    }

    local function updateName()
        frame.nameText:SetText(UnitName("player") or "")
    end
    local function updateHealthText()
        frame.healthText:SetText(formatStatusText(
            UnitHealth("player"), UnitHealthMax("player"),
            UnitHealthPercent("player", true, PERCENT_TO_HUNDRED_CURVE), HEALTH_TEXT_FORMAT
        ))
    end
    local function updatePowerText()
        local powerType, powerToken = UnitPowerType("player")
        if not SUPPORTED_POWER_TYPES[powerToken] then
            frame.powerText:SetText("")
            return
        end
        frame.powerText:SetText(formatStatusText(
            UnitPower("player", powerType), UnitPowerMax("player", powerType),
            UnitPowerPercent("player", powerType, false, PERCENT_TO_HUNDRED_CURVE), POWER_TEXT_FORMAT
        ))
    end

    frame:RegisterEvent("PLAYER_LOGIN")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("UNIT_PORTRAIT_UPDATE")
    frame:RegisterEvent("UNIT_HEALTH")
    frame:RegisterEvent("UNIT_MAXHEALTH")
    frame:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
    frame:RegisterEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED")
    frame:RegisterEvent("UNIT_POWER_UPDATE")
    frame:RegisterEvent("UNIT_MAXPOWER")
    frame:RegisterEvent("UNIT_DISPLAYPOWER")
    frame:RegisterEvent("UNIT_MODEL_CHANGED")
    frame:RegisterEvent("UNIT_NAME_UPDATE")
    frame:SetScript("OnEvent", function(self, event, unit)
        if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
            self.portrait:Update()
            self.healthBar:Update()
            self.powerBar:Update()
            updateName()
            updateHealthText()
            updatePowerText()
            return
        end
        if unit ~= "player" then
            return
        end
        if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
            self.healthBar:Update()
            updateHealthText()
        elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" or event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" then
            self.healthBar:UpdateOverlays()
        elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
            self.powerBar:Update()
            updatePowerText()
        elseif event == "UNIT_MODEL_CHANGED" or event == "UNIT_PORTRAIT_UPDATE" then
            self.portrait:Update()
        elseif event == "UNIT_NAME_UPDATE" then
            updateName()
        end
    end)

    registry:RegisterFrame("player", frame)
    self:SetLayoutUnlocked(false)
    self:UpdateLayout(frame)
    frame.healthBar:Update()
    frame.powerBar:Update()
    updateName()
    updateHealthText()
    updatePowerText()

    return frame
end

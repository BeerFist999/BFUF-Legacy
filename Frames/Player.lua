local addonName, BFUF = ...

-- Temporary layout for the base player frame.
-- All element sizes remain here until LayoutEngine is implemented.
local PLAYER_LAYOUT = {
    frame = {
        width = 240,
        height = 50,
        offsetX = 0,
        offsetY = 0,
    },
    portrait = {
        width = 44,
        inset = 3,
    },
    health = {
        inset = 3,
        bottomOffset = 13,
    },
    power = {
        height = 8,
        inset = 3,
    },
    text = {
        inset = 4,
        size = 12,
        color = { r = 1, g = 1, b = 1, a = 1 },
    },
    healthText = {
        inset = 4,
        size = 12,
        color = { r = 1, g = 1, b = 1, a = 1 },
    },
    powerText = {
        inset = 4,
        size = 12,
        color = { r = 1, g = 1, b = 1, a = 1 },
    },
    indicators = {
        combat = {
            size = 16,
            point = "TOPLEFT",
            relativePoint = "TOPLEFT",
            offsetX = 3,
            offsetY = -3,
            enabled = true,
        },
        resting = {
            size = 16,
            point = "TOPLEFT",
            relativePoint = "TOPLEFT",
            offsetX = 21,
            offsetY = -3,
            enabled = true,
        },
        leader = {
            size = 12,
            point = "TOPRIGHT",
            relativePoint = "TOP",
            offsetX = -1,
            offsetY = -3,
            enabled = true,
        },
        assistant = {
            size = 12,
            point = "TOPLEFT",
            relativePoint = "TOP",
            offsetX = 1,
            offsetY = -3,
            enabled = true,
        },
        pvp = {
            size = 12,
            point = "BOTTOMLEFT",
            relativePoint = "BOTTOMLEFT",
            offsetX = 3,
            offsetY = 3,
            enabled = true,
        },
        afk = {
            size = 12,
            point = "BOTTOMLEFT",
            relativePoint = "BOTTOMLEFT",
            offsetX = 17,
            offsetY = 3,
            enabled = false,
        },
        dnd = {
            size = 12,
            point = "BOTTOMLEFT",
            relativePoint = "BOTTOMLEFT",
            offsetX = 31,
            offsetY = 3,
            enabled = false,
        },
    },
}

-- Blizzard returns health and power percentages in the 0.0 to 1.0 range.
-- Curve converts the result to 0–100 inside the client and avoids forbidden
-- Lua arithmetic on Secret Values.
local PERCENT_TO_HUNDRED_CURVE = C_CurveUtil.CreateCurve()
PERCENT_TO_HUNDRED_CURVE:SetType(Enum.LuaCurveType.Linear)
PERCENT_TO_HUNDRED_CURVE:AddPoint(0.0, 0)
PERCENT_TO_HUNDRED_CURVE:AddPoint(1.0, 100)

-- Health text formats are prepared for future settings without changing update logic.
local HEALTH_TEXT_FORMATS = {
    CURRENT = "current",
    CURRENT_MAX = "currentMax",
    PERCENT = "percent",
    CURRENT_PERCENT = "currentPercent",
    CURRENT_MAX_PERCENT = "currentMaxPercent",
}

local HEALTH_TEXT_FORMAT = HEALTH_TEXT_FORMATS.CURRENT_MAX_PERCENT

-- Format health or power values without Lua arithmetic.
-- In Retail 12, UnitHealth* and UnitPower* can return Secret Values. Addons
-- must not compare, convert, or calculate them directly. Blizzard calculates
-- the percentage natively, and string.format safely produces display text.
local function formatStatusText(currentValue, maxValue, percentValue, displayFormat, formats)
    if displayFormat == formats.CURRENT then
        return string.format("%d", currentValue)
    elseif displayFormat == formats.CURRENT_MAX then
        return string.format("%d / %d", currentValue, maxValue)
    elseif displayFormat == formats.PERCENT then
        return string.format("%.0f%%", percentValue)
    elseif displayFormat == formats.CURRENT_PERCENT then
        return string.format("%d (%.0f%%)", currentValue, percentValue)
    end

    return string.format("%d / %d (%.0f%%)", currentValue, maxValue, percentValue)
end

-- Power text formats are prepared for future settings without changing update logic.
local POWER_TEXT_FORMATS = {
    CURRENT = "current",
    CURRENT_MAX = "currentMax",
    PERCENT = "percent",
    CURRENT_PERCENT = "currentPercent",
    CURRENT_MAX_PERCENT = "currentMaxPercent",
}

local POWER_TEXT_FORMAT = POWER_TEXT_FORMATS.CURRENT_MAX_PERCENT

-- Supported power types for text display.
local SUPPORTED_POWER_TYPES = {
    MANA = true,
    RAGE = true,
    ENERGY = true,
    FOCUS = true,
    RUNIC_POWER = true,
    MAELSTROM = true,
    INSANITY = true,
    ESSENCE = true,
    FURY = true,
    LUNAR_POWER = true,
}

-- This module creates the secure player frame with its resource bars.
BFUF.Frames = BFUF.Frames or {}

local Player = {}
BFUF.Frames.Player = Player

-- Apply the saved portrait visibility to an existing player frame.
function Player:UpdatePortrait(frame)
    frame = frame or BFUF.Framework.Registry:GetFrame("player")

    if not frame or not frame.portrait then
        return
    end

    local settings = BFUF.DB:Get("Player")
    frame.portrait:SetShown(settings.showPortrait)
end

-- Apply saved size, scale, and position to an existing player frame.
function Player:UpdateLayout(frame)
    frame = frame or BFUF.Framework.Registry:GetFrame("player")

    if not frame then
        return
    end

    local settings = BFUF.DB:Get("Player")
    frame:SetSize(settings.width, settings.height)
    frame:SetScale(settings.scale)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", settings.positionX, settings.positionY)
end

-- Create and register the main player unit frame.
function Player:Create()
    local registry = BFUF.Framework.Registry
    local factory = BFUF.Framework.Factory
    local existingFrame = registry:GetFrame("player")

    -- Do not create a second player frame when one is already registered.
    if existingFrame then
        return existingFrame
    end

    -- The secure main frame is the parent for all player frame elements.
    local frame = factory:CreateUnitFrame("player")
    frame:SetSize(PLAYER_LAYOUT.frame.width, PLAYER_LAYOUT.frame.height)
    frame:SetPoint("CENTER", UIParent, "CENTER", PLAYER_LAYOUT.frame.offsetX, PLAYER_LAYOUT.frame.offsetY)

    -- Background fills the main frame and remains behind the portrait.
    local background = factory:CreateTexture(frame)
    background:SetDrawLayer("BACKGROUND")
    background:SetAllPoints(frame)
    background:SetColorTexture(0, 0, 0, 0.8)
    frame.background = background

    -- Portrait is positioned on the left and uses the 2D variant until PlayerModel exists.
    local portrait = BFUF.Elements.Portrait:Create(frame, BFUF.Elements.Portrait.Types.TEXTURE)
    portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", PLAYER_LAYOUT.portrait.inset, -PLAYER_LAYOUT.portrait.inset)
    portrait:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PLAYER_LAYOUT.portrait.inset, PLAYER_LAYOUT.portrait.inset)
    portrait:SetWidth(PLAYER_LAYOUT.portrait.width)
    frame.portrait = portrait

    -- Player Frame only creates independent status indicator modules.
    local indicators = {
        combat = BFUF.Elements.Indicators.Combat:Create(frame, PLAYER_LAYOUT.indicators.combat),
        resting = BFUF.Elements.Indicators.Resting:Create(frame, PLAYER_LAYOUT.indicators.resting),
        leader = BFUF.Elements.Indicators.Leader:Create(frame, PLAYER_LAYOUT.indicators.leader),
        assistant = BFUF.Elements.Indicators.Assistant:Create(frame, PLAYER_LAYOUT.indicators.assistant),
        pvp = BFUF.Elements.Indicators.PvP:Create(frame, PLAYER_LAYOUT.indicators.pvp),
        afk = BFUF.Elements.Indicators.AFK:Create(frame, PLAYER_LAYOUT.indicators.afk),
        dnd = BFUF.Elements.Indicators.DND:Create(frame, PLAYER_LAYOUT.indicators.dnd),
    }
    frame.indicators = indicators

    -- Bar offsets are derived from portrait size defined by the layout.
    local contentLeftOffset = PLAYER_LAYOUT.portrait.inset + PLAYER_LAYOUT.portrait.width + PLAYER_LAYOUT.health.inset

    -- HealthBar occupies the upper area and leaves space for PowerBar.
    local healthBar = BFUF.Elements.Health:Create(frame)
    healthBar:ClearAllPoints()
    healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", contentLeftOffset, -PLAYER_LAYOUT.health.inset)
    healthBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PLAYER_LAYOUT.health.inset, -PLAYER_LAYOUT.health.inset)
    healthBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", contentLeftOffset, PLAYER_LAYOUT.health.bottomOffset)
    healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PLAYER_LAYOUT.health.inset, PLAYER_LAYOUT.health.bottomOffset)
    frame.healthBar = healthBar
    BFUF:Debug("Health element attached.")

    -- PowerBar receives its dimensions exclusively from the Player Frame layout.
    local powerBar = BFUF.Elements.Power:Create(frame)
    powerBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", contentLeftOffset, PLAYER_LAYOUT.power.inset)
    powerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PLAYER_LAYOUT.power.inset, PLAYER_LAYOUT.power.inset)
    powerBar:SetHeight(PLAYER_LAYOUT.power.height)
    frame.powerBar = powerBar

    -- Text Element displays the player name.
    local nameText = BFUF.Elements.Text:Create(healthBar, {
        font = STANDARD_TEXT_FONT,
        size = PLAYER_LAYOUT.text.size,
        color = PLAYER_LAYOUT.text.color,
        justifyH = "LEFT",
        justifyV = "MIDDLE",
    })
    nameText:SetPoint("TOPLEFT", healthBar, "TOPLEFT", PLAYER_LAYOUT.text.inset, 0)
    nameText:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", -PLAYER_LAYOUT.text.inset, 0)
    frame.nameText = nameText

    -- A second Text Element displays current, maximum, and percentage health.
    local healthText = BFUF.Elements.Text:Create(healthBar, {
        font = STANDARD_TEXT_FONT,
        size = PLAYER_LAYOUT.healthText.size,
        color = PLAYER_LAYOUT.healthText.color,
        justifyH = "RIGHT",
        justifyV = "MIDDLE",
    })
    healthText:SetPoint("TOPLEFT", healthBar, "TOPLEFT", PLAYER_LAYOUT.healthText.inset, 0)
    healthText:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", -PLAYER_LAYOUT.healthText.inset, 0)
    frame.healthText = healthText

    -- Text Element displays current, maximum, and percentage primary power.
    local powerText = BFUF.Elements.Text:Create(powerBar, {
        font = STANDARD_TEXT_FONT,
        size = PLAYER_LAYOUT.powerText.size,
        color = PLAYER_LAYOUT.powerText.color,
        justifyH = "RIGHT",
        justifyV = "MIDDLE",
    })
    powerText:SetPoint("TOPLEFT", powerBar, "TOPLEFT", PLAYER_LAYOUT.powerText.inset, 0)
    powerText:SetPoint("BOTTOMRIGHT", powerBar, "BOTTOMRIGHT", -PLAYER_LAYOUT.powerText.inset, 0)
    frame.powerText = powerText

    -- Update the name from one shared function used at creation and on events.
    local function updateNameText()
        nameText:SetText(UnitName("player") or "")
    end

    -- Update health text through the shared formatting function.
    local function updateHealthText()
        local currentHealth = UnitHealth("player")
        local maxHealth = UnitHealthMax("player")
        local healthPercent = UnitHealthPercent("player", true, PERCENT_TO_HUNDRED_CURVE)

        healthText:SetText(formatStatusText(
            currentHealth,
            maxHealth,
            healthPercent,
            HEALTH_TEXT_FORMAT,
            HEALTH_TEXT_FORMATS
        ))
    end

    -- Update text for the current primary power in the selected format.
    local function updatePowerText()
        local powerType, powerToken = UnitPowerType("player")

        if not SUPPORTED_POWER_TYPES[powerToken] then
            powerText:SetText("")
            return
        end

        local currentPower = UnitPower("player", powerType)
        local maxPower = UnitPowerMax("player", powerType)
        local powerPercent = UnitPowerPercent("player", powerType, false, PERCENT_TO_HUNDRED_CURVE)

        powerText:SetText(formatStatusText(
            currentPower,
            maxPower,
            powerPercent,
            POWER_TEXT_FORMAT,
            POWER_TEXT_FORMATS
        ))
    end

    -- Assign player units and perform their first updates.
    portrait:SetUnit("player")
    portrait:Update()
    self:UpdatePortrait(frame)
    self:UpdateLayout(frame)

    healthBar:SetUnit("player")
    healthBar:Update()
    updateHealthText()
    BFUF:Debug("Health updated")

    powerBar:SetUnit("player")
    powerBar:Update()
    updatePowerText()

    updateNameText()

    -- Subscribe only to events needed by player resources and model.
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("UNIT_PORTRAIT_UPDATE")
    frame:RegisterEvent("UNIT_HEALTH")
    frame:RegisterEvent("UNIT_MAXHEALTH")
    frame:RegisterEvent("UNIT_POWER_UPDATE")
    frame:RegisterEvent("UNIT_MAXPOWER")
    frame:RegisterEvent("UNIT_DISPLAYPOWER")
    frame:RegisterEvent("UNIT_MODEL_CHANGED")
    frame:RegisterEvent("UNIT_NAME_UPDATE")
    frame:SetScript("OnEvent", function(self, event, unit)
        -- PLAYER_LOGIN occurs after the character and appearance are fully loaded.
        if event == "PLAYER_LOGIN" then
            portrait:Update()
            self:UnregisterEvent("PLAYER_LOGIN")
            return
        end

        -- Refresh all elements when the player enters the world.
        if event == "PLAYER_ENTERING_WORLD" then
            portrait:Update()
            healthBar:Update()
            powerBar:Update()
            updateNameText()
            updatePowerText()
            updateHealthText()
            self:UnregisterEvent("PLAYER_ENTERING_WORLD")
            return
        end

        -- Events for other units do not affect Player Frame.
        if unit ~= "player" then
            return
        end

        if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
            healthBar:Update()
            updateHealthText()
            BFUF:Debug("Health updated from event.")
        elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
            powerBar:Update()
            updatePowerText()
        elseif event == "UNIT_MODEL_CHANGED" or event == "UNIT_PORTRAIT_UPDATE" then
            -- UNIT_PORTRAIT_UPDATE signals that the current 2D portrait is ready.
            portrait:Update()
        elseif event == "UNIT_NAME_UPDATE" then
            updateNameText()
        end
    end)

    -- Registry keeps the completed frame under the player name.
    if registry:RegisterFrame("player", frame) then
        return frame
    end

    -- Return the existing object if it was registered before this call.
    return registry:GetFrame("player")
end

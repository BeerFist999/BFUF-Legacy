local addonName, BFUF = ...

BFUF.Elements = BFUF.Elements or {}

local Health = {}
BFUF.Elements.Health = Health

-- Deferred until a public, secret-safe prediction-segment API is available.
local INCOMING_HEALS_ENABLED = false

local DEFAULT_SETTINGS = {
    colorMode = "custom",
    customColor = { r = 1, g = 1, b = 1 },
    showAbsorb = true,
    absorbColor = { r = 0.8, g = 0.8, b = 1 },
    absorbAlpha = 0.65,
    absorbPosition = "left",
    absorbTexture = "blizzard",
    showHealAbsorb = true,
    healAbsorbColor = { r = 0.85, g = 0.15, b = 0.15 },
    healAbsorbAlpha = 0.65,
    healAbsorbPosition = "left",
    healAbsorbTexture = "blizzard",
    incomingHeal = false,
    incomingHealColor = { r = 0.25, g = 1, b = 0.4 },
    incomingHealAlpha = 0.55,
    incomingHealPosition = "right",
    incomingHealTexture = "blizzard",
}

local function getSettings(statusBar)
    if statusBar.settings then
        return statusBar.settings
    end

    local context = statusBar.context
    if context and context.getSettings then
        return context.getSettings() or DEFAULT_SETTINGS
    end

    return DEFAULT_SETTINGS
end

local function applyColor(statusBar, settings)
    if statusBar.colorResolver then
        local red, green, blue = statusBar.colorResolver(statusBar.unit)
        statusBar:SetStatusBarColor(red, green, blue)
        return
    end

    local color = settings.customColor or DEFAULT_SETTINGS.customColor

    if settings.colorMode == "class" then
        local _, class = UnitClass(statusBar.unit or "player")
        color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class] or RAID_CLASS_COLORS.PRIEST
    end

    statusBar:SetStatusBarColor(color.r, color.g, color.b)
end

-- Create the health bar and its independent absorb overlays.
function Health:Create(parent, context)
    local statusBar = CreateFrame("StatusBar", nil, parent)
    statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    statusBar.context = context or {}

    local absorbBar = CreateFrame("StatusBar", nil, statusBar)
    absorbBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    statusBar.absorbBar = absorbBar

    local healAbsorbBar = CreateFrame("StatusBar", nil, statusBar)
    healAbsorbBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    statusBar.healAbsorbBar = healAbsorbBar

    local incomingHealBar = CreateFrame("StatusBar", nil, statusBar)
    incomingHealBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    statusBar.incomingHealBar = incomingHealBar

    function statusBar:SetUnit(unit)
        self.unit = unit
    end

    -- Preserve frame-specific color policy, including Target/Boss reaction colors.
    function statusBar:SetColorResolver(resolver)
        self.colorResolver = resolver
    end

    -- Apply a profile-neutral settings table supplied by the frame context.
    function statusBar:ApplySettings(settings)
        self.settings = settings
        self:UpdateStyle()
    end

    function statusBar:UpdateStyle()
        local settings = getSettings(self)
        local absorbColor = settings.absorbColor or DEFAULT_SETTINGS.absorbColor
        local healAbsorbColor = settings.healAbsorbColor or DEFAULT_SETTINGS.healAbsorbColor
        local absorbAlpha = settings.absorbAlpha
        local healAbsorbAlpha = settings.healAbsorbAlpha
        local absorbPosition = settings.absorbPosition or DEFAULT_SETTINGS.absorbPosition
        local healAbsorbPosition = settings.healAbsorbPosition or DEFAULT_SETTINGS.healAbsorbPosition
        local absorbTexture = settings.absorbTexture or DEFAULT_SETTINGS.absorbTexture
        local healAbsorbTexture = settings.healAbsorbTexture or DEFAULT_SETTINGS.healAbsorbTexture
        local incomingHealColor = settings.incomingHealColor or DEFAULT_SETTINGS.incomingHealColor
        local incomingHealAlpha = settings.incomingHealAlpha
        local incomingHealPosition = settings.incomingHealPosition or DEFAULT_SETTINGS.incomingHealPosition
        local incomingHealTexture = settings.incomingHealTexture or DEFAULT_SETTINGS.incomingHealTexture

        if absorbAlpha == nil then
            absorbAlpha = DEFAULT_SETTINGS.absorbAlpha
        end
        if healAbsorbAlpha == nil then
            healAbsorbAlpha = DEFAULT_SETTINGS.healAbsorbAlpha
        end
        if incomingHealAlpha == nil then
            incomingHealAlpha = DEFAULT_SETTINGS.incomingHealAlpha
        end

        applyColor(self, settings)
        self.absorbBar:SetStatusBarTexture(BFUF.Media:GetTexture(absorbTexture))
        self.healAbsorbBar:SetStatusBarTexture(BFUF.Media:GetTexture(healAbsorbTexture))
        self.incomingHealBar:SetStatusBarTexture(BFUF.Media:GetTexture(incomingHealTexture))
        self.absorbBar:SetStatusBarColor(
            absorbColor.r,
            absorbColor.g,
            absorbColor.b,
            absorbAlpha
        )
        self.healAbsorbBar:SetStatusBarColor(
            healAbsorbColor.r,
            healAbsorbColor.g,
            healAbsorbColor.b,
            healAbsorbAlpha
        )
        self.absorbBar:SetReverseFill(absorbPosition == "right")
        self.healAbsorbBar:SetReverseFill(healAbsorbPosition == "right")
        self.incomingHealBar:SetStatusBarColor(
            incomingHealColor.r,
            incomingHealColor.g,
            incomingHealColor.b,
            incomingHealAlpha
        )
        self.incomingHealBar:SetReverseFill(incomingHealPosition == "right")
        self:UpdateOverlays(settings)
    end

    function statusBar:UpdateOverlays(settings)
        settings = settings or getSettings(self)
        local unit = self.unit

        if not unit then
            return
        end

        -- Unit values can be secret while the addon is tainted. Pass them only
        -- to Blizzard status-bar APIs and never use them in Lua control flow.
        local maxHealth = UnitHealthMax(unit)
        self.absorbBar:SetShown(settings.showAbsorb)
        self.healAbsorbBar:SetShown(settings.showHealAbsorb)
        self.incomingHealBar:SetShown(INCOMING_HEALS_ENABLED and settings.incomingHeal)
        self.absorbBar:SetMinMaxValues(0, maxHealth)
        self.healAbsorbBar:SetMinMaxValues(0, maxHealth)
        self.incomingHealBar:SetMinMaxValues(0, maxHealth)
        self.absorbBar:SetValue(UnitGetTotalAbsorbs(unit))
        self.healAbsorbBar:SetValue(UnitGetTotalHealAbsorbs(unit))

        if INCOMING_HEALS_ENABLED and settings.incomingHeal then
            -- Deferred path: retain the Blizzard-compatible nil handling for
            -- the future prediction-segment renderer.
            self.incomingHealBar:SetValue(UnitGetIncomingHeals(unit) or 0)
        else
            -- Do not read the API while the feature is deferred. Existing
            -- profile values remain stored but cannot enable rendering.
            self.incomingHealBar:SetValue(0)
        end
    end

    function statusBar:Update()
        local unit = self.unit
        if not unit then
            return
        end

        -- Keep secret health values inside Blizzard API calls. In particular,
        -- do not compare, coerce, or substitute the values in addon Lua.
        self:SetMinMaxValues(0, UnitHealthMax(unit))
        self:SetValue(UnitHealth(unit))
        self:UpdateStyle()
    end

    -- Health has no independent visibility setting today. Keep this lifecycle
    -- method for frame-owned visibility without introducing new behavior.
    function statusBar:SetVisible(visible)
        self:SetShown(visible ~= false)
    end

    function statusBar:Destroy()
        self.absorbBar:Hide()
        self.healAbsorbBar:Hide()
        self.incomingHealBar:Hide()
        self:Hide()
        self.context = nil
        self.settings = nil
        self.unit = nil
        self.colorResolver = nil
    end

    return statusBar
end

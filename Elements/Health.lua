local addonName, BFUF = ...

BFUF.Elements = BFUF.Elements or {}

local Health = {}
BFUF.Elements.Health = Health

local function applyColor(statusBar)
    local settings = BFUF.DB:Get("Player").health
    local color = settings.customColor

    if settings.colorMode == "class" then
        local _, class = UnitClass(statusBar.unit or "player")
        color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class] or RAID_CLASS_COLORS.PRIEST
    end

    statusBar:SetStatusBarColor(color.r, color.g, color.b)
end

-- Create the health bar and its independent absorb overlays.
function Health:Create(parent)
    local statusBar = CreateFrame("StatusBar", nil, parent)
    statusBar:SetStatusBarTexture("Interface\TargetingFrame\UI-StatusBar")

    local absorbBar = CreateFrame("StatusBar", nil, statusBar)
    absorbBar:SetAllPoints(statusBar)
    absorbBar:SetStatusBarTexture("Interface\TargetingFrame\UI-StatusBar")
    absorbBar:SetStatusBarColor(0.8, 0.8, 1, 0.65)
    statusBar.absorbBar = absorbBar

    local healAbsorbBar = CreateFrame("StatusBar", nil, statusBar)
    healAbsorbBar:SetAllPoints(statusBar)
    healAbsorbBar:SetStatusBarTexture("Interface\TargetingFrame\UI-StatusBar")
    healAbsorbBar:SetStatusBarColor(0.85, 0.15, 0.15, 0.65)
    statusBar.healAbsorbBar = healAbsorbBar

    function statusBar:SetUnit(unit)
        self.unit = unit
    end

    function statusBar:UpdateStyle()
        applyColor(self)
        self:UpdateOverlays()
    end

    function statusBar:UpdateOverlays()
        local settings = BFUF.DB:Get("Player").health
        local unit = self.unit

        if not unit then
            return
        end

        local maxHealth = UnitHealthMax(unit)
        if not maxHealth or maxHealth == 0 then
            return
        end

        self.absorbBar:SetShown(settings.showAbsorb)
        self.healAbsorbBar:SetShown(settings.showHealAbsorb)
        self.absorbBar:SetMinMaxValues(0, maxHealth)
        self.healAbsorbBar:SetMinMaxValues(0, maxHealth)
        self.absorbBar:SetValue(UnitGetTotalAbsorbs(unit) or 0)
        self.healAbsorbBar:SetValue(UnitGetTotalHealAbsorbs(unit) or 0)
    end

    function statusBar:Update()
        local unit = self.unit
        if not unit then
            return
        end

        local health = UnitHealth(unit)
        local maxHealth = UnitHealthMax(unit)
        if not maxHealth or maxHealth == 0 then
            return
        end

        self:SetMinMaxValues(0, maxHealth)
        self:SetValue(health or 0)
        self:UpdateStyle()
    end

    return statusBar
end

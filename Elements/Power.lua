local addonName, BFUF = ...

BFUF.Elements = BFUF.Elements or {}

local Power = {}
BFUF.Elements.Power = Power

local supportedPowerTypes = {
    MANA = true, RAGE = true, ENERGY = true, FOCUS = true, RUNIC_POWER = true,
    MAELSTROM = true, INSANITY = true, ESSENCE = true, FURY = true, LUNAR_POWER = true,
}

local function applyColor(statusBar, powerType, powerToken)
    local settings = BFUF.DB:Get("Player").power
    local color = settings.customColor

    if settings.colorMode == "resource" then
        color = PowerBarColor and (PowerBarColor[powerToken] or PowerBarColor[powerType])
    end

    color = color or { r = 1, g = 1, b = 1 }
    statusBar:SetStatusBarColor(color.r, color.g, color.b)
end

function Power:Create(parent)
    local statusBar = CreateFrame("StatusBar", nil, parent)
    statusBar:SetStatusBarTexture("Interface\TargetingFrame\UI-StatusBar")

    function statusBar:SetUnit(unit)
        self.unit = unit
    end

    function statusBar:UpdateStyle()
        if not self.unit then
            return
        end

        local powerType, powerToken = UnitPowerType(self.unit)
        applyColor(self, powerType, powerToken)
    end

    function statusBar:Update()
        local unit = self.unit
        if not unit then
            return
        end

        local powerType, powerToken = UnitPowerType(unit)
        if not supportedPowerTypes[powerToken] then
            return
        end

        local power = UnitPower(unit, powerType)
        local maxPower = UnitPowerMax(unit, powerType)
        if not maxPower or maxPower == 0 then
            return
        end

        self:SetMinMaxValues(0, maxPower)
        self:SetValue(power or 0)
        applyColor(self, powerType, powerToken)
    end

    return statusBar
end

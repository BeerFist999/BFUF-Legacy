local addonName, BFUF = ...

-- Модуль создаёт и обновляет StatusBar для основного ресурса юнита.
-- Размер и положение полосы задаются внешним Layout-слоем.
BFUF.Elements = BFUF.Elements or {}

local Power = {}
BFUF.Elements.Power = Power

-- Поддерживаемые типы основного ресурса.
local supportedPowerTypes = {
    MANA = true,
    RAGE = true,
    ENERGY = true,
    FOCUS = true,
    RUNIC_POWER = true,
}

-- Создаёт базовый StatusBar без собственного размера и позиционирования.
function Power:Create(parent)
    local statusBar = CreateFrame("StatusBar", nil, parent)
    statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")

    -- Сохраняет игровой юнит, ресурс которого отображает полоса.
    function statusBar:SetUnit(unit)
        self.unit = unit
    end

    -- Обновляет значение и стандартный цвет Blizzard для текущего ресурса.
    function statusBar:Update()
        local unit = self.unit

        if not unit then
            return
        end

        local powerType, powerToken = UnitPowerType(unit)

        -- Не отображаем ресурсы, которые ещё не входят в базовую поддержку.
        if not supportedPowerTypes[powerToken] then
            return
        end

        local power = UnitPower(unit, powerType)
        local maxPower = UnitPowerMax(unit, powerType)

        if not maxPower or maxPower == 0 then
            return
        end

        -- PowerBarColor — штатная таблица цветов Blizzard.
        local color = PowerBarColor and (PowerBarColor[powerToken] or PowerBarColor[powerType])

        if color then
            self:SetStatusBarColor(color.r, color.g, color.b)
        end

        self:SetMinMaxValues(0, maxPower)
        self:SetValue(power or 0)
    end

    return statusBar
end

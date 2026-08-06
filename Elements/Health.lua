local addonName, BFUF = ...

-- Модуль создаёт элемент здоровья и предоставляет ручное обновление его значений.
BFUF.Elements = BFUF.Elements or {}

local Health = {}
BFUF.Elements.Health = Health

-- Создаёт StatusBar, полностью занимающий область родительского фрейма.
function Health:Create(parent)
    -- Используем штатный тип фрейма Blizzard и переданного родителя.
    local statusBar = CreateFrame("StatusBar", nil, parent)

    -- Стандартная текстура Blizzard для полос состояния.
    statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")

    -- Четыре точки привязки обеспечивают ширину и высоту, равные родителю.
    statusBar:SetAllPoints(parent)

    -- Сохраняет игровой юнит, для которого будет отображаться здоровье.
    function statusBar:SetUnit(unit)
        self.unit = unit
    end

    -- Обновляет значения полосы без регистрации игровых событий.
    function statusBar:Update()
        local unit = self.unit

        -- Без юнита нельзя безопасно запрашивать состояние здоровья.
        if not unit then
            return
        end

        local health = UnitHealth(unit)
        local maxHealth = UnitHealthMax(unit)

        -- Нулевой максимум не позволяет корректно настроить диапазон StatusBar.
        if not maxHealth or maxHealth == 0 then
            return
        end

        self:SetMinMaxValues(0, maxHealth)
        self:SetValue(health or 0)
    end

    return statusBar
end

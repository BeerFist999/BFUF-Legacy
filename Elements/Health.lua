local addonName, BFUF = ...

-- Модуль создаёт базовый визуальный элемент здоровья без игровой логики.
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

    return statusBar
end

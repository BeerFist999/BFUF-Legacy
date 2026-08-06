local addonName, BFUF = ...

-- Factory создаёт базовые объекты интерфейса через штатный Blizzard API.
-- Модуль не регистрирует объекты, не применяет Layout и не создаёт игровые элементы.
BFUF.Framework = BFUF.Framework or {}

local Factory = {}
BFUF.Framework.Factory = Factory

-- Создаёт защищённый базовый Unit Frame для указанного юнита.
-- Фрейм не получает визуальные элементы и используется только как основа для дальнейшей сборки.
function Factory:CreateUnitFrame(unit)
    local frame = CreateFrame("Button", nil, UIParent, "SecureUnitButtonTemplate")

    -- Атрибут unit нужен защищённому шаблону Blizzard для связи с игровым юнитом.
    frame:SetAttribute("unit", unit)
    frame.unit = unit

    return frame
end

-- Создаёт пустой контейнер с указанным родительским объектом.
function Factory:CreateContainer(parent)
    return CreateFrame("Frame", nil, parent)
end

-- Создаёт текстуру, принадлежащую переданному фрейму или контейнеру.
function Factory:CreateTexture(parent)
    return parent:CreateTexture(nil, "ARTWORK")
end

-- Создаёт текстовую строку, принадлежащую переданному фрейму или контейнеру.
function Factory:CreateFontString(parent)
    return parent:CreateFontString(nil, "OVERLAY")
end

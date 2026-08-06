local addonName, BFUF = ...

-- Factory создаёт базовые объекты интерфейса через штатный Blizzard API.
-- Модуль не регистрирует объекты, не применяет Layout и не создаёт игровые элементы.
BFUF.Framework = BFUF.Framework or {}

local Factory = {}
BFUF.Framework.Factory = Factory

-- Создаёт пустой фрейм для указанного юнита.
-- Параметр unit зарезервирован для будущей привязки к Unit Frame и пока не используется.
function Factory:CreateUnitFrame(unit)
    return CreateFrame("Frame", nil, UIParent)
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

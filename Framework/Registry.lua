local addonName, BFUF = ...

-- Registry хранит ссылки на зарегистрированные объекты Framework.
-- Таблицы локальны для модуля и не создают игровых объектов.
BFUF.Framework = BFUF.Framework or {}

local Registry = {}
BFUF.Framework.Registry = Registry

-- Внутренние хранилища для разных типов объектов.
local frames = {}
local elements = {}
local layouts = {}

-- Выводит отладочное предупреждение, если публичный метод Debug уже доступен.
local function warnDuplicate(objectType, name)
    if BFUF.Debug then
        BFUF:Debug("BFUF Registry: " .. objectType .. " '" .. tostring(name) .. "' уже зарегистрирован.")
    end
end

-- Регистрирует фрейм под уникальным именем.
function Registry:RegisterFrame(name, frame)
    if frames[name] ~= nil then
        warnDuplicate("Frame", name)
        return false
    end

    frames[name] = frame

    return true
end

-- Возвращает ранее зарегистрированный фрейм или nil, если он отсутствует.
function Registry:GetFrame(name)
    return frames[name]
end

-- Регистрирует элемент под уникальным именем.
function Registry:RegisterElement(name, element)
    if elements[name] ~= nil then
        warnDuplicate("Element", name)
        return false
    end

    elements[name] = element

    return true
end

-- Возвращает ранее зарегистрированный элемент или nil, если он отсутствует.
function Registry:GetElement(name)
    return elements[name]
end

-- Регистрирует Layout под уникальным именем.
function Registry:RegisterLayout(name, layout)
    if layouts[name] ~= nil then
        warnDuplicate("Layout", name)
        return false
    end

    layouts[name] = layout

    return true
end

-- Возвращает ранее зарегистрированный Layout или nil, если он отсутствует.
function Registry:GetLayout(name)
    return layouts[name]
end

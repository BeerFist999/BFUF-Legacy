local addonName, BFUF = ...

-- Публичный API предоставляет единые точки расширения для будущих модулей аддона.

-- В будущем зарегистрирует модуль по указанному имени.
function BFUF:RegisterModule(name, module)
end

-- В будущем зарегистрирует unit frame по указанному имени.
function BFUF:RegisterFrame(name, frame)
end

-- В будущем зарегистрирует визуальный элемент по указанному имени.
function BFUF:RegisterElement(name, element)
end

-- В будущем вернёт таблицу настроек по умолчанию.
function BFUF:GetDefaults()
    return BFUF.Defaults
end

-- В будущем вернёт активную конфигурацию указанного раздела.
function BFUF:GetConfig(section)
    return nil
end

-- В будущем выведет обычное сообщение аддона.
function BFUF:Print(...)
end

-- В будущем выведет отладочное сообщение аддона.
function BFUF:Debug(...)
end

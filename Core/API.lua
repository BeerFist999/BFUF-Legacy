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

-- Выводит сообщение в стандартное окно чата, если оно доступно.
function BFUF:Print(...)
    local message = ...

    if message ~= nil and DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(tostring(message))
    end
end

-- Выводит отладочное сообщение только при включённом режиме отладки.
function BFUF:Debug(...)
    if not self.DebugEnabled then
        return
    end

    self:Print(...)
end

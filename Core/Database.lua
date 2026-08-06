local addonName, BFUF = ...

-- Модуль хранит рабочую копию настроек в локальной таблице.
-- SavedVariables и профили будут подключены позже, поэтому глобальные данные не используются.
local Database = BFUF.DB
local configuration = {}

-- Рекурсивно дополняет таблицу назначения отсутствующими значениями из таблицы по умолчанию.
-- Уже заданные значения не заменяются, что позволит сохранить пользовательские настройки в будущем.
function Database:CopyDefaults(source, destination)
    destination = destination or {}

    -- Нетабличный источник не требует копирования.
    if type(source) ~= "table" then
        return destination
    end

    for key, value in pairs(source) do
        if type(value) == "table" then
            -- Для вложенного раздела всегда создаётся отдельная таблица.
            if type(destination[key]) ~= "table" then
                destination[key] = {}
            end

            self:CopyDefaults(value, destination[key])
        elseif destination[key] == nil then
            -- Простое значение добавляется, только если оно отсутствует.
            destination[key] = value
        end
    end

    return destination
end

-- Создаёт рабочую конфигурацию на основе значений BFUF.Defaults.
function Database:Initialize()
    configuration = self:CopyDefaults(BFUF.Defaults or {}, {})

    return configuration
end

-- Возвращает всю конфигурацию или указанный раздел настроек.
function Database:Get(section)
    if section == nil then
        return configuration
    end

    return configuration[section]
end

-- Восстанавливает рабочую конфигурацию из исходных значений по умолчанию.
function Database:Reset()
    configuration = self:CopyDefaults(BFUF.Defaults or {}, {})

    return configuration
end

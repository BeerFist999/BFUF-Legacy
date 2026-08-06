local addonName, BFUF = ...

-- Создаём базовые пространства имён аддона до загрузки остальных модулей.
BFUF.Core = BFUF.Core or {}
BFUF.DB = BFUF.DB or {}
BFUF.Frames = BFUF.Frames or {}
BFUF.Elements = BFUF.Elements or {}
BFUF.Options = BFUF.Options or {}
BFUF.Utils = BFUF.Utils or {}

-- Режим отладки выключен по умолчанию и может быть включён позже.
BFUF.DebugEnabled = BFUF.DebugEnabled or false

-- Основной фрейм принимает события, необходимые для инициализации аддона.
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(_, event, loadedAddonName)
    -- Инициализируем только этот аддон после его загрузки.
    if event == "ADDON_LOADED" and loadedAddonName == "BFUF-Legacy" then
        BFUF:Initialize()
    end
end)

-- Выполняет минимальную последовательность загрузки подсистем аддона.
function BFUF:Initialize()
    -- Подготавливаем статические значения по умолчанию.
    BFUF.Core.Defaults:Initialize()
    BFUF:Debug("BFUF-Legacy: Defaults initialized.")

    -- Создаём рабочую копию конфигурации.
    BFUF.DB:Initialize()
    BFUF:Debug("BFUF-Legacy: Database initialized.")

    -- Передаём управление следующему этапу загрузки.
    BFUF.Core.Bootstrap:Initialize()
    BFUF:Debug("BFUF-Legacy: Bootstrap initialized.")

    -- Сообщаем об успешном завершении минимальной загрузки.
    BFUF:Print("BFUF-Legacy Alpha 0.0.1 loaded.")
end

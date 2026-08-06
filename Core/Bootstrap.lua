local addonName, BFUF = ...

-- Модуль завершает минимальную инициализацию и запускает первый тестовый фрейм.
local Bootstrap = {}
BFUF.Core.Bootstrap = Bootstrap

-- Создаёт базовый фрейм игрока после подготовки Defaults и Database.
function Bootstrap:Initialize()
    -- Framework уже загружен через TOC; сообщения видны только при включённом Debug.
    BFUF:Debug("Factory initialized")
    BFUF:Debug("Registry initialized")

    local playerFrame = BFUF.Frames.Player:Create()

    -- Сообщаем о результате только после успешного получения фрейма.
    if playerFrame then
        BFUF:Debug("Player Frame created")
        BFUF:Print("Player Frame created.")
    end

    -- Загрузить локализацию.
    -- Зарегистрировать события.
    -- Инициализировать остальные модули.
end

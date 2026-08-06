local addonName, BFUF = ...

-- Модуль завершает минимальную инициализацию и запускает первый тестовый фрейм.
local Bootstrap = {}
BFUF.Core.Bootstrap = Bootstrap

-- Создаёт базовый фрейм игрока после подготовки Defaults и Database.
function Bootstrap:Initialize()
    BFUF.Frames.Player:Create()

    -- Загрузить локализацию.
    -- Зарегистрировать события.
    -- Инициализировать остальные модули.
end

local addonName, BFUF = ...

-- Таблица содержит только стартовые значения настроек аддона.
-- Сохранение и применение этих значений будут реализованы в отдельных модулях.
BFUF.Defaults = {
    -- Общие параметры, применяемые ко всему аддону.
    General = {
        enabled = true, -- Аддон включён по умолчанию.
        width = 200, -- Базовая ширина фреймов.
        height = 40, -- Базовая высота фреймов.
        scale = 1, -- Стандартный масштаб интерфейса.
        show = true, -- Разрешено отображение элементов.
    },

    -- Параметры фрейма игрока.
    Player = {
        enabled = true,
        width = 200,
        height = 40,
        scale = 1,
        show = true,
    },

    -- Параметры фрейма текущей цели.
    Target = {
        enabled = true,
        width = 200,
        height = 40,
        scale = 1,
        show = true,
    },

    -- Параметры фрейма цели текущей цели.
    TargetTarget = {
        enabled = true,
        width = 160,
        height = 32,
        scale = 1,
        show = true,
    },

    -- Параметры фреймов боссов.
    Boss = {
        enabled = true,
        width = 180,
        height = 36,
        scale = 1,
        show = true,
    },

    -- Параметры отображения аур.
    Auras = {
        enabled = true,
        width = 24,
        height = 24,
        scale = 1,
        show = true,
    },

    -- Параметры полосы применения заклинаний.
    Castbar = {
        enabled = true,
        width = 200,
        height = 18,
        scale = 1,
        show = true,
    },

    -- Параметры портрета.
    Portrait = {
        enabled = true,
        width = 40,
        height = 40,
        scale = 1,
        show = true,
    },

    -- Параметры текстовых элементов.
    Text = {
        enabled = true,
        width = 120,
        height = 14,
        scale = 1,
        show = true,
    },
}

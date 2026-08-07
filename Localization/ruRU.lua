local addonName, BFUF = ...

BFUF.Localization:RegisterLocale("ruRU", {
    ADDON_NAME = "BFUF",

    CATEGORY_GENERAL = "Общие",
    CATEGORY_PLAYER = "Игрок",
    CATEGORY_INDICATORS = "Индикаторы",
    CATEGORY_PROFILES = "Профили",
    CATEGORY_ABOUT = "О дополнении",

    DESCRIPTION_GENERAL = "Основные настройки BFUF будут добавлены позже.",
    DESCRIPTION_PLAYER = "Настройки рамки игрока будут добавлены позже.",
    DESCRIPTION_INDICATORS = "Настройки индикаторов статуса будут добавлены позже.",
    DESCRIPTION_PROFILES = "Управление профилями будет добавлено позже.",
    DESCRIPTION_ABOUT = "BFUF — настраиваемые рамки юнитов для World of Warcraft.",

    OPTION_ENABLE_BFUF = "Включить BFUF",
    OPTION_REPLACE_BLIZZARD_UNIT_FRAMES = "Заменять стандартные рамки Blizzard",
    OPTION_ENABLE_DEBUG_MODE = "Включить режим отладки",
    OPTION_SHOW_PORTRAIT = "Показывать портрет",
    SECTION_LAYOUT = "Расположение",
    OPTION_FRAME_WIDTH = "Ширина рамки",
    OPTION_FRAME_HEIGHT = "Высота рамки",
    OPTION_FRAME_SCALE = "Масштаб рамки",
    OPTION_POSITION_X = "Позиция по X",
    OPTION_POSITION_Y = "Позиция по Y",
    BUTTON_RESET_LAYOUT = "Сбросить расположение",
})

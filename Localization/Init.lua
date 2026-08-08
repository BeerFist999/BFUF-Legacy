local addonName, BFUF = ...

local Localization = {
    locales = {},
}

BFUF.Localization = Localization

-- Register a locale table before localization initialization.
function Localization:RegisterLocale(locale, strings)
    self.locales[locale] = strings
end

-- Use Russian when available and fall back to English for missing entries.
-- BFUF.L is created once and refreshed in place so TOC-loaded settings
-- definitions and runtime UI always use the same shared localization table.
BFUF.L = BFUF.L or {}

function Localization:Initialize()
    local fallback = self.locales.enUS or {}
    local selected = self.locales[GetLocale()] or self.locales.ruRU or fallback
    local strings = BFUF.L

    for key in pairs(strings) do
        strings[key] = nil
    end

    setmetatable(strings, {
        __index = fallback,
    })

    for key, value in pairs(selected) do
        strings[key] = value
    end

    return strings
end

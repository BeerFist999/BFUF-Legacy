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
function Localization:Initialize()
    local fallback = self.locales.enUS or {}
    local selected = self.locales[GetLocale()] or self.locales.ruRU or fallback

    BFUF.L = setmetatable({}, {
        __index = fallback,
    })

    for key, value in pairs(selected) do
        BFUF.L[key] = value
    end

    return BFUF.L
end

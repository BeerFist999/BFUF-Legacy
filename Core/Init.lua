local addonName, BFUF = ...

-- Создаём базовые пространства имён аддона до загрузки остальных модулей.
BFUF.Core = BFUF.Core or {}
BFUF.DB = BFUF.DB or {}
BFUF.Frames = BFUF.Frames or {}
BFUF.Elements = BFUF.Elements or {}
BFUF.Options = BFUF.Options or {}
BFUF.Utils = BFUF.Utils or {}

-- Основной фрейм принимает события, необходимые для инициализации аддона.
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(_, event, loadedAddonName)
    -- Инициализируем только этот аддон после его загрузки.
    if event == "ADDON_LOADED" and loadedAddonName == "BFUF-Legacy" then
        BFUF:Initialize()
    end
end)

-- Точка входа аддона. Реализация будет добавлена позже.
function BFUF:Initialize()
end

local addonName, BFUF = ...

-- Модуль создаёт базовый защищённый фрейм игрока с элементом здоровья.
BFUF.Frames = BFUF.Frames or {}

local Player = {}
BFUF.Frames.Player = Player

-- Создаёт и регистрирует временный Unit Frame игрока для проверки Alpha-сборки.
function Player:Create()
    local registry = BFUF.Framework.Registry
    local factory = BFUF.Framework.Factory
    local existingFrame = registry:GetFrame("player")

    -- Не создаём второй фрейм, если игрок уже был зарегистрирован.
    if existingFrame then
        return existingFrame
    end

    -- Factory отвечает за создание защищённого базового фрейма.
    local frame = factory:CreateUnitFrame("player")

    -- Временные размеры и положение используются только для тестирования Alpha.
    frame:SetSize(220, 40)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    -- Контейнер занимает весь фрейм и служит родителем для будущих элементов.
    local container = factory:CreateContainer(frame)
    container:SetAllPoints(frame)

    -- Создаём базовый элемент здоровья внутри контейнера.
    local health = BFUF.Elements.Health:Create(container)
    health:ClearAllPoints()
    health:SetPoint("TOPLEFT", container, "TOPLEFT")
    health:SetPoint("TOPRIGHT", container, "TOPRIGHT")
    health:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT")
    health:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT")
    BFUF:Debug("Health element attached.")

    -- Привязываем элемент к игроку и выполняем первое обновление без игровых событий.
    health:SetUnit("player")
    BFUF:Debug("Health initialized")
    health:Update()
    BFUF:Debug("Health updated")

    -- После входа в мир один раз повторяем обновление доступных значений здоровья.
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_ENTERING_WORLD" then
            health:Update()
            BFUF:Debug("Health updated")
            self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        end
    end)

    -- Registry хранит ссылку на готовый фрейм под именем player.
    if registry:RegisterFrame("player", frame) then
        return frame
    end

    -- Возвращаем уже зарегистрированный объект, если он появился до регистрации.
    return registry:GetFrame("player")
end

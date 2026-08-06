local addonName, BFUF = ...

-- Модуль создаёт только базовый защищённый фрейм игрока без визуальных элементов.
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

    -- Registry хранит ссылку на готовый фрейм под именем player.
    if registry:RegisterFrame("player", frame) then
        return frame
    end

    -- Возвращаем уже зарегистрированный объект, если он появился до регистрации.
    return registry:GetFrame("player")
end

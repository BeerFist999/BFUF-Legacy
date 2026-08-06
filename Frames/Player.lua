local addonName, BFUF = ...

-- Размеры и отступы базового фрейма игрока.
local FRAME_WIDTH = 240
local FRAME_HEIGHT = 50
local FRAME_OFFSET_X = 0
local FRAME_OFFSET_Y = 0
local HEALTH_BAR_INSET = 3

-- Модуль создаёт базовый защищённый фрейм игрока с фоном и полосой здоровья.
BFUF.Frames = BFUF.Frames or {}

local Player = {}
BFUF.Frames.Player = Player

-- Создаёт и регистрирует основной Unit Frame игрока.
function Player:Create()
    local registry = BFUF.Framework.Registry
    local factory = BFUF.Framework.Factory
    local existingFrame = registry:GetFrame("player")

    -- Не создаём второй фрейм, если игрок уже был зарегистрирован.
    if existingFrame then
        return existingFrame
    end

    -- Один главный защищённый фрейм служит родителем для всех будущих частей Player Frame.
    local frame = factory:CreateUnitFrame("player")
    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", FRAME_OFFSET_X, FRAME_OFFSET_Y)

    -- Background занимает всю область главного фрейма.
    local background = factory:CreateTexture(frame)
    background:SetAllPoints(frame)
    background:SetColorTexture(0, 0, 0, 0.8)
    frame.background = background

    -- HealthBar создаётся непосредственно внутри главного фрейма.
    local healthBar = BFUF.Elements.Health:Create(frame)
    healthBar:ClearAllPoints()
    healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", HEALTH_BAR_INSET, -HEALTH_BAR_INSET)
    healthBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -HEALTH_BAR_INSET, -HEALTH_BAR_INSET)
    healthBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", HEALTH_BAR_INSET, HEALTH_BAR_INSET)
    healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -HEALTH_BAR_INSET, HEALTH_BAR_INSET)
    frame.healthBar = healthBar
    BFUF:Debug("Health element attached.")

    -- Привязываем HealthBar к игроку и выполняем первое обновление.
    healthBar:SetUnit("player")
    BFUF:Debug("Health initialized")
    healthBar:Update()
    BFUF:Debug("Health updated")

    -- Подписываемся только на события, необходимые для обновления здоровья игрока.
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("UNIT_HEALTH")
    frame:RegisterEvent("UNIT_MAXHEALTH")
    frame:SetScript("OnEvent", function(self, event, unit)
        -- После входа в мир повторяем обновление и отключаем одноразовое событие.
        if event == "PLAYER_ENTERING_WORLD" then
            healthBar:Update()
            BFUF:Debug("Health updated")
            self:UnregisterEvent("PLAYER_ENTERING_WORLD")
            return
        end

        -- UNIT_HEALTH и UNIT_MAXHEALTH содержат юнит первым дополнительным аргументом.
        if unit ~= "player" then
            return
        end

        healthBar:Update()
        BFUF:Debug("Health updated from event.")
    end)

    -- Registry хранит ссылку на готовый фрейм под именем player.
    if registry:RegisterFrame("player", frame) then
        return frame
    end

    -- Возвращаем уже зарегистрированный объект, если он появился до регистрации.
    return registry:GetFrame("player")
end

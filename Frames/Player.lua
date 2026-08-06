local addonName, BFUF = ...

-- Временный Layout базового фрейма игрока.
-- Все размеры элементов хранятся здесь до появления LayoutEngine.
local PLAYER_LAYOUT = {
    frame = {
        width = 240,
        height = 50,
        offsetX = 0,
        offsetY = 0,
    },
    portrait = {
        width = 44,
        inset = 3,
    },
    health = {
        inset = 3,
        bottomOffset = 13,
    },
    power = {
        height = 8,
        inset = 3,
    },
    text = {
        inset = 4,
        size = 12,
        color = { r = 1, g = 1, b = 1, a = 1 },
    },
}

-- Модуль создаёт базовый защищённый фрейм игрока с фоном и полосами ресурсов.
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
    frame:SetSize(PLAYER_LAYOUT.frame.width, PLAYER_LAYOUT.frame.height)
    frame:SetPoint("CENTER", UIParent, "CENTER", PLAYER_LAYOUT.frame.offsetX, PLAYER_LAYOUT.frame.offsetY)

    -- Background занимает всю область главного фрейма.
    local background = factory:CreateTexture(frame)
    background:SetAllPoints(frame)
    background:SetColorTexture(0, 0, 0, 0.8)
    frame.background = background

    -- Portrait располагается слева и использует 2D-вариант до реализации PlayerModel.
    local portrait = BFUF.Elements.Portrait:Create(frame, BFUF.Elements.Portrait.Types.TEXTURE)
    portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", PLAYER_LAYOUT.portrait.inset, -PLAYER_LAYOUT.portrait.inset)
    portrait:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PLAYER_LAYOUT.portrait.inset, PLAYER_LAYOUT.portrait.inset)
    portrait:SetWidth(PLAYER_LAYOUT.portrait.width)
    frame.portrait = portrait

    -- Смещение полос рассчитывается из размера портрета, заданного Layout.
    local contentLeftOffset = PLAYER_LAYOUT.portrait.inset + PLAYER_LAYOUT.portrait.width + PLAYER_LAYOUT.health.inset

    -- HealthBar занимает верхнюю часть фрейма и оставляет место для PowerBar.
    local healthBar = BFUF.Elements.Health:Create(frame)
    healthBar:ClearAllPoints()
    healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", contentLeftOffset, -PLAYER_LAYOUT.health.inset)
    healthBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PLAYER_LAYOUT.health.inset, -PLAYER_LAYOUT.health.inset)
    healthBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", contentLeftOffset, PLAYER_LAYOUT.health.bottomOffset)
    healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PLAYER_LAYOUT.health.inset, PLAYER_LAYOUT.health.bottomOffset)
    frame.healthBar = healthBar
    BFUF:Debug("Health element attached.")

    -- PowerBar создаётся без собственных размеров; их задаёт временный Layout Player Frame.
    local powerBar = BFUF.Elements.Power:Create(frame)
    powerBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", contentLeftOffset, PLAYER_LAYOUT.power.inset)
    powerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PLAYER_LAYOUT.power.inset, PLAYER_LAYOUT.power.inset)
    powerBar:SetHeight(PLAYER_LAYOUT.power.height)
    frame.powerBar = powerBar

    -- Text Element в Player Frame пока используется только для имени игрока.
    local nameText = BFUF.Elements.Text:Create(healthBar, {
        font = STANDARD_TEXT_FONT,
        size = PLAYER_LAYOUT.text.size,
        color = PLAYER_LAYOUT.text.color,
        justifyH = "LEFT",
        justifyV = "MIDDLE",
    })
    nameText:SetPoint("TOPLEFT", healthBar, "TOPLEFT", PLAYER_LAYOUT.text.inset, 0)
    nameText:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", -PLAYER_LAYOUT.text.inset, 0)
    nameText:SetText(UnitName("player") or "")
    frame.nameText = nameText

    -- Привязываем элементы к игроку и выполняем первое обновление.
    portrait:SetUnit("player")
    portrait:Update()

    healthBar:SetUnit("player")
    healthBar:Update()
    BFUF:Debug("Health updated")

    powerBar:SetUnit("player")
    powerBar:Update()

    -- Подписываемся только на события, необходимые для обновления ресурсов и модели игрока.
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("UNIT_HEALTH")
    frame:RegisterEvent("UNIT_MAXHEALTH")
    frame:RegisterEvent("UNIT_POWER_UPDATE")
    frame:RegisterEvent("UNIT_DISPLAYPOWER")
    frame:RegisterEvent("UNIT_MODEL_CHANGED")
    frame:SetScript("OnEvent", function(self, event, unit)
        -- После входа в мир повторяем обновление всех элементов.
        if event == "PLAYER_ENTERING_WORLD" then
            portrait:Update()
            healthBar:Update()
            powerBar:Update()
            nameText:SetText(UnitName("player") or "")
            self:UnregisterEvent("PLAYER_ENTERING_WORLD")
            return
        end

        -- События других юнитов не относятся к Player Frame.
        if unit ~= "player" then
            return
        end

        if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
            healthBar:Update()
            BFUF:Debug("Health updated from event.")
        elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_DISPLAYPOWER" then
            powerBar:Update()
        elseif event == "UNIT_MODEL_CHANGED" then
            portrait:Update()
        end
    end)

    -- Registry хранит ссылку на готовый фрейм под именем player.
    if registry:RegisterFrame("player", frame) then
        return frame
    end

    -- Возвращаем уже зарегистрированный объект, если он появился до регистрации.
    return registry:GetFrame("player")
end

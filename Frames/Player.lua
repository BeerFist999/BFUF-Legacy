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
    healthText = {
        inset = 4,
        size = 12,
        color = { r = 1, g = 1, b = 1, a = 1 },
    },
    powerText = {
        inset = 4,
        size = 12,
        color = { r = 1, g = 1, b = 1, a = 1 },
    },
}

-- Форматы текста здоровья подготовлены для будущей настройки без изменения логики обновления.
local HEALTH_TEXT_FORMATS = {
    CURRENT = "current",
    CURRENT_MAX = "currentMax",
    PERCENT = "percent",
    CURRENT_PERCENT = "currentPercent",
    CURRENT_MAX_PERCENT = "currentMaxPercent",
}

local HEALTH_TEXT_FORMAT = HEALTH_TEXT_FORMATS.CURRENT_MAX_PERCENT

-- Форматирует значения здоровья или ресурса без арифметики Lua.
-- В Retail 12 UnitHealth* и UnitPower* могут возвращать Secret Values:
-- аддон не имеет права сравнивать, преобразовывать или вычислять их самостоятельно.
-- Процент заранее рассчитывается нативным API Blizzard, а string.format принимает
-- Secret Values и возвращает строку, которую FontString может безопасно отобразить.
local function formatStatusText(currentValue, maxValue, percentValue, displayFormat, formats)
    if displayFormat == formats.CURRENT then
        return string.format("%d", currentValue)
    elseif displayFormat == formats.CURRENT_MAX then
        return string.format("%d / %d", currentValue, maxValue)
    elseif displayFormat == formats.PERCENT then
        return string.format("%d%%", percentValue)
    elseif displayFormat == formats.CURRENT_PERCENT then
        return string.format("%d (%d%%)", currentValue, percentValue)
    end

    return string.format("%d / %d (%d%%)", currentValue, maxValue, percentValue)
end

-- Форматы текста ресурса подготовлены для будущей настройки без изменения логики обновления.
local POWER_TEXT_FORMATS = {
    CURRENT = "current",
    CURRENT_MAX = "currentMax",
    PERCENT = "percent",
    CURRENT_PERCENT = "currentPercent",
    CURRENT_MAX_PERCENT = "currentMaxPercent",
}

local POWER_TEXT_FORMAT = POWER_TEXT_FORMATS.CURRENT_MAX_PERCENT

-- Поддерживаемые типы ресурсов для текстового отображения.
local SUPPORTED_POWER_TYPES = {
    MANA = true,
    RAGE = true,
    ENERGY = true,
    FOCUS = true,
    RUNIC_POWER = true,
    MAELSTROM = true,
    INSANITY = true,
    ESSENCE = true,
    FURY = true,
    LUNAR_POWER = true,
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

    -- Text Element в Player Frame отображает имя игрока.
    local nameText = BFUF.Elements.Text:Create(healthBar, {
        font = STANDARD_TEXT_FONT,
        size = PLAYER_LAYOUT.text.size,
        color = PLAYER_LAYOUT.text.color,
        justifyH = "LEFT",
        justifyV = "MIDDLE",
    })
    nameText:SetPoint("TOPLEFT", healthBar, "TOPLEFT", PLAYER_LAYOUT.text.inset, 0)
    nameText:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", -PLAYER_LAYOUT.text.inset, 0)
    frame.nameText = nameText

    -- Второй Text Element показывает текущий, максимальный и процент здоровья.
    local healthText = BFUF.Elements.Text:Create(healthBar, {
        font = STANDARD_TEXT_FONT,
        size = PLAYER_LAYOUT.healthText.size,
        color = PLAYER_LAYOUT.healthText.color,
        justifyH = "RIGHT",
        justifyV = "MIDDLE",
    })
    healthText:SetPoint("TOPLEFT", healthBar, "TOPLEFT", PLAYER_LAYOUT.healthText.inset, 0)
    healthText:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", -PLAYER_LAYOUT.healthText.inset, 0)
    frame.healthText = healthText


    -- Text Element показывает текущий, максимальный и процент основного ресурса.
    local powerText = BFUF.Elements.Text:Create(powerBar, {
        font = STANDARD_TEXT_FONT,
        size = PLAYER_LAYOUT.powerText.size,
        color = PLAYER_LAYOUT.powerText.color,
        justifyH = "RIGHT",
        justifyV = "MIDDLE",
    })
    powerText:SetPoint("TOPLEFT", powerBar, "TOPLEFT", PLAYER_LAYOUT.powerText.inset, 0)
    powerText:SetPoint("BOTTOMRIGHT", powerBar, "BOTTOMRIGHT", -PLAYER_LAYOUT.powerText.inset, 0)
    frame.powerText = powerText

    -- Обновляет имя через единое место, используемое при создании и событиях.
    local function updateNameText()
        nameText:SetText(UnitName("player") or "")
    end

    -- Обновляет текст здоровья через общую функцию форматирования.
    local function updateHealthText()
        local currentHealth = UnitHealth("player")
        local maxHealth = UnitHealthMax("player")
        local healthPercent = UnitHealthPercent("player")

        healthText:SetText(formatStatusText(
            currentHealth,
            maxHealth,
            healthPercent,
            HEALTH_TEXT_FORMAT,
            HEALTH_TEXT_FORMATS
        ))
    end



    -- Обновляет текст текущего основного ресурса в выбранном формате.
    local function updatePowerText()
        local powerType, powerToken = UnitPowerType("player")

        if not SUPPORTED_POWER_TYPES[powerToken] then
            powerText:SetText("")
            return
        end

        local currentPower = UnitPower("player", powerType)
        local maxPower = UnitPowerMax("player", powerType)
        local powerPercent = UnitPowerPercent("player", powerType)

        powerText:SetText(formatStatusText(
            currentPower,
            maxPower,
            powerPercent,
            POWER_TEXT_FORMAT,
            POWER_TEXT_FORMATS
        ))
    end

    -- Привязываем элементы к игроку и выполняем первое обновление.
    portrait:SetUnit("player")
    portrait:Update()

    healthBar:SetUnit("player")
    healthBar:Update()
    updateHealthText()
    BFUF:Debug("Health updated")

    powerBar:SetUnit("player")
    powerBar:Update()
    updatePowerText()

    updateNameText()

    -- Подписываемся только на события, необходимые для обновления ресурсов и модели игрока.
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("UNIT_HEALTH")
    frame:RegisterEvent("UNIT_MAXHEALTH")
    frame:RegisterEvent("UNIT_POWER_UPDATE")
    frame:RegisterEvent("UNIT_MAXPOWER")
    frame:RegisterEvent("UNIT_DISPLAYPOWER")
    frame:RegisterEvent("UNIT_MODEL_CHANGED")
    frame:RegisterEvent("UNIT_NAME_UPDATE")
    frame:SetScript("OnEvent", function(self, event, unit)
        -- После входа в мир повторяем обновление всех элементов.
        if event == "PLAYER_ENTERING_WORLD" then
            portrait:Update()
            healthBar:Update()
            powerBar:Update()
            updateNameText()
            updatePowerText()
            updateHealthText(healthBar.unit)
            self:UnregisterEvent("PLAYER_ENTERING_WORLD")
            return
        end

        -- События других юнитов не относятся к Player Frame.
        if unit ~= "player" then
            return
        end

        if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
            healthBar:Update()
            updateHealthText()
            BFUF:Debug("Health updated from event.")
        elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
            powerBar:Update()
            updatePowerText()
        elseif event == "UNIT_MODEL_CHANGED" then
            portrait:Update()
        elseif event == "UNIT_NAME_UPDATE" then
            updateNameText()
        end
    end)

    -- Registry хранит ссылку на готовый фрейм под именем player.
    if registry:RegisterFrame("player", frame) then
        return frame
    end

    -- Возвращаем уже зарегистрированный объект, если он появился до регистрации.
    return registry:GetFrame("player")
end

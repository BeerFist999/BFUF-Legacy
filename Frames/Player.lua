local addonName, BFUF = ...

BFUF.Frames = BFUF.Frames or {}
local Player = {}
BFUF.Frames.Player = Player

local PERCENT_CURVE = C_CurveUtil.CreateCurve()
PERCENT_CURVE:SetType(Enum.LuaCurveType.Linear)
PERCENT_CURVE:AddPoint(0, 0)
PERCENT_CURVE:AddPoint(1, 100)

local function createBorder(parent)
    local border = CreateFrame("Frame", nil, parent)
    border:SetFrameLevel(parent:GetFrameLevel() + 1)
    border.lines = {}
    for _, point in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local line = border:CreateTexture(nil, "OVERLAY")
        line:SetColorTexture(0, 0, 0, 1)
        border.lines[string.lower(point)] = line
    end
    return border
end

-- Format Secret Values without Lua arithmetic or comparisons.
local function formatValue(mode, current, maximum, percent)
    if mode == "hidden" then
        return nil
    end

    if mode == "current" then
        return string.format("%d", current)
    elseif mode == "percent" then
        return string.format("%.0f%%", percent)
    elseif mode == "currentPercent" then
        return string.format("%d (%.0f%%)", current, percent)
    elseif mode == "missing" then
        -- A missing absolute value requires arithmetic on Secret Values.
        -- Keep this unsupported mode hidden until it has a native Blizzard API source.
        return nil
    end

    return string.format("%d / %d", current, maximum)
end

local function applyTextStyle(text, settings, value)
    local color = settings.color or { r = 1, g = 1, b = 1, a = 1 }

    text:SetFont(settings.font or STANDARD_TEXT_FONT, settings.fontSize or 12, settings.outline or "")
    text:SetTextColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
    text:SetText(value or "")
    text:SetShown(settings.show ~= false and value ~= nil)
end

-- Fill only missing portrait fields for profiles created before Player portrait settings.
function Player:EnsurePortraitSettings()
    local settings = BFUF.DB:Get("Player")
    local defaults = BFUF.Defaults.profile.Player.portrait

    if type(settings.portrait) ~= "table" then
        settings.portrait = {}
    end

    if settings.portrait.mode == nil then
        settings.portrait.mode = defaults.mode
    end

    if settings.portrait.width == nil then
        settings.portrait.width = defaults.width
    end

    return settings.portrait
end

function Player:UpdateLayout()
    self:EnsurePortraitSettings()
    local root = BFUF.Framework.Registry:GetFrame("player")
    if not root then
        return
    end

    BFUF.Layouts.Player:Apply(root)
    self:UpdateTextElements(root)
end

-- Update independent text elements from their own profile sections.
function Player:UpdateTextElements(root)
    if not root or not root.levelText then
        return
    end

    local settings = BFUF.DB:Get("Player").texts
    local health = UnitHealth("player")
    local maxHealth = UnitHealthMax("player")
    local healthPercent = UnitHealthPercent("player", true, PERCENT_CURVE)
    local powerType = UnitPowerType("player")
    local power = UnitPower("player", powerType)
    local maxPower = UnitPowerMax("player", powerType)
    local powerPercent = UnitPowerPercent("player", powerType, false, PERCENT_CURVE)

    applyTextStyle(
        root.nameText,
        settings.name,
        settings.name.mode == "hidden" and nil or (UnitName("player") or "")
    )
    applyTextStyle(root.healthText, settings.health, formatValue(settings.health.mode, health, maxHealth, healthPercent))
    applyTextStyle(root.powerText, settings.power, formatValue(settings.power.mode, power, maxPower, powerPercent))

    local levelSettings = settings.level
    root.levelText:ClearAllPoints()
    root.levelText:SetPoint(
        levelSettings.anchor or "TOPLEFT",
        root.highFrame,
        levelSettings.relativePoint or levelSettings.anchor or "TOPLEFT",
        levelSettings.offsetX or 0,
        levelSettings.offsetY or 0
    )

    local level = UnitLevel("player")
    applyTextStyle(root.levelText, levelSettings, level and level > 0 and tostring(level) or "??")
end

function Player:IsLayoutUnlocked()
    local root = BFUF.Framework.Registry:GetFrame("player")
    return root and root.layoutUnlocked or false
end

function Player:SetLayoutUnlocked(unlocked)
    local root = BFUF.Framework.Registry:GetFrame("player")
    if not root or InCombatLockdown() then return end
    root.layoutUnlocked = unlocked
    root:EnableMouse(unlocked)
    root.interaction:EnableMouse(not unlocked)
end

function Player:Create()
    local root = BFUF.Framework.Registry:GetFrame("player")
    if root then return root end

    self:EnsurePortraitSettings()
    root = BFUF.Framework.Factory:CreateUnitFrame("player")

    local rootLevel = root:GetFrameLevel()
    root.background = root:CreateTexture(nil, "BACKGROUND", nil, 0)
    root.background:SetColorTexture(0, 0, 0, .8)
    root.border = createBorder(root)

    root.barsContainer = CreateFrame("Frame", nil, root)
    root.barsContainer:SetFrameLevel(rootLevel + 2)
    root.portraitContainer = CreateFrame("Frame", nil, root)
    root.portraitContainer:SetFrameLevel(rootLevel + 3)
    root.highFrame = CreateFrame("Frame", nil, root)
    root.highFrame:SetFrameLevel(rootLevel + 4)
    root.textContainer = root.highFrame
    root.indicatorLayer = CreateFrame("Frame", nil, root)
    root.indicatorLayer:SetFrameLevel(rootLevel + 5)
    root.statusIconsContainer = root.indicatorLayer
    root.classResourceContainer = CreateFrame("Frame", nil, root)
    root.classResourceContainer:SetFrameLevel(rootLevel + 4)
    root.overlayContainer = CreateFrame("Frame", nil, root)
    root.overlayContainer:SetFrameLevel(rootLevel + 5)

    root.portrait = BFUF.Elements.Portrait:Create(root.portraitContainer, {
        frame = root,
        unit = "player",
        unitType = "Player",
        getSettings = function()
            return Player:EnsurePortraitSettings()
        end,
    })
    root.portrait:SetUnit("player")
    root.healthBar = BFUF.Elements.Health:Create(root.barsContainer, {
        frame = root,
        unit = "player",
        unitType = "Player",
        getSettings = function()
            return BFUF.DB:Get("Player").health
        end,
    })
    root.healthBar:SetUnit("player")
    root.healthBar.background = root.healthBar:CreateTexture(nil, "BACKGROUND")
    root.healthBar.background:SetColorTexture(0, 0, 0, 0.2)

    root.powerBar = BFUF.Elements.Power:Create(root.barsContainer)
    root.powerBar:SetUnit("player")
    root.powerBar.background = root.powerBar:CreateTexture(nil, "BACKGROUND")
    root.powerBar.background:SetColorTexture(0, 0, 0, 0.2)

    root.layoutBars = {
        { key = "health", frame = root.healthBar, settingsKey = "health", order = 10 },
        { key = "power", frame = root.powerBar, settingsKey = "power", order = 20 },
    }

    root.nameText = BFUF.Elements.Text:Create(root.highFrame, { justifyH = "LEFT", justifyV = "MIDDLE" })
    root.nameText:SetWordWrap(false)
    root.nameText:SetMaxLines(1)
    root.healthText = BFUF.Elements.Text:Create(root.highFrame, { justifyH = "RIGHT", justifyV = "MIDDLE" })
    root.powerText = BFUF.Elements.Text:Create(root.highFrame, { justifyH = "RIGHT", justifyV = "MIDDLE" })
    root.levelText = BFUF.Elements.Text:Create(root.highFrame, { justifyH = "LEFT", justifyV = "MIDDLE" })

    root.indicators = {
        combat = BFUF.Elements.Indicators.Combat:Create(root.statusIconsContainer),
        resting = BFUF.Elements.Indicators.Resting:Create(root.statusIconsContainer),
        leader = BFUF.Elements.Indicators.Leader:Create(root.statusIconsContainer),
        assistant = BFUF.Elements.Indicators.Assistant:Create(root.statusIconsContainer),
        pvp = BFUF.Elements.Indicators.PvP:Create(root.statusIconsContainer),
        afk = BFUF.Elements.Indicators.AFK:Create(root.statusIconsContainer),
        dnd = BFUF.Elements.Indicators.DND:Create(root.statusIconsContainer),
    }

    root.interaction = CreateFrame("Button", nil, root, "SecureUnitButtonTemplate")
    root.interaction:SetAllPoints(root)
    root.interaction:RegisterForClicks("AnyUp")
    root.interaction:SetAttribute("unit", "player")
    root.interaction:SetAttribute("*type1", "target")
    root.interaction:SetAttribute("*type2", "togglemenu")

    local function refresh()
        root.healthBar:Update()
        root.powerBar:Update()
        self:UpdateTextElements(root)
    end

    root:RegisterEvent("PLAYER_ENTERING_WORLD")
    root:RegisterEvent("PLAYER_REGEN_ENABLED")
    root:RegisterEvent("UNIT_HEALTH")
    root:RegisterEvent("UNIT_MAXHEALTH")
    root:RegisterEvent("UNIT_POWER_UPDATE")
    root:RegisterEvent("UNIT_MAXPOWER")
    root:RegisterEvent("UNIT_DISPLAYPOWER")
    root:SetScript("OnEvent", function(self, event, unit)
        if event == "PLAYER_REGEN_ENABLED" and self.layoutPending then
            Player:EnsurePortraitSettings()
            BFUF.Layouts.Player:Apply(self)
            return
        end
        if event == "PLAYER_ENTERING_WORLD" then refresh(); return end
        if unit == "player" then refresh() end
    end)

    BFUF.Framework.Registry:RegisterFrame("player", root)
    BFUF.Layouts.PlayerEdit:Attach(root)
    self:SetLayoutUnlocked(false)
    self:EnsurePortraitSettings()
    BFUF.Layouts.Player:Apply(root)
    refresh()
    return root
end

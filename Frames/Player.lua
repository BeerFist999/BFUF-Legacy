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
    border:SetFrameLevel(parent:GetFrameLevel() + 2)
    for _, point in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local line = border:CreateTexture(nil, "OVERLAY")
        line:SetColorTexture(0, 0, 0, 1)
        if point == "TOP" or point == "BOTTOM" then
            line:SetHeight(1)
            line:SetPoint(point, border, point)
            line:SetPoint("LEFT", border, "LEFT")
            line:SetPoint("RIGHT", border, "RIGHT")
        else
            line:SetWidth(1)
            line:SetPoint(point, border, point)
            line:SetPoint("TOP", border, "TOP")
            line:SetPoint("BOTTOM", border, "BOTTOM")
        end
    end
    return border
end

function Player:UpdateLayout()
    BFUF.Layouts.Player:Apply(BFUF.Framework.Registry:GetFrame("player"))
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

    root = BFUF.Framework.Factory:CreateUnitFrame("player")
    root.background = root:CreateTexture(nil, "BACKGROUND")
    root.background:SetColorTexture(0, 0, 0, .8)
    root.border = createBorder(root)

    root.portraitContainer = CreateFrame("Frame", nil, root)
    root.barsContainer = CreateFrame("Frame", nil, root)
    root.textContainer = CreateFrame("Frame", nil, root.barsContainer)
    root.statusIconsContainer = CreateFrame("Frame", nil, root)
    root.classResourceContainer = CreateFrame("Frame", nil, root)
    root.overlayContainer = CreateFrame("Frame", nil, root)

    root.portrait = BFUF.Elements.Portrait:Create(root.portraitContainer)
    root.portrait:SetUnit("player")
    root.healthBar = BFUF.Elements.Health:Create(root.barsContainer)
    root.healthBar:SetUnit("player")
    root.powerBar = BFUF.Elements.Power:Create(root.barsContainer)
    root.powerBar:SetUnit("player")

    root.nameText = BFUF.Elements.Text:Create(root.textContainer, { justifyH = "LEFT", justifyV = "MIDDLE" })
    root.healthText = BFUF.Elements.Text:Create(root.textContainer, { justifyH = "RIGHT", justifyV = "MIDDLE" })
    root.powerText = BFUF.Elements.Text:Create(root.textContainer, { justifyH = "RIGHT", justifyV = "MIDDLE" })
    root.nameText:SetPoint("LEFT", root.healthBar, "LEFT", 4, 0)
    root.healthText:SetPoint("RIGHT", root.healthBar, "RIGHT", -4, 0)
    root.powerText:SetPoint("RIGHT", root.powerBar, "RIGHT", -4, 0)

    local defaults = BFUF.Defaults.profile.Player.indicators
    root.indicators = {
        combat = BFUF.Elements.Indicators.Combat:Create(root.statusIconsContainer, { point="TOPLEFT", relativePoint="TOPLEFT", size=defaults.combat.size, offsetX=defaults.combat.offsetX, offsetY=defaults.combat.offsetY }),
        resting = BFUF.Elements.Indicators.Resting:Create(root.statusIconsContainer, { point="TOPLEFT", relativePoint="TOPLEFT", size=defaults.resting.size, offsetX=defaults.resting.offsetX, offsetY=defaults.resting.offsetY }),
        leader = BFUF.Elements.Indicators.Leader:Create(root.statusIconsContainer, { point="TOPRIGHT", relativePoint="TOP", size=defaults.leader.size, offsetX=defaults.leader.offsetX, offsetY=defaults.leader.offsetY }),
        assistant = BFUF.Elements.Indicators.Assistant:Create(root.statusIconsContainer, { point="TOPLEFT", relativePoint="TOP", size=defaults.assistant.size, offsetX=defaults.assistant.offsetX, offsetY=defaults.assistant.offsetY }),
        pvp = BFUF.Elements.Indicators.PvP:Create(root.statusIconsContainer, { point="BOTTOMLEFT", relativePoint="BOTTOMLEFT", size=defaults.pvp.size, offsetX=defaults.pvp.offsetX, offsetY=defaults.pvp.offsetY }),
        afk = BFUF.Elements.Indicators.AFK:Create(root.statusIconsContainer, { point="BOTTOMLEFT", relativePoint="BOTTOMLEFT", size=defaults.afk.size, offsetX=defaults.afk.offsetX, offsetY=defaults.afk.offsetY }),
        dnd = BFUF.Elements.Indicators.DND:Create(root.statusIconsContainer, { point="BOTTOMLEFT", relativePoint="BOTTOMLEFT", size=defaults.dnd.size, offsetX=defaults.dnd.offsetX, offsetY=defaults.dnd.offsetY }),
    }

    root.interaction = CreateFrame("Button", nil, root, "SecureUnitButtonTemplate")
    root.interaction:SetAllPoints(root)
    root.interaction:RegisterForClicks("AnyUp")
    root.interaction:SetAttribute("unit", "player")
    root.interaction:SetAttribute("*type1", "target")
    root.interaction:SetAttribute("*type2", "menu")

    local function refresh()
        root.portrait:Update()
        root.healthBar:Update()
        root.powerBar:Update()
        root.nameText:SetText(UnitName("player") or "")
        root.healthText:SetText(string.format("%d / %d", UnitHealth("player"), UnitHealthMax("player")))
        local type = UnitPowerType("player")
        root.powerText:SetText(string.format("%d / %d", UnitPower("player", type), UnitPowerMax("player", type)))
    end

    root:RegisterEvent("PLAYER_ENTERING_WORLD")
    root:RegisterEvent("PLAYER_REGEN_ENABLED")
    root:RegisterEvent("UNIT_HEALTH")
    root:RegisterEvent("UNIT_MAXHEALTH")
    root:RegisterEvent("UNIT_POWER_UPDATE")
    root:RegisterEvent("UNIT_MAXPOWER")
    root:RegisterEvent("UNIT_DISPLAYPOWER")
    root:RegisterEvent("UNIT_PORTRAIT_UPDATE")
    root:SetScript("OnEvent", function(self, event, unit)
        if event == "PLAYER_REGEN_ENABLED" and self.layoutPending then BFUF.Layouts.Player:Apply(self); return end
        if event == "PLAYER_ENTERING_WORLD" then refresh(); return end
        if unit == "player" then refresh() end
    end)

    BFUF.Framework.Registry:RegisterFrame("player", root)
    BFUF.Layouts.PlayerEdit:Attach(root)
    self:SetLayoutUnlocked(false)
    BFUF.Layouts.Player:Apply(root)
    refresh()
    return root
end

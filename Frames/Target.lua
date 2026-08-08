local addonName, BFUF = ...

BFUF.Frames = BFUF.Frames or {}
local Target = {}
BFUF.Frames.Target = Target

local TARGET_WIDTH = 260
local TARGET_HEIGHT = 58
local PORTRAIT_SIZE = 54
local CONTENT_PADDING = 2
local BAR_GAP = 2
local POWER_HEIGHT = 10

local function createBorder(parent)
    local border = CreateFrame("Frame", nil, parent)
    border:SetFrameLevel(parent:GetFrameLevel() + 1)

    local top = border:CreateTexture(nil, "OVERLAY")
    top:SetColorTexture(0, 0, 0, 1)
    top:SetPoint("TOPLEFT", border, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", border, "TOPRIGHT", 0, 0)
    top:SetHeight(1)

    local bottom = border:CreateTexture(nil, "OVERLAY")
    bottom:SetColorTexture(0, 0, 0, 1)
    bottom:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(1)

    local left = border:CreateTexture(nil, "OVERLAY")
    left:SetColorTexture(0, 0, 0, 1)
    left:SetPoint("TOPLEFT", border, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT", 0, 0)
    left:SetWidth(1)

    local right = border:CreateTexture(nil, "OVERLAY")
    right:SetColorTexture(0, 0, 0, 1)
    right:SetPoint("TOPRIGHT", border, "TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", 0, 0)
    right:SetWidth(1)

    return border
end

local function setText(text, value)
    text:SetText(value or "")
    text:SetShown(value ~= nil)
end

-- Refresh the independent target text values without arithmetic on unit values.
function Target:UpdateTexts(root)
    if not root then
        return
    end

    setText(root.nameText, UnitName("target") or "")

    local health = UnitHealth("target")
    local maxHealth = UnitHealthMax("target")
    if health and maxHealth then
        setText(root.healthText, string.format("%d / %d", health, maxHealth))
    else
        setText(root.healthText, nil)
    end

    local powerType = UnitPowerType("target")
    local power = UnitPower("target", powerType)
    local maxPower = UnitPowerMax("target", powerType)
    if power and maxPower then
        setText(root.powerText, string.format("%d / %d", power, maxPower))
    else
        setText(root.powerText, nil)
    end

    local level = UnitLevel("target")
    setText(root.levelText, level and level > 0 and tostring(level) or nil)
end

-- Keep Target visibility independent from the Player frame.
function Target:UpdateVisibility(root)
    root = root or BFUF.Framework.Registry:GetFrame("target")
    if not root then
        return
    end

    root.visible = UnitExists("target")
    root:SetShown(root.visible)
end

-- Refresh all visual elements after a target-related event.
function Target:Update(root)
    root = root or BFUF.Framework.Registry:GetFrame("target")
    if not root then
        return
    end

    self:UpdateVisibility(root)
    if not root.visible then
        return
    end

    root.portrait:Update()
    root.healthBar:Update()
    root.powerBar:Update()
    self:UpdateTexts(root)
end

-- Create the first independent Target unit frame.
function Target:Create()
    local root = BFUF.Framework.Registry:GetFrame("target")
    if root then
        return root
    end

    root = BFUF.Framework.Factory:CreateUnitFrame("target")
    root:SetSize(TARGET_WIDTH, TARGET_HEIGHT)
    root:SetPoint("CENTER", UIParent, "CENTER", 320, 0)
    root.position = {
        point = "CENTER",
        relativePoint = "CENTER",
        offsetX = 320,
        offsetY = 0,
    }

    local rootLevel = root:GetFrameLevel()
    root.background = root:CreateTexture(nil, "BACKGROUND", nil, 0)
    root.background:SetAllPoints()
    root.background:SetColorTexture(0, 0, 0, 0.8)
    root.border = createBorder(root)
    root.border:SetAllPoints()

    root.portraitContainer = CreateFrame("Frame", nil, root)
    root.portraitContainer:SetPoint("TOPLEFT", root, "TOPLEFT", CONTENT_PADDING, -CONTENT_PADDING)
    root.portraitContainer:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", CONTENT_PADDING, CONTENT_PADDING)
    root.portraitContainer:SetWidth(PORTRAIT_SIZE)
    root.portraitContainer:SetFrameLevel(rootLevel + 2)
    root.portraitContainer:SetClipsChildren(true)

    root.barsContainer = CreateFrame("Frame", nil, root)
    root.barsContainer:SetPoint("TOPLEFT", root.portraitContainer, "TOPRIGHT", BAR_GAP, 0)
    root.barsContainer:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -CONTENT_PADDING, CONTENT_PADDING)
    root.barsContainer:SetFrameLevel(rootLevel + 2)

    root.highFrame = CreateFrame("Frame", nil, root)
    root.highFrame:SetAllPoints(root.barsContainer)
    root.highFrame:SetFrameLevel(rootLevel + 4)
    root.textContainer = root.highFrame

    root.indicatorContainer = CreateFrame("Frame", nil, root)
    root.indicatorContainer:SetAllPoints(root)
    root.indicatorContainer:SetFrameLevel(rootLevel + 5)

    root.auraContainer = CreateFrame("Frame", nil, root)
    root.auraContainer:SetPoint("TOPLEFT", root, "BOTTOMLEFT", 0, -4)
    root.auraContainer:SetPoint("TOPRIGHT", root, "BOTTOMRIGHT", 0, -4)
    root.auraContainer:SetHeight(1)
    root.auraContainer:SetFrameLevel(rootLevel + 5)

    root.portrait = BFUF.Elements.Portrait:Create(root.portraitContainer)
    root.portrait:SetAllPoints(root.portraitContainer)
    root.portrait:SetUnit("target")

    root.healthBar = BFUF.Elements.Health:Create(root.barsContainer)
    root.healthBar:SetUnit("target")
    root.healthBar.background = root.healthBar:CreateTexture(nil, "BACKGROUND")
    root.healthBar.background:SetAllPoints()
    root.healthBar.background:SetColorTexture(0, 0, 0, 0.2)

    root.powerBar = BFUF.Elements.Power:Create(root.barsContainer)
    root.powerBar:SetPoint("BOTTOMLEFT", root.barsContainer, "BOTTOMLEFT", 0, 0)
    root.powerBar:SetPoint("BOTTOMRIGHT", root.barsContainer, "BOTTOMRIGHT", 0, 0)
    root.powerBar:SetHeight(POWER_HEIGHT)
    root.powerBar:SetUnit("target")
    root.powerBar.background = root.powerBar:CreateTexture(nil, "BACKGROUND")
    root.powerBar.background:SetAllPoints()
    root.powerBar.background:SetColorTexture(0, 0, 0, 0.2)

    root.healthBar:SetPoint("TOPLEFT", root.barsContainer, "TOPLEFT", 0, 0)
    root.healthBar:SetPoint("TOPRIGHT", root.barsContainer, "TOPRIGHT", 0, 0)
    root.healthBar:SetPoint("BOTTOMLEFT", root.powerBar, "TOPLEFT", 0, BAR_GAP)
    root.healthBar:SetPoint("BOTTOMRIGHT", root.powerBar, "TOPRIGHT", 0, BAR_GAP)

    root.nameText = BFUF.Elements.Text:Create(root.highFrame, {
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        size = 12,
    })
    root.nameText:SetPoint("LEFT", root.healthBar, "LEFT", 4, 0)

    root.healthText = BFUF.Elements.Text:Create(root.highFrame, {
        justifyH = "RIGHT",
        justifyV = "MIDDLE",
        size = 12,
    })
    root.healthText:SetPoint("RIGHT", root.healthBar, "RIGHT", -4, 0)

    root.levelText = BFUF.Elements.Text:Create(root.highFrame, {
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        size = 11,
    })
    root.levelText:SetPoint("LEFT", root.powerBar, "LEFT", 4, 0)

    root.powerText = BFUF.Elements.Text:Create(root.highFrame, {
        justifyH = "RIGHT",
        justifyV = "MIDDLE",
        size = 11,
    })
    root.powerText:SetPoint("RIGHT", root.powerBar, "RIGHT", -4, 0)

    root:RegisterEvent("PLAYER_ENTERING_WORLD")
    root:RegisterEvent("PLAYER_TARGET_CHANGED")
    root:RegisterEvent("UNIT_HEALTH")
    root:RegisterEvent("UNIT_MAXHEALTH")
    root:RegisterEvent("UNIT_POWER_UPDATE")
    root:RegisterEvent("UNIT_MAXPOWER")
    root:RegisterEvent("UNIT_DISPLAYPOWER")
    root:RegisterEvent("UNIT_NAME_UPDATE")
    root:RegisterEvent("UNIT_PORTRAIT_UPDATE")
    root:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_TARGET_CHANGED" then
            Target:Update(root)
            return
        end

        if unit == "target" then
            Target:Update(root)
        end
    end)

    BFUF.Framework.Registry:RegisterFrame("target", root)
    self:Update(root)
    return root
end

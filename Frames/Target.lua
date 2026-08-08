local addonName, BFUF = ...

BFUF.Frames = BFUF.Frames or {}
local Target = {}
BFUF.Frames.Target = Target

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

-- Fill only missing nested portrait fields for profiles created before Target portraits.
local function getPortraitSettings()
    local settings = BFUF.DB:Get("Target")
    local defaults = BFUF.Defaults.profile.Target.portrait

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

-- Refresh the independent target text values without arithmetic on unit values.
function Target:UpdateTexts(root)
    if not root then
        return
    end

    setText(root.nameText, UnitName("target") or "")

    -- Format unit values without comparing or performing arithmetic on them.
    setText(
        root.healthText,
        string.format("%d / %d", UnitHealth("target"), UnitHealthMax("target"))
    )

    local powerType = UnitPowerType("target")
    setText(
        root.powerText,
        string.format("%d / %d", UnitPower("target", powerType), UnitPowerMax("target", powerType))
    )

    local level = UnitLevel("target")
    setText(root.levelText, level and level > 0 and tostring(level) or nil)
end

-- Read the current target state without directly changing protected frame visibility.
function Target:UpdateVisibility(root)
    root = root or BFUF.Framework.Registry:GetFrame("target")
    if not root then
        return false
    end

    root.visible = UnitExists("target")
    return root.visible
end

-- Apply only Target geometry from its own profile fields.
function Target:UpdateLayout(root)
    root = root or BFUF.Framework.Registry:GetFrame("target")
    if not root then
        return
    end

    if InCombatLockdown() then
        root.layoutPending = true
        return
    end

    local settings = BFUF.DB:Get("Target")
    local anchor = settings.positionAnchor or {
        point = "CENTER",
        relativePoint = "CENTER",
        offsetX = settings.positionX,
        offsetY = settings.positionY,
    }

    root:ClearAllPoints()
    root:SetPoint(anchor.point, UIParent, anchor.relativePoint, anchor.offsetX, anchor.offsetY)
    root:SetSize(settings.width, settings.height)
    root:SetScale(settings.scale)

    local portraitSettings = getPortraitSettings()
    local portraitVisible = portraitSettings.mode ~= BFUF.Elements.Portrait.Modes.HIDDEN
    root.portraitContainer:SetShown(portraitVisible)
    root.portraitContainer:SetWidth(portraitSettings.width)

    root.barsContainer:ClearAllPoints()
    root.barsContainer:SetPoint("TOPLEFT", root, "TOPLEFT", CONTENT_PADDING, -CONTENT_PADDING)
    if portraitVisible then
        root.barsContainer:SetPoint("BOTTOMRIGHT", root.portraitContainer, "BOTTOMLEFT", -BAR_GAP, CONTENT_PADDING)
    else
        root.barsContainer:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -CONTENT_PADDING, CONTENT_PADDING)
    end

    root.position = anchor
    root.layoutPending = nil
end

function Target:IsLayoutUnlocked()
    local root = BFUF.Framework.Registry:GetFrame("target")
    return root and root.layoutUnlocked or false
end

function Target:RefreshLayoutControls()
    if BFUF.Core.Settings and BFUF.Core.Settings.RefreshFrameLayoutControls then
        BFUF.Core.Settings:RefreshFrameLayoutControls("Target")
    end
end

-- Store the native frame anchor without manual cursor calculations.
function Target:SavePosition(root)
    local point, _, relativePoint, offsetX, offsetY = root:GetPoint()
    local settings = BFUF.DB:Get("Target")

    settings.positionAnchor = {
        point = point,
        relativePoint = relativePoint,
        offsetX = offsetX,
        offsetY = offsetY,
    }
    settings.positionX = offsetX
    settings.positionY = offsetY
    self:RefreshLayoutControls()
end

function Target:SetLayoutUnlocked(unlocked)
    local root = BFUF.Framework.Registry:GetFrame("target")
    if not root or InCombatLockdown() then
        return
    end

    root.layoutUnlocked = unlocked
    root:EnableMouse(true)
    root:SetAttribute("*type1", unlocked and nil or "target")
    root:SetAttribute("*type2", unlocked and nil or "togglemenu")
end

-- Attach Blizzard's native movement lifecycle to the Target root.
function Target:AttachDrag(root)
    root:SetMovable(true)
    root:SetClampedToScreen(true)
    root:RegisterForDrag("LeftButton")

    root:SetScript("OnDragStart", function(frame)
        if frame.layoutUnlocked and not InCombatLockdown() then
            frame:StartMoving()
        end
    end)

    root:SetScript("OnDragStop", function(frame)
        if not frame.layoutUnlocked then
            return
        end

        frame:StopMovingOrSizing()
        Target:SavePosition(frame)
        Target:UpdateLayout(frame)
    end)
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

    root.portrait:SetMode(getPortraitSettings().mode)
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

    -- The visible Target root is the protected unit button, so UnitWatch can
    -- control its visibility without insecure SetShown calls during combat.
    root = CreateFrame("Button", nil, UIParent, "SecureUnitButtonTemplate")
    root.unit = "target"
    root.layoutUnlocked = false

    local portraitSettings = getPortraitSettings()
    local rootLevel = root:GetFrameLevel()
    root.background = root:CreateTexture(nil, "BACKGROUND", nil, 0)
    root.background:SetAllPoints()
    root.background:SetColorTexture(0, 0, 0, 0.8)
    root.border = createBorder(root)
    root.border:SetAllPoints()

    root.portraitContainer = CreateFrame("Frame", nil, root)
    root.portraitContainer:SetPoint("TOPRIGHT", root, "TOPRIGHT", -CONTENT_PADDING, -CONTENT_PADDING)
    root.portraitContainer:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -CONTENT_PADDING, CONTENT_PADDING)
    root.portraitContainer:SetWidth(portraitSettings.width)
    root.portraitContainer:SetFrameLevel(rootLevel + 3)
    root.portraitContainer:SetClipsChildren(true)

    root.barsContainer = CreateFrame("Frame", nil, root)
    root.barsContainer:SetPoint("TOPLEFT", root, "TOPLEFT", CONTENT_PADDING, -CONTENT_PADDING)
    root.barsContainer:SetPoint("BOTTOMRIGHT", root.portraitContainer, "BOTTOMLEFT", -BAR_GAP, 0)
    root.barsContainer:SetFrameLevel(rootLevel + 2)

    root.highFrame = CreateFrame("Frame", nil, root)
    root.highFrame:SetAllPoints(root.barsContainer)
    root.highFrame:SetFrameLevel(rootLevel + 4)
    root.highFrame:SetClipsChildren(true)
    root.textContainer = root.highFrame

    root.indicatorContainer = CreateFrame("Frame", nil, root)
    root.indicatorContainer:SetAllPoints(root)
    root.indicatorContainer:SetFrameLevel(rootLevel + 5)

    root.auraContainer = CreateFrame("Frame", nil, root)
    root.auraContainer:SetPoint("TOPLEFT", root, "BOTTOMLEFT", 0, -4)
    root.auraContainer:SetPoint("TOPRIGHT", root, "BOTTOMRIGHT", 0, -4)
    root.auraContainer:SetHeight(1)
    root.auraContainer:SetFrameLevel(rootLevel + 5)

    -- Keep the existing interaction reference while the root itself provides
    -- the secure click surface and secure unit visibility.
    root.interaction = root
    root:RegisterForClicks("AnyUp")
    root:SetAttribute("unit", "target")
    root:SetAttribute("*type1", "target")
    root:SetAttribute("*type2", "togglemenu")
    RegisterUnitWatch(root)

    root.portrait = BFUF.Elements.Portrait:Create(root.portraitContainer, {
        frame = root,
        unit = "target",
        unitType = "Target",
        getSettings = getPortraitSettings,
    })
    root.portrait:ApplyLayout({
        parent = root.portraitContainer,
        left = 0,
        right = 0,
        top = 0,
        bottom = 0,
    })
    root.portrait:SetUnit("target")

    root.healthBar = BFUF.Elements.Health:Create(root.barsContainer, {
        frame = root,
        unit = "target",
        unitType = "Target",
        getSettings = function()
            -- Target has no independent health profile yet; preserve its
            -- existing shared health policy without exposing that detail to
            -- the renderer.
            return BFUF.DB:Get("Player").health
        end,
    })
    root.healthBar:SetColorResolver(BFUF.Utils.GetUnitHealthColor)
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

    -- Target owns its manually anchored health-bar geometry, including the
    -- independent absorb overlays created by the shared Health element.
    root.healthBar.absorbBar:SetAllPoints(root.healthBar)
    root.healthBar.healAbsorbBar:SetAllPoints(root.healthBar)

    root.nameText = BFUF.Elements.Text:Create(root.highFrame, {
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        size = 12,
    })
    root.nameText:SetWordWrap(false)
    root.nameText:SetMaxLines(1)

    root.healthText = BFUF.Elements.Text:Create(root.highFrame, {
        justifyH = "RIGHT",
        justifyV = "MIDDLE",
        size = 12,
    })
    root.healthText:SetPoint("RIGHT", root.healthBar, "RIGHT", -4, 0)

    -- The name uses the dynamically available space between the health bar edge
    -- and its value text, so it cannot overlap the portrait or health values.
    root.nameText:SetPoint("LEFT", root.healthBar, "LEFT", 4, 0)
    root.nameText:SetPoint("RIGHT", root.healthText, "LEFT", -6, 0)

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
    root:RegisterEvent("PLAYER_REGEN_ENABLED")
    root:RegisterEvent("PLAYER_TARGET_CHANGED")
    root:RegisterEvent("UNIT_HEALTH")
    root:RegisterEvent("UNIT_MAXHEALTH")
    root:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
    root:RegisterEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED")
    root:RegisterEvent("UNIT_POWER_UPDATE")
    root:RegisterEvent("UNIT_MAXPOWER")
    root:RegisterEvent("UNIT_DISPLAYPOWER")
    root:RegisterEvent("UNIT_NAME_UPDATE")
    root:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_REGEN_ENABLED" and root.layoutPending then
            Target:UpdateLayout(root)
            return
        end

        if event == "PLAYER_ENTERING_WORLD" then
            Target:Update(root)
            return
        end

        if event == "PLAYER_TARGET_CHANGED" then
            Target:Update(root)
            return
        end

        if event == "UNIT_ABSORB_AMOUNT_CHANGED" or event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" then
            -- The event may identify the displayed target through another
            -- valid unit alias, such as "player" when targeting yourself.
            if unit and UnitIsUnit("target", unit) then
                root.healthBar:UpdateOverlays()
            end
            return
        end

        if unit == "target" then
            Target:Update(root)
        end
    end)

    BFUF.Framework.Registry:RegisterFrame("target", root)
    self:AttachDrag(root)
    self:UpdateLayout(root)
    self:SetLayoutUnlocked(false)
    self:Update(root)
    return root
end

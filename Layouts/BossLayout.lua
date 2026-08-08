local addonName, BFUF = ...

BFUF.Layouts = BFUF.Layouts or {}

local BossLayout = {}
BFUF.Layouts.Boss = BossLayout

local CONTENT_PADDING = 2
local BAR_GAP = 2
local POWER_HEIGHT = 8

local function setRectangle(region, parent, left, right, top, bottom)
    region:ClearAllPoints()
    region:SetPoint("TOPLEFT", parent, "TOPLEFT", left, top)
    region:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", right, bottom)
end

local function applyBorderGeometry(border)
    border:ClearAllPoints()
    border:SetAllPoints(border:GetParent())

    local top = border.lines.top
    top:ClearAllPoints()
    top:SetPoint("TOPLEFT", border, "TOPLEFT")
    top:SetPoint("TOPRIGHT", border, "TOPRIGHT")
    top:SetHeight(1)

    local bottom = border.lines.bottom
    bottom:ClearAllPoints()
    bottom:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT")
    bottom:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT")
    bottom:SetHeight(1)

    local left = border.lines.left
    left:ClearAllPoints()
    left:SetPoint("TOPLEFT", border, "TOPLEFT")
    left:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT")
    left:SetWidth(1)

    local right = border.lines.right
    right:ClearAllPoints()
    right:SetPoint("TOPRIGHT", border, "TOPRIGHT")
    right:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT")
    right:SetWidth(1)
end

local function applyRootAnchor(root, previous, settings)
    root:ClearAllPoints()

    if root.index == 1 then
        root:SetPoint("CENTER", UIParent, "CENTER", settings.positionX or 0, settings.positionY or 0)
    elseif settings.growth == "UP" then
        root:SetPoint("BOTTOMLEFT", previous, "TOPLEFT", 0, settings.spacing or 0)
    else
        root:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -(settings.spacing or 0))
    end
end

local function applyUnitWatch(root, enabled)
    if enabled and not root.unitWatchRegistered then
        RegisterUnitWatch(root)
        root.unitWatchRegistered = true
    elseif not enabled and root.unitWatchRegistered then
        UnregisterUnitWatch(root)
        root.unitWatchRegistered = false
        root:Hide()
    end
end

-- Apply the shared boss-frame geometry without touching Player or Target layouts.
function BossLayout:Apply(root, previous, settings)
    if InCombatLockdown() then
        root.layoutPending = true
        return
    end

    local count = math.max(1, math.min(5, settings.count or 5))
    local enabled = settings.enabled ~= false and root.index <= count
    applyUnitWatch(root, enabled)
    root.enabled = enabled

    if not enabled then
        root.layoutPending = false
        return
    end

    root:SetSize(settings.width, settings.height)
    root:SetScale(settings.scale or 1)
    applyRootAnchor(root, previous, settings)
    setRectangle(root.background, root, 0, 0, 0, 0)
    applyBorderGeometry(root.border)

    local portraitEnabled = settings.portrait and settings.portrait.enabled ~= false
    root.portraitContainer:SetShown(portraitEnabled)
    root.portraitContainer:ClearAllPoints()

    if portraitEnabled then
        root.portraitContainer:SetPoint("TOPLEFT", root, "TOPLEFT", CONTENT_PADDING, -CONTENT_PADDING)
        root.portraitContainer:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", CONTENT_PADDING, CONTENT_PADDING)
        root.portraitContainer:SetWidth(settings.portrait.width)
        setRectangle(
            root.barsContainer,
            root,
            CONTENT_PADDING + settings.portrait.width + BAR_GAP,
            -CONTENT_PADDING,
            -CONTENT_PADDING,
            CONTENT_PADDING
        )
    else
        setRectangle(root.barsContainer, root, CONTENT_PADDING, -CONTENT_PADDING, -CONTENT_PADDING, CONTENT_PADDING)
    end

    setRectangle(root.portrait, root.portraitContainer, 0, 0, 0, 0)
    setRectangle(root.portrait.texture, root.portrait, 0, 0, 0, 0)

    root.powerBar:ClearAllPoints()
    root.powerBar:SetPoint("BOTTOMLEFT", root.barsContainer, "BOTTOMLEFT")
    root.powerBar:SetPoint("BOTTOMRIGHT", root.barsContainer, "BOTTOMRIGHT")
    root.powerBar:SetHeight(POWER_HEIGHT)

    root.healthBar:ClearAllPoints()
    root.healthBar:SetPoint("TOPLEFT", root.barsContainer, "TOPLEFT")
    root.healthBar:SetPoint("TOPRIGHT", root.barsContainer, "TOPRIGHT")
    root.healthBar:SetPoint("BOTTOMLEFT", root.powerBar, "TOPLEFT", 0, BAR_GAP)
    root.healthBar:SetPoint("BOTTOMRIGHT", root.powerBar, "TOPRIGHT", 0, BAR_GAP)

    setRectangle(root.healthBar.background, root.healthBar, 0, 0, 0, 0)
    setRectangle(root.powerBar.background, root.powerBar, 0, 0, 0, 0)
    setRectangle(root.healthBar.absorbBar, root.healthBar, 0, 0, 0, 0)
    setRectangle(root.healthBar.healAbsorbBar, root.healthBar, 0, 0, 0, 0)
    setRectangle(root.highFrame, root.barsContainer, 0, 0, 0, 0)

    root.layoutPending = false
end

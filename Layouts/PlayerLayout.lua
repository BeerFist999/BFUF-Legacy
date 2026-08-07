local addonName, BFUF = ...

BFUF.Layouts = BFUF.Layouts or {}

local PlayerLayout = {}
BFUF.Layouts.Player = PlayerLayout

local GEOMETRY = {
    padding = 3,
    barGap = 2,
    borderThickness = 1,
}

local INDICATOR_ANCHORS = {
    combat = { point = "TOPLEFT", relativePoint = "TOPLEFT" },
    resting = { point = "TOPLEFT", relativePoint = "TOPLEFT" },
    leader = { point = "TOPRIGHT", relativePoint = "TOP" },
    assistant = { point = "TOPLEFT", relativePoint = "TOP" },
    pvp = { point = "BOTTOMLEFT", relativePoint = "BOTTOMLEFT" },
    afk = { point = "BOTTOMLEFT", relativePoint = "BOTTOMLEFT" },
    dnd = { point = "BOTTOMLEFT", relativePoint = "BOTTOMLEFT" },
}

local function setRectangle(region, parent, left, right, top, bottom)
    region:ClearAllPoints()
    region:SetPoint("TOPLEFT", parent, "TOPLEFT", left, top)
    region:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", right, bottom)
end

local function setHorizontalBar(region, parent, verticalPoint, height, horizontalInset, verticalOffset)
    region:ClearAllPoints()
    region:SetPoint(verticalPoint .. "LEFT", parent, verticalPoint .. "LEFT", horizontalInset, verticalOffset)
    region:SetPoint(verticalPoint .. "RIGHT", parent, verticalPoint .. "RIGHT", -horizontalInset, verticalOffset)
    region:SetHeight(height)
end

local function setTextAnchor(text, point, relativeTo, relativePoint, offsetX, offsetY)
    text:ClearAllPoints()
    text:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY)
end

local function setIndicatorGeometry(indicator, parent, settings, anchor)
    setRectangle(indicator.holder, parent, 0, 0, 0, 0)
    indicator:ClearAllPoints()
    indicator:SetSize(settings.size, settings.size)
    indicator:SetPoint(anchor.point, parent, anchor.relativePoint, settings.offsetX, settings.offsetY)
end

local function applyBorderGeometry(border)
    local thickness = GEOMETRY.borderThickness
    setRectangle(border, border:GetParent(), 0, 0, 0, 0)
    setRectangle(border.lines.top, border, 0, 0, 0, -thickness)
    setRectangle(border.lines.bottom, border, 0, 0, thickness, 0)
    setRectangle(border.lines.left, border, 0, thickness, 0, 0)
    setRectangle(border.lines.right, border, -thickness, 0, 0, 0)
end

local function applyRootAnchor(root, settings)
    root:ClearAllPoints()
    local anchor = settings.positionAnchor
    if anchor then
        root:SetPoint(anchor.point, UIParent, anchor.relativePoint, anchor.offsetX, anchor.offsetY)
        return
    end
    root:SetPoint("CENTER", UIParent, "CENTER", settings.positionX, settings.positionY)
end

-- Resolve and apply every Player Frame rectangle from one authoritative layout pass.
function PlayerLayout:Apply(root)
    if InCombatLockdown() then
        root.layoutPending = true
        return
    end

    local settings = BFUF.DB:Get("Player")
    local portrait = settings.portrait
    local health = settings.health
    local power = settings.power
    local width = math.max(1, settings.width)
    local height = math.max(1, settings.height)
    local padding = GEOMETRY.padding
    local contentHeight = math.max(1, height - padding * 2)

    root:SetSize(width, height)
    root:SetScale(settings.scale)
    applyRootAnchor(root, settings)

    setRectangle(root.background, root, 0, 0, 0, 0)
    applyBorderGeometry(root.border)
    setRectangle(root.statusIconsContainer, root, 0, 0, 0, 0)
    setRectangle(root.overlayContainer, root, 0, 0, 0, 0)

    local portraitVisible = portrait.mode ~= BFUF.Elements.Portrait.Modes.HIDDEN
    local barsLeft = padding
    if portraitVisible then
        local portraitWidth = math.min(portrait.width, math.max(1, width - padding * 2))
        local portraitHeight = math.min(portrait.height, contentHeight)
        setRectangle(root.portraitContainer, root, padding, -(width - padding - portraitWidth), -padding, -(height - padding - portraitHeight))
        root.portraitContainer:Show()
        setRectangle(root.portrait, root.portraitContainer, 0, 0, 0, 0)
        setRectangle(root.portrait.texture, root.portrait, 0, 0, 0, 0)
        setRectangle(root.portrait.model, root.portrait, 0, 0, 0, 0)
        barsLeft = padding + portraitWidth + GEOMETRY.barGap
    else
        root.portraitContainer:Hide()
    end

    setRectangle(root.barsContainer, root, barsLeft, -padding, -padding, padding)
    setRectangle(root.textContainer, root.barsContainer, 0, 0, 0, 0)

    local healthInset = math.max(0, health.offsetX)
    local powerInset = math.max(0, power.offsetX)
    local healthTopInset = math.max(0, -health.offsetY)
    local powerBottomInset = math.max(0, power.offsetY)
    local barSpace = math.max(1, contentHeight - healthTopInset - powerBottomInset)
    local resolvedPowerHeight = math.min(power.height, barSpace)
    local resolvedHealthHeight = math.min(health.height, math.max(1, barSpace - resolvedPowerHeight - GEOMETRY.barGap))

    setHorizontalBar(root.healthBar, root.barsContainer, "TOP", resolvedHealthHeight, healthInset, health.offsetY)
    setRectangle(root.healthBar.absorbBar, root.healthBar, 0, 0, 0, 0)
    setRectangle(root.healthBar.healAbsorbBar, root.healthBar, 0, 0, 0, 0)
    setHorizontalBar(root.powerBar, root.barsContainer, "BOTTOM", resolvedPowerHeight, powerInset, power.offsetY)

    local texts = settings.texts
    setTextAnchor(root.nameText, "LEFT", root.healthBar, "LEFT", texts.name.offsetX, texts.name.offsetY)
    setTextAnchor(root.healthText, "RIGHT", root.healthBar, "RIGHT", texts.health.offsetX, texts.health.offsetY)
    setTextAnchor(root.powerText, "RIGHT", root.powerBar, "RIGHT", texts.power.offsetX, texts.power.offsetY)

    setRectangle(root.classResourceContainer, root.barsContainer, 0, 0, -GEOMETRY.barGap, -GEOMETRY.barGap)
    for name, indicator in pairs(root.indicators) do
        setIndicatorGeometry(indicator, root.statusIconsContainer, settings.indicators[name], INDICATOR_ANCHORS[name])
    end

    root.portrait:SetMode(portrait.mode)
    root.healthBar:UpdateStyle()
    root.powerBar:UpdateStyle()
    root.layoutPending = false
end

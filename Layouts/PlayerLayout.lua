local addonName, BFUF = ...

BFUF.Layouts = BFUF.Layouts or {}

local PlayerLayout = {}
BFUF.Layouts.Player = PlayerLayout

local LAYOUT = {
    frameInset = 2,
    barSpacing = 2,
    borderThickness = 1,
}

local BAR_ORDER = {
    { key = "health", field = "healthBar", order = 10 },
    { key = "power", field = "powerBar", order = 20 },
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

local function setBarGeometry(bar, parent, left, right, top, height)
    bar:ClearAllPoints()
    bar:SetPoint("TOPLEFT", parent, "TOPLEFT", left, top)
    bar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", right, top)
    bar:SetHeight(height)
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
    local thickness = LAYOUT.borderThickness
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

local function resolveBarStack(root, settings, left, right, innerHeight)
    local totalWeight = 0
    for _, definition in ipairs(BAR_ORDER) do
        totalWeight = totalWeight + math.max(1, settings[definition.key].height)
    end

    local availableHeight = math.max(2, innerHeight - LAYOUT.barSpacing * (#BAR_ORDER - 1))
    local consumedHeight = 0
    local top = 0

    for index, definition in ipairs(BAR_ORDER) do
        local bar = root[definition.field]
        local weight = math.max(1, settings[definition.key].height)
        local height

        if index == #BAR_ORDER then
            height = availableHeight - consumedHeight
        else
            height = math.max(
                1,
                math.floor(availableHeight * weight / totalWeight + 0.5)
            )
            height = math.min(height, availableHeight - consumedHeight - 1)
        end

        setBarGeometry(bar, root.barsContainer, left, right, top, height)

        consumedHeight = consumedHeight + height
        top = top - height - LAYOUT.barSpacing
    end
end

-- Apply BFUF's SUF-style ordered bar and portrait layout in one pass.
function PlayerLayout:Apply(root)
    if InCombatLockdown() then
        root.layoutPending = true
        return
    end

    local settings = BFUF.DB:Get("Player")
    local portrait = settings.portrait
    local width = math.max(1, settings.width)
    local height = math.max(1, settings.height)
    local inset = LAYOUT.frameInset
    local innerWidth = math.max(1, width - inset * 2)
    local innerHeight = math.max(2, height - inset * 2)

    root:SetSize(width, height)
    root:SetScale(settings.scale)
    applyRootAnchor(root, settings)

    setRectangle(root.background, root, 0, 0, 0, 0)
    applyBorderGeometry(root.border)
    setRectangle(root.barsContainer, root, inset, -inset, -inset, inset)
    setRectangle(root.textContainer, root.barsContainer, 0, 0, 0, 0)
    setRectangle(root.statusIconsContainer, root, 0, 0, 0, 0)
    setRectangle(root.classResourceContainer, root, inset, -inset, -inset, inset)
    setRectangle(root.overlayContainer, root, inset, -inset, -inset, inset)

    local portraitVisible = portrait.mode ~= BFUF.Elements.Portrait.Modes.HIDDEN
    local barsLeft = 0

    if portraitVisible then
        local portraitWidth = math.min(
            math.max(1, portrait.width),
            math.max(1, innerWidth - 1)
        )

        setRectangle(
            root.portraitContainer,
            root,
            inset,
            -(width - inset - portraitWidth),
            -inset,
            inset
        )
        root.portraitContainer:Show()
        setRectangle(root.portrait, root.portraitContainer, 0, 0, 0, 0)
        setRectangle(root.portrait.texture, root.portrait, 0, 0, 0, 0)
        setRectangle(root.portrait.model, root.portrait, 0, 0, 0, 0)

        barsLeft = portraitWidth
    else
        root.portraitContainer:Hide()
    end

    resolveBarStack(root, settings, barsLeft, 0, innerHeight)
    setRectangle(root.healthBar.absorbBar, root.healthBar, 0, 0, 0, 0)
    setRectangle(root.healthBar.healAbsorbBar, root.healthBar, 0, 0, 0, 0)

    local texts = settings.texts
    setTextAnchor(root.nameText, "LEFT", root.healthBar, "LEFT", texts.name.offsetX, texts.name.offsetY)
    setTextAnchor(root.healthText, "RIGHT", root.healthBar, "RIGHT", texts.health.offsetX, texts.health.offsetY)
    setTextAnchor(root.powerText, "RIGHT", root.powerBar, "RIGHT", texts.power.offsetX, texts.power.offsetY)

    for name, indicator in pairs(root.indicators) do
        setIndicatorGeometry(
            indicator,
            root.statusIconsContainer,
            settings.indicators[name],
            INDICATOR_ANCHORS[name]
        )
    end

    root.portrait:SetMode(portrait.mode)
    root.healthBar:UpdateStyle()
    root.powerBar:UpdateStyle()
    root.layoutPending = false
end

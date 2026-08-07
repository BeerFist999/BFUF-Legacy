local addonName, BFUF = ...

BFUF.Layouts = BFUF.Layouts or {}

local PlayerLayout = {}
BFUF.Layouts.Player = PlayerLayout

local LAYOUT = {
    frameInset = 2,
    barSpacing = 2,
    borderThickness = 1,
    portraitFirstOrder = 0,
    portraitLastOrder = 50,
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

local function setBarGeometry(bar, parent, geometry)
    bar:ClearAllPoints()
    bar:SetPoint("TOPLEFT", parent, "TOPLEFT", geometry.left, geometry.top)
    bar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", geometry.right, geometry.top)
    bar:SetHeight(geometry.height)
end

local function printPortraitTiming(stage, container, region)
    BFUF:Print(string.format(
        "[BFUF Portrait Timing] %s W=%s H=%s ExpectedW=%s ExpectedH=%s Match=%s",
        stage,
        tostring(container:GetWidth()),
        tostring(container:GetHeight()),
        tostring(region.width),
        tostring(region.height),
        tostring(
            container:GetWidth() == region.width
                and container:GetHeight() == region.height
        )
    ))
end

-- Apply the LayoutResult dimensions directly to the portrait container.
local function setPortraitContainerGeometry(container, parent, region)
    container:ClearAllPoints()
    container:SetPoint("TOPLEFT", parent, "TOPLEFT", region.left, region.top)
    printPortraitTiming("Before SetSize", container, region)

    container:SetSize(region.width, region.height)
    printPortraitTiming("After SetSize", container, region)
end

local function setTextGeometry(text, geometry)
    text:ClearAllPoints()
    text:SetPoint(
        geometry.point,
        geometry.relativeTo,
        geometry.relativePoint,
        geometry.offsetX,
        geometry.offsetY
    )
end

local function applyBorderGeometry(border)
    local thickness = LAYOUT.borderThickness
    setRectangle(border, border:GetParent(), 0, 0, 0, 0)
    setRectangle(border.lines.top, border, 0, 0, 0, -thickness)
    setRectangle(border.lines.bottom, border, 0, 0, thickness, 0)
    setRectangle(border.lines.left, border, 0, thickness, 0, 0)
    setRectangle(border.lines.right, border, -thickness, 0, 0, 0)
end

local function applyRootAnchor(root, anchor)
    root:ClearAllPoints()
    root:SetPoint(anchor.point, UIParent, anchor.relativePoint, anchor.offsetX, anchor.offsetY)
end

-- Build the root data without changing visual components.
function PlayerLayout:SetupFrame(root, settings)
    local width = math.max(1, settings.width)
    local height = math.max(1, settings.height)
    local anchor = settings.positionAnchor or {
        point = "CENTER",
        relativePoint = "CENTER",
        offsetX = settings.positionX,
        offsetY = settings.positionY,
    }

    return {
        root = {
            width = width,
            height = height,
            scale = settings.scale,
            anchor = anchor,
            inset = LAYOUT.frameInset,
            innerWidth = math.max(1, width - LAYOUT.frameInset * 2),
            innerHeight = math.max(2, height - LAYOUT.frameInset * 2),
        },
        bars = {},
        portrait = {
            visible = settings.portrait.mode ~= BFUF.Elements.Portrait.Modes.HIDDEN,
            mode = settings.portrait.mode,
        },
        textRegions = {},
        indicatorRegions = {},
        layers = {
            backdrop = root.background,
            bars = root.barsContainer,
            portrait = root.portraitContainer,
            highFrame = root.highFrame,
            indicators = root.indicatorLayer,
            secureInteraction = root.interaction,
        },
    }
end

-- Collect all registered visual bars. Future modules only need to register a descriptor.
function PlayerLayout:CollectBars(root, settings, result)
    for _, descriptor in ipairs(root.layoutBars or {}) do
        local bar = descriptor.frame
        local section = settings[descriptor.settingsKey] or {}
        if bar and descriptor.enabled ~= false then
            table.insert(result.bars, {
                key = descriptor.key,
                frame = bar,
                order = descriptor.order,
                weight = math.max(1, section.height or descriptor.defaultWeight or 1),
                portraitCompatible = false,
            })
        end
    end
end

function PlayerLayout:SortBars(result)
    table.sort(result.bars, function(left, right)
        return left.order < right.order
    end)
end

-- Select the ordered bar range that shares horizontal space with the portrait.
function PlayerLayout:ComputePortraitRegion(settings, result)
    local region = result.portrait
    if not region.visible then
        return
    end

    local firstOrder = settings.portrait.fullBefore or LAYOUT.portraitFirstOrder
    local lastOrder = settings.portrait.fullAfter or LAYOUT.portraitLastOrder
    local totalWidth = result.root.innerWidth
    local portraitWidth = math.min(
        math.max(1, settings.portrait.width),
        math.max(1, totalWidth - 1)
    )

    region.width = portraitWidth
    region.left = result.root.inset
    region.right = -(result.root.width - result.root.inset - portraitWidth)
    region.firstBar = nil
    region.lastBar = nil

    for _, bar in ipairs(result.bars) do
        if bar.order >= firstOrder and bar.order <= lastOrder then
            bar.portraitCompatible = true
            region.firstBar = region.firstBar or bar
            region.lastBar = bar
        end
    end

    if not region.firstBar then
        region.visible = false
    end
end

-- Resolve every bar from order and weight. No component chooses its own geometry.
function PlayerLayout:ComputeBarGeometry(result)
    local count = #result.bars
    if count == 0 then
        return
    end

    local totalWeight = 0
    for _, bar in ipairs(result.bars) do
        totalWeight = totalWeight + bar.weight
    end

    local availableHeight = math.max(
        count,
        result.root.innerHeight - LAYOUT.barSpacing * (count - 1)
    )
    local consumedHeight = 0
    local top = -result.root.inset

    for index, bar in ipairs(result.bars) do
        local height
        if index == count then
            height = availableHeight - consumedHeight
        else
            height = math.max(1, math.floor(availableHeight * bar.weight / totalWeight + 0.5))
            height = math.min(height, availableHeight - consumedHeight - (count - index))
        end

        local left = result.root.inset
        local right = -result.root.inset
        if result.portrait.visible and bar.portraitCompatible then
            left = left + result.portrait.width
        end

        bar.geometry = {
            left = left,
            right = right,
            top = top,
            height = height,
            bottom = top - height,
        }

        consumedHeight = consumedHeight + height
        top = top - height - LAYOUT.barSpacing
    end

    local portrait = result.portrait
    if portrait.visible then
        portrait.top = portrait.firstBar.geometry.top
        portrait.bottom = portrait.lastBar.geometry.bottom
        portrait.height = portrait.top - portrait.bottom
    end
end

function PlayerLayout:ComputeTextRegions(settings, result)
    local bars = {}
    for _, bar in ipairs(result.bars) do
        bars[bar.key] = bar.frame
    end

    local texts = settings.texts
    result.textRegions.name = {
        point = "LEFT",
        relativeTo = bars.health,
        relativePoint = "LEFT",
        offsetX = texts.name.offsetX,
        offsetY = texts.name.offsetY,
    }
    result.textRegions.health = {
        point = "RIGHT",
        relativeTo = bars.health,
        relativePoint = "RIGHT",
        offsetX = texts.health.offsetX,
        offsetY = texts.health.offsetY,
    }
    result.textRegions.power = {
        point = "RIGHT",
        relativeTo = bars.power,
        relativePoint = "RIGHT",
        offsetX = texts.power.offsetX,
        offsetY = texts.power.offsetY,
    }
end

function PlayerLayout:ComputeIndicatorRegions(settings, result)
    for name, settingsEntry in pairs(settings.indicators) do
        local anchor = INDICATOR_ANCHORS[name]
        if anchor then
            result.indicatorRegions[name] = {
                point = anchor.point,
                relativePoint = anchor.relativePoint,
                offsetX = settingsEntry.offsetX,
                offsetY = settingsEntry.offsetY,
                size = settingsEntry.size,
            }
        end
    end
end

function PlayerLayout:ApplyLayout(root, result)
    root:SetSize(result.root.width, result.root.height)
    root:SetScale(result.root.scale)
    applyRootAnchor(root, result.root.anchor)

    -- Apply the visual layer order without changing layout geometry.
    local rootLevel = root:GetFrameLevel()
    root.portraitContainer:SetFrameLevel(rootLevel + 2)
    root.barsContainer:SetFrameLevel(rootLevel + 3)
    root.highFrame:SetFrameLevel(rootLevel + 4)
    root.classResourceContainer:SetFrameLevel(rootLevel + 4)
    root.indicatorLayer:SetFrameLevel(rootLevel + 5)
    root.overlayContainer:SetFrameLevel(rootLevel + 6)

    setRectangle(root.background, root, 0, 0, 0, 0)
    applyBorderGeometry(root.border)
    setRectangle(root.barsContainer, root, 0, 0, 0, 0)
    setRectangle(root.highFrame, root, 0, 0, 0, 0)
    setRectangle(root.indicatorLayer, root, 0, 0, 0, 0)
    setRectangle(root.classResourceContainer, root, 0, 0, 0, 0)
    setRectangle(root.overlayContainer, root, 0, 0, 0, 0)

    for _, bar in ipairs(result.bars) do
        setBarGeometry(bar.frame, root.barsContainer, bar.geometry)
        if bar.frame.background then
            setRectangle(bar.frame.background, bar.frame, 0, 0, 0, 0)
        end
    end

    setRectangle(root.healthBar.absorbBar, root.healthBar, 0, 0, 0, 0)
    setRectangle(root.healthBar.healAbsorbBar, root.healthBar, 0, 0, 0, 0)

    if result.portrait.visible then
        setPortraitContainerGeometry(root.portraitContainer, root, result.portrait)
        setRectangle(root.portrait, root.portraitContainer, 2, -2, -2, 2)
        setRectangle(root.portrait.texture, root.portrait, 0, 0, 0, 0)
        setRectangle(root.portrait.model, root.portrait, 0, 0, 0, 0)
        root.portraitContainer:Show()

        local compatibleBarCount = 0
        local compatibleBarHeight = 0
        for _, bar in ipairs(result.bars) do
            if bar.portraitCompatible then
                compatibleBarCount = compatibleBarCount + 1
                compatibleBarHeight = compatibleBarHeight + bar.geometry.height
            end
        end

        local groupHeight = compatibleBarHeight + LAYOUT.barSpacing * math.max(0, compatibleBarCount - 1)
        local regionHeight = result.portrait.height
        BFUF:Print(string.format(
            "[BFUF Portrait] RootH=%.2f HealthH=%.2f PowerH=%.2f Gap=%.2f RegionW=%.2f RegionH=%.2f ContainerH=%.2f GroupH=%.2f Match=%s",
            root:GetHeight(),
            root.healthBar:GetHeight(),
            root.powerBar:GetHeight(),
            LAYOUT.barSpacing,
            result.portrait.width,
            regionHeight,
            root.portraitContainer:GetHeight(),
            groupHeight,
            tostring(regionHeight == groupHeight)
        ))
    else
        root.portraitContainer:Hide()
    end

    setTextGeometry(root.nameText, result.textRegions.name)
    setTextGeometry(root.healthText, result.textRegions.health)
    setTextGeometry(root.powerText, result.textRegions.power)

    for name, region in pairs(result.indicatorRegions) do
        local indicator = root.indicators[name]
        if indicator then
            setRectangle(indicator.holder, root.indicatorLayer, 0, 0, 0, 0)
            indicator:ClearAllPoints()
            indicator:SetSize(region.size, region.size)
            indicator:SetPoint(
                region.point,
                root.indicatorLayer,
                region.relativePoint,
                region.offsetX,
                region.offsetY
            )
        end
    end

    if result.portrait.visible then
        printPortraitTiming("After ApplyLayout", root.portraitContainer, result.portrait)
        C_Timer.After(0, function()
            printPortraitTiming("Next Frame", root.portraitContainer, result.portrait)
        end)
    end
end

function PlayerLayout:NotifyModules(root, result)
    root.portrait:SetMode(result.portrait.mode)
    root.healthBar:UpdateStyle()
    root.powerBar:UpdateStyle()

    for _, module in ipairs(root.layoutModules or {}) do
        if module.OnLayoutApplied then
            module:OnLayoutApplied(root, result)
        end
    end
end

-- Run the complete Player layout pipeline from a single authority.
function PlayerLayout:Apply(root)
    if InCombatLockdown() then
        root.layoutPending = true
        return
    end

    local settings = BFUF.DB:Get("Player")
    local result = self:SetupFrame(root, settings)
    self:CollectBars(root, settings, result)
    self:SortBars(result)
    self:ComputePortraitRegion(settings, result)
    self:ComputeBarGeometry(result)
    self:ComputeTextRegions(settings, result)
    self:ComputeIndicatorRegions(settings, result)
    self:ApplyLayout(root, result)
    self:NotifyModules(root, result)

    root.layoutResult = result
    root.layoutPending = false
end

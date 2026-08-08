local addonName, BFUF = ...

BFUF.Frames = BFUF.Frames or {}

local Boss = {}
BFUF.Frames.Boss = Boss

local MAX_BOSS_FRAMES = 5

local PERCENT_CURVE = C_CurveUtil.CreateCurve()
PERCENT_CURVE:SetType(Enum.LuaCurveType.Linear)
PERCENT_CURVE:AddPoint(0, 0)
PERCENT_CURVE:AddPoint(1, 100)

local function copyDefaults(source, destination)
    for key, value in pairs(source) do
        if type(value) == "table" then
            destination[key] = destination[key] or {}
            copyDefaults(value, destination[key])
        elseif destination[key] == nil then
            destination[key] = value
        end
    end
end

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


local function createPreviewFrame(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame.background = frame:CreateTexture(nil, "BACKGROUND", nil, 0)
    frame.background:SetColorTexture(0, 0, 0, 0.8)
    frame.border = createBorder(frame)

    frame.portraitContainer = CreateFrame("Frame", nil, frame)
    frame.portraitContainer:SetFrameLevel(frame:GetFrameLevel() + 2)
    frame.portraitContainer:SetClipsChildren(true)

    frame.portrait = frame.portraitContainer:CreateTexture(nil, "ARTWORK")
    frame.portrait:SetAllPoints(frame.portraitContainer)
    frame.portrait:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    frame.barsContainer = CreateFrame("Frame", nil, frame)
    frame.barsContainer:SetFrameLevel(frame:GetFrameLevel() + 3)

    frame.highFrame = CreateFrame("Frame", nil, frame)
    frame.highFrame:SetFrameLevel(frame:GetFrameLevel() + 4)
    frame.highFrame:SetClipsChildren(true)

    frame.healthBar = CreateFrame("StatusBar", nil, frame.barsContainer)
    frame.healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    frame.healthBar:SetMinMaxValues(0, 100)
    frame.healthBar:SetStatusBarColor(0.8, 0.15, 0.15)

    frame.powerBar = CreateFrame("StatusBar", nil, frame.barsContainer)
    frame.powerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    frame.powerBar:SetMinMaxValues(0, 100)
    frame.powerBar:SetStatusBarColor(0.2, 0.4, 1)

    frame.nameText = BFUF.Elements.Text:Create(frame.highFrame, {
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        size = 12,
    })
    frame.nameText:SetWordWrap(false)
    frame.nameText:SetMaxLines(1)

    frame.healthText = BFUF.Elements.Text:Create(frame.highFrame, {
        justifyH = "RIGHT",
        justifyV = "MIDDLE",
        size = 12,
    })

    frame.powerText = BFUF.Elements.Text:Create(frame.highFrame, {
        justifyH = "RIGHT",
        justifyV = "MIDDLE",
        size = 11,
    })

    return frame
end

local function applyTextLayout(frame, settings)
    frame.nameText:ClearAllPoints()
    frame.nameText:SetPoint("LEFT", frame.healthBar, "LEFT", 4, 0)
    frame.nameText:SetShown(settings.showName ~= false)

    frame.healthText:ClearAllPoints()
    frame.healthText:SetPoint("RIGHT", frame.healthBar, "RIGHT", -4, 0)
    frame.healthText:SetShown(settings.showHealthText ~= false)

    if settings.showHealthText ~= false then
        frame.nameText:SetPoint("RIGHT", frame.healthText, "LEFT", -6, 0)
    else
        frame.nameText:SetPoint("RIGHT", frame.healthBar, "RIGHT", -4, 0)
    end

    frame.powerText:ClearAllPoints()
    frame.powerText:SetPoint("RIGHT", frame.powerBar, "RIGHT", -4, 0)
    frame.powerText:SetShown(settings.showPowerText ~= false)
end

local function setHealthText(text, unit, format)
    local current = UnitHealth(unit)
    local maximum = UnitHealthMax(unit)

    if format == "percent" then
        text:SetFormattedText("%.0f%%", UnitHealthPercent(unit, true, PERCENT_CURVE))
    elseif format == "currentPercent" then
        text:SetFormattedText("%d (%.0f%%)", current, UnitHealthPercent(unit, true, PERCENT_CURVE))
    else
        text:SetFormattedText("%d / %d", current, maximum)
    end
end

local function setPowerText(text, unit, format)
    local powerType = UnitPowerType(unit)

    if format == "percent" then
        text:SetFormattedText("%.0f%%", UnitPowerPercent(unit, powerType, false, PERCENT_CURVE))
    else
        text:SetFormattedText("%d", UnitPower(unit, powerType))
    end
end

local function formatPreviewHealth(current, maximum, format)
    if format == "percent" then
        return string.format("%.0f%%", current / maximum * 100)
    elseif format == "currentPercent" then
        return string.format("%d (%.0f%%)", current, current / maximum * 100)
    end

    return string.format("%d / %d", current, maximum)
end

local function formatPreviewPower(current, maximum, format)
    if format == "percent" then
        return string.format("%.0f%%", current / maximum * 100)
    end

    return string.format("%d", current)
end

local function applyPreviewBorder(frame)
    frame.border:ClearAllPoints()
    frame.border:SetAllPoints(frame)

    local top = frame.border.lines.top
    top:ClearAllPoints()
    top:SetPoint("TOPLEFT", frame.border, "TOPLEFT")
    top:SetPoint("TOPRIGHT", frame.border, "TOPRIGHT")
    top:SetHeight(1)

    local bottom = frame.border.lines.bottom
    bottom:ClearAllPoints()
    bottom:SetPoint("BOTTOMLEFT", frame.border, "BOTTOMLEFT")
    bottom:SetPoint("BOTTOMRIGHT", frame.border, "BOTTOMRIGHT")
    bottom:SetHeight(1)

    local left = frame.border.lines.left
    left:ClearAllPoints()
    left:SetPoint("TOPLEFT", frame.border, "TOPLEFT")
    left:SetPoint("BOTTOMLEFT", frame.border, "BOTTOMLEFT")
    left:SetWidth(1)

    local right = frame.border.lines.right
    right:ClearAllPoints()
    right:SetPoint("TOPRIGHT", frame.border, "TOPRIGHT")
    right:SetPoint("BOTTOMRIGHT", frame.border, "BOTTOMRIGHT")
    right:SetWidth(1)
end

local function applyPreviewGeometry(frame, previous, settings, index)
    frame:ClearAllPoints()
    frame:SetSize(settings.width, settings.height)
    frame:SetScale(settings.scale or 1)

    if index == 1 then
        frame:SetAllPoints(frame:GetParent())
    elseif settings.growth == "UP" then
        frame:SetPoint("BOTTOMLEFT", previous, "TOPLEFT", 0, settings.spacing or 0)
    else
        frame:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -(settings.spacing or 0))
    end

    frame.background:ClearAllPoints()
    frame.background:SetAllPoints(frame)
    applyPreviewBorder(frame)

    local portraitEnabled = settings.portrait and settings.portrait.enabled ~= false
    frame.portraitContainer:SetShown(portraitEnabled)
    frame.portraitContainer:ClearAllPoints()

    if portraitEnabled then
        frame.portraitContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
        frame.portraitContainer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 2, 2)
        frame.portraitContainer:SetWidth(settings.portrait.width)
        frame.barsContainer:ClearAllPoints()
        frame.barsContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 4 + settings.portrait.width, -2)
        frame.barsContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    else
        frame.barsContainer:ClearAllPoints()
        frame.barsContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
        frame.barsContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    end

    frame.powerBar:ClearAllPoints()
    frame.powerBar:SetPoint("BOTTOMLEFT", frame.barsContainer, "BOTTOMLEFT")
    frame.powerBar:SetPoint("BOTTOMRIGHT", frame.barsContainer, "BOTTOMRIGHT")
    frame.powerBar:SetHeight(8)

    frame.healthBar:ClearAllPoints()
    frame.healthBar:SetPoint("TOPLEFT", frame.barsContainer, "TOPLEFT")
    frame.healthBar:SetPoint("TOPRIGHT", frame.barsContainer, "TOPRIGHT")
    frame.healthBar:SetPoint("BOTTOMLEFT", frame.powerBar, "TOPLEFT", 0, 2)
    frame.healthBar:SetPoint("BOTTOMRIGHT", frame.powerBar, "TOPRIGHT", 0, 2)

    frame.highFrame:ClearAllPoints()
    frame.highFrame:SetAllPoints(frame.barsContainer)
    applyTextLayout(frame, settings)
end

function Boss:HidePreview()
    if self.previewAnchor then
        self.previewAnchor:Hide()
    end
end

function Boss:SavePreviewPosition()
    if not self.previewAnchor then
        return
    end

    local point, _, relativePoint, x, y = self.previewAnchor:GetPoint()
    local position = self:EnsurePosition()
    position.point = point
    position.relativePoint = relativePoint
    position.x = x
    position.y = y
    self:UpdateLayout()
end

function Boss:CreatePreviewAnchor()
    if self.previewAnchor then
        return self.previewAnchor
    end

    local anchor = CreateFrame("Frame", nil, UIParent)
    anchor:SetMovable(true)
    anchor:RegisterForDrag("LeftButton")
    anchor:SetClampedToScreen(true)

    anchor:SetScript("OnDragStart", function(frame)
        if frame.unlocked and not InCombatLockdown() then
            frame.dragging = true
            frame:StartMoving()
        end
    end)

    anchor:SetScript("OnDragStop", function(frame)
        if not frame.dragging then
            return
        end

        frame:StopMovingOrSizing()
        frame.dragging = false
        Boss:SavePreviewPosition()
    end)

    self.previewAnchor = anchor
    return anchor
end

function Boss:UpdatePreview(settings)
    settings = settings or self:EnsureSettings()
    settings.position = settings.position or self:EnsurePosition()

    if not settings.preview or InCombatLockdown() then
        self:HidePreview()
        return
    end

    local anchor = self:CreatePreviewAnchor()
    self.previewFrames = self.previewFrames or {}
    local previous
    local count = math.max(1, math.min(MAX_BOSS_FRAMES, settings.count or MAX_BOSS_FRAMES))

    anchor:SetSize(settings.width, settings.height)
    anchor:SetShown(true)
    anchor.unlocked = settings.previewUnlocked == true
    anchor:EnableMouse(anchor.unlocked)

    if not anchor.dragging then
        anchor:ClearAllPoints()
        anchor:SetPoint(
            settings.position.point,
            UIParent,
            settings.position.relativePoint,
            settings.position.x,
            settings.position.y
        )
    end

    for index = 1, MAX_BOSS_FRAMES do
        local frame = self.previewFrames[index]
        if not frame then
            frame = createPreviewFrame(anchor)
            self.previewFrames[index] = frame
        end

        if index <= count then
            applyPreviewGeometry(frame, previous, settings, index)
            local health = math.max(20, 100 - (index - 1) * 15)
            local power = 100 - (index - 1) * 10
            frame.healthBar:SetValue(health)
            frame.powerBar:SetValue(power)
            frame.nameText:SetText("Boss " .. index)
            frame.healthText:SetText(formatPreviewHealth(health, 100, settings.healthTextFormat))
            frame.powerText:SetText(formatPreviewPower(power, 100, settings.powerTextFormat))
            frame:Show()
            previous = frame
        else
            frame:Hide()
        end
    end
end

function Boss:EnsureSettings()
    local settings = BFUF.DB:Get("Boss")
    copyDefaults(BFUF.Defaults.profile.Boss, settings)
    return settings
end

function Boss:EnsurePosition()
    local storage = BFUF.DB:Get("BossFrames")
    storage.position = storage.position or {}

    local position = storage.position
    local legacy = BFUF.DB:Get("Boss")
    local defaults = BFUF.Defaults.profile.BossFrames.position

    position.point = position.point or defaults.point
    position.relativePoint = position.relativePoint or defaults.relativePoint
    position.x = position.x or legacy.positionX or defaults.x
    position.y = position.y or legacy.positionY or defaults.y

    return position
end

function Boss:UpdateTexts(root)
    local settings = self:EnsureSettings()
    local unit = root.unit

    root.nameText:SetText(UnitName(unit) or "")
    setHealthText(root.healthText, unit, settings.healthTextFormat)
    setPowerText(root.powerText, unit, settings.powerTextFormat)
end

function Boss:Update(root)
    if not root or not root.enabled then
        return
    end

    applyTextLayout(root, self:EnsureSettings())
    root.portrait:Update()
    root.healthBar:Update()
    root.powerBar:Update()
    self:UpdateTexts(root)
end

function Boss:UpdateLayout()
    local settings = self:EnsureSettings()
    settings.position = self:EnsurePosition()
    local previous

    for index = 1, MAX_BOSS_FRAMES do
        local root = BFUF.Framework.Registry:GetFrame("boss" .. index)
        if root then
            BFUF.Layouts.Boss:Apply(root, previous, settings)
            if root.enabled then
                self:Update(root)
                previous = root
            end
        end
    end

    self:UpdatePreview(settings)
end

local function createBossFrame(index)
    local unit = "boss" .. index
    local root = CreateFrame("Button", nil, UIParent, "SecureUnitButtonTemplate")
    root.unit = unit
    root.index = index
    root:SetAttribute("unit", unit)

    local rootLevel = root:GetFrameLevel()
    root.background = root:CreateTexture(nil, "BACKGROUND", nil, 0)
    root.background:SetColorTexture(0, 0, 0, 0.8)
    root.border = createBorder(root)

    root.portraitContainer = CreateFrame("Frame", nil, root)
    root.portraitContainer:SetFrameLevel(rootLevel + 2)
    root.portraitContainer:SetClipsChildren(true)

    root.barsContainer = CreateFrame("Frame", nil, root)
    root.barsContainer:SetFrameLevel(rootLevel + 3)

    root.highFrame = CreateFrame("Frame", nil, root)
    root.highFrame:SetFrameLevel(rootLevel + 4)
    root.highFrame:SetClipsChildren(true)

    root.portrait = BFUF.Elements.Portrait:Create(root.portraitContainer, {
        frame = root,
        unit = unit,
        unitType = "Boss",
        getSettings = function()
            return Boss:EnsureSettings().portrait
        end,
    })
    root.portrait:ApplyLayout({
        parent = root.portraitContainer,
        left = 0,
        right = 0,
        top = 0,
        bottom = 0,
    })
    root.portrait:SetUnit(unit)

    root.healthBar = BFUF.Elements.Health:Create(root.barsContainer, {
        frame = root,
        unit = unit,
        unitType = "Boss",
        getSettings = function()
            -- Boss frames retain the existing shared health policy until a
            -- separate Boss health-settings sprint introduces its own profile.
            return BFUF.DB:Get("Player").health
        end,
    })
    root.healthBar:SetUnit(unit)
    root.healthBar:SetColorResolver(BFUF.Utils.GetUnitHealthColor)
    root.healthBar.background = root.healthBar:CreateTexture(nil, "BACKGROUND")
    root.healthBar.background:SetColorTexture(0, 0, 0, 0.2)

    root.powerBar = BFUF.Elements.Power:Create(root.barsContainer)
    root.powerBar:SetUnit(unit)
    root.powerBar.background = root.powerBar:CreateTexture(nil, "BACKGROUND")
    root.powerBar.background:SetColorTexture(0, 0, 0, 0.2)

    root.nameText = BFUF.Elements.Text:Create(root.highFrame, {
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        size = 12,
    })
    root.nameText:SetWordWrap(false)
    root.nameText:SetMaxLines(1)
    root.nameText:SetPoint("LEFT", root.healthBar, "LEFT", 4, 0)

    root.healthText = BFUF.Elements.Text:Create(root.highFrame, {
        justifyH = "RIGHT",
        justifyV = "MIDDLE",
        size = 12,
    })
    root.healthText:SetPoint("RIGHT", root.healthBar, "RIGHT", -4, 0)
    root.nameText:SetPoint("RIGHT", root.healthText, "LEFT", -6, 0)

    root.powerText = BFUF.Elements.Text:Create(root.highFrame, {
        justifyH = "RIGHT",
        justifyV = "MIDDLE",
        size = 11,
    })
    root.powerText:SetPoint("RIGHT", root.powerBar, "RIGHT", -4, 0)

    -- UnitWatch can show a newly available boss without a subsequent unit event.
    -- Refresh only after the visible secure root has its unit data available.
    root:HookScript("OnShow", function(frame)
        Boss:Update(frame)
    end)

    root:RegisterEvent("PLAYER_ENTERING_WORLD")
    root:RegisterEvent("PLAYER_REGEN_ENABLED")
    root:RegisterEvent("PLAYER_REGEN_DISABLED")
    root:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    root:RegisterEvent("UNIT_HEALTH")
    root:RegisterEvent("UNIT_MAXHEALTH")
    root:RegisterEvent("UNIT_POWER_UPDATE")
    root:RegisterEvent("UNIT_MAXPOWER")
    root:RegisterEvent("UNIT_DISPLAYPOWER")
    root:RegisterEvent("UNIT_NAME_UPDATE")

    root:SetScript("OnEvent", function(frame, event, eventUnit)
        if event == "PLAYER_REGEN_DISABLED" then
            Boss:HidePreview()
            return
        end

        if event == "PLAYER_REGEN_ENABLED" then
            if frame.layoutPending then
                Boss:UpdateLayout()
            else
                Boss:UpdatePreview()
            end
            return
        end

        if event == "PLAYER_ENTERING_WORLD" or event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
            Boss:Update(frame)
        elseif eventUnit == frame.unit then
            Boss:Update(frame)
        end
    end)

    BFUF.Framework.Registry:RegisterFrame(unit, root)
    return root
end

-- Create the fixed boss1-boss5 group and let UnitWatch manage each secure root.
function Boss:Create()
    self:EnsureSettings()

    local frames = {}
    for index = 1, MAX_BOSS_FRAMES do
        local unit = "boss" .. index
        local root = BFUF.Framework.Registry:GetFrame(unit)
        if not root then
            root = createBossFrame(index)
        end
        frames[index] = root
    end

    self:UpdateLayout()

    -- Populate any boss units that already exist when the frame group is created.
    for _, root in ipairs(frames) do
        if root.enabled then
            self:Update(root)
        end
    end

    return frames
end

local addonName, BFUF = ...

BFUF.Frames = BFUF.Frames or {}

local Boss = {}
BFUF.Frames.Boss = Boss

local MAX_BOSS_FRAMES = 5

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

    frame.healthBar = CreateFrame("StatusBar", nil, frame.barsContainer)
    frame.healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    frame.healthBar:SetMinMaxValues(0, 100)
    frame.healthBar:SetStatusBarColor(0.8, 0.15, 0.15)

    frame.powerBar = CreateFrame("StatusBar", nil, frame.barsContainer)
    frame.powerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    frame.powerBar:SetMinMaxValues(0, 100)
    frame.powerBar:SetStatusBarColor(0.2, 0.4, 1)

    frame.nameText = BFUF.Elements.Text:Create(frame.barsContainer, {
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        size = 12,
    })
    frame.nameText:SetWordWrap(false)
    frame.nameText:SetMaxLines(1)

    frame.healthText = BFUF.Elements.Text:Create(frame.barsContainer, {
        justifyH = "RIGHT",
        justifyV = "MIDDLE",
        size = 12,
    })

    return frame
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
        frame:SetPoint("CENTER", UIParent, "CENTER", settings.positionX or 0, settings.positionY or 0)
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

    frame.nameText:ClearAllPoints()
    frame.nameText:SetPoint("LEFT", frame.healthBar, "LEFT", 4, 0)
    frame.nameText:SetPoint("RIGHT", frame.healthText, "LEFT", -6, 0)
    frame.healthText:ClearAllPoints()
    frame.healthText:SetPoint("RIGHT", frame.healthBar, "RIGHT", -4, 0)
end

function Boss:HidePreview()
    if self.previewFrames then
        for _, frame in ipairs(self.previewFrames) do
            frame:Hide()
        end
    end
end

function Boss:UpdatePreview(settings)
    settings = settings or self:EnsureSettings()

    if not settings.preview or InCombatLockdown() then
        self:HidePreview()
        return
    end

    self.previewFrames = self.previewFrames or {}
    local previous
    local count = math.max(1, math.min(MAX_BOSS_FRAMES, settings.count or MAX_BOSS_FRAMES))

    for index = 1, MAX_BOSS_FRAMES do
        local frame = self.previewFrames[index]
        if not frame then
            frame = createPreviewFrame(UIParent)
            self.previewFrames[index] = frame
        end

        if index <= count then
            applyPreviewGeometry(frame, previous, settings, index)
            local health = math.max(20, 100 - (index - 1) * 15)
            frame.healthBar:SetValue(health)
            frame.powerBar:SetValue(100 - (index - 1) * 10)
            frame.nameText:SetText("Boss " .. index)
            frame.healthText:SetText(health .. "%")
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

function Boss:UpdateTexts(root)
    local unit = root.unit
    root.nameText:SetText(UnitName(unit))
    root.healthText:SetText(UnitHealth(unit))
    root.powerText:SetText(UnitPower(unit, UnitPowerType(unit)))
end

function Boss:Update(root)
    if not root or not root.enabled then
        return
    end

    root.portrait:Update()
    root.healthBar:Update()
    root.powerBar:Update()
    self:UpdateTexts(root)
end

function Boss:UpdateLayout()
    local settings = self:EnsureSettings()
    local previous

    for index = 1, MAX_BOSS_FRAMES do
        local root = BFUF.Framework.Registry:GetFrame("boss" .. index)
        if root then
            BFUF.Layouts.Boss:Apply(root, previous, settings)
            if root.enabled then
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

    root.portrait = BFUF.Elements.Portrait:Create(root.portraitContainer)
    root.portrait:SetAllPoints(root.portraitContainer)
    root.portrait:SetUnit(unit)

    root.healthBar = BFUF.Elements.Health:Create(root.barsContainer)
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
    return frames
end

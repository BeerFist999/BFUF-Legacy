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
    root:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    root:RegisterEvent("UNIT_HEALTH")
    root:RegisterEvent("UNIT_MAXHEALTH")
    root:RegisterEvent("UNIT_POWER_UPDATE")
    root:RegisterEvent("UNIT_MAXPOWER")
    root:RegisterEvent("UNIT_DISPLAYPOWER")
    root:RegisterEvent("UNIT_NAME_UPDATE")

    root:SetScript("OnEvent", function(frame, event, eventUnit)
        if event == "PLAYER_REGEN_ENABLED" and frame.layoutPending then
            Boss:UpdateLayout()
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

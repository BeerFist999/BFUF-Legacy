local addonName, BFUF = ...

local Player = {}
BFUF.Config.Player = Player

local LAYOUT_OPTIONS = {
    {
        key = "width",
        variable = "BFUF_PLAYER_FRAME_WIDTH",
        label = "OPTION_FRAME_WIDTH",
        minValue = 120,
        maxValue = 600,
        step = 1,
    },
    {
        key = "height",
        variable = "BFUF_PLAYER_FRAME_HEIGHT",
        label = "OPTION_FRAME_HEIGHT",
        minValue = 20,
        maxValue = 200,
        step = 1,
    },
    {
        key = "scale",
        variable = "BFUF_PLAYER_FRAME_SCALE",
        label = "OPTION_FRAME_SCALE",
        minValue = 0.5,
        maxValue = 2,
        step = 0.05,
    },
    {
        key = "positionX",
        variable = "BFUF_PLAYER_POSITION_X",
        label = "OPTION_POSITION_X",
        minValue = -1000,
        maxValue = 1000,
        step = 1,
    },
    {
        key = "positionY",
        variable = "BFUF_PLAYER_POSITION_Y",
        label = "OPTION_POSITION_Y",
        minValue = -1000,
        maxValue = 1000,
        step = 1,
    },
}

local function formatValue(value, step)
    if step < 1 then
        return string.format("%.2f", value)
    end

    return string.format("%.0f", value)
end

local function normalizeValue(value, option)
    value = math.max(option.minValue, math.min(option.maxValue, value))
    return math.floor((value - option.minValue) / option.step + 0.5) * option.step + option.minValue
end

-- Create one Blizzard slider with a numeric input field.
local function createLayoutControl(parent, option, yOffset, controls)
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    slider:SetWidth(280)
    slider:SetMinMaxValues(option.minValue, option.maxValue)
    slider:SetValueStep(option.step)
    slider:SetObeyStepOnDrag(true)
    slider.Text:SetText(BFUF.L[option.label])
    slider.Low:SetText(formatValue(option.minValue, option.step))
    slider.High:SetText(formatValue(option.maxValue, option.step))

    local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    input:SetPoint("LEFT", slider, "RIGHT", 35, 0)
    input:SetSize(70, 20)
    input:SetAutoFocus(false)
    input:SetJustifyH("CENTER")

    local function setValue(value)
        value = normalizeValue(value, option)
        BFUF.DB:Get("Player")[option.key] = value
        BFUF.Frames.Player:UpdateLayout()

        if slider:GetValue() ~= value then
            slider:SetValue(value)
        end

        input:SetText(formatValue(value, option.step))
    end

    slider:SetScript("OnValueChanged", function(_, value)
        setValue(value)
    end)

    local function applyInput()
        local value = tonumber(input:GetText())

        if value then
            setValue(value)
        else
            input:SetText(formatValue(BFUF.DB:Get("Player")[option.key], option.step))
        end

        input:ClearFocus()
    end

    input:SetScript("OnEnterPressed", applyInput)
    input:SetScript("OnEditFocusLost", applyInput)

    local value = BFUF.DB:Get("Player")[option.key]
    slider:SetValue(value)
    input:SetText(formatValue(value, option.step))

    controls[option.key] = {
        slider = slider,
        input = input,
        option = option,
    }
end

-- Create the Player category with live layout controls.
function Player:Create(parentCategory)
    local frame = CreateFrame("Frame")
    local category = Settings.RegisterCanvasLayoutSubcategory(
        parentCategory,
        frame,
        BFUF.L.CATEGORY_PLAYER
    )

    local portraitCheckbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    portraitCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -20)
    portraitCheckbox:SetChecked(BFUF.DB:Get("Player").showPortrait)

    local portraitLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    portraitLabel:SetPoint("LEFT", portraitCheckbox, "RIGHT", 2, 0)
    portraitLabel:SetText(BFUF.L.OPTION_SHOW_PORTRAIT)

    portraitCheckbox:SetScript("OnClick", function(self)
        BFUF.DB:Get("Player").showPortrait = self:GetChecked()
        BFUF.Frames.Player:UpdatePortrait()
    end)

    local sectionTitle = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    sectionTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -65)
    sectionTitle:SetText(BFUF.L.SECTION_LAYOUT)

    local controls = {}
    for index, option in ipairs(LAYOUT_OPTIONS) do
        createLayoutControl(frame, option, -95 - (index - 1) * 60, controls)
    end

    local resetButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    resetButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -405)
    resetButton:SetSize(180, 24)
    resetButton:SetText(BFUF.L.BUTTON_RESET_LAYOUT)
    resetButton:SetScript("OnClick", function()
        local settings = BFUF.DB:Get("Player")
        local defaults = BFUF.Defaults.profile.Player

        for _, option in ipairs(LAYOUT_OPTIONS) do
            settings[option.key] = defaults[option.key]
            controls[option.key].slider:SetValue(defaults[option.key])
            controls[option.key].input:SetText(formatValue(defaults[option.key], option.step))
        end

        BFUF.Frames.Player:UpdateLayout()
    end)

    return category
end

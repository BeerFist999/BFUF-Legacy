local addonName, BFUF = ...

local Player = {}
BFUF.Config.Player = Player

local NUMBER_OPTIONS = {
    width = { label = "OPTION_FRAME_WIDTH", minValue = 120, maxValue = 600, step = 1 },
    height = { label = "OPTION_FRAME_HEIGHT", minValue = 20, maxValue = 200, step = 1 },
    scale = { label = "OPTION_FRAME_SCALE", minValue = 0.5, maxValue = 2, step = 0.05 },
    positionX = { label = "OPTION_POSITION_X", minValue = -1000, maxValue = 1000, step = 1 },
    positionY = { label = "OPTION_POSITION_Y", minValue = -1000, maxValue = 1000, step = 1 },
}

local function formatValue(value, step)
    return step < 1 and string.format("%.2f", value) or string.format("%.0f", value)
end

local function normalizeValue(value, option)
    value = math.max(option.minValue, math.min(option.maxValue, value))
    return math.floor((value - option.minValue) / option.step + 0.5) * option.step + option.minValue
end

local function getSection(path)
    local section = BFUF.DB:Get("Player")
    for _, key in ipairs(path) do
        section = section[key]
    end
    return section
end

local function createLabel(parent, text, y)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
    label:SetText(text)
    return label
end

local function createCheckbox(parent, text, y, getValue, setValue)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
    checkbox:SetChecked(getValue())
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("LEFT", checkbox, "RIGHT", 2, 0)
    label:SetText(text)
    checkbox:SetScript("OnClick", function(self)
        setValue(self:GetChecked())
    end)
    return checkbox
end

local function createSlider(parent, text, y, option, getValue, setValue, controls, controlKey)
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
    slider:SetWidth(280)
    slider:SetMinMaxValues(option.minValue, option.maxValue)
    slider:SetValueStep(option.step)
    slider:SetObeyStepOnDrag(true)
    slider.Text:SetText(text)
    slider.Low:SetText(formatValue(option.minValue, option.step))
    slider.High:SetText(formatValue(option.maxValue, option.step))

    local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    input:SetPoint("LEFT", slider, "RIGHT", 35, 0)
    input:SetSize(70, 20)
    input:SetAutoFocus(false)
    input:SetJustifyH("CENTER")

    local applying = false
    local function apply(value)
        if applying then
            return
        end
        applying = true
        value = normalizeValue(value, option)
        setValue(value)
        slider:SetValue(value)
        input:SetText(formatValue(value, option.step))
        applying = false
    end

    slider:SetScript("OnValueChanged", function(_, value)
        apply(value)
    end)
    local function applyInput()
        local value = tonumber(input:GetText())
        if value then
            apply(value)
        else
            input:SetText(formatValue(getValue(), option.step))
        end
        input:ClearFocus()
    end
    input:SetScript("OnEnterPressed", applyInput)
    input:SetScript("OnEditFocusLost", applyInput)

    applying = true
    slider:SetValue(getValue())
    input:SetText(formatValue(getValue(), option.step))
    applying = false
    controls[controlKey] = { slider = slider, input = input, option = option, getValue = getValue }
end

local function createColorButton(parent, text, y, getColor, setColor)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
    button:SetSize(180, 24)
    button:SetText(text)
    button:SetScript("OnClick", function()
        local color = getColor()
        ColorPickerFrame:SetupColorPickerAndShow({
            r = color.r,
            g = color.g,
            b = color.b,
            hasOpacity = false,
            swatchFunc = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                setColor({ r = r, g = g, b = b })
            end,
            cancelFunc = function(previous)
                setColor({ r = previous.r, g = previous.g, b = previous.b })
            end,
        })
    end)
end

local function createModeButtons(parent, y, classText, customText, getMode, setMode)
    local classButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    classButton:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
    classButton:SetSize(180, 24)
    classButton:SetText(classText)
    classButton:SetScript("OnClick", function()
        setMode("class")
    end)
    local customButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    customButton:SetPoint("LEFT", classButton, "RIGHT", 8, 0)
    customButton:SetSize(180, 24)
    customButton:SetText(customText)
    customButton:SetScript("OnClick", function()
        setMode("custom")
    end)
end

function Player:RefreshLayoutControls()
    if not self.controls then
        return
    end
    for _, control in pairs(self.controls) do
        local value = control.getValue()
        control.slider:SetValue(value)
        control.input:SetText(formatValue(value, control.option.step))
    end
end

function Player:Create(parentCategory)
    local frame = CreateFrame("Frame")
    local category = Settings.RegisterCanvasLayoutSubcategory(parentCategory, frame, BFUF.L.CATEGORY_PLAYER)
    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, 0)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(620, 4000)
    scroll:SetScrollChild(content)

    local controls = {}
    self.controls = controls
    local settings = BFUF.DB:Get("Player")

    createLabel(content, BFUF.L.SECTION_LAYOUT, -20)
    local layoutKeys = { "width", "height", "scale", "positionX", "positionY" }
    for index, key in ipairs(layoutKeys) do
        local option = NUMBER_OPTIONS[key]
        createSlider(content, BFUF.L[option.label], -50 - (index - 1) * 60, option,
            function() return BFUF.DB:Get("Player")[key] end,
            function(value) BFUF.DB:Get("Player")[key] = value; BFUF.Frames.Player:UpdateLayout() end,
            controls, key)
    end

    local unlockButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    unlockButton:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -360)
    unlockButton:SetSize(180, 24)
    local function refreshUnlock()
        unlockButton:SetText(BFUF.Frames.Player:IsLayoutUnlocked() and BFUF.L.BUTTON_LOCK_PLAYER_FRAME or BFUF.L.BUTTON_UNLOCK_PLAYER_FRAME)
    end
    refreshUnlock()
    unlockButton:SetScript("OnClick", function()
        BFUF.Frames.Player:SetLayoutUnlocked(not BFUF.Frames.Player:IsLayoutUnlocked())
        refreshUnlock()
    end)

    local resetButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    resetButton:SetPoint("LEFT", unlockButton, "RIGHT", 8, 0)
    resetButton:SetSize(180, 24)
    resetButton:SetText(BFUF.L.BUTTON_RESET_LAYOUT)
    resetButton:SetScript("OnClick", function()
        local profile = BFUF.DB:Get("Player")
        local defaults = BFUF.Defaults.profile.Player
        for _, key in ipairs(layoutKeys) do
            profile[key] = defaults[key]
        end
        BFUF.Frames.Player:UpdateLayout()
        Player:RefreshLayoutControls()
    end)

    createLabel(content, BFUF.L.SECTION_PORTRAIT, -410)
    createCheckbox(content, BFUF.L.OPTION_SHOW_PORTRAIT, -440,
        function() return BFUF.DB:Get("Player").portrait.show end,
        function(value) BFUF.DB:Get("Player").portrait.show = value; BFUF.Frames.Player:UpdateLayout() end)
    local portraitOptions = {
        { key = "width", label = "OPTION_PORTRAIT_WIDTH", minValue = 20, maxValue = 160, step = 1 },
        { key = "height", label = "OPTION_PORTRAIT_HEIGHT", minValue = 20, maxValue = 160, step = 1 },
        { key = "offsetX", label = "OPTION_OFFSET_X", minValue = -200, maxValue = 200, step = 1 },
        { key = "offsetY", label = "OPTION_OFFSET_Y", minValue = -200, maxValue = 200, step = 1 },
    }
    for index, option in ipairs(portraitOptions) do
        createSlider(content, BFUF.L[option.label], -470 - (index - 1) * 60, option,
            function() return BFUF.DB:Get("Player").portrait[option.key] end,
            function(value) BFUF.DB:Get("Player").portrait[option.key] = value; BFUF.Frames.Player:UpdateLayout() end,
            controls, "portrait" .. option.key)
    end

    createLabel(content, BFUF.L.SECTION_HEALTH, -730)
    local healthOptions = {
        { key = "height", label = "OPTION_HEALTH_HEIGHT", minValue = 10, maxValue = 160, step = 1 },
        { key = "offsetX", label = "OPTION_OFFSET_X", minValue = -200, maxValue = 200, step = 1 },
        { key = "offsetY", label = "OPTION_OFFSET_Y", minValue = -200, maxValue = 200, step = 1 },
    }
    for index, option in ipairs(healthOptions) do
        createSlider(content, BFUF.L[option.label], -760 - (index - 1) * 60, option,
            function() return BFUF.DB:Get("Player").health[option.key] end,
            function(value) BFUF.DB:Get("Player").health[option.key] = value; BFUF.Frames.Player:UpdateLayout() end,
            controls, "health" .. option.key)
    end
    createModeButtons(content, -940, BFUF.L.OPTION_CLASS_COLOR, BFUF.L.OPTION_CUSTOM_COLOR,
        function() return BFUF.DB:Get("Player").health.colorMode end,
        function(mode) BFUF.DB:Get("Player").health.colorMode = mode; BFUF.Frames.Player:UpdateLayout() end)
    createColorButton(content, BFUF.L.BUTTON_SELECT_COLOR, -970,
        function() return BFUF.DB:Get("Player").health.customColor end,
        function(color) BFUF.DB:Get("Player").health.customColor = color; BFUF.Frames.Player:UpdateLayout() end)
    createCheckbox(content, BFUF.L.OPTION_SHOW_ABSORB, -1005,
        function() return BFUF.DB:Get("Player").health.showAbsorb end,
        function(value) BFUF.DB:Get("Player").health.showAbsorb = value; BFUF.Frames.Player:UpdateLayout() end)
    createCheckbox(content, BFUF.L.OPTION_SHOW_HEAL_ABSORB, -1035,
        function() return BFUF.DB:Get("Player").health.showHealAbsorb end,
        function(value) BFUF.DB:Get("Player").health.showHealAbsorb = value; BFUF.Frames.Player:UpdateLayout() end)

    createLabel(content, BFUF.L.SECTION_POWER, -1080)
    local powerOptions = {
        { key = "height", label = "OPTION_POWER_HEIGHT", minValue = 4, maxValue = 100, step = 1 },
        { key = "offsetX", label = "OPTION_OFFSET_X", minValue = -200, maxValue = 200, step = 1 },
        { key = "offsetY", label = "OPTION_OFFSET_Y", minValue = -200, maxValue = 200, step = 1 },
    }
    for index, option in ipairs(powerOptions) do
        createSlider(content, BFUF.L[option.label], -1110 - (index - 1) * 60, option,
            function() return BFUF.DB:Get("Player").power[option.key] end,
            function(value) BFUF.DB:Get("Player").power[option.key] = value; BFUF.Frames.Player:UpdateLayout() end,
            controls, "power" .. option.key)
    end
    createModeButtons(content, -1290, BFUF.L.OPTION_RESOURCE_COLOR, BFUF.L.OPTION_CUSTOM_COLOR,
        function() return BFUF.DB:Get("Player").power.colorMode end,
        function(mode) BFUF.DB:Get("Player").power.colorMode = mode; BFUF.Frames.Player:UpdateLayout() end)
    createColorButton(content, BFUF.L.BUTTON_SELECT_COLOR, -1320,
        function() return BFUF.DB:Get("Player").power.customColor end,
        function(color) BFUF.DB:Get("Player").power.customColor = color; BFUF.Frames.Player:UpdateLayout() end)

    createLabel(content, BFUF.L.SECTION_TEXTS, -1370)
    local textY = -1400
    for _, name in ipairs({ "name", "health", "power" }) do
        createLabel(content, BFUF.L["SECTION_TEXT_" .. string.upper(name)], textY)
        createCheckbox(content, BFUF.L.OPTION_SHOW, textY - 28,
            function() return BFUF.DB:Get("Player").texts[name].show end,
            function(value) BFUF.DB:Get("Player").texts[name].show = value; BFUF.Frames.Player:UpdateLayout() end)
        local textOptions = {
            { key = "fontSize", label = "OPTION_FONT_SIZE", minValue = 6, maxValue = 32, step = 1 },
            { key = "offsetX", label = "OPTION_OFFSET_X", minValue = -200, maxValue = 200, step = 1 },
            { key = "offsetY", label = "OPTION_OFFSET_Y", minValue = -200, maxValue = 200, step = 1 },
        }
        for index, option in ipairs(textOptions) do
            createSlider(content, BFUF.L[option.label], textY - 58 - (index - 1) * 60, option,
                function() return BFUF.DB:Get("Player").texts[name][option.key] end,
                function(value) BFUF.DB:Get("Player").texts[name][option.key] = value; BFUF.Frames.Player:UpdateLayout() end,
                controls, "text" .. name .. option.key)
        end
        textY = textY - 250
    end

    createLabel(content, BFUF.L.SECTION_INDICATORS, textY)
    local indicatorY = textY - 30
    for _, name in ipairs({ "combat", "resting", "leader", "assistant", "pvp", "afk", "dnd" }) do
        createLabel(content, BFUF.L["INDICATOR_" .. string.upper(name)], indicatorY)
        createCheckbox(content, BFUF.L.OPTION_ENABLE, indicatorY - 28,
            function() return BFUF.DB:Get("Player").indicators[name].enabled end,
            function(value) BFUF.DB:Get("Player").indicators[name].enabled = value; BFUF.Frames.Player:UpdateLayout() end)
        local indicatorOptions = {
            { key = "size", label = "OPTION_SIZE", minValue = 8, maxValue = 64, step = 1 },
            { key = "offsetX", label = "OPTION_OFFSET_X", minValue = -200, maxValue = 200, step = 1 },
            { key = "offsetY", label = "OPTION_OFFSET_Y", minValue = -200, maxValue = 200, step = 1 },
        }
        for index, option in ipairs(indicatorOptions) do
            createSlider(content, BFUF.L[option.label], indicatorY - 58 - (index - 1) * 60, option,
                function() return BFUF.DB:Get("Player").indicators[name][option.key] end,
                function(value) BFUF.DB:Get("Player").indicators[name][option.key] = value; BFUF.Frames.Player:UpdateLayout() end,
                controls, "indicator" .. name .. option.key)
        end
        indicatorY = indicatorY - 250
    end

    return category
end

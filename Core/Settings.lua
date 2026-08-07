local addonName, BFUF = ...

local SettingsModule = {}
BFUF.Core.Settings = SettingsModule

local UI = {
    PagePanel = {},
    NavigationList = {},
    SettingsShell = {},
    SectionPanel = {},
    CheckboxRow = {},
    SliderRow = {},
    DropdownRow = {},
    ColorRow = {},
    ButtonRow = {},
    ExpandableSection = {},
}
SettingsModule.UI = UI

-- Store page definitions independently from their navigation and rendering.
local PageRegistry = {}
PageRegistry.__index = PageRegistry
SettingsModule.PageRegistry = PageRegistry

function PageRegistry:Create()
    return setmetatable({
        pages = {},
        order = {},
    }, self)
end

function PageRegistry:Register(definition)
    assert(type(definition) == "table", "Page definition must be a table")
    assert(definition.id, "Page definition must have an id")
    assert(definition.title, "Page definition must have a title")
    assert(type(definition.builder) == "function", "Page definition must have a builder")

    if self.pages[definition.id] then
        return false
    end

    self.pages[definition.id] = definition
    table.insert(self.order, definition.id)
    return true
end

function PageRegistry:Get(id)
    return self.pages[id]
end

function PageRegistry:ForEach(callback)
    for _, id in ipairs(self.order) do
        callback(self.pages[id])
    end
end

local function createTitle(parent, text)
    local title = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    title:SetText(text)
    return title
end

-- Create the persistent page container used by all settings pages.
function UI.PagePanel:Create(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)

    local panel = {
        frame = frame,
        currentPage = nil,
    }

    function panel:ShowPage(title, description, hasSettings, buildContent, resetAction)
        if self.currentPage then
            self.currentPage:Hide()
        end

        local page = CreateFrame("Frame", nil, self.frame)
        page:SetAllPoints()
        self.currentPage = page

        createTitle(page, title)

        if description then
            local text = page:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            text:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -30)
            text:SetPoint("TOPRIGHT", page, "TOPRIGHT", -16, -30)
            text:SetJustifyH("LEFT")
            text:SetText(description)
        end

        local reset = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
        reset:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 0)
        reset:SetSize(150, 24)
        reset:SetText(BFUF.L.SETTINGS_RESET_PAGE)
        reset:SetEnabled(hasSettings == true)
        if resetAction then
            reset:SetScript("OnClick", resetAction)
        end

        if buildContent then
            buildContent(page)
        end

        return page
    end

    return panel
end

-- Create a generic vertical navigation list.
function UI.NavigationList:Create(parent, width)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetWidth(width)

    local list = {
        frame = frame,
        buttons = {},
        selectedKey = nil,
        nextOffset = 0,
    }

    function list:AddEntry(entry)
        local button = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
        button:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, self.nextOffset)
        button:SetSize(width, 24)
        button:SetText(entry.label)

        if entry.disabled then
            button:Disable()

            local description = self.frame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
            description:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 6, -1)
            description:SetText(BFUF.L.SETTINGS_COMING_LATER)
            self.nextOffset = self.nextOffset - 42
        else
            button:SetScript("OnClick", function()
                self:Select(entry.key)
            end)
            self.nextOffset = self.nextOffset - 30
        end

        self.buttons[entry.key] = {
            button = button,
            entry = entry,
        }
    end

    function list:Select(key)
        local item = self.buttons[key]
        if not item or item.entry.disabled then
            return
        end

        self.selectedKey = key
        for buttonKey, buttonItem in pairs(self.buttons) do
            if buttonItem.entry.disabled then
                buttonItem.button:Disable()
            else
                buttonItem.button:Enable(buttonKey ~= key)
            end
        end

        item.entry.onSelect()
    end

    return list
end

-- Create the root shell with persistent left navigation and a page host.
function UI.SettingsShell:Create(parent)
    local shell = CreateFrame("Frame", nil, parent)
    shell:SetAllPoints()

    local navigation = UI.NavigationList:Create(shell, 150)
    navigation.frame:SetPoint("TOPLEFT", shell, "TOPLEFT", 12, -12)
    navigation.frame:SetPoint("BOTTOMLEFT", shell, "BOTTOMLEFT", 12, 12)

    local divider = shell:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("TOPLEFT", navigation.frame, "TOPRIGHT", 12, 0)
    divider:SetPoint("BOTTOMLEFT", navigation.frame, "BOTTOMRIGHT", 12, 0)
    divider:SetWidth(1)
    divider:SetColorTexture(0.35, 0.35, 0.35, 0.8)

    local pageHost = CreateFrame("Frame", nil, shell)
    pageHost:SetPoint("TOPLEFT", divider, "TOPRIGHT", 16, 0)
    pageHost:SetPoint("BOTTOMRIGHT", shell, "BOTTOMRIGHT", -16, 12)

    return {
        frame = shell,
        navigation = navigation,
        pages = UI.PagePanel:Create(pageHost),
    }
end

-- Create a reusable titled content section.
function UI.SectionPanel:Create(parent, title, y)
    local section = CreateFrame("Frame", nil, parent)
    section:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
    section:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, y)
    section:SetHeight(28)
    createTitle(section, title)
    return section
end

-- Create a reusable checkbox row.
function UI.CheckboxRow:Create(parent, label, y, getValue, setValue)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
    checkbox:SetChecked(getValue())

    local text = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetPoint("LEFT", checkbox, "RIGHT", 2, 0)
    text:SetText(label)

    checkbox:SetScript("OnClick", function(self)
        setValue(self:GetChecked())
    end)

    return checkbox
end

-- Create a reusable slider row with a numeric edit box.
function UI.SliderRow:Create(parent, label, y, minValue, maxValue, step, getValue, setValue)
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
    slider:SetWidth(280)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider.Text:SetText(label)
    slider.Low:SetText(minValue)
    slider.High:SetText(maxValue)

    local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    input:SetPoint("LEFT", slider, "RIGHT", 35, 0)
    input:SetSize(70, 20)
    input:SetAutoFocus(false)
    input:SetJustifyH("CENTER")

    local applying = false
    local function formatValue(value)
        if step < 1 then
            return string.format("%.2f", value)
        end

        return string.format("%.0f", value)
    end

    local function normalizeValue(value)
        value = math.max(minValue, math.min(maxValue, value))
        return math.floor((value - minValue) / step + 0.5) * step + minValue
    end

    local function apply(value)
        if applying then
            return
        end

        applying = true
        value = normalizeValue(value)
        setValue(value)
        slider:SetValue(value)
        input:SetText(formatValue(value))
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
            input:SetText(formatValue(getValue()))
        end
        input:ClearFocus()
    end

    input:SetScript("OnEnterPressed", applyInput)
    input:SetScript("OnEditFocusLost", applyInput)

    applying = true
    slider:SetValue(getValue())
    input:SetText(formatValue(getValue()))
    applying = false

    return {
        slider = slider,
        input = input,
        Refresh = function()
            applying = true
            slider:SetValue(getValue())
            input:SetText(formatValue(getValue()))
            applying = false
        end,
    }
end

-- Create a reusable dropdown-style button row.
function UI.DropdownRow:Create(parent, label, y, getValue, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
    button:SetSize(240, 24)
    button:SetText(label .. ": " .. getValue())
    button:SetScript("OnClick", onClick)
    return button
end

-- Create a reusable color picker row.
function UI.ColorRow:Create(parent, label, y, getColor, setColor)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
    button:SetSize(180, 24)
    button:SetText(label)
    button:SetScript("OnClick", function()
        local color = getColor()
        ColorPickerFrame:SetupColorPickerAndShow({
            r = color.r,
            g = color.g,
            b = color.b,
            hasOpacity = color.a ~= nil,
            swatchFunc = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                setColor({ r = r, g = g, b = b, a = color.a })
            end,
            cancelFunc = function(previous)
                setColor(previous)
            end,
        })
    end)
    return button
end

-- Create a reusable action button row.
function UI.ButtonRow:Create(parent, label, y, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
    button:SetSize(180, 24)
    button:SetText(label)
    button:SetScript("OnClick", onClick)
    return button
end

-- Create a reusable expandable section without page-specific behavior.
function UI.ExpandableSection:Create(parent, title, y)
    local header = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
    header:SetSize(260, 24)
    header:SetText(title)

    local content = CreateFrame("Frame", nil, parent)
    content:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 12, -4)
    content:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -4)
    content:SetHeight(1)
    content:Hide()

    header:SetScript("OnClick", function()
        content:SetShown(not content:IsShown())
    end)

    return header, content
end

-- Create a legacy placeholder category for fallback Config pages.
function SettingsModule:CreatePlaceholderCategory(parentCategory, title, description)
    local frame = CreateFrame("Frame")
    frame:SetSize(620, 300)

    local text = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -16)
    text:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, -16)
    text:SetJustifyH("LEFT")
    text:SetText(description)

    return Settings.RegisterCanvasLayoutSubcategory(parentCategory, frame, title)
end

-- Show the existing General settings without changing their profile bindings.
function SettingsModule:ShowGeneralPage()
    local function resetGeneral()
        local general = BFUF.DB:Get("General")
        general.debugMode = BFUF.Defaults.profile.General.debugMode
        BFUF.DebugEnabled = general.debugMode
    end

    self.shell.pages:ShowPage(BFUF.L.SETTINGS_PAGE_GENERAL, nil, true, function(page)
        UI.CheckboxRow:Create(
            page,
            BFUF.L.OPTION_ENABLE_DEBUG_MODE,
            -42,
            function()
                return BFUF.DB:Get("General").debugMode
            end,
            function(value)
                BFUF.DB:Get("General").debugMode = value
                BFUF.DebugEnabled = value
            end
        )
    end, resetGeneral)
end

-- Create an informational placeholder page.
function SettingsModule:ShowPlaceholderPage(title, description)
    self.shell.pages:ShowPage(title, description or BFUF.L.SETTINGS_DESCRIPTION_COMING_LATER, false)
end

-- Show the Player general settings using the existing AceDB bindings.
function SettingsModule:ShowPlayerGeneralPage(pages)
    local controls = {}
    local options = {
        { key = "width", label = "OPTION_FRAME_WIDTH", minValue = 120, maxValue = 600, step = 1 },
        { key = "height", label = "OPTION_FRAME_HEIGHT", minValue = 20, maxValue = 200, step = 1 },
        { key = "scale", label = "OPTION_FRAME_SCALE", minValue = 0.5, maxValue = 2, step = 0.05 },
        { key = "positionX", label = "OPTION_POSITION_X", minValue = -1000, maxValue = 1000, step = 1 },
        { key = "positionY", label = "OPTION_POSITION_Y", minValue = -1000, maxValue = 1000, step = 1 },
    }

    local function resetLayout()
        local profile = BFUF.DB:Get("Player")
        local defaults = BFUF.Defaults.profile.Player

        for _, option in ipairs(options) do
            profile[option.key] = defaults[option.key]
        end

        profile.positionAnchor = nil
        BFUF.Frames.Player:UpdateLayout()

        for _, control in pairs(controls) do
            control.Refresh()
        end
    end

    pages:ShowPage(BFUF.L.SETTINGS_PLAYER_GENERAL, nil, true, function(page)
        UI.SectionPanel:Create(page, BFUF.L.SECTION_LAYOUT, -36)

        for index, option in ipairs(options) do
            local optionKey = option.key
            controls[optionKey] = UI.SliderRow:Create(
                page,
                BFUF.L[option.label],
                -66 - (index - 1) * 58,
                option.minValue,
                option.maxValue,
                option.step,
                function()
                    return BFUF.DB:Get("Player")[optionKey]
                end,
                function(value)
                    BFUF.DB:Get("Player")[optionKey] = value
                    BFUF.Frames.Player:UpdateLayout()
                end
            )
        end

        local unlockButton
        unlockButton = UI.ButtonRow:Create(page, "", -372, function()
            BFUF.Frames.Player:SetLayoutUnlocked(not BFUF.Frames.Player:IsLayoutUnlocked())
            unlockButton:SetText(
                BFUF.Frames.Player:IsLayoutUnlocked()
                    and BFUF.L.BUTTON_LOCK_PLAYER_FRAME
                    or BFUF.L.BUTTON_UNLOCK_PLAYER_FRAME
            )
        end)
        unlockButton:SetText(
            BFUF.Frames.Player:IsLayoutUnlocked()
                and BFUF.L.BUTTON_LOCK_PLAYER_FRAME
                or BFUF.L.BUTTON_UNLOCK_PLAYER_FRAME
        )

        UI.ButtonRow:Create(page, BFUF.L.BUTTON_RESET_LAYOUT, -404, resetLayout)
    end, resetLayout)

    self.playerGeneralControls = controls
end

-- Show the Player health page using the existing health profile fields.
function SettingsModule:ShowPlayerHealthPage(pages)
    local controls = {}

    local function updateHealth()
        BFUF.Frames.Player:UpdateLayout()
    end

    local function resetHealth()
        local health = BFUF.DB:Get("Player").health
        local defaults = BFUF.Defaults.profile.Player.health
        health.height = defaults.height
        health.colorMode = defaults.colorMode
        health.customColor = {
            r = defaults.customColor.r,
            g = defaults.customColor.g,
            b = defaults.customColor.b,
        }
        health.showAbsorb = defaults.showAbsorb
        health.showHealAbsorb = defaults.showHealAbsorb
        updateHealth()

        if controls.height then
            controls.height.Refresh()
        end
    end

    pages:ShowPage(BFUF.L.SETTINGS_PLAYER_HEALTH, nil, true, function(page)
        UI.SectionPanel:Create(page, BFUF.L.SECTION_HEALTH, -36)

        controls.height = UI.SliderRow:Create(
            page,
            BFUF.L.OPTION_HEALTH_HEIGHT,
            -66,
            10,
            160,
            1,
            function()
                return BFUF.DB:Get("Player").health.height
            end,
            function(value)
                BFUF.DB:Get("Player").health.height = value
                updateHealth()
            end
        )

        local classButton = UI.ButtonRow:Create(page, BFUF.L.OPTION_CLASS_COLOR, -124, function()
            BFUF.DB:Get("Player").health.colorMode = "class"
            updateHealth()
        end)
        classButton:SetSize(150, 24)

        local customButton = UI.ButtonRow:Create(page, BFUF.L.OPTION_CUSTOM_COLOR, -124, function()
            BFUF.DB:Get("Player").health.colorMode = "custom"
            updateHealth()
        end)
        customButton:ClearAllPoints()
        customButton:SetPoint("LEFT", classButton, "RIGHT", 8, 0)
        customButton:SetSize(150, 24)

        UI.ColorRow:Create(
            page,
            BFUF.L.BUTTON_SELECT_COLOR,
            -158,
            function()
                return BFUF.DB:Get("Player").health.customColor
            end,
            function(color)
                BFUF.DB:Get("Player").health.customColor = color
                updateHealth()
            end
        )

        UI.CheckboxRow:Create(
            page,
            BFUF.L.OPTION_SHOW_ABSORB,
            -194,
            function()
                return BFUF.DB:Get("Player").health.showAbsorb
            end,
            function(value)
                BFUF.DB:Get("Player").health.showAbsorb = value
                updateHealth()
            end
        )

        UI.CheckboxRow:Create(
            page,
            BFUF.L.OPTION_SHOW_HEAL_ABSORB,
            -222,
            function()
                return BFUF.DB:Get("Player").health.showHealAbsorb
            end,
            function(value)
                BFUF.DB:Get("Player").health.showHealAbsorb = value
                updateHealth()
            end
        )
    end, resetHealth)

    self.playerHealthControls = controls
end

-- Show the Player power page using the existing power profile fields.
function SettingsModule:ShowPlayerPowerPage(pages)
    local controls = {}

    local function updatePower()
        BFUF.Frames.Player:UpdateLayout()
    end

    local function resetPower()
        local power = BFUF.DB:Get("Player").power
        local defaults = BFUF.Defaults.profile.Player.power
        power.height = defaults.height
        power.colorMode = defaults.colorMode
        power.customColor = {
            r = defaults.customColor.r,
            g = defaults.customColor.g,
            b = defaults.customColor.b,
        }
        updatePower()

        if controls.height then
            controls.height.Refresh()
        end
    end

    pages:ShowPage(BFUF.L.SETTINGS_PLAYER_POWER, nil, true, function(page)
        UI.SectionPanel:Create(page, BFUF.L.SECTION_POWER, -36)

        controls.height = UI.SliderRow:Create(
            page,
            BFUF.L.OPTION_POWER_HEIGHT,
            -66,
            4,
            100,
            1,
            function()
                return BFUF.DB:Get("Player").power.height
            end,
            function(value)
                BFUF.DB:Get("Player").power.height = value
                updatePower()
            end
        )

        local resourceButton = UI.ButtonRow:Create(page, BFUF.L.OPTION_RESOURCE_COLOR, -124, function()
            BFUF.DB:Get("Player").power.colorMode = "resource"
            updatePower()
        end)
        resourceButton:SetSize(150, 24)

        local customButton = UI.ButtonRow:Create(page, BFUF.L.OPTION_CUSTOM_COLOR, -124, function()
            BFUF.DB:Get("Player").power.colorMode = "custom"
            updatePower()
        end)
        customButton:ClearAllPoints()
        customButton:SetPoint("LEFT", resourceButton, "RIGHT", 8, 0)
        customButton:SetSize(150, 24)

        UI.ColorRow:Create(
            page,
            BFUF.L.BUTTON_SELECT_COLOR,
            -158,
            function()
                return BFUF.DB:Get("Player").power.customColor
            end,
            function(color)
                BFUF.DB:Get("Player").power.customColor = color
                updatePower()
            end
        )
    end, resetPower)

    self.playerPowerControls = controls
end

-- Copy a profile value without sharing nested color tables.
local function copyProfileValue(source)
    if type(source) ~= "table" then
        return source
    end

    local copy = {}
    for key, value in pairs(source) do
        copy[key] = copyProfileValue(value)
    end
    return copy
end

-- Show one existing status indicator without changing its runtime logic.
function SettingsModule:ShowPlayerIndicatorPage(pages, indicatorKey, title)
    local controls = {}

    local function updateIndicators()
        BFUF.Frames.Player:UpdateLayout()
    end

    local function resetIndicator()
        BFUF.DB:Get("Player").indicators[indicatorKey] = copyProfileValue(
            BFUF.Defaults.profile.Player.indicators[indicatorKey]
        )
        updateIndicators()

        for _, control in pairs(controls) do
            control.Refresh()
        end
    end

    pages:ShowPage(title, nil, true, function(page)
        UI.SectionPanel:Create(page, title, -36)

        UI.CheckboxRow:Create(
            page,
            BFUF.L.OPTION_ENABLE,
            -66,
            function()
                return BFUF.DB:Get("Player").indicators[indicatorKey].enabled
            end,
            function(value)
                BFUF.DB:Get("Player").indicators[indicatorKey].enabled = value
                updateIndicators()
            end
        )

        controls.size = UI.SliderRow:Create(
            page,
            BFUF.L.OPTION_SIZE,
            -94,
            8,
            64,
            1,
            function()
                return BFUF.DB:Get("Player").indicators[indicatorKey].size
            end,
            function(value)
                BFUF.DB:Get("Player").indicators[indicatorKey].size = value
                updateIndicators()
            end
        )

        controls.offsetX = UI.SliderRow:Create(
            page,
            BFUF.L.OPTION_OFFSET_X,
            -152,
            -200,
            200,
            1,
            function()
                return BFUF.DB:Get("Player").indicators[indicatorKey].offsetX
            end,
            function(value)
                BFUF.DB:Get("Player").indicators[indicatorKey].offsetX = value
                updateIndicators()
            end
        )

        controls.offsetY = UI.SliderRow:Create(
            page,
            BFUF.L.OPTION_OFFSET_Y,
            -210,
            -200,
            200,
            1,
            function()
                return BFUF.DB:Get("Player").indicators[indicatorKey].offsetY
            end,
            function(value)
                BFUF.DB:Get("Player").indicators[indicatorKey].offsetY = value
                updateIndicators()
            end
        )
    end, resetIndicator)

    self.playerIndicatorControls = self.playerIndicatorControls or {}
    self.playerIndicatorControls[indicatorKey] = controls
end

-- Show the local navigation for the existing player indicators.
function SettingsModule:ShowPlayerIndicatorsPage(pages)
    local page = pages:ShowPage(BFUF.L.SETTINGS_PLAYER_INDICATORS, nil, false)

    local navigation = UI.NavigationList:Create(page, 120)
    navigation.frame:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -34)
    navigation.frame:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 0, 0)

    local divider = page:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("TOPLEFT", navigation.frame, "TOPRIGHT", 10, 0)
    divider:SetPoint("BOTTOMLEFT", navigation.frame, "BOTTOMRIGHT", 10, 0)
    divider:SetWidth(1)
    divider:SetColorTexture(0.35, 0.35, 0.35, 0.8)

    local localHost = CreateFrame("Frame", nil, page)
    localHost:SetPoint("TOPLEFT", divider, "TOPRIGHT", 12, 0)
    localHost:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
    local indicatorPages = UI.PagePanel:Create(localHost)

    local entries = {
        { key = "combat", label = BFUF.L.INDICATOR_COMBAT },
        { key = "resting", label = BFUF.L.INDICATOR_RESTING },
        { key = "leader", label = BFUF.L.INDICATOR_LEADER },
        { key = "assistant", label = BFUF.L.INDICATOR_ASSISTANT },
        { key = "pvp", label = BFUF.L.INDICATOR_PVP },
        { key = "afk", label = BFUF.L.INDICATOR_AFK },
        { key = "dnd", label = BFUF.L.INDICATOR_DND },
    }

    for _, entry in ipairs(entries) do
        local currentEntry = entry
        currentEntry.onSelect = function()
            self:ShowPlayerIndicatorPage(indicatorPages, currentEntry.key, currentEntry.label)
        end
        navigation:AddEntry(currentEntry)
    end

    navigation:Select("combat")
end

-- Show one existing text object without changing its renderer or display model.
function SettingsModule:ShowPlayerTextObjectPage(pages, textKey, title)
    local controls = {}
    local displayModes = textKey == "name" and {
        { key = "name", label = "TEXT_MODE_NAME" },
        { key = "hidden", label = "TEXT_MODE_HIDDEN" },
    } or {
        { key = "current", label = "TEXT_MODE_CURRENT" },
        { key = "currentMax", label = "TEXT_MODE_CURRENT_MAX" },
        { key = "percent", label = "TEXT_MODE_PERCENT" },
        { key = "currentPercent", label = "TEXT_MODE_CURRENT_PERCENT" },
        { key = "missing", label = "TEXT_MODE_MISSING" },
        { key = "hidden", label = "TEXT_MODE_HIDDEN" },
    }

    local function updateText()
        BFUF.Frames.Player:UpdateLayout()
    end

    local function resetText()
        BFUF.DB:Get("Player").texts[textKey] = copyProfileValue(BFUF.Defaults.profile.Player.texts[textKey])
        updateText()

        for _, control in pairs(controls) do
            control.Refresh()
        end
    end

    pages:ShowPage(title, nil, true, function(page)
        UI.SectionPanel:Create(page, title, -36)

        UI.CheckboxRow:Create(
            page,
            BFUF.L.OPTION_SHOW,
            -66,
            function()
                return BFUF.DB:Get("Player").texts[textKey].show
            end,
            function(value)
                BFUF.DB:Get("Player").texts[textKey].show = value
                updateText()
            end
        )

        controls.fontSize = UI.SliderRow:Create(
            page,
            BFUF.L.OPTION_FONT_SIZE,
            -94,
            6,
            32,
            1,
            function()
                return BFUF.DB:Get("Player").texts[textKey].fontSize
            end,
            function(value)
                BFUF.DB:Get("Player").texts[textKey].fontSize = value
                updateText()
            end
        )

        controls.offsetX = UI.SliderRow:Create(
            page,
            BFUF.L.OPTION_OFFSET_X,
            -152,
            -200,
            200,
            1,
            function()
                return BFUF.DB:Get("Player").texts[textKey].offsetX
            end,
            function(value)
                BFUF.DB:Get("Player").texts[textKey].offsetX = value
                updateText()
            end
        )

        controls.offsetY = UI.SliderRow:Create(
            page,
            BFUF.L.OPTION_OFFSET_Y,
            -210,
            -200,
            200,
            1,
            function()
                return BFUF.DB:Get("Player").texts[textKey].offsetY
            end,
            function(value)
                BFUF.DB:Get("Player").texts[textKey].offsetY = value
                updateText()
            end
        )

        if textKey ~= "level" then
            for index, mode in ipairs(displayModes) do
                local modeKey = mode.key
                local row = math.floor((index - 1) / 3)
                local column = (index - 1) % 3
                local button = UI.ButtonRow:Create(page, BFUF.L[mode.label], -270, function()
                    BFUF.DB:Get("Player").texts[textKey].mode = modeKey
                    updateText()
                end)
                button:ClearAllPoints()
                button:SetPoint("TOPLEFT", page, "TOPLEFT", column * 122, -270 - row * 30)
                button:SetSize(114, 24)
            end
        end
    end, resetText)

    self.playerTextControls = self.playerTextControls or {}
    self.playerTextControls[textKey] = controls
end

-- Show the local navigation for the existing text objects.
function SettingsModule:ShowPlayerTextPage(pages)
    local page = pages:ShowPage(BFUF.L.SETTINGS_PLAYER_TEXT, nil, false)

    local navigation = UI.NavigationList:Create(page, 110)
    navigation.frame:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -34)
    navigation.frame:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 0, 0)

    local divider = page:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("TOPLEFT", navigation.frame, "TOPRIGHT", 10, 0)
    divider:SetPoint("BOTTOMLEFT", navigation.frame, "BOTTOMRIGHT", 10, 0)
    divider:SetWidth(1)
    divider:SetColorTexture(0.35, 0.35, 0.35, 0.8)

    local localHost = CreateFrame("Frame", nil, page)
    localHost:SetPoint("TOPLEFT", divider, "TOPRIGHT", 12, 0)
    localHost:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
    local textPages = UI.PagePanel:Create(localHost)

    local entries = {
        { key = "name", label = BFUF.L.SECTION_TEXT_NAME },
        { key = "health", label = BFUF.L.SECTION_TEXT_HEALTH },
        { key = "power", label = BFUF.L.SECTION_TEXT_POWER },
        { key = "level", label = BFUF.L.SECTION_TEXT_LEVEL },
    }

    for _, entry in ipairs(entries) do
        local currentEntry = entry
        currentEntry.onSelect = function()
            self:ShowPlayerTextObjectPage(textPages, currentEntry.key, currentEntry.label)
        end
        navigation:AddEntry(currentEntry)
    end

    navigation:Select("name")
end

-- Show the Player portrait page using the existing portrait profile fields.
function SettingsModule:ShowPlayerPortraitPage(pages)
    local controls = {}
    local modes = {
        { key = BFUF.Elements.Portrait.Modes.HIDDEN, label = BFUF.L.OPTION_PORTRAIT_HIDDEN },
        { key = BFUF.Elements.Portrait.Modes.TWO_D, label = BFUF.L.OPTION_PORTRAIT_2D },
        { key = BFUF.Elements.Portrait.Modes.THREE_D, label = BFUF.L.OPTION_PORTRAIT_3D },
    }

    local function resetPortrait()
        local portrait = BFUF.DB:Get("Player").portrait
        local defaults = BFUF.Defaults.profile.Player.portrait
        portrait.mode = defaults.mode
        portrait.width = defaults.width
        BFUF.Frames.Player:UpdateLayout()

        if controls.width then
            controls.width.Refresh()
        end
    end

    pages:ShowPage(BFUF.L.SETTINGS_PLAYER_PORTRAIT, nil, true, function(page)
        UI.SectionPanel:Create(page, BFUF.L.SECTION_PORTRAIT, -36)

        for index, mode in ipairs(modes) do
            local modeKey = mode.key
            local button = UI.ButtonRow:Create(page, mode.label, -68, function()
                BFUF.DB:Get("Player").portrait.mode = modeKey
                BFUF.Frames.Player:UpdateLayout()
            end)
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", page, "TOPLEFT", (index - 1) * 122, -68)
            button:SetSize(114, 24)
        end

        controls.width = UI.SliderRow:Create(
            page,
            BFUF.L.OPTION_PORTRAIT_WIDTH,
            -116,
            20,
            160,
            1,
            function()
                return BFUF.DB:Get("Player").portrait.width
            end,
            function(value)
                BFUF.DB:Get("Player").portrait.width = value
                BFUF.Frames.Player:UpdateLayout()
            end
        )
    end, resetPortrait)

    self.playerPortraitControls = controls
end

-- Build the local navigation used by the Player settings entry.
function SettingsModule:ShowPlayerPage()
    local page = self.shell.pages:ShowPage(BFUF.L.SETTINGS_PAGE_PLAYER, nil, false)

    local navigation = UI.NavigationList:Create(page, 130)
    navigation.frame:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -34)
    navigation.frame:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 0, 0)

    local divider = page:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("TOPLEFT", navigation.frame, "TOPRIGHT", 10, 0)
    divider:SetPoint("BOTTOMLEFT", navigation.frame, "BOTTOMRIGHT", 10, 0)
    divider:SetWidth(1)
    divider:SetColorTexture(0.35, 0.35, 0.35, 0.8)

    local localHost = CreateFrame("Frame", nil, page)
    localHost:SetPoint("TOPLEFT", divider, "TOPRIGHT", 12, 0)
    localHost:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
    local pages = UI.PagePanel:Create(localHost)

    local entries = {
        { key = "general", label = BFUF.L.SETTINGS_PLAYER_GENERAL },
        { key = "portrait", label = BFUF.L.SETTINGS_PLAYER_PORTRAIT },
        { key = "health", label = BFUF.L.SETTINGS_PLAYER_HEALTH },
        { key = "power", label = BFUF.L.SETTINGS_PLAYER_POWER },
        { key = "text", label = BFUF.L.SETTINGS_PLAYER_TEXT },
        { key = "indicators", label = BFUF.L.SETTINGS_PLAYER_INDICATORS },
        { key = "resources", label = BFUF.L.SETTINGS_PLAYER_RESOURCES },
        { key = "auras", label = BFUF.L.SETTINGS_PLAYER_AURAS },
    }

    if BFUF.DebugEnabled then
        table.insert(entries, { key = "advanced", label = BFUF.L.SETTINGS_PLAYER_ADVANCED })
    end

    for _, entry in ipairs(entries) do
        local currentEntry = entry
        currentEntry.onSelect = function()
            if currentEntry.key == "general" then
                self:ShowPlayerGeneralPage(pages)
                return
            end

            if currentEntry.key == "portrait" then
                self:ShowPlayerPortraitPage(pages)
                return
            end

            if currentEntry.key == "health" then
                self:ShowPlayerHealthPage(pages)
                return
            end

            if currentEntry.key == "power" then
                self:ShowPlayerPowerPage(pages)
                return
            end

            if currentEntry.key == "text" then
                self:ShowPlayerTextPage(pages)
                return
            end

            if currentEntry.key == "indicators" then
                self:ShowPlayerIndicatorsPage(pages)
                return
            end

            pages:ShowPage(currentEntry.label, BFUF.L.SETTINGS_DESCRIPTION_COMING_LATER, false)
        end
        navigation:AddEntry(currentEntry)
    end

    navigation:Select("general")
end

-- Register the shell and preserve legacy pages until each replacement has been validated.
function SettingsModule:Initialize()
    if self.category then
        return
    end

    local rootFrame = CreateFrame("Frame")
    rootFrame:SetSize(820, 540)
    self.category = Settings.RegisterCanvasLayoutCategory(rootFrame, BFUF.L.ADDON_NAME)
    Settings.RegisterAddOnCategory(self.category)

    self.shell = UI.SettingsShell:Create(rootFrame)

    local entries = {
        {
            key = "general",
            label = BFUF.L.SETTINGS_PAGE_GENERAL,
            onSelect = function()
                self:ShowGeneralPage()
            end,
        },
        {
            key = "player",
            label = BFUF.L.SETTINGS_PAGE_PLAYER,
            onSelect = function()
                self:ShowPlayerPage()
            end,
        },
        { key = "target", label = BFUF.L.SETTINGS_PAGE_TARGET, disabled = true },
        { key = "targetTarget", label = BFUF.L.SETTINGS_PAGE_TARGET_TARGET, disabled = true },
        { key = "focus", label = BFUF.L.SETTINGS_PAGE_FOCUS, disabled = true },
        { key = "focusTarget", label = BFUF.L.SETTINGS_PAGE_FOCUS_TARGET, disabled = true },
        { key = "pet", label = BFUF.L.SETTINGS_PAGE_PET, disabled = true },
        { key = "petTarget", label = BFUF.L.SETTINGS_PAGE_PET_TARGET, disabled = true },
        { key = "boss", label = BFUF.L.SETTINGS_PAGE_BOSS, disabled = true },
        { key = "arena", label = BFUF.L.SETTINGS_PAGE_ARENA, disabled = true },
        {
            key = "profiles",
            label = BFUF.L.SETTINGS_PAGE_PROFILES,
            onSelect = function()
                self:ShowPlaceholderPage(BFUF.L.SETTINGS_PAGE_PROFILES, BFUF.L.DESCRIPTION_PROFILES)
            end,
        },
        {
            key = "about",
            label = BFUF.L.SETTINGS_PAGE_ABOUT,
            onSelect = function()
                self:ShowPlaceholderPage(BFUF.L.SETTINGS_PAGE_ABOUT, BFUF.L.DESCRIPTION_ABOUT)
            end,
        },
    }

    for _, entry in ipairs(entries) do
        self.shell.navigation:AddEntry(entry)
    end

    self.shell.navigation:Select("general")

    -- Keep legacy modules available internally without publishing old pages to Blizzard Settings.
    self.legacyPages = {
        General = BFUF.Config.General,
        Player = BFUF.Config.Player,
        Indicators = BFUF.Config.Indicators,
        Profiles = BFUF.Config.Profiles,
        About = BFUF.Config.About,
    }
end

-- Open the root BFUF category in Blizzard Settings.
function SettingsModule:Open()
    self:Initialize()
    Settings.OpenToCategory(self.category:GetID())
end

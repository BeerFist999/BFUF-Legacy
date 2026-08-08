local addonName, BFUF = ...

local SettingsModule = {}
BFUF.Core.Settings = SettingsModule

local UI = {
    PagePanel = {},
    NavigationList = {},
    TabBar = {},
    SettingsShell = {},
    SectionPanel = {},
    CheckboxRow = {},
    SliderRow = {},
    DropdownRow = {},
    ColorRow = {},
    ButtonRow = {},
    ExpandableSection = {},
    ScrollablePageHost = {},
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

    definition.refresh = definition.refresh or function()
    end

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

-- Normalize the shared binding contract used by interactive settings widgets.
local function normalizeBinding(labelOrBinding, getValue, setValue)
    if type(labelOrBinding) == "table" then
        return labelOrBinding
    end

    return {
        label = labelOrBinding,
        get = getValue,
        set = setValue,
    }
end

local function refreshBinding(widget, binding, applyValue)
    function widget:Refresh()
        if binding.disabled then
            self:SetEnabled(not binding.disabled())
        end

        if applyValue and binding.get then
            applyValue(binding.get())
        end

        if binding.refresh then
            binding.refresh(self)
        end
    end

    widget:Refresh()
    return widget
end

local function createTitle(parent, text)
    local title = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    title:SetText(text)
    return title
end

-- Create the page container with a bounded transient page cache.
function UI.PagePanel:Create(parent)
    local container = parent.scrollChild or parent
    local frame = CreateFrame("Frame", nil, container)
    frame:SetAllPoints(container)

    local panel = {
        frame = frame,
        currentPage = nil,
        cache = {},
        cacheOrder = {},
        cacheLimit = 5,
    }

    function panel:TrimCache()
        while #self.cacheOrder > self.cacheLimit do
            local id = table.remove(self.cacheOrder, 1)
            local page = self.cache[id]
            if page and page ~= self.currentPage then
                page:Hide()
                page:SetParent(nil)
                self.cache[id] = nil
            else
                table.insert(self.cacheOrder, id)
                break
            end
        end
    end

    function panel:ClearCache()
        for id, page in pairs(self.cache) do
            page:Hide()
            page:SetParent(nil)
            self.cache[id] = nil
        end

        wipe(self.cacheOrder)
        self.currentPage = nil
    end

    function panel:ShowDefinition(definition)
        if self.currentPage then
            self.currentPage:Hide()
        end

        local page = self.cache[definition.id]
        if not page then
            page = CreateFrame("Frame", nil, self.frame)
            page:SetAllPoints()

            createTitle(page, definition.title)

            if definition.description then
                local text = page:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
                text:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -30)
                text:SetPoint("TOPRIGHT", page, "TOPRIGHT", -16, -30)
                text:SetJustifyH("LEFT")
                text:SetText(definition.description)
            end

            local reset = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
            reset:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 0)
            reset:SetSize(150, 24)
            reset:SetText(BFUF.L.SETTINGS_RESET_PAGE)
            reset:SetEnabled(definition.hasSettings == true)
            if definition.reset then
                reset:SetScript("OnClick", definition.reset)
            end

            if definition.builder then
                definition.builder(page)
            end

            page._bfufRefresh = definition.refresh
            self.cache[definition.id] = page
            table.insert(self.cacheOrder, definition.id)
            self:TrimCache()
        end

        self.currentPage = page
        page:Show()

        if page._bfufRefresh then
            page._bfufRefresh(page)
        end

        return page
    end

    -- Preserve the previous API while routing it through the page lifecycle.
    function panel:ShowPage(title, description, hasSettings, buildContent, resetAction)
        return self:ShowDefinition({
            id = "legacy:" .. title,
            title = title,
            description = description,
            hasSettings = hasSettings,
            builder = buildContent,
            reset = resetAction,
        })
    end

    return panel
end

-- Create the single scrollable host used by the settings shell.
function UI.ScrollablePageHost:Create(parent)
    local host = CreateFrame("Frame", nil, parent)
    host:SetAllPoints()

    local scrollFrame = CreateFrame("ScrollFrame", nil, host, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", host, "TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -26, 0)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
    scrollChild:SetSize(1, 1)
    scrollFrame:SetScrollChild(scrollChild)

    host:SetScript("OnSizeChanged", function(_, width, height)
        scrollChild:SetSize(math.max(width - 26, 1), math.max(height, 1))
    end)

    return {
        frame = host,
        scrollFrame = scrollFrame,
        scrollChild = scrollChild,
    }
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
        local depth = entry.depth or 0
        local indent = depth * 14
        local button = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
        button:SetPoint("TOPLEFT", self.frame, "TOPLEFT", indent, self.nextOffset)
        button:SetSize(width - indent, 24)
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

    -- Add a navigation tree while retaining the same entry selection behavior.
    function list:AddTree(entries, depth)
        depth = depth or 0

        for _, entry in ipairs(entries) do
            local item = {}
            for key, value in pairs(entry) do
                item[key] = value
            end
            item.depth = depth

            self:AddEntry(item)

            if item.children then
                self:AddTree(item.children, depth + 1)
            end
        end
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

-- Create a reusable horizontal tab bar for a navigation level.
function UI.TabBar:Create(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(24)

    local tabBar = {
        frame = frame,
        buttons = {},
        entries = {},
        selectedKey = nil,
        nextOffset = 0,
    }

    function tabBar:Clear()
        for _, item in pairs(self.buttons) do
            item.button:Hide()
            item.button:SetParent(nil)
        end

        wipe(self.buttons)
        wipe(self.entries)
        self.selectedKey = nil
        self.nextOffset = 0
        self.frame:Hide()
    end

    function tabBar:AddEntry(entry)
        local button = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
        button:SetText(entry.label)

        local fontString = button:GetFontString()
        local textWidth = fontString and fontString:GetStringWidth() or 0
        local width = math.max(58, math.min(textWidth + 24, 120))

        button:SetPoint("LEFT", self.frame, "LEFT", self.nextOffset, 0)
        button:SetSize(width, 24)
        self.nextOffset = self.nextOffset + width + 4

        if entry.disabled then
            button:Disable()
            button:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetText(BFUF.L.SETTINGS_COMING_LATER)
                GameTooltip:Show()
            end)
            button:SetScript("OnLeave", GameTooltip_Hide)
        else
            button:SetScript("OnClick", function()
                self:Select(entry.key)
            end)
        end

        self.buttons[entry.key] = {
            button = button,
            entry = entry,
        }
        self.entries[entry.key] = entry
        self.frame:Show()
    end

    function tabBar:SetEntries(entries)
        self:Clear()
        for _, entry in ipairs(entries) do
            self:AddEntry(entry)
        end
    end

    function tabBar:Select(key)
        local item = self.buttons[key]
        if not item or item.entry.disabled then
            return
        end

        self.selectedKey = key
        for buttonKey, buttonItem in pairs(self.buttons) do
            if buttonItem.entry.disabled then
                buttonItem.button:Disable()
            else
                buttonItem.button:SetEnabled(buttonKey ~= key)
            end
        end

        item.entry.onSelect()
    end

    return tabBar
end

-- Create the root shell with horizontal tab navigation and one shared content host.
function UI.SettingsShell:Create(parent)
    local shell = CreateFrame("Frame", nil, parent)
    shell:SetAllPoints()

    local topTabs = UI.TabBar:Create(shell)
    local frameTabs = UI.TabBar:Create(shell)
    local contextTabs = UI.TabBar:Create(shell)
    local layerTabs = UI.TabBar:Create(shell)
    local pageHost = UI.ScrollablePageHost:Create(shell)

    local settingsShell = {
        frame = shell,
        topTabs = topTabs,
        frameTabs = frameTabs,
        contextTabs = contextTabs,
        layerTabs = layerTabs,
        pageHost = pageHost,
    }
    settingsShell.navigation = topTabs
    settingsShell.pages = UI.PagePanel:Create(pageHost)

    function settingsShell:UpdateLayout()
        local y = -12
        local rows = { self.topTabs, self.frameTabs, self.contextTabs, self.layerTabs }

        for _, tabBar in ipairs(rows) do
            tabBar.frame:ClearAllPoints()
            if next(tabBar.buttons) then
                tabBar.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 12, y)
                tabBar.frame:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -12, y)
                tabBar.frame:Show()
                y = y - 30
            else
                tabBar.frame:Hide()
            end
        end

        self.pageHost.frame:ClearAllPoints()
        self.pageHost.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 12, y)
        self.pageHost.frame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -12, 12)
    end

    function settingsShell:SetTopEntries(entries)
        self.topTabs:SetEntries(entries)
        self:UpdateLayout()
    end

    function settingsShell:SetFrameEntries(entries)
        self.frameTabs:SetEntries(entries)
        self.contextTabs:Clear()
        self.layerTabs:Clear()
        self:UpdateLayout()
    end

    function settingsShell:SetContextEntries(entries)
        self.contextTabs:SetEntries(entries)
        self.layerTabs:Clear()
        self:UpdateLayout()
    end

    function settingsShell:SetLayerEntries(entries)
        self.layerTabs:SetEntries(entries)
        self:UpdateLayout()
    end

    settingsShell:UpdateLayout()
    return settingsShell
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
function UI.CheckboxRow:Create(parent, labelOrBinding, y, getValue, setValue)
    local binding = normalizeBinding(labelOrBinding, getValue, setValue)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)

    local text = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetPoint("LEFT", checkbox, "RIGHT", 2, 0)
    text:SetText(binding.label)

    checkbox:SetScript("OnClick", function(self)
        if binding.set then
            binding.set(self:GetChecked())
        end
    end)

    return refreshBinding(checkbox, binding, function(value)
        checkbox:SetChecked(value == true)
    end)
end

-- Create a reusable slider row with a numeric edit box.
function UI.SliderRow:Create(parent, labelOrBinding, y, minValue, maxValue, step, getValue, setValue)
    local binding = normalizeBinding(labelOrBinding, getValue, setValue)
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
    slider:SetWidth(280)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider.Text:SetText(binding.label)
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
        binding.set(value)
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
            input:SetText(formatValue(binding.get()))
        end
        input:ClearFocus()
    end

    input:SetScript("OnEnterPressed", applyInput)
    input:SetScript("OnEditFocusLost", applyInput)

    applying = true
    slider:SetValue(binding.get())
    input:SetText(formatValue(binding.get()))
    applying = false

    local row = {
        slider = slider,
        input = input,
    }

    function row:Refresh()
        applying = true
        slider:SetValue(binding.get())
        input:SetText(formatValue(binding.get()))
        applying = false

        local disabled = binding.disabled and binding.disabled() or false
        slider:SetEnabled(not disabled)
        input:SetEnabled(not disabled)

        if binding.refresh then
            binding.refresh(self)
        end
    end

    row:Refresh()
    return row
end

-- Create a reusable dropdown row backed by the Blizzard context menu API.
function UI.DropdownRow:Create(parent, labelOrBinding, y, getValue, onClick)
    local binding = normalizeBinding(labelOrBinding, getValue, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
    button:SetSize(240, 24)

    local row = {
        button = button,
    }

    local function getLabel(value)
        for _, option in ipairs(binding.values or {}) do
            if option.value == value then
                return option.label
            end
        end

        return tostring(value or "")
    end

    function row:Refresh()
        local value = binding.get and binding.get() or nil
        button:SetText(binding.label .. ": " .. getLabel(value))

        local disabled = binding.disabled and binding.disabled() or false
        button:SetEnabled(not disabled)

        if binding.refresh then
            binding.refresh(self)
        end
    end

    button:SetScript("OnClick", function()
        if binding.disabled and binding.disabled() then
            return
        end

        if binding.values and binding.set then
            MenuUtil.CreateContextMenu(button, function(_, rootDescription)
                for _, option in ipairs(binding.values) do
                    rootDescription:CreateButton(option.label, function()
                        binding.set(option.value)
                        row:Refresh()
                    end)
                end
            end)
            return
        end

        if onClick then
            onClick()
        end
    end)

    row:Refresh()
    return row
end

-- Create a reusable color picker row.
function UI.ColorRow:Create(parent, labelOrBinding, y, getColor, setColor)
    local binding = normalizeBinding(labelOrBinding, getColor, setColor)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
    button:SetSize(180, 24)
    button:SetText(binding.label)

    button:SetScript("OnClick", function()
        local color = binding.get()
        ColorPickerFrame:SetupColorPickerAndShow({
            r = color.r,
            g = color.g,
            b = color.b,
            hasOpacity = color.a ~= nil,
            swatchFunc = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                binding.set({ r = r, g = g, b = b, a = color.a })
            end,
            cancelFunc = function(previous)
                binding.set(previous)
            end,
        })
    end)

    return refreshBinding(button, binding)
end

-- Create a reusable action button row.
function UI.ButtonRow:Create(parent, labelOrBinding, y, onClick)
    local binding
    if type(labelOrBinding) == "table" then
        binding = labelOrBinding
    else
        binding = {
            label = labelOrBinding,
            set = onClick,
        }
    end

    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
    button:SetSize(180, 24)
    button:SetText(binding.label or "")
    button:SetScript("OnClick", function()
        if binding.set then
            binding.set()
        end
    end)

    return refreshBinding(button, binding)
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
        { value = "name", label = BFUF.L.TEXT_MODE_NAME },
        { value = "hidden", label = BFUF.L.TEXT_MODE_HIDDEN },
    } or {
        { value = "current", label = BFUF.L.TEXT_MODE_CURRENT },
        { value = "currentMax", label = BFUF.L.TEXT_MODE_CURRENT_MAX },
        { value = "percent", label = BFUF.L.TEXT_MODE_PERCENT },
        { value = "hidden", label = BFUF.L.TEXT_MODE_HIDDEN },
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
            controls.mode = UI.DropdownRow:Create(page, {
                label = BFUF.L.OPTION_DISPLAY_MODE,
                values = displayModes,
                get = function()
                    return BFUF.DB:Get("Player").texts[textKey].mode
                end,
                set = function(value)
                    BFUF.DB:Get("Player").texts[textKey].mode = value
                    updateText()
                end,
            }, -270)
        end
    end, resetText)

    self.playerTextControls = self.playerTextControls or {}
    self.playerTextControls[textKey] = controls
end

-- Show the contextual text navigation and preserve the current text controls.
function SettingsModule:ShowPlayerTextPage()
    local entries = {}

    self.textPages:ForEach(function(definition)
        table.insert(entries, {
            key = definition.id,
            label = definition.title,
            onSelect = definition.builder,
        })
    end)

    self.shell:SetContextEntries(entries)
    self.shell.contextTabs:Select("player.text.name")
end

-- Show the layer tabs for one text group without changing the text renderer.
function SettingsModule:ShowPlayerTextLayers(textKey)
    local registry = self.textLayerPages[textKey]
    local entries = {}

    registry:ForEach(function(definition)
        table.insert(entries, {
            key = definition.id,
            label = definition.title,
            onSelect = definition.builder,
        })
    end)

    self.shell:SetLayerEntries(entries)
    self.shell.layerTabs:Select("player.text." .. textKey .. ".layer1")
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

-- Register all navigation definitions independently from the settings views.
function SettingsModule:RegisterPages()
    if self.topLevelPages then
        return
    end

    self.topLevelPages = PageRegistry:Create()
    self.playerPages = PageRegistry:Create()
    self.textPages = PageRegistry:Create()
    self.textLayerPages = {
        health = PageRegistry:Create(),
        power = PageRegistry:Create(),
    }

    self.topLevelPages:Register({
        id = "general",
        title = BFUF.L.SETTINGS_PAGE_GENERAL,
        builder = function()
            self.shell:SetFrameEntries({})
            self:ShowGeneralPage()
        end,
    })
    self.topLevelPages:Register({
        id = "player",
        title = BFUF.L.SETTINGS_PAGE_PLAYER,
        builder = function()
            self:ShowPlayerPage()
        end,
    })

    local unavailablePages = {
        { id = "target", title = BFUF.L.SETTINGS_PAGE_TARGET },
        { id = "targetTarget", title = BFUF.L.SETTINGS_PAGE_TARGET_TARGET },
        { id = "focus", title = BFUF.L.SETTINGS_PAGE_FOCUS },
        { id = "focusTarget", title = BFUF.L.SETTINGS_PAGE_FOCUS_TARGET },
        { id = "pet", title = BFUF.L.SETTINGS_PAGE_PET },
        { id = "petTarget", title = BFUF.L.SETTINGS_PAGE_PET_TARGET },
        { id = "boss", title = BFUF.L.SETTINGS_PAGE_BOSS },
        { id = "arena", title = BFUF.L.SETTINGS_PAGE_ARENA },
    }

    for _, page in ipairs(unavailablePages) do
        page.disabled = true
        page.builder = function()
        end
        self.topLevelPages:Register(page)
    end

    self.topLevelPages:Register({
        id = "profiles",
        title = BFUF.L.SETTINGS_PAGE_PROFILES,
        builder = function()
            self.shell:SetFrameEntries({})
            self:ShowPlaceholderPage(BFUF.L.SETTINGS_PAGE_PROFILES, BFUF.L.DESCRIPTION_PROFILES)
        end,
    })
    self.topLevelPages:Register({
        id = "about",
        title = BFUF.L.SETTINGS_PAGE_ABOUT,
        builder = function()
            self.shell:SetFrameEntries({})
            self:ShowPlaceholderPage(BFUF.L.SETTINGS_PAGE_ABOUT, BFUF.L.DESCRIPTION_ABOUT)
        end,
    })

    local playerDefinitions = {
        {
            id = "player.general",
            title = BFUF.L.SETTINGS_PLAYER_GENERAL,
            navigation = true,
            builder = function(pages)
                self:ShowPlayerGeneralPage(pages)
            end,
        },
        {
            id = "player.bars",
            title = BFUF.L.SETTINGS_PLAYER_BARS,
            navigation = true,
            builder = function()
                self:ShowPlayerBarsPage()
            end,
        },
        {
            id = "player.portrait",
            title = BFUF.L.SETTINGS_PLAYER_PORTRAIT,
            navigation = true,
            builder = function(pages)
                self:ShowPlayerPortraitPage(pages)
            end,
        },
        {
            id = "player.health",
            title = BFUF.L.SETTINGS_PLAYER_HEALTH,
            context = "bars",
            builder = function(pages)
                self:ShowPlayerHealthPage(pages)
            end,
        },
        {
            id = "player.power",
            title = BFUF.L.SETTINGS_PLAYER_POWER,
            context = "bars",
            builder = function(pages)
                self:ShowPlayerPowerPage(pages)
            end,
        },
        {
            id = "player.text",
            title = BFUF.L.SETTINGS_PLAYER_TEXT,
            navigation = true,
            builder = function(pages)
                self:ShowPlayerTextPage(pages)
            end,
        },
        {
            id = "player.indicators",
            title = BFUF.L.SETTINGS_PLAYER_INDICATORS,
            navigation = true,
            builder = function(pages)
                self:ShowPlayerIndicatorsPage(pages)
            end,
        },
        {
            id = "player.resources",
            title = BFUF.L.SETTINGS_PLAYER_RESOURCES,
            navigation = true,
            builder = function(pages)
                pages:ShowPage(BFUF.L.SETTINGS_PLAYER_RESOURCES, BFUF.L.SETTINGS_DESCRIPTION_COMING_LATER, false)
            end,
        },
        {
            id = "player.auras",
            title = BFUF.L.SETTINGS_PLAYER_AURAS,
            navigation = true,
            builder = function(pages)
                pages:ShowPage(BFUF.L.SETTINGS_PLAYER_AURAS, BFUF.L.SETTINGS_DESCRIPTION_COMING_LATER, false)
            end,
        },
    }

    if BFUF.DebugEnabled then
        table.insert(playerDefinitions, {
            id = "player.advanced",
            title = BFUF.L.SETTINGS_PLAYER_ADVANCED,
            navigation = true,
            builder = function(pages)
                pages:ShowPage(BFUF.L.SETTINGS_PLAYER_ADVANCED, BFUF.L.SETTINGS_DESCRIPTION_COMING_LATER, false)
            end,
        })
    end

    for _, definition in ipairs(playerDefinitions) do
        self.playerPages:Register(definition)
    end

    local textDefinitions = {
        {
            id = "player.text.name",
            title = BFUF.L.SECTION_TEXT_NAME,
            builder = function()
                self.shell:SetLayerEntries({})
                self:ShowPlayerTextObjectPage(self.shell.pages, "name", BFUF.L.SECTION_TEXT_NAME)
            end,
        },
        {
            id = "player.text.health",
            title = BFUF.L.SECTION_TEXT_HEALTH,
            builder = function()
                self:ShowPlayerTextLayers("health")
            end,
        },
        {
            id = "player.text.power",
            title = BFUF.L.SECTION_TEXT_POWER,
            builder = function()
                self:ShowPlayerTextLayers("power")
            end,
        },
        {
            id = "player.text.level",
            title = BFUF.L.SECTION_TEXT_LEVEL,
            builder = function()
                self.shell:SetLayerEntries({})
                self:ShowPlayerTextObjectPage(self.shell.pages, "level", BFUF.L.SECTION_TEXT_LEVEL)
            end,
        },
    }

    for _, definition in ipairs(textDefinitions) do
        self.textPages:Register(definition)
    end

    for textKey, registry in pairs(self.textLayerPages) do
        registry:Register({
            id = "player.text." .. textKey .. ".layer1",
            title = BFUF.L.SETTINGS_TEXT_LAYER_1,
            builder = function()
                self:ShowPlayerTextObjectPage(
                    self.shell.pages,
                    textKey,
                    textKey == "health" and BFUF.L.SECTION_TEXT_HEALTH or BFUF.L.SECTION_TEXT_POWER
                )
            end,
        })
        registry:Register({
            id = "player.text." .. textKey .. ".layer2",
            title = BFUF.L.SETTINGS_TEXT_LAYER_2,
            builder = function()
                self:ShowPlaceholderPage(BFUF.L.SETTINGS_TEXT_LAYER_2, BFUF.L.SETTINGS_DESCRIPTION_COMING_LATER)
            end,
        })
        registry:Register({
            id = "player.text." .. textKey .. ".layer3",
            title = BFUF.L.SETTINGS_TEXT_LAYER_3,
            builder = function()
                self:ShowPlaceholderPage(BFUF.L.SETTINGS_TEXT_LAYER_3, BFUF.L.SETTINGS_DESCRIPTION_COMING_LATER)
            end,
        })
    end
end

-- Show the contextual Bars tabs without changing existing health or power controls.
function SettingsModule:ShowPlayerBarsPage()
    local entries = {
        {
            key = "player.health",
            label = BFUF.L.SETTINGS_PLAYER_HEALTH,
            onSelect = function()
                self:ShowPlayerHealthPage(self.shell.pages)
            end,
        },
        {
            key = "player.power",
            label = BFUF.L.SETTINGS_PLAYER_POWER,
            onSelect = function()
                self:ShowPlayerPowerPage(self.shell.pages)
            end,
        },
    }

    self.shell:SetContextEntries(entries)
    self.shell.contextTabs:Select("player.health")
end

-- Build the horizontal frame navigation used by the Player settings entry.
function SettingsModule:ShowPlayerPage()
    local entries = {}

    self.playerPages:ForEach(function(definition)
        if definition.navigation then
            table.insert(entries, {
                key = definition.id,
                label = definition.title,
                disabled = definition.disabled,
                onSelect = definition.builder,
            })
        end
    end)

    self.shell:SetFrameEntries(entries)
    self.shell.frameTabs:Select("player.general")
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
    rootFrame:SetScript("OnHide", function()
        self.shell.pages:ClearCache()
    end)

    self:RegisterPages()

    local topEntries = {}
    self.topLevelPages:ForEach(function(definition)
        table.insert(topEntries, {
            key = definition.id,
            label = definition.title,
            disabled = definition.disabled,
            onSelect = definition.builder,
        })
    end)

    self.shell:SetTopEntries(topEntries)
    self.shell.topTabs:Select("general")

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

    local selectedPage = self.shell.navigation.selectedKey or "general"
    self.shell.navigation:Select(selectedPage)

    Settings.OpenToCategory(self.category:GetID())
end

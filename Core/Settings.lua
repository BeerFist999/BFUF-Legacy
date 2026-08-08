local addonName, BFUF = ...

local SettingsInfrastructure = BFUF.Core.SettingsInfrastructure
local BindingFactory = SettingsInfrastructure.BindingFactory

local SettingsModule = {}
BFUF.Core.Settings = SettingsModule

local UI = {
    PagePanel = {},
    NavigationList = {},
    SidebarNavigation = {},
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

        if self.currentPage and self.currentPage._bfufTransient then
            self.currentPage:Hide()
            self.currentPage:SetParent(nil)
        end

        wipe(self.cacheOrder)
        self.currentPage = nil
    end

    function panel:ShowDefinition(definition)
        if self.currentPage then
            self.currentPage:Hide()
            if self.currentPage._bfufTransient then
                self.currentPage:SetParent(nil)
            end
        end

        local cacheable = definition.cache ~= false
        local page = cacheable and self.cache[definition.id] or nil
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

            if definition.hasSettings then
                local reset = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
                reset:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 0)
                reset:SetSize(150, 24)
                reset:SetText(BFUF.L.SETTINGS_RESET_PAGE)
                if definition.reset then
                    reset:SetScript("OnClick", definition.reset)
                end
            end

            if definition.builder then
                definition.builder(page)
            end

            page._bfufRefresh = definition.refresh
            page._bfufTransient = not cacheable
            if cacheable then
                self.cache[definition.id] = page
                table.insert(self.cacheOrder, definition.id)
                self:TrimCache()
            end
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
            cache = false,
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

-- Create a stable vertical navigation list for Settings modules and pages.
function UI.SidebarNavigation:Create(parent, width)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetWidth(width)

    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.06, 0.06, 0.06, 0.72)

    local navigation = {
        frame = frame,
        width = width,
        buttons = {},
        selectedKey = nil,
        nextOffset = -8,
    }

    function navigation:Clear()
        for _, item in pairs(self.buttons) do
            item.button:Hide()
            item.button:SetParent(nil)
        end

        wipe(self.buttons)
        self.selectedKey = nil
        self.nextOffset = -8
    end

    function navigation:AddEntry(entry)
        local button = CreateFrame("Button", nil, self.frame)
        button:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 6, self.nextOffset)
        button:SetSize(self.width - 12, 26)
        self.nextOffset = self.nextOffset - 28

        local highlight = button:CreateTexture(nil, "BACKGROUND")
        highlight:SetAllPoints()
        highlight:SetColorTexture(0.2, 0.55, 0.35, 0.32)
        highlight:Hide()

        local label = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("LEFT", button, "LEFT", 8, 0)
        label:SetPoint("RIGHT", button, "RIGHT", -8, 0)
        label:SetJustifyH("LEFT")
        label:SetWordWrap(false)
        label:SetText(entry.label)

        if entry.disabled then
            label:SetTextColor(0.5, 0.5, 0.5)
            button:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
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
            highlight = highlight,
            label = label,
        }
    end

    function navigation:SetEntries(entries)
        self:Clear()
        for _, entry in ipairs(entries) do
            self:AddEntry(entry)
        end
    end

    function navigation:Select(key)
        local selected = self.buttons[key]
        if not selected or selected.entry.disabled then
            return
        end

        self.selectedKey = key
        for buttonKey, item in pairs(self.buttons) do
            local active = buttonKey == key
            item.highlight:SetShown(active)
            item.label:SetTextColor(
                active and 1 or 0.85,
                active and 1 or 0.85,
                active and 1 or 0.85
            )
        end

        selected.entry.onSelect()
    end

    return navigation
end

-- Create a reusable horizontal tab bar with an overflow popup.
function UI.TabBar:Create(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(24)

    local tabBar = {
        frame = frame,
        buttons = {},
        entries = {},
        entryOrder = {},
        selectedKey = nil,
        overflowWidth = 30,
        tabSpacing = 4,
    }

    local overflowButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    overflowButton:SetSize(tabBar.overflowWidth, 24)
    overflowButton:SetText("»")
    overflowButton:Hide()
    tabBar.overflowButton = overflowButton

    function tabBar:Clear()
        for _, item in pairs(self.buttons) do
            item.button:Hide()
            item.button:SetParent(nil)
        end

        wipe(self.buttons)
        wipe(self.entries)
        wipe(self.entryOrder)
        self.selectedKey = nil
        self.overflowButton:Hide()
        self.frame:Hide()
    end

    function tabBar:AddEntry(entry)
        local button = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
        button:SetText(entry.label)

        local fontString = button:GetFontString()
        local textWidth = fontString and fontString:GetStringWidth() or 0
        local width = math.max(58, textWidth + 24)

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
            desiredWidth = width,
            inOverflow = false,
        }
        self.entries[entry.key] = entry
        table.insert(self.entryOrder, entry)
        self.frame:Show()
    end

    function tabBar:ShowOverflowMenu()
        MenuUtil.CreateContextMenu(self.overflowButton, function(_, rootDescription)
            for _, entry in ipairs(self.entryOrder) do
                local item = self.buttons[entry.key]
                if item and item.inOverflow then
                    rootDescription:CreateButton(entry.label, function()
                        self:Select(entry.key)
                    end)
                end
            end
        end)
    end

    overflowButton:SetScript("OnClick", function()
        tabBar:ShowOverflowMenu()
    end)

    function tabBar:Relayout()
        local availableWidth = math.max(self.frame:GetWidth(), 0)
        local totalWidth = 0
        for _, entry in ipairs(self.entryOrder) do
            local item = self.buttons[entry.key]
            totalWidth = totalWidth + item.desiredWidth
        end
        totalWidth = totalWidth + math.max(#self.entryOrder - 1, 0) * self.tabSpacing

        local hasOverflow = totalWidth > availableWidth
        local overflowWidth = math.max(1, math.min(self.overflowWidth, availableWidth))
        local visibleWidth = hasOverflow and math.max(0, availableWidth - overflowWidth - self.tabSpacing) or availableWidth
        local usedWidth = 0

        for _, entry in ipairs(self.entryOrder) do
            local item = self.buttons[entry.key]
            local spacing = usedWidth > 0 and self.tabSpacing or 0
            local fits = usedWidth + spacing + item.desiredWidth <= visibleWidth

            item.inOverflow = hasOverflow and not fits
            item.button:Hide()

            if not item.inOverflow then
                item.button:ClearAllPoints()
                item.button:SetPoint("LEFT", self.frame, "LEFT", usedWidth + spacing, 0)
                item.button:SetSize(item.desiredWidth, 24)
                item.button:Show()
                usedWidth = usedWidth + spacing + item.desiredWidth
            end
        end

        self.overflowButton:ClearAllPoints()
        self.overflowButton:SetShown(hasOverflow)
        if hasOverflow then
            self.overflowButton:SetSize(overflowWidth, 24)
            self.overflowButton:SetPoint("RIGHT", self.frame, "RIGHT", 0, 0)
        end
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

-- Create the stable Settings shell with sidebar navigation and one content host.
function UI.SettingsShell:Create(parent)
    local shell = CreateFrame("Frame", nil, parent)
    shell:SetAllPoints()

    local sidebar = UI.SidebarNavigation:Create(shell, 160)
    sidebar.frame:SetPoint("TOPLEFT", shell, "TOPLEFT", 12, -12)
    sidebar.frame:SetPoint("BOTTOMLEFT", shell, "BOTTOMLEFT", 12, 12)

    local sidebarDivider = shell:CreateTexture(nil, "ARTWORK")
    sidebarDivider:SetPoint("TOPLEFT", sidebar.frame, "TOPRIGHT", 10, 0)
    sidebarDivider:SetPoint("BOTTOMLEFT", sidebar.frame, "BOTTOMRIGHT", 10, 0)
    sidebarDivider:SetWidth(1)
    sidebarDivider:SetColorTexture(0.35, 0.35, 0.35, 0.7)

    local frameNavigation = UI.SidebarNavigation:Create(shell, 132)
    frameNavigation.frame:SetPoint("TOPLEFT", sidebarDivider, "TOPRIGHT", 12, 0)
    frameNavigation.frame:SetPoint("BOTTOMLEFT", sidebarDivider, "BOTTOMRIGHT", 12, 0)
    frameNavigation.frame:Hide()

    local frameDivider = shell:CreateTexture(nil, "ARTWORK")
    frameDivider:SetPoint("TOPLEFT", frameNavigation.frame, "TOPRIGHT", 10, 0)
    frameDivider:SetPoint("BOTTOMLEFT", frameNavigation.frame, "BOTTOMRIGHT", 10, 0)
    frameDivider:SetWidth(1)
    frameDivider:SetColorTexture(0.35, 0.35, 0.35, 0.7)
    frameDivider:Hide()

    local pageHost = UI.ScrollablePageHost:Create(shell)

    local settingsShell = {
        frame = shell,
        sidebar = sidebar,
        frameNavigation = frameNavigation,
        pageHost = pageHost,
    }
    settingsShell.navigation = sidebar
    settingsShell.pages = UI.PagePanel:Create(pageHost)

    function settingsShell:UpdateLayout()
        self.pageHost.frame:ClearAllPoints()
        if next(self.frameNavigation.buttons) then
            self.frameNavigation.frame:Show()
            frameDivider:Show()
            self.pageHost.frame:SetPoint("TOPLEFT", frameDivider, "TOPRIGHT", 12, 0)
        else
            self.frameNavigation.frame:Hide()
            frameDivider:Hide()
            self.pageHost.frame:SetPoint("TOPLEFT", sidebarDivider, "TOPRIGHT", 12, 0)
        end
        self.pageHost.frame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -12, 12)
    end

    function settingsShell:SetSidebarEntries(entries)
        self.sidebar:SetEntries(entries)
    end

    function settingsShell:SetFrameEntries(entries)
        self.frameNavigation:SetEntries(entries or {})
        self:UpdateLayout()
    end

    shell:SetScript("OnSizeChanged", function()
        settingsShell:UpdateLayout()
    end)

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

-- Show the contextual navigation for the existing player indicators.
function SettingsModule:ShowPlayerIndicatorsPage()
    local entries = {}

    self.indicatorPages:ForEach(function(definition)
        table.insert(entries, {
            key = definition.id,
            label = definition.title,
            onSelect = definition.builder,
        })
    end)

    self.shell:SetContextEntries(entries)
    self.shell.contextTabs:Select("player.indicators.combat")
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
    local function resetPortrait()
        local portrait = BFUF.DB:Get("Player").portrait
        local defaults = BFUF.Defaults.profile.Player.portrait
        portrait.width = defaults.width
        BFUF.Frames.Player:UpdateLayout()

        if controls.width then
            controls.width.Refresh()
        end
    end

    pages:ShowPage(BFUF.L.SETTINGS_PLAYER_PORTRAIT, nil, true, function(page)
        UI.SectionPanel:Create(page, BFUF.L.SECTION_PORTRAIT, -36)

        controls.width = UI.SliderRow:Create(
            page,
            BFUF.L.OPTION_PORTRAIT_WIDTH,
            -68,
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

-- Show one lightweight shell page without creating configuration controls.
function SettingsModule:ShowShellPage(id, title, description)
    self.shell.pages:ShowDefinition({
        id = id,
        title = title,
        description = description or BFUF.L.SETTINGS_DESCRIPTION_COMING_LATER,
        hasSettings = false,
        builder = function()
        end,
        refresh = function()
        end,
    })
end

-- Refresh the basic layout controls of a frame page after drag or reset.
function SettingsModule:RefreshFrameLayoutControls(profileKey)
    local controls = self.frameLayoutControls and self.frameLayoutControls[profileKey]
    if not controls then
        return
    end

    for _, control in pairs(controls) do
        control:Refresh()
    end
end

-- Build the shared layout page through profile bindings and refresh intents.
function SettingsModule:ShowBasicFrameLayoutPage(profileKey, frameModule, title, lockLabel, unlockLabel)
    local intent = profileKey == "Player" and "PLAYER_LAYOUT" or "TARGET_LAYOUT"
    local context = { unit = profileKey == "Player" and "player" or "target" }
    local options = {
        { key = "width", label = "OPTION_FRAME_WIDTH", minValue = 120, maxValue = 600, step = 1 },
        { key = "height", label = "OPTION_FRAME_HEIGHT", minValue = 20, maxValue = 200, step = 1 },
        { key = "scale", label = "OPTION_FRAME_SCALE", minValue = 0.5, maxValue = 2, step = 0.05 },
        { key = "positionX", label = "OPTION_POSITION_X", minValue = -1000, maxValue = 1000, step = 1 },
        { key = "positionY", label = "OPTION_POSITION_Y", minValue = -1000, maxValue = 1000, step = 1 },
    }

    self.frameLayoutControls = self.frameLayoutControls or {}
    local controls = {}
    local bindings = {}

    for _, option in ipairs(options) do
        local optionKey = option.key
        local definition = {
            label = BFUF.L[option.label],
            refreshIntent = intent,
            context = context,
        }

        if optionKey == "positionX" or optionKey == "positionY" then
            definition.profileKey = profileKey
            definition.key = optionKey
            bindings[optionKey] = BindingFactory:CreatePositionBinding(definition)
        else
            definition.path = profileKey .. "." .. optionKey
            bindings[optionKey] = BindingFactory:CreateProfileBinding(definition)
        end
    end

    local function refreshControls()
        self:RefreshFrameLayoutControls(profileKey)
    end

    local function resetPosition()
        BindingFactory:ResetPosition(profileKey, intent, context)
        refreshControls()
    end

    local function resetFrameDefaults()
        BindingFactory:ResetProfileSection(profileKey, intent, context)
        refreshControls()
    end

    self.shell.pages:ShowPage(title, nil, true, function(page)
        UI.SectionPanel:Create(page, BFUF.L.SECTION_LAYOUT, -36)

        for index, option in ipairs(options) do
            controls[option.key] = UI.SliderRow:Create(
                page,
                bindings[option.key],
                -66 - (index - 1) * 58,
                option.minValue,
                option.maxValue,
                option.step
            )
        end

        local lockButton
        lockButton = UI.ButtonRow:Create(page, "", -372, function()
            frameModule:SetLayoutUnlocked(not frameModule:IsLayoutUnlocked())
            lockButton:SetText(
                frameModule:IsLayoutUnlocked() and lockLabel or unlockLabel
            )
        end)
        lockButton:SetText(
            frameModule:IsLayoutUnlocked() and lockLabel or unlockLabel
        )

        UI.ButtonRow:Create(page, BFUF.L.BUTTON_RESET_POSITION, -404, resetPosition)
        UI.ButtonRow:Create(page, BFUF.L.BUTTON_RESET_DEFAULTS, -436, resetFrameDefaults)
    end, resetPosition)

    self.frameLayoutControls[profileKey] = controls
end

-- Show the Target portrait page through shared profile bindings.
function SettingsModule:ShowTargetPortraitPage()
    local context = { unit = "target" }
    local widthBinding = BindingFactory:CreateProfileBinding({
        path = "Target.portrait.width",
        label = BFUF.L.OPTION_PORTRAIT_WIDTH,
        refreshIntent = "PORTRAIT",
        context = context,
    })

    local function resetPortrait()
        BindingFactory:Reset({ widthBinding })
    end

    self.shell.pages:ShowPage(BFUF.L.SETTINGS_PLAYER_PORTRAIT, nil, true, function(page)
        UI.SectionPanel:Create(page, BFUF.L.SECTION_PORTRAIT, -36)
        UI.SliderRow:Create(page, widthBinding, -66, 20, 160, 1)
    end, resetPortrait)
end

-- Show the Player portrait page through shared profile bindings.
function SettingsModule:ShowPlayerPortraitPage()
    BFUF.Frames.Player:EnsurePortraitSettings()

    local context = { unit = "player" }
    local widthBinding = BindingFactory:CreateProfileBinding({
        path = "Player.portrait.width",
        label = BFUF.L.OPTION_PORTRAIT_WIDTH,
        refreshIntent = "PORTRAIT",
        context = context,
    })

    local function resetPortrait()
        BindingFactory:Reset({ widthBinding })
    end

    self.shell.pages:ShowPage(BFUF.L.SETTINGS_PLAYER_PORTRAIT, nil, true, function(page)
        UI.SectionPanel:Create(page, BFUF.L.SECTION_PORTRAIT, -36)
        UI.SliderRow:Create(page, widthBinding, -66, 20, 160, 1)
    end, resetPortrait)
end

-- Show the Boss Frames foundation controls without changing Player or Target settings.
function SettingsModule:ShowBossFramePage()
    local context = { unit = "boss" }
    local bindings = {
        enabled = BindingFactory:CreateProfileBinding({
            path = "Boss.enabled",
            label = BFUF.L.OPTION_ENABLE_BOSS_FRAMES,
            refreshIntent = "BOSS_LAYOUT",
            context = context,
        }),
        preview = BindingFactory:CreateProfileBinding({
            path = "Boss.preview",
            label = BFUF.L.OPTION_PREVIEW_BOSS_FRAMES,
            refreshIntent = "BOSS_LAYOUT",
            context = context,
        }),
        count = BindingFactory:CreateProfileBinding({
            path = "Boss.count",
            label = BFUF.L.OPTION_BOSS_FRAME_COUNT,
            refreshIntent = "BOSS_LAYOUT",
            context = context,
        }),
        width = BindingFactory:CreateProfileBinding({
            path = "Boss.width",
            label = BFUF.L.OPTION_FRAME_WIDTH,
            refreshIntent = "BOSS_LAYOUT",
            context = context,
        }),
        height = BindingFactory:CreateProfileBinding({
            path = "Boss.height",
            label = BFUF.L.OPTION_FRAME_HEIGHT,
            refreshIntent = "BOSS_LAYOUT",
            context = context,
        }),
        spacing = BindingFactory:CreateProfileBinding({
            path = "Boss.spacing",
            label = BFUF.L.OPTION_BOSS_SPACING,
            refreshIntent = "BOSS_LAYOUT",
            context = context,
        }),
        growth = BindingFactory:CreateProfileBinding({
            path = "Boss.growth",
            label = BFUF.L.OPTION_BOSS_GROWTH,
            refreshIntent = "BOSS_LAYOUT",
            context = context,
            values = {
                { value = "UP", label = BFUF.L.GROWTH_UP },
                { value = "DOWN", label = BFUF.L.GROWTH_DOWN },
            },
        }),
    }

    self.shell.pages:ShowPage(BFUF.L.SETTINGS_BOSS_FRAMES, nil, true, function(page)
        UI.SectionPanel:Create(page, BFUF.L.SETTINGS_BOSS_FRAMES, -36)
        UI.CheckboxRow:Create(page, bindings.enabled, -66)
        UI.CheckboxRow:Create(page, bindings.preview, -94)
        UI.SliderRow:Create(page, bindings.count, -122, 1, 5, 1)
        UI.SliderRow:Create(page, bindings.width, -180, 120, 600, 1)
        UI.SliderRow:Create(page, bindings.height, -238, 20, 200, 1)
        UI.SliderRow:Create(page, bindings.spacing, -296, 0, 100, 1)
        UI.DropdownRow:Create(page, bindings.growth, -354)
    end, function()
        BindingFactory:Reset(bindings)
    end)
end

-- Show the single Boss portrait visibility setting.
function SettingsModule:ShowBossPortraitPage()
    local binding = BindingFactory:CreateProfileBinding({
        path = "Boss.portrait.enabled",
        label = BFUF.L.OPTION_BOSS_PORTRAIT_ENABLED,
        refreshIntent = "BOSS_LAYOUT",
        context = { unit = "boss" },
    })

    self.shell.pages:ShowPage(BFUF.L.SECTION_PORTRAIT, nil, true, function(page)
        UI.SectionPanel:Create(page, BFUF.L.SECTION_PORTRAIT, -36)
        UI.CheckboxRow:Create(page, binding, -66)
    end, function()
        BindingFactory:Reset({ binding })
    end)
end

-- Build the second-level navigation for a frame module.
function SettingsModule:ShowShellFrame(frameKey, title, isFuture)
    local hasBasicLayout = frameKey == "player" or frameKey == "target" or frameKey == "boss"
    local pageDefinitions = {
        { key = "general", title = BFUF.L.SETTINGS_PLAYER_GENERAL, disabled = isFuture == true },
        { key = "bars", title = BFUF.L.SETTINGS_PLAYER_BARS, disabled = true },
        { key = "portrait", title = BFUF.L.SETTINGS_PLAYER_PORTRAIT, disabled = frameKey ~= "player" and frameKey ~= "target" and frameKey ~= "boss" },
        { key = "text", title = BFUF.L.SETTINGS_PLAYER_TEXT, disabled = true },
        { key = "indicators", title = BFUF.L.SETTINGS_PLAYER_INDICATORS, disabled = true },
        { key = "resources", title = BFUF.L.SETTINGS_PLAYER_RESOURCES, disabled = true },
        { key = "auras", title = BFUF.L.SETTINGS_PLAYER_AURAS, disabled = true },
    }

    local entries = {}
    for _, definition in ipairs(pageDefinitions) do
        local pageId = frameKey .. "::" .. definition.key
        table.insert(entries, {
            key = pageId,
            label = definition.title,
            disabled = definition.disabled,
            onSelect = function()
                if definition.key == "general" and hasBasicLayout then
                    if frameKey == "player" then
                        self:ShowBasicFrameLayoutPage(
                            "Player",
                            BFUF.Frames.Player,
                            definition.title,
                            BFUF.L.BUTTON_LOCK_PLAYER_FRAME,
                            BFUF.L.BUTTON_UNLOCK_PLAYER_FRAME
                        )
                    elseif frameKey == "target" then
                        self:ShowBasicFrameLayoutPage(
                            "Target",
                            BFUF.Frames.Target,
                            definition.title,
                            BFUF.L.BUTTON_LOCK_TARGET_FRAME,
                            BFUF.L.BUTTON_UNLOCK_TARGET_FRAME
                        )
                    else
                        self:ShowBossFramePage()
                    end
                    return
                end

                if definition.key == "portrait" then
                    if frameKey == "player" then
                        self:ShowPlayerPortraitPage()
                    elseif frameKey == "target" then
                        self:ShowTargetPortraitPage()
                    elseif frameKey == "boss" then
                        self:ShowBossPortraitPage()
                    end
                    return
                end

                self:ShowShellPage(pageId, definition.title)
            end,
        })
    end

    self.shell:SetFrameEntries(entries)
    if isFuture then
        self:ShowShellPage(frameKey, title)
    else
        self.shell.frameNavigation:Select(frameKey .. "::general")
    end
end

-- Register only the visual shell navigation used during this migration sprint.
function SettingsModule:RegisterShellPages()
    if self.shellPages then
        return
    end

    self.shellPages = PageRegistry:Create()
    local futureFrames = {
        { key = "targetTarget", title = BFUF.L.SETTINGS_PAGE_TARGET_TARGET },
        { key = "focus", title = BFUF.L.SETTINGS_PAGE_FOCUS },
        { key = "focusTarget", title = BFUF.L.SETTINGS_PAGE_FOCUS_TARGET },
        { key = "pet", title = BFUF.L.SETTINGS_PAGE_PET },
        { key = "petTarget", title = BFUF.L.SETTINGS_PAGE_PET_TARGET },
    }

    self.shellPages:Register({
        id = "general",
        title = BFUF.L.SETTINGS_PAGE_GENERAL,
        builder = function()
            self.shell:SetFrameEntries({})
            self:ShowShellPage("general", BFUF.L.SETTINGS_PAGE_GENERAL)
        end,
        refresh = function()
        end,
    })
    self.shellPages:Register({
        id = "player",
        title = BFUF.L.SETTINGS_PAGE_PLAYER,
        builder = function()
            self:ShowShellFrame("player", BFUF.L.SETTINGS_PAGE_PLAYER, false)
        end,
        refresh = function()
        end,
    })
    self.shellPages:Register({
        id = "target",
        title = BFUF.L.SETTINGS_PAGE_TARGET,
        builder = function()
            self:ShowShellFrame("target", BFUF.L.SETTINGS_PAGE_TARGET, false)
        end,
        refresh = function()
        end,
    })

    self.shellPages:Register({
        id = "boss",
        title = BFUF.L.SETTINGS_PAGE_BOSS,
        builder = function()
            self:ShowShellFrame("boss", BFUF.L.SETTINGS_PAGE_BOSS, false)
        end,
        refresh = function()
        end,
    })

    for _, frame in ipairs(futureFrames) do
        local frameKey = frame.key
        local frameTitle = frame.title
        self.shellPages:Register({
            id = frameKey,
            title = frameTitle,
            builder = function()
                self:ShowShellFrame(frameKey, frameTitle, true)
            end,
            refresh = function()
            end,
        })
    end

    self.shellPages:Register({
        id = "profiles",
        title = BFUF.L.SETTINGS_PAGE_PROFILES,
        builder = function()
            self.shell:SetFrameEntries({})
            self:ShowShellPage("profiles", BFUF.L.SETTINGS_PAGE_PROFILES, BFUF.L.DESCRIPTION_PROFILES)
        end,
        refresh = function()
        end,
    })
    self.shellPages:Register({
        id = "about",
        title = BFUF.L.SETTINGS_PAGE_ABOUT,
        builder = function()
            self.shell:SetFrameEntries({})
            self:ShowShellPage("about", BFUF.L.SETTINGS_PAGE_ABOUT, BFUF.L.DESCRIPTION_ABOUT)
        end,
        refresh = function()
        end,
    })
end

-- Register all navigation definitions independently from the settings views.
function SettingsModule:RegisterPages()
    if self.topLevelPages then
        return
    end

    self.topLevelPages = PageRegistry:Create()
    self.playerPages = PageRegistry:Create()
    self.textPages = PageRegistry:Create()
    self.indicatorPages = PageRegistry:Create()
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
            builder = function()
                self:ShowPlayerGeneralPage(self.shell.pages)
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
            builder = function()
                self:ShowPlayerPortraitPage(self.shell.pages)
            end,
        },
        {
            id = "player.health",
            title = BFUF.L.SETTINGS_PLAYER_HEALTH,
            context = "bars",
            builder = function()
                self:ShowPlayerHealthPage(self.shell.pages)
            end,
        },
        {
            id = "player.power",
            title = BFUF.L.SETTINGS_PLAYER_POWER,
            context = "bars",
            builder = function()
                self:ShowPlayerPowerPage(self.shell.pages)
            end,
        },
        {
            id = "player.text",
            title = BFUF.L.SETTINGS_PLAYER_TEXT,
            navigation = true,
            builder = function()
                self:ShowPlayerTextPage()
            end,
        },
        {
            id = "player.indicators",
            title = BFUF.L.SETTINGS_PLAYER_INDICATORS,
            navigation = true,
            builder = function()
                self:ShowPlayerIndicatorsPage()
            end,
        },
        {
            id = "player.resources",
            title = BFUF.L.SETTINGS_PLAYER_RESOURCES,
            navigation = true,
            builder = function()
                self.shell.pages:ShowPage(BFUF.L.SETTINGS_PLAYER_RESOURCES, BFUF.L.SETTINGS_DESCRIPTION_COMING_LATER, false)
            end,
        },
        {
            id = "player.auras",
            title = BFUF.L.SETTINGS_PLAYER_AURAS,
            navigation = true,
            builder = function()
                self.shell.pages:ShowPage(BFUF.L.SETTINGS_PLAYER_AURAS, BFUF.L.SETTINGS_DESCRIPTION_COMING_LATER, false)
            end,
        },
    }

    if BFUF.DebugEnabled then
        table.insert(playerDefinitions, {
            id = "player.advanced",
            title = BFUF.L.SETTINGS_PLAYER_ADVANCED,
            navigation = true,
            builder = function()
                self.shell.pages:ShowPage(BFUF.L.SETTINGS_PLAYER_ADVANCED, BFUF.L.SETTINGS_DESCRIPTION_COMING_LATER, false)
            end,
        })
    end

    for _, definition in ipairs(playerDefinitions) do
        self.playerPages:Register(definition)
    end

    local indicators = {
        { key = "combat", title = BFUF.L.INDICATOR_COMBAT },
        { key = "resting", title = BFUF.L.INDICATOR_RESTING },
        { key = "leader", title = BFUF.L.INDICATOR_LEADER },
        { key = "assistant", title = BFUF.L.INDICATOR_ASSISTANT },
        { key = "pvp", title = BFUF.L.INDICATOR_PVP },
        { key = "afk", title = BFUF.L.INDICATOR_AFK },
        { key = "dnd", title = BFUF.L.INDICATOR_DND },
    }

    for _, indicator in ipairs(indicators) do
        local indicatorKey = indicator.key
        local indicatorTitle = indicator.title
        self.indicatorPages:Register({
            id = "player.indicators." .. indicatorKey,
            title = indicatorTitle,
            builder = function()
                self:ShowPlayerIndicatorPage(self.shell.pages, indicatorKey, indicatorTitle)
            end,
        })
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
    local entries = {}

    self.playerPages:ForEach(function(definition)
        if definition.context == "bars" then
            table.insert(entries, {
                key = definition.id,
                label = definition.title,
                onSelect = definition.builder,
            })
        end
    end)

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

-- Create the independent BFUF settings host used outside Blizzard Settings.
function SettingsModule:CreateStandaloneWindow()
    if self.window then
        return self.window
    end

    local window = CreateFrame("Frame", "BFUFSettingsWindow", UIParent)
    window:SetSize(980, 680)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetToplevel(true)
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetUserPlaced(true)
    window:Hide()

    local background = window:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.045, 0.045, 0.055, 0.98)

    local borderColor = { 0.22, 0.22, 0.28, 1 }
    local borders = {
        { "TOPLEFT", "TOPRIGHT", 1 },
        { "BOTTOMLEFT", "BOTTOMRIGHT", 1 },
        { "TOPLEFT", "BOTTOMLEFT", 1, true },
        { "TOPRIGHT", "BOTTOMRIGHT", 1, true },
    }
    for _, edge in ipairs(borders) do
        local border = window:CreateTexture(nil, "BORDER")
        border:SetColorTexture(unpack(borderColor))
        border:SetPoint(edge[1], window, edge[1], 0, 0)
        border:SetPoint(edge[2], window, edge[2], 0, 0)
        if edge[4] then
            border:SetWidth(edge[3])
        else
            border:SetHeight(edge[3])
        end
    end

    local content = CreateFrame("Frame", nil, window)
    content:SetPoint("TOPLEFT", window, "TOPLEFT", 1, -38)
    content:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -1, 1)

    local header = CreateFrame("Frame", nil, window)
    header:SetPoint("TOPLEFT", window, "TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", window, "TOPRIGHT", -1, -1)
    header:SetHeight(36)

    local headerBackground = header:CreateTexture(nil, "BACKGROUND")
    headerBackground:SetAllPoints()
    headerBackground:SetColorTexture(0.09, 0.09, 0.12, 1)

    local title = header:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    title:SetPoint("LEFT", header, "LEFT", 14, 0)
    title:SetText(BFUF.L.ADDON_NAME)

    local close = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    close:SetPoint("RIGHT", header, "RIGHT", -2, 0)
    close:SetScript("OnClick", function()
        window:Hide()
    end)

    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function()
        window:StartMoving()
    end)
    header:SetScript("OnDragStop", function()
        window:StopMovingOrSizing()
        window:SetUserPlaced(true)
    end)

    self.window = window
    self.shell = UI.SettingsShell:Create(content)
    return window
end

-- Open the standalone host from either slash commands or the Blizzard proxy category.
function SettingsModule:OpenStandalone()
    self:Initialize()
    self.window:Show()
    self.window:Raise()

    local selectedPage = self.shell.navigation.selectedKey or "general"
    self.shell.navigation:Select(selectedPage)
end

-- Redirect the legacy Blizzard Settings category to the standalone window.
function SettingsModule:OpenFromBlizzardSettings()
    if self.openingFromBlizzardSettings then
        return
    end

    self.openingFromBlizzardSettings = true
    C_Timer.After(0, function()
        self.openingFromBlizzardSettings = false
        self:OpenStandalone()

        if SettingsPanel and SettingsPanel:IsShown() then
            HideUIPanel(SettingsPanel)
        end
    end)
end

-- Register the shell and preserve legacy pages until each replacement has been validated.
function SettingsModule:Initialize()
    if self.window then
        return
    end

    local proxyFrame = CreateFrame("Frame")
    proxyFrame:SetSize(1, 1)
    self.category = Settings.RegisterCanvasLayoutCategory(proxyFrame, BFUF.L.ADDON_NAME)
    Settings.RegisterAddOnCategory(self.category)

    if self.category.SetOnRefresh then
        self.category:SetOnRefresh(function()
            self:OpenFromBlizzardSettings()
        end)
    end

    proxyFrame:SetScript("OnShow", function()
        self:OpenFromBlizzardSettings()
    end)

    self:CreateStandaloneWindow()
    self:RegisterShellPages()

    local entries = {}
    self.shellPages:ForEach(function(definition)
        table.insert(entries, {
            key = definition.id,
            label = definition.title,
            onSelect = definition.builder,
        })
    end)

    self.shell:SetSidebarEntries(entries)
    self.shell.sidebar:Select("general")

    -- Keep legacy modules available internally without publishing old pages to Blizzard Settings.
    self.legacyPages = {
        General = BFUF.Config.General,
        Player = BFUF.Config.Player,
        Indicators = BFUF.Config.Indicators,
        Profiles = BFUF.Config.Profiles,
        About = BFUF.Config.About,
    }
end

-- Open the standalone BFUF Settings window.
function SettingsModule:Open()
    self:OpenStandalone()
end

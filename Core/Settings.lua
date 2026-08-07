local addonName, BFUF = ...

local SettingsModule = {}
BFUF.Core.Settings = SettingsModule

local UI = {}
SettingsModule.UI = UI

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

    function panel:ShowPage(title, description, hasSettings, buildContent)
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
            buttonItem.button:Enable(buttonKey ~= key)
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

-- Create a reusable slider row.
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
    slider:SetValue(getValue())

    slider:SetScript("OnValueChanged", function(_, value)
        setValue(value)
    end)

    return slider
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

-- Create an informational placeholder page.
function SettingsModule:ShowPlaceholderPage(title, description)
    self.shell.pages:ShowPage(title, description or BFUF.L.SETTINGS_DESCRIPTION_COMING_LATER, false)
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
        entry.onSelect = function()
            pages:ShowPage(entry.label, BFUF.L.SETTINGS_DESCRIPTION_COMING_LATER, false)
        end
        navigation:AddEntry(entry)
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
                self:ShowPlaceholderPage(BFUF.L.SETTINGS_PAGE_GENERAL, BFUF.L.DESCRIPTION_GENERAL)
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

    self.legacyCategories = {
        General = BFUF.Config.General:Create(self.category),
        Player = BFUF.Config.Player:Create(self.category),
        Indicators = BFUF.Config.Indicators:Create(self.category),
        Profiles = BFUF.Config.Profiles:Create(self.category),
        About = BFUF.Config.About:Create(self.category),
    }
end

-- Open the root BFUF category in Blizzard Settings.
function SettingsModule:Open()
    self:Initialize()
    Settings.OpenToCategory(self.category:GetID())
end

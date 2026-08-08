local addonName, BFUF = ...

BFUF.Core = BFUF.Core or {}

-- Render declarative controls through the existing reusable Settings widgets.
local ControlRegistry = {}
BFUF.Core.SettingsControlRegistry = ControlRegistry

local supportedTypes = {
    checkbox = true,
    slider = true,
    dropdown = true,
    color = true,
    input = true,
    header = true,
    description = true,
    spacer = true,
}

local function isAvailable(descriptor)
    if descriptor.availability == nil then
        return true
    end

    if type(descriptor.availability) == "function" then
        return descriptor.availability() == true
    end

    return descriptor.availability == true
end

local function resolveBinding(descriptor)
    local binding = descriptor.binding
    if not binding then
        return nil
    end

    -- Descriptor metadata decorates a binding without changing its API.
    if descriptor.label or descriptor.values then
        local decorated = {}
        for key, value in pairs(binding) do
            decorated[key] = value
        end
        decorated.label = descriptor.label or binding.label
        decorated.values = descriptor.values or binding.values
        return decorated
    end

    return binding
end

function ControlRegistry:Validate(descriptor)
    assert(type(descriptor) == "table", "Settings control descriptor must be a table")
    assert(supportedTypes[descriptor.type], "Unsupported settings control type: " .. tostring(descriptor.type))

    if descriptor.type ~= "header" and descriptor.type ~= "description" and descriptor.type ~= "spacer" then
        assert(descriptor.key, "Interactive settings control must have a key")
        assert(descriptor.binding, "Interactive settings control must have a binding")
    end
end

function ControlRegistry:Render(parent, controls)
    local settings = BFUF.Core.Settings
    local UI = settings and settings.UI
    assert(UI, "Settings UI must be initialized before rendering controls")

    local rendered = {}
    local offset = -36

    for _, descriptor in ipairs(controls or {}) do
        self:Validate(descriptor)

        if isAvailable(descriptor) then
            local control
            local binding = resolveBinding(descriptor)

            if descriptor.type == "header" then
                control = UI.SectionPanel:Create(parent, descriptor.label, offset)
                offset = offset - 32
            elseif descriptor.type == "description" then
                control = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
                control:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, offset)
                control:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -24, offset)
                control:SetJustifyH("LEFT")
                control:SetText(descriptor.description or descriptor.label or "")
                offset = offset - (descriptor.height or 28)
            elseif descriptor.type == "spacer" then
                offset = offset - (descriptor.height or 16)
            elseif descriptor.type == "checkbox" then
                control = UI.CheckboxRow:Create(parent, binding, offset)
                offset = offset - 30
            elseif descriptor.type == "slider" then
                control = UI.SliderRow:Create(
                    parent,
                    binding,
                    offset,
                    descriptor.min,
                    descriptor.max,
                    descriptor.step
                )
                offset = offset - 58
            elseif descriptor.type == "dropdown" then
                control = UI.DropdownRow:Create(parent, binding, offset)
                offset = offset - 32
            elseif descriptor.type == "color" then
                control = UI.ColorRow:Create(parent, binding, offset)
                offset = offset - 32
            elseif descriptor.type == "input" then
                local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
                input:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, offset)
                input:SetSize(descriptor.width or 220, 24)
                input:SetAutoFocus(false)

                local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                label:SetPoint("BOTTOMLEFT", input, "TOPLEFT", 0, 4)
                label:SetText(binding.label or descriptor.label or "")

                input:SetScript("OnEnterPressed", function(self)
                    binding.set(self:GetText())
                    self:ClearFocus()
                end)
                input:SetScript("OnEditFocusLost", function(self)
                    binding.set(self:GetText())
                end)

                function input:Refresh()
                    self:SetText(tostring(binding.get() or ""))
                    self:SetEnabled(not (binding.disabled and binding.disabled()))
                end

                input:Refresh()
                control = input
                offset = offset - 52
            end

            if control and descriptor.key then
                rendered[descriptor.key] = control
            end
        end
    end

    return rendered
end

local addonName, BFUF = ...

BFUF.Core = BFUF.Core or {}

-- Declarative page metadata is independent from navigation widgets and page rendering.
local PageRegistry = {}
PageRegistry.__index = PageRegistry
BFUF.Core.SettingsPageRegistry = PageRegistry

function PageRegistry:Create()
    return setmetatable({
        pages = {},
        order = {},
    }, self)
end

function PageRegistry:Register(definition)
    assert(type(definition) == "table", "Settings page definition must be a table")
    assert(type(definition.id) == "string" and definition.id ~= "", "Settings page definition must have an id")
    assert(type(definition.title) == "string" and definition.title ~= "", "Settings page definition must have a title")
    assert(type(definition.builder) == "function", "Settings page definition must have a builder")

    if self.pages[definition.id] then
        return false
    end

    definition.category = definition.category or "General"
    definition.availability = definition.availability or function()
        return true
    end
    definition.bindings = definition.bindings or {}
    definition.refreshIntent = definition.refreshIntent or "NONE"
    definition.resetScope = definition.resetScope or "NONE"
    definition.refresh = definition.refresh or function()
    end

    self.pages[definition.id] = definition
    table.insert(self.order, definition.id)
    return true
end

function PageRegistry:Get(id)
    return self.pages[id]
end

function PageRegistry:IsAvailable(id, context)
    local definition = self:Get(id)
    return definition ~= nil and definition.availability(context) == true
end

function PageRegistry:Open(id, context)
    local definition = self:Get(id)
    if not definition or not self:IsAvailable(id, context) then
        return false
    end

    definition.builder(context, definition)
    return true
end

function PageRegistry:ForEach(callback, category, context)
    for _, id in ipairs(self.order) do
        local definition = self.pages[id]
        if (not category or definition.category == category) and self:IsAvailable(id, context) then
            callback(definition)
        end
    end
end

-- This registry is the future source of truth. Legacy pages can remain adapters
-- while their controls are migrated to declarative binding definitions.
BFUF.Core.SettingsPageDefinitions = PageRegistry:Create()

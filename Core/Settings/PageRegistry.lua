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

    definition.type = definition.type or "page"
    assert(
        definition.type == "page" or definition.type == "category",
        "Settings definition type must be page or category"
    )

    if definition.type == "page" then
        assert(type(definition.builder) == "function", "Settings page definition must have a builder")
    else
        definition.children = definition.children or {}
    end

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
    if not definition or definition.type ~= "page" or not self:IsAvailable(id, context) then
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

-- Return root definitions with their declared, available children for tree navigation.
function PageRegistry:GetNavigationTree(context)
    local children = {}
    for _, id in ipairs(self.order) do
        local definition = self.pages[id]
        if definition.type == "category" then
            for _, childId in ipairs(definition.children) do
                children[childId] = true
            end
        end
    end

    local tree = {}
    for _, id in ipairs(self.order) do
        local definition = self.pages[id]
        if not children[id] and self:IsAvailable(id, context) then
            local node = {
                definition = definition,
                children = {},
            }

            if definition.type == "category" then
                for _, childId in ipairs(definition.children) do
                    local child = self.pages[childId]
                    if child and self:IsAvailable(childId, context) then
                        table.insert(node.children, child)
                    end
                end
            end

            table.insert(tree, node)
        end
    end

    return tree
end

-- This registry is the future source of truth. Legacy pages can remain adapters
-- while their controls are migrated to declarative binding definitions.
BFUF.Core.SettingsPageDefinitions = PageRegistry:Create()

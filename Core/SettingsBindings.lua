local addonName, BFUF = ...

local SettingsInfrastructure = {}
BFUF.Core.SettingsInfrastructure = SettingsInfrastructure

local BindingFactory = {}
SettingsInfrastructure.BindingFactory = BindingFactory

local RefreshDispatcher = {
    batchDepth = 0,
    pending = {},
    deferred = {},
    deferredScheduled = false,
}
SettingsInfrastructure.RefreshDispatcher = RefreshDispatcher

local function splitPath(path)
    local parts = {}

    for part in string.gmatch(path, "[^%.]+") do
        table.insert(parts, part)
    end

    assert(#parts > 0, "Settings binding path cannot be empty")
    return parts
end

local function readPath(source, parts)
    local value = source

    for _, part in ipairs(parts) do
        if type(value) ~= "table" then
            return nil
        end

        value = value[part]
    end

    return value
end

local function writePath(destination, parts, value)
    local parent = destination

    for index = 1, #parts - 1 do
        local part = parts[index]
        parent[part] = parent[part] or {}
        parent = parent[part]
    end

    parent[parts[#parts]] = value
end

local function copyValue(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, entry in pairs(value) do
        copy[key] = copyValue(entry)
    end

    return copy
end

local function getFrameRoot(frameKey)
    if not BFUF.Framework or not BFUF.Framework.Registry then
        return nil
    end

    return BFUF.Framework.Registry:GetFrame(frameKey)
end

local function refreshPlayerLayout()
    if BFUF.Frames and BFUF.Frames.Player then
        BFUF.Frames.Player:UpdateLayout()
    end
end

local function refreshTargetLayout()
    if BFUF.Frames and BFUF.Frames.Target then
        BFUF.Frames.Target:UpdateLayout()
        BFUF.Frames.Target:Update()
    end
end

local function refreshPortrait(context)
    if context and context.unit == "target" then
        refreshTargetLayout()
    else
        refreshPlayerLayout()
    end
end

local function refreshText(context)
    if context and context.unit == "player" and BFUF.Frames and BFUF.Frames.Player then
        BFUF.Frames.Player:UpdateTextElements(getFrameRoot("player"))
    end
end

local function refreshHealth(context)
    if context and context.unit == "player" then
        local root = getFrameRoot("player")
        if root and root.healthBar and root.healthBar.UpdateStyle then
            root.healthBar:UpdateStyle()
        end
    end
end

local function refreshPower(context)
    if context and context.unit == "player" then
        local root = getFrameRoot("player")
        if root and root.powerBar and root.powerBar.UpdateStyle then
            root.powerBar:UpdateStyle()
        end
    end
end

local function refreshIndicators(context)
    if context and context.unit == "player" then
        refreshPlayerLayout()
    end
end

local handlers = {
    PLAYER_LAYOUT = refreshPlayerLayout,
    TARGET_LAYOUT = refreshTargetLayout,
    PORTRAIT = refreshPortrait,
    TEXT = refreshText,
    HEALTH = refreshHealth,
    POWER = refreshPower,
    AURA = function()
    end,
    INDICATORS = refreshIndicators,
}

function RefreshDispatcher:Dispatch(intent, context)
    local handler = handlers[intent]
    if not handler then
        return false
    end

    handler(context)
    return true
end

function RefreshDispatcher:FlushDeferred()
    self.deferredScheduled = false

    local deferred = self.deferred
    self.deferred = {}

    for _, request in pairs(deferred) do
        self:Dispatch(request.intent, request.context)
    end
end

function RefreshDispatcher:Request(intent, context, defer)
    if not intent or intent == "NONE" then
        return
    end

    local unit = context and context.unit or "global"
    if self.batchDepth > 0 then
        self.pending[intent .. ":" .. unit] = {
            intent = intent,
            context = context,
        }
        return
    end

    if defer then
        self.deferred[intent .. ":" .. unit] = {
            intent = intent,
            context = context,
        }

        if not self.deferredScheduled then
            self.deferredScheduled = true
            C_Timer.After(0, function()
                RefreshDispatcher:FlushDeferred()
            end)
        end
        return
    end

    self:Dispatch(intent, context)
end

function RefreshDispatcher:BeginBatch()
    self.batchDepth = self.batchDepth + 1
end

function RefreshDispatcher:EndBatch()
    if self.batchDepth == 0 then
        return
    end

    self.batchDepth = self.batchDepth - 1
    if self.batchDepth > 0 then
        return
    end

    local pending = self.pending
    self.pending = {}

    for _, request in pairs(pending) do
        self:Dispatch(request.intent, request.context)
    end
end

function BindingFactory:Create(definition)
    assert(type(definition) == "table", "Settings binding definition must be a table")
    assert(definition.key, "Settings binding must have a key")
    assert(type(definition.get) == "function", "Settings binding must have a getter")
    assert(type(definition.set) == "function", "Settings binding must have a setter")

    local binding = {
        key = definition.key,
        label = definition.label,
        refreshIntent = definition.refreshIntent or "NONE",
        context = definition.context,
        values = definition.values,
        disabled = definition.disabled,
        deferRefresh = definition.deferRefresh == true,
    }

    binding.get = function()
        return definition.get()
    end

    binding.set = function(value)
        definition.set(value)
        if definition.afterSet then
            definition.afterSet(value)
        end
        RefreshDispatcher:Request(binding.refreshIntent, binding.context, binding.deferRefresh)
    end

    binding.default = function()
        if type(definition.default) == "function" then
            return copyValue(definition.default())
        end

        return copyValue(definition.default)
    end

    function binding:Reset(requestRefresh)
        definition.set(self.default())

        if requestRefresh ~= false then
            RefreshDispatcher:Request(self.refreshIntent, self.context)
        end
    end

    return binding
end

function BindingFactory:CreateProfileBinding(definition)
    assert(definition.path, "Profile binding must have a path")

    local parts = splitPath(definition.path)
    local defaultProvider = definition.default or function()
        return readPath(BFUF.Defaults.profile, parts)
    end

    return self:Create({
        key = definition.key or definition.path,
        label = definition.label,
        values = definition.values,
        disabled = definition.disabled,
        refreshIntent = definition.refreshIntent,
        context = definition.context,
        get = function()
            return readPath(BFUF.DB:Get(), parts)
        end,
        set = function(value)
            writePath(BFUF.DB:Get(), parts, value)
        end,
        default = defaultProvider,
        afterSet = definition.afterSet,
        deferRefresh = definition.deferRefresh,
    })
end

-- Create a position binding that clears the native drag anchor in the same write.
function BindingFactory:CreatePositionBinding(definition)
    assert(definition.profileKey, "Position binding must have a profile key")
    assert(definition.key, "Position binding must have a key")

    local profileKey = definition.profileKey
    local positionKey = definition.key

    return self:Create({
        key = profileKey .. "." .. positionKey,
        label = definition.label,
        disabled = definition.disabled,
        refreshIntent = definition.refreshIntent,
        context = definition.context,
        deferRefresh = true,
        get = function()
            return BFUF.DB:Get(profileKey)[positionKey]
        end,
        set = function(value)
            local profile = BFUF.DB:Get(profileKey)
            profile[positionKey] = value
            profile.positionAnchor = nil
        end,
        default = function()
            return BFUF.Defaults.profile[profileKey][positionKey]
        end,
    })
end

function BindingFactory:Reset(bindings)
    RefreshDispatcher:BeginBatch()

    for _, binding in pairs(bindings) do
        binding:Reset()
    end

    RefreshDispatcher:EndBatch()
end

function BindingFactory:ResetPosition(profileKey, refreshIntent, context)
    local positionX = self:CreateProfileBinding({
        path = profileKey .. ".positionX",
        refreshIntent = refreshIntent,
        context = context,
    })
    local positionY = self:CreateProfileBinding({
        path = profileKey .. ".positionY",
        refreshIntent = refreshIntent,
        context = context,
    })
    local positionAnchor = self:CreateProfileBinding({
        path = profileKey .. ".positionAnchor",
        refreshIntent = "NONE",
        context = context,
        default = nil,
    })

    RefreshDispatcher:BeginBatch()
    positionX:Reset()
    positionY:Reset()
    positionAnchor.set(nil)
    RefreshDispatcher:EndBatch()
end

function BindingFactory:ResetProfileSection(profileKey, refreshIntent, context)
    local profile = BFUF.DB:Get(profileKey)
    local defaults = BFUF.Defaults.profile[profileKey]

    if not profile or not defaults then
        return false
    end

    wipe(profile)
    for key, value in pairs(copyValue(defaults)) do
        profile[key] = value
    end

    RefreshDispatcher:Request(refreshIntent, context)
    return true
end

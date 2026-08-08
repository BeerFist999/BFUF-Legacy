local addonName, BFUF = ...

local BindingFactory = BFUF.Core.SettingsBindingFactory
local pages = BFUF.Core.SettingsPageDefinitions

local function settingsAvailable()
    return BFUF.Core.Settings ~= nil
end

local function createPortraitEnabledBinding(profileKey, refreshIntent, context)
    if profileKey == "Boss" then
        return BindingFactory:CreateProfileBinding({
            path = "Boss.portrait.enabled",
            label = BFUF.L.OPTION_SHOW_PORTRAIT,
            refreshIntent = refreshIntent,
            context = context,
        })
    end

    return BindingFactory:Create({
        key = profileKey .. ".portrait.enabled",
        label = BFUF.L.OPTION_SHOW_PORTRAIT,
        refreshIntent = refreshIntent,
        context = context,
        get = function()
            return BFUF.DB:Get(profileKey).portrait.mode ~= "hidden"
        end,
        set = function(enabled)
            BFUF.DB:Get(profileKey).portrait.mode = enabled and "2d" or "hidden"
        end,
        default = function()
            return BFUF.Defaults.profile[profileKey].portrait.mode ~= "hidden"
        end,
    })
end

-- Player, Target, and Boss share this descriptor factory; only bindings and
-- refresh context differ by frame type.
local function createPortraitControls(profileKey, refreshIntent, context)
    local enabledBinding = createPortraitEnabledBinding(profileKey, refreshIntent, context)
    local widthBinding = BindingFactory:CreateProfileBinding({
        path = profileKey .. ".portrait.width",
        label = BFUF.L.OPTION_PORTRAIT_WIDTH,
        refreshIntent = refreshIntent,
        context = context,
    })

    return {
        {
            type = "header",
            key = "portrait",
            label = BFUF.L.SECTION_PORTRAIT,
        },
        {
            type = "checkbox",
            key = "enabled",
            label = BFUF.L.OPTION_SHOW_PORTRAIT,
            binding = enabledBinding,
            refreshIntent = refreshIntent,
        },
        {
            type = "slider",
            key = "width",
            label = BFUF.L.OPTION_PORTRAIT_WIDTH,
            binding = widthBinding,
            refreshIntent = refreshIntent,
            min = 20,
            max = 160,
            step = 1,
        },
    }
end

local function createPortraitPage(id, title, profileKey, refreshIntent, context)
    return {
        id = id,
        title = title,
        category = "Elements",
        availability = settingsAvailable,
        bindings = {
            profileKey .. ".portrait.enabled",
            profileKey .. ".portrait.width",
        },
        refreshIntent = refreshIntent,
        resetScope = profileKey .. ".portrait",
        controls = createPortraitControls(profileKey, refreshIntent, context),
        builder = function(settings, definition)
            if profileKey == "Player" then
                BFUF.Frames.Player:EnsurePortraitSettings()
            end
            settings:ShowDeclarativeControlsPage(definition)
        end,
    }
end

pages:Register(createPortraitPage(
    "elements.portrait.player",
    BFUF.L.SETTINGS_PLAYER_PORTRAIT,
    "Player",
    "PORTRAIT",
    { unit = "player" }
))

pages:Register(createPortraitPage(
    "elements.portrait.target",
    BFUF.L.SETTINGS_PLAYER_PORTRAIT,
    "Target",
    "PORTRAIT",
    { unit = "target" }
))

pages:Register(createPortraitPage(
    "elements.portrait.boss",
    BFUF.L.SECTION_PORTRAIT,
    "Boss",
    "BOSS_LAYOUT",
    { unit = "boss" }
))

local playerHealthTextBindings = {
    show = BindingFactory:CreateProfileBinding({
        path = "Player.texts.health.show",
        label = BFUF.L.OPTION_SHOW,
        refreshIntent = "TEXT",
        context = { unit = "player" },
    }),
    format = BindingFactory:CreateProfileBinding({
        path = "Player.texts.health.mode",
        label = BFUF.L.OPTION_BOSS_HEALTH_TEXT_FORMAT,
        refreshIntent = "TEXT",
        context = { unit = "player" },
    }),
}

pages:Register({
    id = "elements.health.player",
    title = BFUF.L.SETTINGS_PLAYER_HEALTH,
    category = "Elements",
    availability = settingsAvailable,
    bindings = {
        "Player.texts.health.show",
        "Player.texts.health.mode",
    },
    refreshIntent = "TEXT",
    resetScope = "Player.texts.health",
    controls = {
        {
            type = "header",
            key = "healthText",
            label = BFUF.L.SECTION_TEXT_HEALTH,
        },
        {
            type = "checkbox",
            key = "show",
            label = BFUF.L.OPTION_SHOW,
            binding = playerHealthTextBindings.show,
            refreshIntent = "TEXT",
        },
        {
            type = "dropdown",
            key = "format",
            label = BFUF.L.OPTION_BOSS_HEALTH_TEXT_FORMAT,
            binding = playerHealthTextBindings.format,
            refreshIntent = "TEXT",
            values = {
                { value = "current", label = BFUF.L.TEXT_MODE_CURRENT },
                { value = "currentMax", label = BFUF.L.TEXT_MODE_CURRENT_MAX },
                { value = "percent", label = BFUF.L.TEXT_MODE_PERCENT },
            },
        },
    },
    builder = function(settings, definition)
        settings:ShowDeclarativeControlsPage(definition)
    end,
})

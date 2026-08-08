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

-- Keep the existing Health Text controls in the Text-system profile section.
pages:Register({
    id = "elements.health.player",
    title = BFUF.L.SETTINGS_HEALTH_TEXT,
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

-- The shared policy remains stored in Player.health. Target and Boss receive it
-- through their existing frame-side settings providers.
local playerHealthBindings = {}

playerHealthBindings.height = BindingFactory:CreateProfileBinding({
    path = "Player.health.height",
    label = BFUF.L.OPTION_HEALTH_HEIGHT,
    refreshIntent = "PLAYER_LAYOUT",
    context = { unit = "player" },
})

playerHealthBindings.colorMode = BindingFactory:CreateProfileBinding({
    path = "Player.health.colorMode",
    label = BFUF.L.OPTION_HEALTH_COLOR_MODE,
    refreshIntent = "HEALTH",
    context = { scope = "sharedHealth" },
})

playerHealthBindings.customColor = BindingFactory:CreateProfileBinding({
    path = "Player.health.customColor",
    label = BFUF.L.OPTION_CUSTOM_HEALTH_COLOR,
    refreshIntent = "HEALTH",
    context = { scope = "sharedHealth" },
    disabled = function()
        return playerHealthBindings.colorMode:get() ~= "custom"
    end,
})

playerHealthBindings.showAbsorb = BindingFactory:CreateProfileBinding({
    path = "Player.health.showAbsorb",
    label = BFUF.L.OPTION_SHOW_ABSORB,
    refreshIntent = "HEALTH",
    context = { scope = "sharedHealth" },
})

playerHealthBindings.absorbColor = BindingFactory:CreateProfileBinding({
    path = "Player.health.absorbColor",
    label = BFUF.L.OPTION_ABSORB_COLOR,
    refreshIntent = "HEALTH",
    context = { scope = "sharedHealth" },
})

playerHealthBindings.absorbAlpha = BindingFactory:CreateProfileBinding({
    path = "Player.health.absorbAlpha",
    label = BFUF.L.OPTION_ABSORB_ALPHA,
    refreshIntent = "HEALTH",
    context = { scope = "sharedHealth" },
})

playerHealthBindings.showHealAbsorb = BindingFactory:CreateProfileBinding({
    path = "Player.health.showHealAbsorb",
    label = BFUF.L.OPTION_SHOW_HEAL_ABSORB,
    refreshIntent = "HEALTH",
    context = { scope = "sharedHealth" },
})

playerHealthBindings.healAbsorbColor = BindingFactory:CreateProfileBinding({
    path = "Player.health.healAbsorbColor",
    label = BFUF.L.OPTION_HEAL_ABSORB_COLOR,
    refreshIntent = "HEALTH",
    context = { scope = "sharedHealth" },
})

playerHealthBindings.healAbsorbAlpha = BindingFactory:CreateProfileBinding({
    path = "Player.health.healAbsorbAlpha",
    label = BFUF.L.OPTION_HEAL_ABSORB_ALPHA,
    refreshIntent = "HEALTH",
    context = { scope = "sharedHealth" },
})

pages:Register({
    id = "elements.health.general",
    title = BFUF.L.SETTINGS_HEALTH_GENERAL,
    category = "Elements",
    availability = settingsAvailable,
    bindings = {
        "Player.health.height",
        "Player.health.colorMode",
        "Player.health.customColor",
    },
    refreshIntent = "HEALTH",
    resetScope = "Player.health",
    controls = {
        {
            type = "header",
            key = "general",
            label = BFUF.L.SETTINGS_HEALTH_GENERAL,
        },
        {
            type = "slider",
            key = "height",
            label = BFUF.L.OPTION_HEALTH_HEIGHT,
            binding = playerHealthBindings.height,
            refreshIntent = "PLAYER_LAYOUT",
            min = 10,
            max = 160,
            step = 1,
        },
        {
            type = "dropdown",
            key = "colorMode",
            label = BFUF.L.OPTION_HEALTH_COLOR_MODE,
            binding = playerHealthBindings.colorMode,
            refreshIntent = "HEALTH",
            values = {
                { value = "class", label = BFUF.L.OPTION_CLASS_COLOR },
                { value = "custom", label = BFUF.L.OPTION_CUSTOM_COLOR },
            },
        },
        {
            type = "color",
            key = "customColor",
            label = BFUF.L.OPTION_CUSTOM_HEALTH_COLOR,
            binding = playerHealthBindings.customColor,
            refreshIntent = "HEALTH",
        },
    },
    builder = function(settings, definition)
        settings:ShowDeclarativeControlsPage(definition)
    end,
})

pages:Register({
    id = "elements.health.absorb",
    title = BFUF.L.SETTINGS_HEALTH_ABSORB,
    category = "Elements",
    availability = settingsAvailable,
    bindings = {
        "Player.health.showAbsorb",
        "Player.health.absorbColor",
        "Player.health.absorbAlpha",
    },
    refreshIntent = "HEALTH",
    resetScope = "Player.health",
    controls = {
        {
            type = "header",
            key = "absorb",
            label = BFUF.L.SETTINGS_HEALTH_ABSORB,
        },
        {
            type = "checkbox",
            key = "showAbsorb",
            label = BFUF.L.OPTION_SHOW_ABSORB,
            binding = playerHealthBindings.showAbsorb,
            refreshIntent = "HEALTH",
        },
        {
            type = "color",
            key = "absorbColor",
            label = BFUF.L.OPTION_ABSORB_COLOR,
            binding = playerHealthBindings.absorbColor,
            refreshIntent = "HEALTH",
        },
        {
            type = "slider",
            key = "absorbAlpha",
            label = BFUF.L.OPTION_ABSORB_ALPHA,
            binding = playerHealthBindings.absorbAlpha,
            refreshIntent = "HEALTH",
            min = 0,
            max = 1,
            step = 0.05,
        },
    },
    builder = function(settings, definition)
        settings:ShowDeclarativeControlsPage(definition)
    end,
})

pages:Register({
    id = "elements.health.healAbsorb",
    title = BFUF.L.SETTINGS_HEALTH_HEAL_ABSORB,
    category = "Elements",
    availability = settingsAvailable,
    bindings = {
        "Player.health.showHealAbsorb",
        "Player.health.healAbsorbColor",
        "Player.health.healAbsorbAlpha",
    },
    refreshIntent = "HEALTH",
    resetScope = "Player.health",
    controls = {
        {
            type = "header",
            key = "healAbsorb",
            label = BFUF.L.SETTINGS_HEALTH_HEAL_ABSORB,
        },
        {
            type = "checkbox",
            key = "showHealAbsorb",
            label = BFUF.L.OPTION_SHOW_HEAL_ABSORB,
            binding = playerHealthBindings.showHealAbsorb,
            refreshIntent = "HEALTH",
        },
        {
            type = "color",
            key = "healAbsorbColor",
            label = BFUF.L.OPTION_HEAL_ABSORB_COLOR,
            binding = playerHealthBindings.healAbsorbColor,
            refreshIntent = "HEALTH",
        },
        {
            type = "slider",
            key = "healAbsorbAlpha",
            label = BFUF.L.OPTION_HEAL_ABSORB_ALPHA,
            binding = playerHealthBindings.healAbsorbAlpha,
            refreshIntent = "HEALTH",
            min = 0,
            max = 1,
            step = 0.05,
        },
    },
    builder = function(settings, definition)
        settings:ShowDeclarativeControlsPage(definition)
    end,
})

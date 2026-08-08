local addonName, BFUF = ...

local pages = BFUF.Core.SettingsPageDefinitions

local function settingsAvailable()
    return BFUF.Core.Settings ~= nil
end

pages:Register({
    id = "elements.portrait.player",
    title = BFUF.L.SETTINGS_PLAYER_PORTRAIT,
    category = "Elements",
    availability = settingsAvailable,
    builder = function(settings)
        settings:ShowPlayerPortraitPage()
    end,
    bindings = {
        "Player.portrait.width",
    },
    refreshIntent = "PORTRAIT",
    resetScope = "Player.portrait",
})

pages:Register({
    id = "elements.portrait.target",
    title = BFUF.L.SETTINGS_PLAYER_PORTRAIT,
    category = "Elements",
    availability = settingsAvailable,
    builder = function(settings)
        settings:ShowTargetPortraitPage()
    end,
    bindings = {
        "Target.portrait.width",
    },
    refreshIntent = "PORTRAIT",
    resetScope = "Target.portrait",
})

pages:Register({
    id = "elements.portrait.boss",
    title = BFUF.L.SETTINGS_PLAYER_PORTRAIT,
    category = "Elements",
    availability = settingsAvailable,
    builder = function(settings)
        settings:ShowBossPortraitPage()
    end,
    bindings = {
        "Boss.portrait.enabled",
        "Boss.portrait.width",
    },
    refreshIntent = "BOSS_LAYOUT",
    resetScope = "Boss.portrait",
})

pages:Register({
    id = "elements.health.player",
    title = BFUF.L.SETTINGS_PLAYER_HEALTH,
    category = "Elements",
    availability = settingsAvailable,
    builder = function(settings)
        settings:ShowPlayerHealthPage(settings.shell.pages)
    end,
    bindings = {
        "Player.health.height",
        "Player.health.colorMode",
        "Player.health.showAbsorb",
        "Player.health.showHealAbsorb",
    },
    refreshIntent = "HEALTH",
    resetScope = "Player.health",
})

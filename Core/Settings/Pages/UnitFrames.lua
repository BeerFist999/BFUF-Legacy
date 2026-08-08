local addonName, BFUF = ...

local pages = BFUF.Core.SettingsPageDefinitions

local function settingsAvailable()
    return BFUF.Core.Settings ~= nil
end

pages:Register({
    id = "unit_frames.player",
    title = BFUF.L.SETTINGS_PAGE_PLAYER,
    category = "Unit Frames",
    availability = settingsAvailable,
    builder = function(settings)
        settings:ShowShellFrame("player", BFUF.L.SETTINGS_PAGE_PLAYER, false)
    end,
    bindings = {
        "Player.width",
        "Player.height",
        "Player.scale",
        "Player.positionX",
        "Player.positionY",
    },
    refreshIntent = "PLAYER_LAYOUT",
    resetScope = "Player",
})

pages:Register({
    id = "unit_frames.target",
    title = BFUF.L.SETTINGS_PAGE_TARGET,
    category = "Unit Frames",
    availability = settingsAvailable,
    builder = function(settings)
        settings:ShowShellFrame("target", BFUF.L.SETTINGS_PAGE_TARGET, false)
    end,
    bindings = {
        "Target.width",
        "Target.height",
        "Target.scale",
        "Target.positionX",
        "Target.positionY",
    },
    refreshIntent = "TARGET_LAYOUT",
    resetScope = "Target",
})

pages:Register({
    id = "unit_frames.boss",
    title = BFUF.L.SETTINGS_PAGE_BOSS,
    category = "Unit Frames",
    availability = settingsAvailable,
    builder = function(settings)
        settings:ShowShellFrame("boss", BFUF.L.SETTINGS_PAGE_BOSS, false)
    end,
    bindings = {
        "Boss.enabled",
        "Boss.count",
        "Boss.width",
        "Boss.height",
        "Boss.spacing",
        "Boss.growth",
    },
    refreshIntent = "BOSS_LAYOUT",
    resetScope = "Boss",
})

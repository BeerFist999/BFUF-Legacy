local addonName, BFUF = ...

BFUF.Core = BFUF.Core or {}

local SettingsShell = {}
BFUF.Core.SettingsShell = SettingsShell

function SettingsShell:Get()
    local settings = BFUF.Core.Settings
    return settings and settings.shell or nil
end

function SettingsShell:Open()
    local settings = BFUF.Core.Settings
    if settings then
        settings:Open()
        return true
    end

    return false
end

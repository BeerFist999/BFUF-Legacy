local addonName, BFUF = ...

-- Default values are stored in AceDB's profile scope.
BFUF.Defaults = {
    profile = {
        General = {
            enabled = true,
            scale = 1,
            show = true,
        },

        Player = {
            enabled = true,
            width = 240,
            height = 50,
            scale = 1,
            show = true,
        },

        Target = {
            enabled = true,
            width = 220,
            height = 40,
            scale = 1,
            show = true,
        },

        TargetTarget = {
            enabled = true,
            width = 160,
            height = 32,
            scale = 1,
            show = true,
        },

        Boss = {
            enabled = true,
            width = 200,
            height = 36,
            scale = 1,
            show = true,
        },

        Auras = {
            enabled = true,
            show = true,
        },

        Castbar = {
            enabled = true,
            width = 220,
            height = 18,
            show = true,
        },

        Portrait = {
            enabled = true,
            width = 50,
            height = 50,
            show = true,
        },

        Text = {
            enabled = true,
            show = true,
        },

        Indicators = {
            enabled = true,
            show = true,
        },
    },
}

local Defaults = {}
BFUF.Core.Defaults = Defaults

-- Reserved for future validation of default values.
function Defaults:Initialize()
end

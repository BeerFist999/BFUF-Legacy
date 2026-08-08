local addonName, BFUF = ...

-- Default values are stored in AceDB's profile scope.
BFUF.Defaults = {
    profile = {
        General = {
            debugMode = false,
            scale = 1,
            show = true,
        },

        Player = {
            width = 240,
            height = 50,
            scale = 1,
            positionX = 0,
            positionY = 0,

            portrait = {
                mode = "2d",
                width = 44,
            },

            health = {
                height = 34,
                colorMode = "class",
                customColor = { r = 0.2, g = 0.8, b = 0.2 },
                showAbsorb = true,
                showHealAbsorb = true,
            },

            power = {
                height = 8,
                colorMode = "resource",
                customColor = { r = 0.2, g = 0.4, b = 1 },
            },

            texts = {
                name = {
                    show = true,
                    mode = "name",
                    font = STANDARD_TEXT_FONT,
                    fontSize = 12,
                    outline = "",
                    color = { r = 1, g = 1, b = 1, a = 1 },
                    offsetX = 4,
                    offsetY = 0,
                },
                health = {
                    show = true,
                    mode = "currentMax",
                    font = STANDARD_TEXT_FONT,
                    fontSize = 12,
                    outline = "",
                    color = { r = 1, g = 1, b = 1, a = 1 },
                    offsetX = -4,
                    offsetY = 0,
                },
                power = {
                    show = true,
                    mode = "currentMax",
                    font = STANDARD_TEXT_FONT,
                    fontSize = 12,
                    outline = "",
                    color = { r = 1, g = 1, b = 1, a = 1 },
                    offsetX = -4,
                    offsetY = 0,
                },
                level = {
                    show = true,
                    font = STANDARD_TEXT_FONT,
                    fontSize = 12,
                    outline = "",
                    color = { r = 1, g = 1, b = 1, a = 1 },
                    anchor = "TOPLEFT",
                    relativePoint = "TOPLEFT",
                    offsetX = 4,
                    offsetY = -4,
                },
            },

            indicators = {
                combat = { enabled = true, size = 16, offsetX = 3, offsetY = -3 },
                resting = { enabled = true, size = 16, offsetX = 21, offsetY = -3 },
                leader = { enabled = true, size = 12, offsetX = -1, offsetY = -3 },
                assistant = { enabled = true, size = 12, offsetX = 1, offsetY = -3 },
                pvp = { enabled = true, size = 12, offsetX = 3, offsetY = 3 },
                afk = { enabled = false, size = 12, offsetX = 17, offsetY = 3 },
                dnd = { enabled = false, size = 12, offsetX = 31, offsetY = 3 },
            },
        },

        Target = {
            enabled = true,
            width = 260,
            height = 58,
            scale = 1,
            positionX = 320,
            positionY = 0,
            show = true,

            portrait = {
                mode = "2d",
                width = 54,
            },
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

        Auras = { enabled = true, show = true },
        Castbar = { enabled = true, width = 220, height = 18, show = true },
        Portrait = { enabled = true, width = 50, height = 50, show = true },
        Text = { enabled = true, show = true },
        Indicators = { enabled = true, show = true },
    },
}

local Defaults = {}
BFUF.Core.Defaults = Defaults

function Defaults:Initialize()
end

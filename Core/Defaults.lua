local addonName, BFUF = ...

-- Shared defaults keep the base dimensions of every unit frame consistent.
local UNIT_FRAME_DEFAULTS = {
    width = 324,
    height = 55,
    scale = 1,
    portraitWidth = 54,

    positions = {
        player = { x = 0, y = 0 },
        target = { x = 320, y = 0 },
        targetTarget = { x = 0, y = -100 },
        boss = { x = 0, y = 120 },
    },
}

-- Default values are stored in AceDB's profile scope.
BFUF.Defaults = {
    profile = {
        General = {
            debugMode = false,
            scale = 1,
            show = true,
        },

        Player = {
            width = UNIT_FRAME_DEFAULTS.width,
            height = UNIT_FRAME_DEFAULTS.height,
            scale = UNIT_FRAME_DEFAULTS.scale,
            positionX = UNIT_FRAME_DEFAULTS.positions.player.x,
            positionY = UNIT_FRAME_DEFAULTS.positions.player.y,

            portrait = {
                mode = "2d",
                width = UNIT_FRAME_DEFAULTS.portraitWidth,
            },

            health = {
                height = 34,
                colorMode = "class",
                customColor = { r = 0.2, g = 0.8, b = 0.2 },
                showAbsorb = true,
                absorbColor = { r = 0.8, g = 0.8, b = 1 },
                absorbAlpha = 0.65,
                showHealAbsorb = true,
                healAbsorbColor = { r = 0.85, g = 0.15, b = 0.15 },
                healAbsorbAlpha = 0.65,
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
            width = UNIT_FRAME_DEFAULTS.width,
            height = UNIT_FRAME_DEFAULTS.height,
            scale = UNIT_FRAME_DEFAULTS.scale,
            positionX = UNIT_FRAME_DEFAULTS.positions.target.x,
            positionY = UNIT_FRAME_DEFAULTS.positions.target.y,
            show = true,

            portrait = {
                mode = "2d",
                width = UNIT_FRAME_DEFAULTS.portraitWidth,
            },
        },

        TargetTarget = {
            enabled = true,
            width = UNIT_FRAME_DEFAULTS.width,
            height = UNIT_FRAME_DEFAULTS.height,
            scale = UNIT_FRAME_DEFAULTS.scale,
            positionX = UNIT_FRAME_DEFAULTS.positions.targetTarget.x,
            positionY = UNIT_FRAME_DEFAULTS.positions.targetTarget.y,
            show = true,
        },

        Boss = {
            enabled = true,
            count = 5,
            width = 300,
            height = 55,
            scale = UNIT_FRAME_DEFAULTS.scale,
            positionX = UNIT_FRAME_DEFAULTS.positions.boss.x,
            positionY = UNIT_FRAME_DEFAULTS.positions.boss.y,
            spacing = 5,
            growth = "DOWN",
            preview = false,
            previewUnlocked = false,
            show = true,
            showName = true,
            showHealthText = true,
            healthTextFormat = "currentMax",
            showPowerText = true,
            powerTextFormat = "current",

            portrait = {
                enabled = true,
                width = 55,
            },
        },

        BossFrames = {
            position = {
                point = "CENTER",
                relativePoint = "CENTER",
                x = UNIT_FRAME_DEFAULTS.positions.boss.x,
                y = UNIT_FRAME_DEFAULTS.positions.boss.y,
            },
        },

        -- Future unit frames inherit the shared Target-based geometry.
        Focus = {
            enabled = true,
            width = UNIT_FRAME_DEFAULTS.width,
            height = UNIT_FRAME_DEFAULTS.height,
            scale = UNIT_FRAME_DEFAULTS.scale,
            show = true,
        },

        FocusTarget = {
            enabled = true,
            width = UNIT_FRAME_DEFAULTS.width,
            height = UNIT_FRAME_DEFAULTS.height,
            scale = UNIT_FRAME_DEFAULTS.scale,
            show = true,
        },

        Pet = {
            enabled = true,
            width = UNIT_FRAME_DEFAULTS.width,
            height = UNIT_FRAME_DEFAULTS.height,
            scale = UNIT_FRAME_DEFAULTS.scale,
            show = true,
        },

        PetTarget = {
            enabled = true,
            width = UNIT_FRAME_DEFAULTS.width,
            height = UNIT_FRAME_DEFAULTS.height,
            scale = UNIT_FRAME_DEFAULTS.scale,
            show = true,
        },

        Auras = { enabled = true, show = true },
        Castbar = { enabled = true, width = 220, height = 18, show = true },
        Portrait = { enabled = true, width = 50, height = 50, show = true },
        Text = { enabled = true, show = true },
        Indicators = { enabled = true, show = true },
    },
}

-- Keep shared layout metadata outside AceDB's iterable defaults schema.
-- AceDB sees only the valid profile scope, while BFUF code still accesses
-- the centralized values through BFUF.Defaults.UnitFrame.
setmetatable(BFUF.Defaults, {
    __index = {
        UnitFrame = UNIT_FRAME_DEFAULTS,
    },
})

local Defaults = {}
BFUF.Core.Defaults = Defaults

function Defaults:Initialize()
end

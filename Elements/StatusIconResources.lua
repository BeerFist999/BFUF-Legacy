local addonName, BFUF = ...

-- Resource definitions for the independent player status indicators.
BFUF.Elements = BFUF.Elements or {}

local StatusIconResources = {}
BFUF.Elements.StatusIconResources = StatusIconResources

StatusIconResources.ICON_RESOURCES = {
    combat = {
        type = "atlas",
        value = "UI-HUD-UnitFrame-Player-CombatIcon",
    },
    rest = {
        type = "texture",
        value = "Interface\\CharacterFrame\\UI-StateIcon",
        texCoord = { 0.0, 0.5, 0.0, 0.5 },
    },
    leader = {
        type = "atlas",
        value = "UI-HUD-UnitFrame-Player-Group-LeaderIcon",
    },
    assistant = {
        type = "texture",
        value = "Interface\\GroupFrame\\UI-Group-AssistantIcon",
    },
    pvp = {
        type = "atlas",
        value = "UI-HUD-UnitFrame-Player-PVP-FFAIcon",
    },
    afk = {
        type = "texture",
        value = "Interface\\FriendsFrame\\StatusIcon-Away",
    },
    dnd = {
        type = "texture",
        value = "Interface\\FriendsFrame\\StatusIcon-DnD",
    },
}

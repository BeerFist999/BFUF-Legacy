local addonName, BFUF = ...

-- Status icon resource definitions shared by all unit frame elements.
BFUF.Elements = BFUF.Elements or {}

local StatusIconResources = {}
BFUF.Elements.StatusIconResources = StatusIconResources

local ICON_RESOURCES = {
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
StatusIconResources.ICON_RESOURCES = ICON_RESOURCES

-- Creates a texture and selects the appropriate Blizzard resource API.
function StatusIconResources:CreateTexture(parent, resource)
    local icon = parent:CreateTexture(nil, "OVERLAY")

    if resource.type == "atlas" then
        icon:SetAtlas(resource.value)
    else
        icon:SetTexture(resource.value)
    end

    if resource.texCoord then
        icon:SetTexCoord(unpack(resource.texCoord))
    end

    return icon
end

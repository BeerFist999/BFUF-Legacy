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
        value = "UI-HUD-UnitFrame-Player-CombatIcon",
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

-- Prints runtime resource information for every player status indicator.
local function printIndicatorResource(name, indicator)
    BFUF:Print("==========")
    BFUF:Print(name)
    BFUF:Print("==========")

    if not indicator then
        BFUF:Print("Indicator: not created")
        return
    end

    local left, right, top, bottom = indicator:GetTexCoord()

    BFUF:Print("GetAtlas(): " .. tostring(indicator:GetAtlas()))
    BFUF:Print("GetTexture(): " .. tostring(indicator:GetTexture()))
    BFUF:Print("GetObjectType(): " .. tostring(indicator:GetObjectType()))
    BFUF:Print("GetBlendMode(): " .. tostring(indicator:GetBlendMode()))
    BFUF:Print(
        "GetTexCoord(): "
        .. tostring(left) .. ", "
        .. tostring(right) .. ", "
        .. tostring(top) .. ", "
        .. tostring(bottom)
    )
end

-- Runs temporary status icon resource diagnostics from the game client.
function StatusIconResources:Debug()
    local playerFrame = BFUF.Framework.Registry:GetFrame("player")
    local indicators = playerFrame and playerFrame.indicators

    printIndicatorResource("Combat", indicators and indicators.combat)
    printIndicatorResource("Rest", indicators and indicators.resting)
    printIndicatorResource("Leader", indicators and indicators.leader)
    printIndicatorResource("Assistant", indicators and indicators.assistant)
    printIndicatorResource("PvP", indicators and indicators.pvp)
    printIndicatorResource("AFK", indicators and indicators.afk)
    printIndicatorResource("DND", indicators and indicators.dnd)
end

SLASH_BFUFICONRESOURCESDEBUG1 = "/bfuficonresourcesdebug"
SlashCmdList.BFUFICONRESOURCESDEBUG = function()
    StatusIconResources:Debug()
end

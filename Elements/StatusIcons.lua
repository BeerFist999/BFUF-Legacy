local addonName, BFUF = ...

-- StatusIcons manages the player status icon textures.
BFUF.Elements = BFUF.Elements or {}

local StatusIcons = {}
BFUF.Elements.StatusIcons = StatusIcons

local ICON_RESOURCES = BFUF.Elements.StatusIconResources.ICON_RESOURCES

-- Shared logical anchor groups for current and future unit frames.
local StatusLayout = {
    TopCenterGroup = {
        leader = {
            size = 12,
            point = "TOPRIGHT",
            relativePoint = "TOP",
            offsetX = -1,
            offsetY = -3,
            enabled = true,
        },
        assistant = {
            size = 12,
            point = "TOPLEFT",
            relativePoint = "TOP",
            offsetX = 1,
            offsetY = -3,
            enabled = true,
        },
    },
    TopLeftGroup = {
        combat = {
            size = 16,
            point = "TOPLEFT",
            relativePoint = "TOPLEFT",
            offsetX = 3,
            offsetY = -3,
            enabled = true,
        },
        rest = {
            size = 16,
            point = "TOPLEFT",
            relativePoint = "TOPLEFT",
            offsetX = 21,
            offsetY = -3,
            enabled = true,
        },
    },
    LeftBottomGroup = {
        pvp = {
            size = 12,
            point = "BOTTOMLEFT",
            relativePoint = "BOTTOMLEFT",
            offsetX = 3,
            offsetY = 3,
            enabled = true,
        },
        afk = {
            size = 12,
            point = "BOTTOMLEFT",
            relativePoint = "BOTTOMLEFT",
            offsetX = 17,
            offsetY = 3,
            enabled = false,
        },
        dnd = {
            size = 12,
            point = "BOTTOMLEFT",
            relativePoint = "BOTTOMLEFT",
            offsetX = 31,
            offsetY = 3,
            enabled = false,
        },
    },
}
StatusIcons.Layout = StatusLayout

local function createIcon(parent, position, resource)
    local icon = BFUF.Elements.StatusIconResources:CreateTexture(parent, resource)

    icon:SetSize(position.size, position.size)
    icon:SetPoint(
        position.point,
        parent,
        position.relativePoint,
        position.offsetX,
        position.offsetY
    )
    icon.layoutEnabled = position.enabled
    icon:Hide()

    return icon
end

-- Creates independent icon objects and registers the required Blizzard events.
function StatusIcons:Create(parent, layout)
    local icons = {
        leader = createIcon(parent, StatusLayout.TopCenterGroup.leader, ICON_RESOURCES.leader),
        assistant = createIcon(parent, StatusLayout.TopCenterGroup.assistant, ICON_RESOURCES.assistant),
        pvp = createIcon(parent, StatusLayout.LeftBottomGroup.pvp, ICON_RESOURCES.pvp),
        afk = createIcon(parent, StatusLayout.LeftBottomGroup.afk, ICON_RESOURCES.afk),
        dnd = createIcon(parent, StatusLayout.LeftBottomGroup.dnd, ICON_RESOURCES.dnd),
    }

    -- Updates group role indicators.
    function icons:UpdateGroup()
        self.leader:SetShown(self.leader.layoutEnabled and UnitIsGroupLeader("player"))
        self.assistant:SetShown(self.assistant.layoutEnabled and UnitIsGroupAssistant("player"))
    end

    -- Updates player flag indicators.
    function icons:UpdateFlags()
        self.pvp:SetShown(self.pvp.layoutEnabled and UnitIsPVP("player"))
        self.afk:SetShown(self.afk.layoutEnabled and UnitIsAFK("player"))
        self.dnd:SetShown(self.dnd.layoutEnabled and UnitIsDND("player"))
    end

    -- Updates all status indicators.
    function icons:Update()
        self:UpdateGroup()
        self:UpdateFlags()
    end

    -- Registers the minimal set of events needed by the status icons.
    function icons:RegisterEvents()
        local eventFrame = CreateFrame("Frame")

        eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
        eventFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
        eventFrame:SetScript("OnEvent", function(_, event, unit)
            if event == "GROUP_ROSTER_UPDATE" then
                self:UpdateGroup()
            elseif event == "PLAYER_FLAGS_CHANGED" then
                if not unit or unit == "player" then
                    self:UpdateFlags()
                end
            else
                self:Update()
            end
        end)

        self.eventFrame = eventFrame
    end

    icons:RegisterEvents()
    icons:Update()

    return icons
end


-- Temporary diagnostics for comparing status icon runtime properties.
local function printDebugLine(label, value)
    BFUF:Print(label .. ": " .. tostring(value))
end

local function getFrameLabel(frame)
    if not frame then
        return "nil"
    end

    return frame:GetName() or "<unnamed>"
end

local function printIconDebug(name, icon, condition)
    BFUF:Print("==========")
    BFUF:Print(name)
    BFUF:Print("==========")

    if not icon then
        BFUF:Print("Icon: not created")
        return
    end

    local parent = icon:GetParent()
    local point, relativeTo, relativePoint, offsetX, offsetY = icon:GetPoint()
    local drawLayer, subLevel = icon:GetDrawLayer()

    printDebugLine("Parent", getFrameLabel(parent))
    printDebugLine("Texture", icon:GetTexture())
    printDebugLine("Width", icon:GetWidth())
    printDebugLine("Height", icon:GetHeight())
    printDebugLine(
        "Point",
        string.format(
            "%s -> %s:%s (%s, %s)",
            tostring(point),
            getFrameLabel(relativeTo),
            tostring(relativePoint),
            tostring(offsetX),
            tostring(offsetY)
        )
    )
    printDebugLine("FrameLevel", parent and parent:GetFrameLevel() or "nil")
    printDebugLine("FrameStrata", parent and parent:GetFrameStrata() or "nil")
    printDebugLine("DrawLayer", string.format("%s:%s", tostring(drawLayer), tostring(subLevel)))
    printDebugLine("Alpha", icon:GetAlpha())
    printDebugLine("IsShown()", icon:IsShown())
    printDebugLine("IsVisible()", icon:IsVisible())
    printDebugLine("EffectiveScale()", icon:GetEffectiveScale())
    printDebugLine("Left", icon:GetLeft())
    printDebugLine("Right", icon:GetRight())
    printDebugLine("Top", icon:GetTop())
    printDebugLine("Bottom", icon:GetBottom())
    printDebugLine("Current state condition", condition)
end

-- Prints the runtime state of Combat, Rest, and all StatusIcons.
function StatusIcons:Debug()
    local playerFrame = BFUF.Framework.Registry:GetFrame("player")

    if not playerFrame then
        BFUF:Print("StatusIcons debug: Player Frame is not available.")
        return
    end

    local icons = playerFrame.statusIcons

    printIconDebug("Combat", playerFrame.combatIndicator, UnitAffectingCombat("player"))
    printIconDebug("Rest", playerFrame.restingIndicator, IsResting())
    printIconDebug("Leader", icons and icons.leader, UnitIsGroupLeader("player"))
    printIconDebug("Assistant", icons and icons.assistant, UnitIsGroupAssistant("player"))
    printIconDebug("PvP", icons and icons.pvp, UnitIsPVP("player"))
    printIconDebug("AFK", icons and icons.afk, UnitIsAFK("player"))
    printIconDebug("DND", icons and icons.dnd, UnitIsDND("player"))
end

SLASH_BFUFSTATUSDEBUG1 = "/bfufstatusdebug"
SlashCmdList.BFUFSTATUSDEBUG = function()
    StatusIcons:Debug()
end

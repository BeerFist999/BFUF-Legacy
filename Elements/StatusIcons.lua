local addonName, BFUF = ...

-- StatusIcons manages the player status icon textures.
BFUF.Elements = BFUF.Elements or {}

local StatusIcons = {}
BFUF.Elements.StatusIcons = StatusIcons

local ICON_TEXTURES = {
    leader = "Interface\\GroupFrame\\UI-Group-LeaderIcon",
    assistant = "Interface\\GroupFrame\\UI-Group-AssistantIcon",
    pvp = "Interface\\TargetingFrame\\UI-PVP-FFA",
    afk = "Interface\\FriendsFrame\\StatusIcon-Away",
    dnd = "Interface\\FriendsFrame\\StatusIcon-DnD",
}

local function createIcon(parent, layout, texture)
    local icon = parent:CreateTexture(nil, "TOOLTIP")

    icon:SetTexture(texture)
    icon:SetSize(layout.size, layout.size)
    icon:SetPoint(
        layout.point,
        parent,
        layout.relativePoint,
        layout.offsetX,
        layout.offsetY
    )
    icon:Hide()

    return icon
end

-- Creates independent icon objects and registers the required Blizzard events.
function StatusIcons:Create(parent, layout)
    local icons = {
        leader = createIcon(parent, layout.leader, ICON_TEXTURES.leader),
        assistant = createIcon(parent, layout.assistant, ICON_TEXTURES.assistant),
        pvp = createIcon(parent, layout.pvp, ICON_TEXTURES.pvp),
        afk = createIcon(parent, layout.afk, ICON_TEXTURES.afk),
        dnd = createIcon(parent, layout.dnd, ICON_TEXTURES.dnd),
    }

    -- Updates group role indicators.
    function icons:UpdateGroup()
        self.leader:SetShown(UnitIsGroupLeader("player"))
        self.assistant:SetShown(UnitIsGroupAssistant("player"))
    end

    -- Updates player flag indicators.
    function icons:UpdateFlags()
        self.pvp:SetShown(UnitIsPVP("player"))
        self.afk:SetShown(UnitIsAFK("player"))
        self.dnd:SetShown(UnitIsDND("player"))
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

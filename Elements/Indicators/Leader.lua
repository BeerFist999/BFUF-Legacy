local addonName, BFUF = ...

-- Leader owns the player leader indicator.
BFUF.Elements = BFUF.Elements or {}
BFUF.Elements.Indicators = BFUF.Elements.Indicators or {}

local Leader = {}
BFUF.Elements.Indicators.Leader = Leader

function Leader:Create(parent, layout)
    local resource = BFUF.Elements.StatusIconResources.ICON_RESOURCES.leader
    local indicator = BFUF.Elements.StatusIconResources:CreateTexture(parent, resource)

    indicator:SetSize(layout.size, layout.size)
    indicator:SetPoint(
        layout.point,
        parent,
        layout.relativePoint,
        layout.offsetX,
        layout.offsetY
    )
    indicator:Hide()

    function indicator:Update()
        indicator:SetShown(layout.enabled and UnitIsGroupLeader("player"))
    end

    function indicator:RegisterEvents()
        local eventFrame = CreateFrame("Frame")

        eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
        eventFrame:SetScript("OnEvent", function()
            self:Update()
        end)

        self.eventFrame = eventFrame
    end

    indicator:RegisterEvents()
    indicator:Update()

    return indicator
end

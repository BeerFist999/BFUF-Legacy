local addonName, BFUF = ...

-- PvP owns the player pvp indicator.
BFUF.Elements = BFUF.Elements or {}
BFUF.Elements.Indicators = BFUF.Elements.Indicators or {}

local PvP = {}
BFUF.Elements.Indicators.PvP = PvP

function PvP:Create(parent, layout)
    local resource = BFUF.Elements.StatusIconResources.ICON_RESOURCES.pvp
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
        indicator:SetShown(layout.enabled and UnitIsPVP("player"))
    end

    function indicator:RegisterEvents()
        local eventFrame = CreateFrame("Frame")

        eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        eventFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
        eventFrame:SetScript("OnEvent", function(_, _, unit)
            if not unit or unit == "player" then
                self:Update()
            end
        end)

        self.eventFrame = eventFrame
    end

    indicator:RegisterEvents()
    indicator:Update()

    return indicator
end

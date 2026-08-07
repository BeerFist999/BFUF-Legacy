local addonName, BFUF = ...

-- Resting owns the player rest indicator.
BFUF.Elements = BFUF.Elements or {}
BFUF.Elements.Indicators = BFUF.Elements.Indicators or {}

local Resting = {}
BFUF.Elements.Indicators.Resting = Resting

function Resting:Create(parent, layout)
    local resource = BFUF.Elements.StatusIconResources.ICON_RESOURCES.rest
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
        indicator:SetShown(layout.enabled and IsResting())
    end

    function indicator:RegisterEvents()
        local eventFrame = CreateFrame("Frame")

        eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        eventFrame:RegisterEvent("PLAYER_UPDATE_RESTING")
        eventFrame:SetScript("OnEvent", function()
            self:Update()
        end)

        self.eventFrame = eventFrame
    end

    indicator:RegisterEvents()
    indicator:Update()

    return indicator
end

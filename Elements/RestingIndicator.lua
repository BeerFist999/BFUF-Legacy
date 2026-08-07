local addonName, BFUF = ...

-- RestingIndicator displays the player's resting state.
-- The module updates its own visibility and contains no Player Frame logic.
BFUF.Elements = BFUF.Elements or {}

local RestingIndicator = {}
BFUF.Elements.RestingIndicator = RestingIndicator

-- Creates the indicator texture and applies the supplied Layout position.
function RestingIndicator:Create(parent, layout)
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

    -- Shows the indicator only while the player is resting.
    function indicator:Update()
        if IsResting() then
            self:Show()
        else
            self:Hide()
        end
    end

    -- Registers resting-state and world-entry events.
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

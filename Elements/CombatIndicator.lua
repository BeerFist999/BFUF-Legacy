local addonName, BFUF = ...

-- CombatIndicator displays the player's combat state.
-- The module updates its own visibility and contains no Player Frame logic.
BFUF.Elements = BFUF.Elements or {}

local CombatIndicator = {}
BFUF.Elements.CombatIndicator = CombatIndicator

-- Creates the indicator texture and applies the supplied Layout position.
function CombatIndicator:Create(parent, layout)
    local resource = BFUF.Elements.StatusIconResources.ICON_RESOURCES.combat
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

    -- Shows the indicator only while the player is in combat.
    function indicator:Update()
        if UnitAffectingCombat("player") then
            self:Show()
        else
            self:Hide()
        end
    end

    -- Registers only combat start and end events.
    function indicator:RegisterEvents()
        local eventFrame = CreateFrame("Frame")

        eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
        eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        eventFrame:SetScript("OnEvent", function()
            self:Update()
        end)

        self.eventFrame = eventFrame
    end

    indicator:RegisterEvents()
    indicator:Update()

    return indicator
end

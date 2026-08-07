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
    indicator:Show()

    return indicator
end

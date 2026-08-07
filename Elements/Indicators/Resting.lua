local addonName, BFUF = ...

-- Resting manages its own player status indicator.
BFUF.Elements = BFUF.Elements or {}
BFUF.Elements.Indicators = BFUF.Elements.Indicators or {}

local Resting = {}
BFUF.Elements.Indicators.Resting = Resting

local function applyResource(texture, resource)
    if resource.type == "atlas" then
        texture:SetAtlas(resource.value)
    else
        texture:SetTexture(resource.value)
    end

    if resource.texCoord then
        texture:SetTexCoord(unpack(resource.texCoord))
    end
end

function Resting:Create(parent, layout)
    local resource = BFUF.Elements.StatusIconResources.ICON_RESOURCES.rest
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetAllPoints(parent)
    holder:SetFrameLevel(parent:GetFrameLevel() + 20)

    local indicator = holder:CreateTexture(nil, "OVERLAY", nil, 7)
    applyResource(indicator, resource)
    indicator:SetSize(layout.size, layout.size)
    indicator:SetPoint(
        layout.point,
        parent,
        layout.relativePoint,
        layout.offsetX,
        layout.offsetY
    )
    indicator:Hide()

    local function update()
        if BFUF.DB:Get("Player").indicators.resting.enabled and IsResting() then
            indicator:Show()
        else
            indicator:Hide()
        end
    end

    local eventFrame = CreateFrame("Frame", nil, holder)
        eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        eventFrame:RegisterEvent("PLAYER_UPDATE_RESTING")
        eventFrame:SetScript("OnEvent", update)

    indicator.Update = update
    update()

    return indicator
end

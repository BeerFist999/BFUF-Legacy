local addonName, BFUF = ...

-- PvP manages its own player status indicator.
BFUF.Elements = BFUF.Elements or {}
BFUF.Elements.Indicators = BFUF.Elements.Indicators or {}

local PvP = {}
BFUF.Elements.Indicators.PvP = PvP

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

function PvP:Create(parent)
    local resource = BFUF.Elements.StatusIconResources.ICON_RESOURCES.pvp
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetFrameLevel(parent:GetFrameLevel() + 20)

    local indicator = holder:CreateTexture(nil, "OVERLAY", nil, 7)
    applyResource(indicator, resource)
    indicator.holder = holder
    indicator:Hide()

    local function update()
        if BFUF.DB:Get("Player").indicators.pvp.enabled and UnitIsPVP("player") then
            indicator:Show()
        else
            indicator:Hide()
        end
    end

    local eventFrame = CreateFrame("Frame", nil, holder)
        eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        eventFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
        eventFrame:SetScript("OnEvent", function(_, _, unit)
            if not unit or unit == "player" then
                update()
            end
        end)

    indicator.Update = update
    update()

    return indicator
end

local addonName, BFUF = ...

-- Assistant manages its own player status indicator.
BFUF.Elements = BFUF.Elements or {}
BFUF.Elements.Indicators = BFUF.Elements.Indicators or {}

local Assistant = {}
BFUF.Elements.Indicators.Assistant = Assistant

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

function Assistant:Create(parent)
    local resource = BFUF.Elements.StatusIconResources.ICON_RESOURCES.assistant
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetFrameLevel(parent:GetFrameLevel() + 20)

    local indicator = holder:CreateTexture(nil, "OVERLAY", nil, 7)
    applyResource(indicator, resource)
    indicator.holder = holder
    indicator:Hide()

    local function update()
        local isAssistant = UnitIsGroupAssistant("player")

        if BFUF.DB:Get("Player").indicators.assistant.enabled and not issecretvalue(isAssistant) and isAssistant then
            indicator:Show()
        else
            indicator:Hide()
        end
    end

    local eventFrame = CreateFrame("Frame", nil, holder)
        eventFrame:RegisterEvent("PARTY_LEADER_CHANGED")
        eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
        eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        eventFrame:SetScript("OnEvent", update)

    indicator.Update = update
    update()

    return indicator
end

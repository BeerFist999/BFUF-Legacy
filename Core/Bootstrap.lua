local addonName, BFUF = ...

local Bootstrap = {}
BFUF.Core.Bootstrap = Bootstrap

local function hideBlizzardPlayerFrame()
    if PlayerFrame then
        PlayerFrame:UnregisterAllEvents()
        PlayerFrame:Hide()
    end
end

function Bootstrap:Initialize()
    BFUF:Debug("Factory initialized")
    BFUF:Debug("Registry initialized")

    local playerFrame = BFUF.Frames.Player:Create()
    if playerFrame then
        BFUF:Debug("Player Frame created")
        BFUF:Print("Player Frame created.")
    end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:SetScript("OnEvent", hideBlizzardPlayerFrame)
    hideBlizzardPlayerFrame()
end

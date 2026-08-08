local addonName, BFUF = ...

local Bootstrap = {}
BFUF.Core.Bootstrap = Bootstrap

function Bootstrap:Initialize()
    BFUF:Debug("Factory initialized")
    BFUF:Debug("Registry initialized")

    local playerFrame = BFUF.Frames.Player:Create()
    if playerFrame then
        BFUF:Debug("Player Frame created")
        BFUF:Print("Player Frame created.")
    end

    local targetFrame = BFUF.Frames.Target:Create()
    if targetFrame then
        BFUF:Debug("Target Frame created")
    end

    local bossFrames = BFUF.Frames.Boss:Create()
    if bossFrames then
        BFUF:Debug("Boss Frames created")
    end

    BFUF.Core.BlizzardFrameController:Initialize()
    BFUF.Core.BlizzardBossController:Initialize()
end

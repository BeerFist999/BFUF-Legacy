local addonName, BFUF = ...

local SlashCommands = {}
BFUF.Core.SlashCommands = SlashCommands

-- Register the supported commands once during addon initialization.
function SlashCommands:Initialize()
    if self.initialized then
        return
    end

    SLASH_BFUF1 = "/bfuf"
    SLASH_BFUF2 = "/bf"
    SLASH_BFUF3 = "/beerfist"

    SlashCmdList.BFUF = function()
        BFUF.Core.Settings:Open()
    end

    self.initialized = true
end

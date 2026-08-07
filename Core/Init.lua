local addonName, BFUF = ...

-- Create addon namespaces before the remaining modules are loaded.
BFUF.Core = BFUF.Core or {}
BFUF.DB = BFUF.DB or {}
BFUF.Frames = BFUF.Frames or {}
BFUF.Elements = BFUF.Elements or {}
BFUF.Options = BFUF.Options or {}
BFUF.Utils = BFUF.Utils or {}
BFUF.Config = BFUF.Config or {}

-- This flag is a temporary debug switch for development builds.
BFUF.DebugEnabled = BFUF.DebugEnabled or false

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(_, event, loadedAddonName)
    if event == "ADDON_LOADED" and loadedAddonName == addonName then
        BFUF:Initialize()
    end
end)

-- Initialize only the foundational systems required by the addon.
function BFUF:Initialize()
    BFUF.Localization:Initialize()
    BFUF:Debug("BFUF: Localization initialized.")

    BFUF.Core.Defaults:Initialize()
    BFUF:Debug("BFUF: Defaults initialized.")

    BFUF.DB:Initialize()
    BFUF:Debug("BFUF: Database initialized.")

    BFUF.Core.Settings:Initialize()
    BFUF.Core.SlashCommands:Initialize()
    BFUF:Debug("BFUF: Settings initialized.")

    BFUF.Core.Bootstrap:Initialize()
    BFUF:Debug("BFUF: Bootstrap initialized.")

    BFUF:Print("BFUF Alpha 0.0.1 loaded.")
end

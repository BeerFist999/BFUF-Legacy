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

    SLASH_BFUFDRAGDEBUG1 = "/bfufdragdebug"
    SlashCmdList.BFUFDRAGDEBUG = function()
        local root = BFUF.Framework.Registry:GetFrame("player")
        if not root then return end
        local cursorX, cursorY = GetCursorPosition()
        local point, relativeTo, relativePoint, offsetX, offsetY = root:GetPoint()
        local settings = BFUF.DB:Get("Player")
        local output = {
            "BFUF drag debug:",
            "Cursor: " .. cursorX .. ", " .. cursorY,
            "UIParent scale: " .. UIParent:GetEffectiveScale(),
            "PlayerRoot effective scale: " .. root:GetEffectiveScale(),
            "PlayerRoot left/bottom: " .. tostring(root:GetLeft()) .. ", " .. tostring(root:GetBottom()),
            "Calculated/saved position: " .. settings.positionX .. ", " .. settings.positionY,
            "Anchor: " .. tostring(point) .. " / " .. tostring(relativePoint) .. " / " .. tostring(offsetX) .. ", " .. tostring(offsetY),
        }
        for _, line in ipairs(output) do DEFAULT_CHAT_FRAME:AddMessage(line) end
    end

    self.initialized = true
end

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

    SLASH_BFUFGEOMETRYDEBUG1 = "/bfufgeometrydebug"
    SlashCmdList.BFUFGEOMETRYDEBUG = function()
        local function printGeometry(label, frameKey, profileKey)
            local root = BFUF.Framework.Registry:GetFrame(frameKey)
            local settings = BFUF.DB:Get(profileKey)

            DEFAULT_CHAT_FRAME:AddMessage("BFUF geometry: " .. label)
            DEFAULT_CHAT_FRAME:AddMessage(
                "Profile W/H/Scale: "
                    .. tostring(settings and settings.width)
                    .. " / "
                    .. tostring(settings and settings.height)
                    .. " / "
                    .. tostring(settings and settings.scale)
            )

            if not root then
                DEFAULT_CHAT_FRAME:AddMessage("Root: not created")
                return
            end

            DEFAULT_CHAT_FRAME:AddMessage(
                "Root W/H/Scale/Effective: "
                    .. tostring(root:GetWidth())
                    .. " / "
                    .. tostring(root:GetHeight())
                    .. " / "
                    .. tostring(root:GetScale())
                    .. " / "
                    .. tostring(root:GetEffectiveScale())
            )
            DEFAULT_CHAT_FRAME:AddMessage(
                "Root screen W/H: "
                    .. tostring(root:GetWidth() * root:GetEffectiveScale())
                    .. " / "
                    .. tostring(root:GetHeight() * root:GetEffectiveScale())
            )
            DEFAULT_CHAT_FRAME:AddMessage(
                "Root left/right/top/bottom: "
                    .. tostring(root:GetLeft())
                    .. " / "
                    .. tostring(root:GetRight())
                    .. " / "
                    .. tostring(root:GetTop())
                    .. " / "
                    .. tostring(root:GetBottom())
            )
        end

        printGeometry("Player", "player", "Player")
        printGeometry("Target", "target", "Target")
    end

    self.initialized = true
end

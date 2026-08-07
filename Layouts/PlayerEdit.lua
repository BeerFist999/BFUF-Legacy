local addonName, BFUF = ...

BFUF.Layouts = BFUF.Layouts or {}

local PlayerEdit = {}
BFUF.Layouts.PlayerEdit = PlayerEdit

-- Attach Blizzard's native movement lifecycle to PlayerRoot.
function PlayerEdit:Attach(root)
    root:SetMovable(true)
    root:SetClampedToScreen(true)
    root:RegisterForDrag("LeftButton")

    root:SetScript("OnDragStart", function(frame)
        if frame.layoutUnlocked then
            frame:StartMoving()
        end
    end)

    root:SetScript("OnDragStop", function(frame)
        if not frame.layoutUnlocked then
            return
        end

        frame:StopMovingOrSizing()
        PlayerEdit:SaveAnchor(frame)
        BFUF.Layouts.Player:Apply(frame)
    end)
end

-- Persist the final native anchor without cursor or scale calculations.
function PlayerEdit:SaveAnchor(root)
    local point, relativeTo, relativePoint, offsetX, offsetY = root:GetPoint()
    local settings = BFUF.DB:Get("Player")

    settings.positionAnchor = {
        point = point,
        relativePoint = relativePoint,
        offsetX = offsetX,
        offsetY = offsetY,
    }

    -- PlayerLayout currently stores its root offsets in these profile fields.
    settings.positionX = offsetX
    settings.positionY = offsetY
    BFUF.Config.Player:RefreshLayoutControls()
end

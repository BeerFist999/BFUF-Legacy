local addonName, BFUF = ...

BFUF.Layouts = BFUF.Layouts or {}

local PlayerEdit = {}
BFUF.Layouts.PlayerEdit = PlayerEdit

function PlayerEdit:Attach(root)
    root:SetClampedToScreen(true)
    root:SetMovable(true)
    root:SetScript("OnMouseDown", function(frame, button)
        if button == "LeftButton" and frame.layoutUnlocked then
            frame.isDragging = true
            frame:StartMoving()
        end
    end)
    root:SetScript("OnMouseUp", function(frame, button)
        if button == "LeftButton" and frame.isDragging then
            frame:StopMovingOrSizing()
            frame.isDragging = false
            PlayerEdit:SavePosition(frame)
            BFUF.Layouts.Player:Apply(frame)
        end
    end)
    root:SetScript("OnUpdate", function(frame)
        if frame.isDragging then
            PlayerEdit:SavePosition(frame)
        end
    end)
end

function PlayerEdit:SavePosition(root)
    local left, bottom = root:GetLeft(), root:GetBottom()
    if not left or not bottom then return end
    local parentScale = UIParent:GetEffectiveScale()
    local frameScale = root:GetEffectiveScale() / parentScale
    local settings = BFUF.DB:Get("Player")
    settings.positionX = math.floor(left / parentScale + root:GetWidth() * frameScale / 2 - UIParent:GetWidth() / 2 + .5)
    settings.positionY = math.floor(bottom / parentScale + root:GetHeight() * frameScale / 2 - UIParent:GetHeight() / 2 + .5)
    BFUF.Config.Player:RefreshLayoutControls()
end

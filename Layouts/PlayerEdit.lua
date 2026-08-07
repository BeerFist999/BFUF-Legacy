local addonName, BFUF = ...

BFUF.Layouts = BFUF.Layouts or {}

local PlayerEdit = {}
BFUF.Layouts.PlayerEdit = PlayerEdit

function PlayerEdit:Attach(root)
    root:SetClampedToScreen(true)
    root:SetScript("OnMouseDown", function(frame, button)
        if button ~= "LeftButton" or not frame.layoutUnlocked then return end
        local scale = UIParent:GetEffectiveScale()
        local cursorX, cursorY = GetCursorPosition()
        local left, bottom = frame:GetLeft(), frame:GetBottom()
        if not left or not bottom then return end
        frame.dragOffsetX = cursorX / scale - left / scale
        frame.dragOffsetY = cursorY / scale - bottom / scale
        frame.isDragging = true
    end)
    root:SetScript("OnMouseUp", function(frame)
        if not frame.isDragging then return end
        frame.isDragging = false
        BFUF.Layouts.PlayerEdit:SavePosition(frame)
        BFUF.Layouts.Player:Apply(frame)
    end)
    root:SetScript("OnUpdate", function(frame)
        if not frame.isDragging then return end
        local scale = UIParent:GetEffectiveScale()
        local cursorX, cursorY = GetCursorPosition()
        frame:ClearAllPoints()
        frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", cursorX / scale - frame.dragOffsetX, cursorY / scale - frame.dragOffsetY)
        BFUF.Layouts.PlayerEdit:SavePosition(frame)
    end)
end

function PlayerEdit:SavePosition(root)
    local scale = UIParent:GetEffectiveScale()
    local left, bottom = root:GetLeft(), root:GetBottom()
    if not left or not bottom then return end
    local settings = BFUF.DB:Get("Player")
    settings.positionX = math.floor(left / scale + root:GetWidth() * root:GetScale() / 2 - UIParent:GetWidth() / 2 + .5)
    settings.positionY = math.floor(bottom / scale + root:GetHeight() * root:GetScale() / 2 - UIParent:GetHeight() / 2 + .5)
    BFUF.Config.Player:RefreshLayoutControls()
end

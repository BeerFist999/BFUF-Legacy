local addonName, BFUF = ...

BFUF.Elements = BFUF.Elements or {}

local Portrait = {
    Modes = {
        HIDDEN = "hidden",
        TWO_D = "2d",
    },
}
BFUF.Elements.Portrait = Portrait

local PORTRAIT_TEX_COORD = {
    left = 0.08,
    right = 0.92,
    top = 0.08,
    bottom = 0.92,
}

local function isTargetUnit(unit)
    return unit == "target"
end

local function setTwoDPortrait(texture, unit)
    SetPortraitTexture(texture, unit)
    texture:SetTexCoord(
        PORTRAIT_TEX_COORD.left,
        PORTRAIT_TEX_COORD.right,
        PORTRAIT_TEX_COORD.top,
        PORTRAIT_TEX_COORD.bottom
    )
end

-- Create a square 2D portrait renderer that fills geometry supplied by a layout.
function Portrait:Create(parent, context)
    local container = CreateFrame("Frame", nil, parent)
    container.context = context or {}

    local texture = container:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints(container)
    container.texture = texture
    container.mode = Portrait.Modes.TWO_D
    container.activeRenderer = "2d"
    container.visible = true

    function container:SetUnit(unit)
        if self.unit == unit then
            return
        end

        self.unit = unit
        self:Update("UNIT_CHANGED")
    end

    -- Apply a profile-neutral settings table supplied by the frame context.
    function container:ApplySettings(settings)
        settings = settings or (self.context.getSettings and self.context.getSettings())
        local mode = settings and settings.mode

        if mode == Portrait.Modes.HIDDEN then
            self.mode = Portrait.Modes.HIDDEN
        elseif mode then
            -- Portrait is intentionally 2D-only; legacy modes continue using
            -- the existing 2D renderer without changing profile data.
            self.mode = Portrait.Modes.TWO_D
        end

        self:SetVisible(self.mode ~= Portrait.Modes.HIDDEN)
        if self.visible then
            self:Update("SETTINGS_CHANGED")
        end
    end

    -- Preserve the legacy frame API while routing it through the shared contract.
    function container:SetMode(mode)
        if mode == nil then
            self:ApplySettings()
        else
            self:ApplySettings({ mode = mode })
        end
    end

    -- Layout owns all geometry calculations. The element applies only this
    -- already-resolved rectangle and keeps its texture bound to the renderer.
    function container:ApplyLayout(region)
        if not region or not region.parent then
            return false
        end

        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", region.parent, "TOPLEFT", region.left, region.top)
        self:SetPoint("BOTTOMRIGHT", region.parent, "BOTTOMRIGHT", region.right, region.bottom)
        return true
    end

    function container:SetVisible(visible)
        self.visible = visible ~= false

        if self.visible then
            self:Show()
        else
            self.texture:Hide()
            self:Hide()
        end
    end

    function container:Update()
        if self.mode == Portrait.Modes.HIDDEN then
            self:SetVisible(false)
            return
        end

        local unit = self.unit or self.context.unit
        if not unit or not UnitExists(unit) then
            self.texture:SetTexture(nil)
            self.texture:Hide()
            self:SetVisible(false)
            return
        end

        self:SetVisible(true)
        setTwoDPortrait(self.texture, unit)
        self.texture:Show()
        self.activeRenderer = "2d"
    end

    function container:RegisterEvents()
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:RegisterEvent("PLAYER_TARGET_CHANGED")
        self:RegisterEvent("UNIT_PORTRAIT_UPDATE")
        self:RegisterEvent("UNIT_CONNECTION")

        self:SetScript("OnEvent", function(renderer, event, unit)
            if event == "PLAYER_ENTERING_WORLD" then
                renderer:Update(event)
            elseif event == "PLAYER_TARGET_CHANGED" then
                if isTargetUnit(renderer.unit) then
                    renderer:Update(event)
                end
            elseif unit == renderer.unit then
                renderer:Update(event)
            end
        end)
    end

    function container:Destroy()
        self:UnregisterAllEvents()
        self:SetScript("OnEvent", nil)
        self.texture:SetTexture(nil)
        self:SetVisible(false)
        self.context = nil
        self.unit = nil
    end

    container:RegisterEvents()
    return container
end

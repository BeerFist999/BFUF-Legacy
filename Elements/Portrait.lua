local addonName, BFUF = ...

BFUF.Elements = BFUF.Elements or {}

local Portrait = {
    Modes = {
        TWO_D = "2d",
    },
}
BFUF.Elements.Portrait = Portrait

local function isTargetUnit(unit)
    return unit == "target"
end

-- Create a square 2D portrait renderer that fills its parent container.
function Portrait:Create(parent)
    local container = CreateFrame("Frame", nil, parent)

    local texture = container:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints(container)
    container.texture = texture
    container.mode = Portrait.Modes.TWO_D
    container.activeRenderer = "2d"

    function container:SetUnit(unit)
        if self.unit == unit then
            return
        end

        self.unit = unit
        self:Update("UNIT_CHANGED")
    end

    -- Keep the public mode method for existing frame callers while using 2D only.
    function container:SetMode()
        self.mode = Portrait.Modes.TWO_D
        self:Update("MODE_CHANGED")
    end

    function container:Update()
        local unit = self.unit

        if not unit or not UnitExists(unit) then
            self.texture:SetTexture(nil)
            self.texture:Hide()
            self:Hide()
            return
        end

        self:Show()
        SetPortraitTexture(self.texture, unit)
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

    container:RegisterEvents()
    return container
end

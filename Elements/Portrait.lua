local addonName, BFUF = ...

BFUF.Elements = BFUF.Elements or {}

local Portrait = {
    Modes = {
        HIDDEN = "hidden",
        TWO_D = "2d",
        THREE_D = "3d",
    },
}
BFUF.Elements.Portrait = Portrait

-- Create a complete portrait container that supports 2D and 3D renderers.
function Portrait:Create(parent)
    local container = CreateFrame("Frame", nil, parent)

    local texture = container:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints(container)
    container.texture = texture

    local model = CreateFrame("PlayerModel", nil, container)
    model:SetAllPoints(container)
    model:SetScript("OnShow", function(self)
        -- Keep the viewport camera consistent after the renderer becomes visible.
        self:SetPortraitZoom(1)
        self:SetPosition(0, 0, 0)
    end)
    model:Hide()
    container.model = model
    container.mode = Portrait.Modes.TWO_D

    function container:SetUnit(unit)
        self.unit = unit
    end

    function container:SetMode(mode)
        self.mode = mode
        self:Update()
    end

    function container:Update()
        if not self.unit then
            return
        end

        if self.mode == Portrait.Modes.HIDDEN then
            self:Hide()
            return
        end

        self:Show()
        if self.mode == Portrait.Modes.THREE_D then
            self.texture:Hide()
            self.model:ClearModel()
            self.model:SetUnit(self.unit)
            self.model:SetPortraitZoom(1)
            self.model:SetPosition(0, 0, 0)
            self.model:Show()
        else
            self.model:Hide()
            SetPortraitTexture(self.texture, self.unit)
            self.texture:Show()
        end
    end

    return container
end

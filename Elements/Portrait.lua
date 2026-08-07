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


-- Print the final runtime state of both portrait renderers for diagnostics.
function Portrait:PrintRenderState()
    local root = BFUF.Framework.Registry:GetFrame("player")
    if not root or not root.portraitContainer or not root.portrait then
        BFUF:Print("[BFUF Portrait] Player portrait is not available.")
        return
    end

    local container = root.portraitContainer
    local portrait = root.portrait
    local texture = portrait.texture
    local model = portrait.model
    local textureLayer, textureSubLevel = texture:GetDrawLayer()

    BFUF:Print(string.format(
        "[BFUF Portrait] Container W=%s H=%s Level=%s Strata=%s Shown=%s",
        tostring(container:GetWidth()),
        tostring(container:GetHeight()),
        tostring(container:GetFrameLevel()),
        tostring(container:GetFrameStrata()),
        tostring(container:IsShown())
    ))
    BFUF:Print(string.format(
        "[BFUF Portrait] Texture W=%s H=%s Alpha=%s Shown=%s Visible=%s Layer=%s/%s",
        tostring(texture:GetWidth()),
        tostring(texture:GetHeight()),
        tostring(texture:GetAlpha()),
        tostring(texture:IsShown()),
        tostring(texture:IsVisible()),
        tostring(textureLayer),
        tostring(textureSubLevel)
    ))
    BFUF:Print(string.format(
        "[BFUF Portrait] Model W=%s H=%s Alpha=%s Shown=%s Visible=%s Level=%s Strata=%s",
        tostring(model:GetWidth()),
        tostring(model:GetHeight()),
        tostring(model:GetAlpha()),
        tostring(model:IsShown()),
        tostring(model:IsVisible()),
        tostring(model:GetFrameLevel()),
        tostring(model:GetFrameStrata())
    ))
end

-- The temporary command lives beside the diagnostic code for simple removal.
SLASH_BFUFPORTRAITDEBUG1 = "/bfufportraitdebug"
SlashCmdList.BFUFPORTRAITDEBUG = function()
    Portrait:PrintRenderState()
end

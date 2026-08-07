local addonName, BFUF = ...

BFUF.Elements = BFUF.Elements or {}

local Portrait = {
    Modes = {
        HIDDEN = "hidden",
        TWO_D = "2d",
        THREE_D = "3d",
    },
    PortraitFitScale = 1.00,
}
BFUF.Elements.Portrait = Portrait

local function normalizeFitScale(value)
    value = tonumber(value) or 1.00
    value = math.max(0.60, math.min(1.20, value))
    return math.floor(value * 100 + 0.5) / 100
end

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
        self:SetPortraitZoom(Portrait.PortraitFitScale)
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

    function container:ApplyFitScale()
        -- A 2D texture already fills its layout-owned rectangle. Only PlayerModel
        -- has an independent camera viewport that needs calibration.
        self.model:SetPortraitZoom(Portrait.PortraitFitScale)
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
            self:ApplyFitScale()
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

-- Apply the temporary calibration coefficient without changing layout geometry.
function Portrait:SetFitScale(value)
    self.PortraitFitScale = normalizeFitScale(value)

    local root = BFUF.Framework.Registry:GetFrame("player")
    if root and root.portrait then
        root.portrait:ApplyFitScale()
    end

    return self.PortraitFitScale
end

-- Open a temporary developer-only slider for PlayerModel portrait calibration.
function Portrait:OpenFitCalibration()
    if not self.fitCalibrationFrame then
        local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        frame:SetSize(260, 54)
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 180)
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 5, right = 5, top = 5, bottom = 5 },
        })
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

        local slider = CreateFrame("Slider", nil, frame, "OptionsSliderTemplate")
        slider:SetPoint("CENTER", frame, "CENTER", 0, 0)
        slider:SetWidth(210)
        slider:SetMinMaxValues(0.60, 1.20)
        slider:SetValueStep(0.01)
        slider:SetObeyStepOnDrag(true)

        local value = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        value:SetPoint("BOTTOM", slider, "TOP", 0, 6)

        slider:SetScript("OnValueChanged", function(_, newValue)
            local fitScale = Portrait:SetFitScale(newValue)
            value:SetText(string.format("%.2f", fitScale))
        end)

        frame.slider = slider
        frame.value = value
        self.fitCalibrationFrame = frame
    end

    local frame = self.fitCalibrationFrame
    frame.slider:SetValue(self.PortraitFitScale)
    frame:Show()
end

-- The temporary command intentionally lives beside its calibration UI.
SLASH_BFUFPORTRAITFIT1 = "/bfufportraitfit"
SlashCmdList.BFUFPORTRAITFIT = function()
    Portrait:OpenFitCalibration()
end

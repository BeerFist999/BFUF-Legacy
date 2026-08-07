local addonName, BFUF = ...

BFUF.Layouts = BFUF.Layouts or {}

local PlayerLayout = {}
BFUF.Layouts.Player = PlayerLayout

local function setRectangle(region, parent, left, right, top, bottom)
    region:ClearAllPoints()
    region:SetPoint("TOPLEFT", parent, "TOPLEFT", left, top)
    region:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", right, bottom)
end

-- Apply every Player Frame rectangle from one resolved layout.
function PlayerLayout:Apply(root)
    if InCombatLockdown() then
        root.layoutPending = true
        return
    end

    local settings = BFUF.DB:Get("Player")
    local portrait = settings.portrait
    local health = settings.health
    local power = settings.power
    local padding = 3
    local spacing = 2

    root:SetSize(settings.width, settings.height)
    root:SetScale(settings.scale)
    root:ClearAllPoints()
    root:SetPoint("CENTER", UIParent, "CENTER", settings.positionX, settings.positionY)

    setRectangle(root.background, root, 0, 0, 0, 0)
    setRectangle(root.border, root, 0, 0, 0, 0)
    setRectangle(root.statusIconsContainer, root, 0, 0, 0, 0)
    setRectangle(root.overlayContainer, root, 0, 0, 0, 0)

    local portraitVisible = portrait.mode ~= BFUF.Elements.Portrait.Modes.HIDDEN
    local barsLeft = padding
    if portraitVisible then
        root.portraitContainer:Show()
        root.portraitContainer:ClearAllPoints()
        root.portraitContainer:SetPoint("TOPLEFT", root, "TOPLEFT", padding, -padding)
        root.portraitContainer:SetSize(portrait.width, portrait.height)
        barsLeft = padding + portrait.width + spacing
    else
        root.portraitContainer:Hide()
    end

    setRectangle(root.barsContainer, root, barsLeft, -padding, -padding, padding)
    setRectangle(root.textContainer, root.barsContainer, 0, 0, 0, 0)

    root.healthBar:ClearAllPoints()
    root.healthBar:SetPoint("TOPLEFT", root.barsContainer, "TOPLEFT", health.offsetX, health.offsetY)
    root.healthBar:SetPoint("TOPRIGHT", root.barsContainer, "TOPRIGHT", -health.offsetX, health.offsetY)
    root.healthBar:SetHeight(health.height)

    root.powerBar:ClearAllPoints()
    root.powerBar:SetPoint("BOTTOMLEFT", root.barsContainer, "BOTTOMLEFT", power.offsetX, power.offsetY)
    root.powerBar:SetPoint("BOTTOMRIGHT", root.barsContainer, "BOTTOMRIGHT", -power.offsetX, power.offsetY)
    root.powerBar:SetHeight(power.height)

    root.classResourceContainer:ClearAllPoints()
    root.classResourceContainer:SetPoint("TOPLEFT", root.barsContainer, "BOTTOMLEFT", 0, -spacing)
    root.classResourceContainer:SetPoint("TOPRIGHT", root.barsContainer, "BOTTOMRIGHT", 0, -spacing)
    root.classResourceContainer:SetHeight(0)

    root.portrait:SetMode(portrait.mode)
    root.healthBar:UpdateStyle()
    root.powerBar:UpdateStyle()
    root.layoutPending = false
end

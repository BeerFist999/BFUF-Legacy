local addonName, BFUF = ...

-- CombatIndicator отображает состояние боя игрока.
-- Модуль самостоятельно обновляет видимость и не содержит логики Player Frame.
BFUF.Elements = BFUF.Elements or {}

local CombatIndicator = {}
BFUF.Elements.CombatIndicator = CombatIndicator

-- Создаёт текстуру индикатора и применяет положение из переданного Layout.
function CombatIndicator:Create(parent, layout)
    local indicator = parent:CreateTexture(nil, "OVERLAY")

    indicator:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
    -- Правая верхняя часть стандартной текстуры Blizzard содержит значок боя.
    indicator:SetTexCoord(0.5, 1.0, 0.0, 0.5)
    indicator:SetSize(layout.size, layout.size)
    indicator:SetPoint(
        layout.point,
        parent,
        layout.relativePoint,
        layout.offsetX,
        layout.offsetY
    )
    indicator:Hide()

    -- Показывает индикатор только во время боя.
    function indicator:Update()
        if UnitAffectingCombat("player") then
            self:Show()
        else
            self:Hide()
        end
    end

    -- Регистрирует только события начала и завершения боя.
    function indicator:RegisterEvents()
        local eventFrame = CreateFrame("Frame")

        eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
        eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        eventFrame:SetScript("OnEvent", function()
            self:Update()
        end)

        self.eventFrame = eventFrame
    end

    indicator:RegisterEvents()
    indicator:Update()

    return indicator
end

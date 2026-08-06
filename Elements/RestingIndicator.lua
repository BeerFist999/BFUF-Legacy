local addonName, BFUF = ...

-- RestingIndicator отображает состояние отдыха игрока.
-- Модуль самостоятельно обновляет видимость и не содержит логики Player Frame.
BFUF.Elements = BFUF.Elements or {}

local RestingIndicator = {}
BFUF.Elements.RestingIndicator = RestingIndicator

-- Создаёт текстуру индикатора и применяет положение из переданного Layout.
function RestingIndicator:Create(parent, layout)
    local indicator = parent:CreateTexture(nil, "OVERLAY")

    indicator:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
    -- Левая верхняя часть стандартной текстуры Blizzard содержит значок отдыха.
    indicator:SetTexCoord(0.0, 0.5, 0.0, 0.5)
    indicator:SetSize(layout.size, layout.size)
    indicator:SetPoint(
        layout.point,
        parent,
        layout.relativePoint,
        layout.offsetX,
        layout.offsetY
    )
    indicator:Hide()

    -- Показывает индикатор только в состоянии отдыха.
    function indicator:Update()
        if IsResting() then
            self:Show()
        else
            self:Hide()
        end
    end

    -- Регистрирует событие изменения состояния отдыха.
    function indicator:RegisterEvents()
        local eventFrame = CreateFrame("Frame")

        eventFrame:RegisterEvent("PLAYER_UPDATE_RESTING")
        eventFrame:SetScript("OnEvent", function()
            self:Update()
        end)

        self.eventFrame = eventFrame
    end

    indicator:RegisterEvents()
    indicator:Update()

    return indicator
end

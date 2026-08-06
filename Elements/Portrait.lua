local addonName, BFUF = ...

-- Portrait создаёт независимый элемент портрета юнита.
-- API предусматривает варианты Texture и PlayerModel; пока реализован только Texture.
BFUF.Elements = BFUF.Elements or {}

local Portrait = {
    Types = {
        TEXTURE = "texture",
        MODEL = "model",
    },
}
BFUF.Elements.Portrait = Portrait

-- Создаёт 2D-портрет. Размер и положение передаются внешним Layout-слоем.
function Portrait:Create(parent, portraitType)
    local texture = parent:CreateTexture(nil, "ARTWORK")

    -- Сохраняем запрошенный тип для будущей реализации PlayerModel.
    texture.portraitType = portraitType or Portrait.Types.TEXTURE

    -- Сохраняет игровой юнит, портрет которого должен отображаться.
    function texture:SetUnit(unit)
        self.unit = unit
    end

    -- Обновляет 2D-портрет штатной функцией Blizzard.
    function texture:Update()
        if not self.unit then
            return
        end

        -- PlayerModel будет реализован отдельно; пока оба типа используют 2D-портрет.
        SetPortraitTexture(self, self.unit)
    end

    return texture
end

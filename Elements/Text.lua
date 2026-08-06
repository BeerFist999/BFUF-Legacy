local addonName, BFUF = ...

-- Text создаёт универсальные FontString без привязки к конкретному Unit Frame.
BFUF.Elements = BFUF.Elements or {}

local Text = {}
BFUF.Elements.Text = Text

-- Создаёт FontString и применяет переданные параметры отображения.
function Text:Create(parent, options)
    options = options or {}

    local fontString = parent:CreateFontString(nil, options.layer or "OVERLAY")
    local font = options.font or STANDARD_TEXT_FONT
    local size = options.size or 12
    local flags = options.flags or ""
    local color = options.color or { r = 1, g = 1, b = 1, a = 1 }

    -- Шрифт и размер могут быть переопределены вызывающим модулем.
    fontString:SetFont(font, size, flags)

    -- Цвет поддерживает именованные и числовые поля таблицы.
    fontString:SetTextColor(
        color.r or color[1] or 1,
        color.g or color[2] or 1,
        color.b or color[3] or 1,
        color.a or color[4] or 1
    )

    -- Выравнивание текста задаётся отдельно по горизонтали и вертикали.
    fontString:SetJustifyH(options.justifyH or "LEFT")
    fontString:SetJustifyV(options.justifyV or "MIDDLE")

    -- Для отображения текста используется штатный метод FontString:SetText().
    if options.text ~= nil then
        fontString:SetText(options.text)
    end

    return fontString
end

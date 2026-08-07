local addonName, BFUF = ...

local Indicators = {}
BFUF.Config.Indicators = Indicators

-- Create the Indicators placeholder category.
function Indicators:Create(parentCategory)
    return BFUF.Core.Settings:CreatePlaceholderCategory(
        parentCategory,
        BFUF.L.CATEGORY_INDICATORS,
        BFUF.L.DESCRIPTION_INDICATORS
    )
end

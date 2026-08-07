local addonName, BFUF = ...

local General = {}
BFUF.Config.General = General

-- Create the General placeholder category.
function General:Create(parentCategory)
    return BFUF.Core.Settings:CreatePlaceholderCategory(
        parentCategory,
        BFUF.L.CATEGORY_GENERAL,
        BFUF.L.DESCRIPTION_GENERAL
    )
end

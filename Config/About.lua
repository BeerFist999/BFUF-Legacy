local addonName, BFUF = ...

local About = {}
BFUF.Config.About = About

-- Create the About placeholder category.
function About:Create(parentCategory)
    return BFUF.Core.Settings:CreatePlaceholderCategory(
        parentCategory,
        BFUF.L.CATEGORY_ABOUT,
        BFUF.L.DESCRIPTION_ABOUT
    )
end

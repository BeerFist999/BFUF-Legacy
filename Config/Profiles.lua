local addonName, BFUF = ...

local Profiles = {}
BFUF.Config.Profiles = Profiles

-- Create the Profiles placeholder category.
function Profiles:Create(parentCategory)
    return BFUF.Core.Settings:CreatePlaceholderCategory(
        parentCategory,
        BFUF.L.CATEGORY_PROFILES,
        BFUF.L.DESCRIPTION_PROFILES
    )
end

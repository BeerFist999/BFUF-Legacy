local addonName, BFUF = ...

local Player = {}
BFUF.Config.Player = Player

-- Create the Player placeholder category.
function Player:Create(parentCategory)
    return BFUF.Core.Settings:CreatePlaceholderCategory(
        parentCategory,
        BFUF.L.CATEGORY_PLAYER,
        BFUF.L.DESCRIPTION_PLAYER
    )
end

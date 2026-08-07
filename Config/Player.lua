local addonName, BFUF = ...

local Player = {}
BFUF.Config.Player = Player

-- Create the Player settings category.
function Player:Create(parentCategory)
    local category = Settings.RegisterVerticalLayoutSubcategory(
        parentCategory,
        BFUF.L.CATEGORY_PLAYER
    )

    local function getShowPortrait()
        return BFUF.DB:Get("Player").showPortrait
    end

    local function setShowPortrait(value)
        BFUF.DB:Get("Player").showPortrait = value
        BFUF.Frames.Player:UpdatePortrait()
    end

    local setting = Settings.RegisterProxySetting(
        category,
        "BFUF_PLAYER_SHOW_PORTRAIT",
        Settings.VarType.Boolean,
        BFUF.L.OPTION_SHOW_PORTRAIT,
        true,
        getShowPortrait,
        setShowPortrait
    )

    Settings.CreateCheckbox(category, setting)

    return category
end

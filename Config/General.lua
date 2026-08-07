local addonName, BFUF = ...

local General = {}
BFUF.Config.General = General

function General:Create(parentCategory)
    local category = Settings.RegisterVerticalLayoutSubcategory(parentCategory, BFUF.L.CATEGORY_GENERAL)
    BFUF.DebugEnabled = BFUF.DB:Get("General").debugMode

    local setting = Settings.RegisterProxySetting(
        category,
        "BFUF_DEBUG_MODE",
        Settings.VarType.Boolean,
        BFUF.L.OPTION_ENABLE_DEBUG_MODE,
        false,
        function()
            return BFUF.DB:Get("General").debugMode
        end,
        function(value)
            BFUF.DB:Get("General").debugMode = value
            BFUF.DebugEnabled = value
        end
    )
    Settings.CreateCheckbox(category, setting)
    return category
end

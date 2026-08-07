local addonName, BFUF = ...

local General = {}
BFUF.Config.General = General

-- Register a Boolean proxy setting backed by the active AceDB profile.
local function createBooleanSetting(category, variable, key, label, defaultValue, onChanged)
    local function getValue()
        return BFUF.DB:Get("General")[key]
    end

    local function setValue(value)
        BFUF.DB:Get("General")[key] = value

        if onChanged then
            onChanged(value)
        end
    end

    local setting = Settings.RegisterProxySetting(
        category,
        variable,
        Settings.VarType.Boolean,
        label,
        defaultValue,
        getValue,
        setValue
    )

    Settings.CreateCheckbox(category, setting)
end

-- Create the General settings category.
function General:Create(parentCategory)
    local category = Settings.RegisterVerticalLayoutSubcategory(
        parentCategory,
        BFUF.L.CATEGORY_GENERAL
    )
    local settings = BFUF.DB:Get("General")

    -- Apply the saved debug setting before the remaining addon modules are initialized.
    BFUF.DebugEnabled = settings.debugMode

    createBooleanSetting(
        category,
        "BFUF_GENERAL_ENABLED",
        "enabled",
        BFUF.L.OPTION_ENABLE_BFUF,
        true
    )
    createBooleanSetting(
        category,
        "BFUF_REPLACE_BLIZZARD_UNIT_FRAMES",
        "replaceBlizzardUnitFrames",
        BFUF.L.OPTION_REPLACE_BLIZZARD_UNIT_FRAMES,
        false
    )
    createBooleanSetting(
        category,
        "BFUF_DEBUG_MODE",
        "debugMode",
        BFUF.L.OPTION_ENABLE_DEBUG_MODE,
        false,
        function(value)
            BFUF.DebugEnabled = value
        end
    )

    return category
end

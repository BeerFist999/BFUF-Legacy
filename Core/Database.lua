local addonName, BFUF = ...

local Database = BFUF.DB

-- Copy values recursively without sharing nested tables.
function Database:CopyDefaults(source, destination)
    for key, value in pairs(source) do
        if type(value) == "table" then
            destination[key] = destination[key] or {}
            self:CopyDefaults(value, destination[key])
        elseif destination[key] == nil then
            destination[key] = value
        end
    end
end

-- Create the saved-variable database with AceDB defaults.
function Database:Initialize()
    if self.database then
        return self.database
    end

    local AceDB = LibStub("AceDB-3.0")
    self.database = AceDB:New("BFUFDB", BFUF.Defaults, true)

    return self.database
end

-- Return either the complete active profile or one requested section.
function Database:Get(section)
    if not self.database then
        return nil
    end

    if section == nil then
        return self.database.profile
    end

    return self.database.profile[section]
end

-- Reset the active profile to its default values.
function Database:Reset()
    if self.database then
        self.database:ResetProfile()
    end

    return self:Get()
end

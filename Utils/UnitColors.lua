local addonName, BFUF = ...

BFUF.Utils = BFUF.Utils or {}

local UnitColors = {}
BFUF.Utils.UnitColors = UnitColors

local CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS

local function getClassColor(unit)
    local _, classToken = UnitClass(unit)
    local color = classToken and CLASS_COLORS[classToken]
    if color then
        return color.r, color.g, color.b
    end
end

-- Return the standard health color for a unit without relying on creature type.
function UnitColors:GetUnitHealthColor(unit)
    if not unit or not UnitExists(unit) then
        return 1, 1, 1
    end

    if UnitIsPlayer(unit) then
        local red, green, blue = getClassColor(unit)
        if red then
            return red, green, blue
        end
    end

    -- Attackability is the authoritative hostile fallback for creatures and bosses.
    if UnitCanAttack("player", unit) or UnitIsEnemy("player", unit) then
        return 1, 0, 0
    end

    local reaction = UnitReaction(unit, "player")
    if reaction then
        if reaction <= 3 then
            return 1, 0, 0
        elseif reaction == 4 then
            return 1, 1, 0
        end

        return 0, 1, 0
    end

    if UnitIsFriend("player", unit) then
        return 0, 1, 0
    end

    return 1, 1, 0
end

BFUF.Utils.GetUnitHealthColor = function(unit)
    return UnitColors:GetUnitHealthColor(unit)
end

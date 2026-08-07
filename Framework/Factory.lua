local addonName, BFUF = ...

BFUF.Framework = BFUF.Framework or {}

local Factory = {}
BFUF.Framework.Factory = Factory

-- Create a normal unit-frame container. Player frames currently provide no secure clicks.
function Factory:CreateUnitFrame(unit)
    local frame = CreateFrame("Frame", nil, UIParent)
    frame.unit = unit
    return frame
end

function Factory:CreateContainer(parent)
    return CreateFrame("Frame", nil, parent)
end

function Factory:CreateTexture(parent)
    return parent:CreateTexture(nil, "ARTWORK")
end

function Factory:CreateFontString(parent)
    return parent:CreateFontString(nil, "OVERLAY")
end

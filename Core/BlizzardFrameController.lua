local addonName, BFUF = ...

local BlizzardFrameController = {}
BFUF.Core.BlizzardFrameController = BlizzardFrameController

local hiddenParent
local eventFrame
local pendingFrames = {}
local hookedFrames = {}
local editModeHooked = false
local deferredQueued = false

local frameManifest = {
    player = function()
        return PlayerFrame
    end,
    target = function()
        return TargetFrame
    end,
}

local function isEditModeActive()
    return EditModeManagerFrame and EditModeManagerFrame:IsShown()
end

function BlizzardFrameController:GetFrame(unit)
    local provider = frameManifest[unit]
    return provider and provider() or nil
end

function BlizzardFrameController:QueueFrame(frame)
    if not frame then
        return
    end

    pendingFrames[frame] = true
    if deferredQueued then
        return
    end

    deferredQueued = true
    C_Timer.After(0, function()
        deferredQueued = false
        BlizzardFrameController:ProcessPending()
    end)
end

function BlizzardFrameController:QueueAll()
    for unit in pairs(frameManifest) do
        self:QueueFrame(self:GetFrame(unit))
    end
end

function BlizzardFrameController:ApplyFrame(frame)
    if not frame or frame:GetParent() == hiddenParent then
        pendingFrames[frame] = nil
        return
    end

    if isEditModeActive() then
        return
    end

    if InCombatLockdown() and frame:IsProtected() then
        eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end

    pendingFrames[frame] = nil
    frame:UnregisterAllEvents()
    frame:Hide()
    frame:SetParent(hiddenParent)
end

function BlizzardFrameController:ProcessPending()
    if isEditModeActive() then
        return
    end

    for frame in pairs(pendingFrames) do
        self:ApplyFrame(frame)
    end
end

function BlizzardFrameController:HookFrame(frame)
    if not frame or hookedFrames[frame] then
        return
    end

    hookedFrames[frame] = true
    hooksecurefunc(frame, "SetParent", function(changedFrame, parent)
        if parent ~= hiddenParent then
            BlizzardFrameController:QueueFrame(changedFrame)
        end
    end)
end

function BlizzardFrameController:AttachEditModeHook()
    if editModeHooked or not EditModeManagerFrame then
        return
    end

    editModeHooked = true
    EditModeManagerFrame:HookScript("OnHide", function()
        BlizzardFrameController:QueueAll()
    end)
end

function BlizzardFrameController:Initialize()
    if self.initialized then
        return
    end

    self.initialized = true
    hiddenParent = CreateFrame("Frame", nil, UIParent)
    hiddenParent:Hide()

    eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:SetScript("OnEvent", function(_, event, addon)
        if event == "ADDON_LOADED" and addon == "Blizzard_EditMode" then
            BlizzardFrameController:AttachEditModeHook()
            return
        end

        if event == "PLAYER_REGEN_ENABLED" then
            BlizzardFrameController:ProcessPending()
            return
        end

        BlizzardFrameController:AttachEditModeHook()
        BlizzardFrameController:QueueAll()
    end)

    for unit in pairs(frameManifest) do
        self:HookFrame(self:GetFrame(unit))
    end

    self:AttachEditModeHook()
    self:QueueAll()
end

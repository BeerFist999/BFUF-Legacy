local addonName, BFUF = ...

local BlizzardBossController = {}
BFUF.Core.BlizzardBossController = BlizzardBossController

local hiddenParent
local eventFrame
local pendingFrames = {}
local hookedFrames = {}
local deferredQueued = false
local editModeHooked = false

local function isEditModeActive()
    return EditModeManagerFrame and EditModeManagerFrame:IsShown()
end

local function getBossFrame(index)
    return _G["Boss" .. index .. "TargetFrame"]
end

function BlizzardBossController:QueueFrame(frame)
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
        BlizzardBossController:ProcessPending()
    end)
end

function BlizzardBossController:QueueAll()
    for index = 1, 5 do
        self:QueueFrame(getBossFrame(index))
    end
end

function BlizzardBossController:ApplyFrame(frame)
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

function BlizzardBossController:ProcessPending()
    if isEditModeActive() then
        return
    end

    for frame in pairs(pendingFrames) do
        self:ApplyFrame(frame)
    end
end

function BlizzardBossController:HookFrame(frame)
    if not frame or hookedFrames[frame] then
        return
    end

    hookedFrames[frame] = true
    hooksecurefunc(frame, "SetParent", function(changedFrame, parent)
        if parent ~= hiddenParent then
            BlizzardBossController:QueueFrame(changedFrame)
        end
    end)
end

function BlizzardBossController:AttachEditModeHook()
    if editModeHooked or not EditModeManagerFrame then
        return
    end

    editModeHooked = true
    EditModeManagerFrame:HookScript("OnHide", function()
        BlizzardBossController:QueueAll()
    end)
end

function BlizzardBossController:Initialize()
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
            BlizzardBossController:AttachEditModeHook()
            return
        end

        if event == "PLAYER_REGEN_ENABLED" then
            BlizzardBossController:ProcessPending()
            return
        end

        BlizzardBossController:AttachEditModeHook()
        for index = 1, 5 do
            BlizzardBossController:HookFrame(getBossFrame(index))
        end
        BlizzardBossController:QueueAll()
    end)

    for index = 1, 5 do
        self:HookFrame(getBossFrame(index))
    end

    self:AttachEditModeHook()
    self:QueueAll()
end

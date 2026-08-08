local addonName, BFUF = ...

BFUF.Elements = BFUF.Elements or {}

local Portrait = {
    Modes = {
        HIDDEN = "hidden",
        TWO_D = "2d",
        THREE_D = "3d",
    },
}
BFUF.Elements.Portrait = Portrait

local FALLBACK_MODEL = "Interface\\Buttons\\TalkToMeQuestionMark.m2"
local INITIAL_3D_RETRY_DELAY = 1

local function describeValue(value)
    if issecretvalue and issecretvalue(value) then
        return "<secret>"
    end

    return tostring(value)
end

local function isTargetUnit(unit)
    return unit == "target"
end

-- Create a portrait renderer with its own event-driven lifecycle.
function Portrait:Create(parent)
    local container = CreateFrame("Frame", nil, parent)

    local texture = container:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints(container)
    container.texture = texture

    local model = CreateFrame("PlayerModel", nil, container)
    model:SetAllPoints(container)
    model:SetCamera(0)
    model:Hide()
    container.model = model
    container.mode = Portrait.Modes.TWO_D
    container.debugState = {}
    container.retryPending = false
    container.initialRetryScheduled = false

    function container:ClearRenderer()
        self.debugState.clearRenderer = true
        self.texture:SetTexture(nil)
        self.texture:Hide()
        self.model:ClearModel()
        self.model:Hide()
        self.activeRenderer = nil
        self.retryPending = false
        self.retryAttempt = nil
        self.retryReason = nil
        self.debugState.activeRenderer = self.activeRenderer
        self.debugState.retryPending = self.retryPending
    end

    function container:ScheduleInitialRetry()
        if self.initialRetryScheduled or not C_Timer or not C_Timer.After then
            return
        end

        self.initialRetryScheduled = true
        C_Timer.After(INITIAL_3D_RETRY_DELAY, function()
            self.initialRetryScheduled = false

            if self.mode == Portrait.Modes.THREE_D and self.retryPending then
                self.retryAttempt = 2
                self.retryReason = "PLAYER_ENTERING_WORLD"
                self:Update("INITIAL_3D_RETRY")
            end
        end)
    end

    function container:ShowModelFallback()
        self.debugState.usedFallback = true
        self.activeRenderer = "3d-fallback"
        self.retryPending = true
        self.debugState.activeRenderer = self.activeRenderer
        self.debugState.retryPending = self.retryPending
        self.texture:Hide()
        self.model:ClearModel()
        self.model:SetCamDistanceScale(0.25)
        self.model:SetPortraitZoom(0)
        self.model:SetPosition(0, 0, 0.25)
        self.model:SetModel(FALLBACK_MODEL)
        self.model:Show()
    end

    function container:SetUnit(unit)
        if self.unit == unit then
            return
        end

        self.unit = unit
        self:Update("UNIT_CHANGED")
    end

    function container:SetMode(mode)
        mode = mode or Portrait.Modes.TWO_D
        if self.mode == mode then
            return
        end

        self.mode = mode
        self:Update("MODE_CHANGED")
    end

    function container:Update(event)
        if event == "PLAYER_ENTERING_WORLD" then
            self.retryAttempt = 1
            self.retryReason = event
        elseif event ~= "INITIAL_3D_RETRY" then
            self.retryAttempt = nil
            self.retryReason = nil
        end

        local unit = self.unit
        self.debugState = {
            event = event or "DIRECT",
            unit = unit,
            mode = self.mode,
            retryPending = self.retryPending,
            retryAttempt = self.retryAttempt,
            retryReason = self.retryReason,
        }
        if self.mode == Portrait.Modes.HIDDEN then
            self:ClearRenderer()
            self:Hide()
            return
        end

        if not unit or not UnitExists(unit) then
            self:ClearRenderer()
            self:Hide()
            return
        end

        self:Show()
        if self.mode == Portrait.Modes.THREE_D then
            self.texture:Hide()

            if not UnitIsConnected(unit) or not UnitIsVisible(unit) then
                self:ShowModelFallback()
                return
            end

            -- The PlayerModel must be visible before it accepts a unit.
            self.model:Show()
            self.debugState.clearModel = true
            self.model:ClearModel()
            self.debugState.canSetUnit = self.model:CanSetUnit(unit)
            self.debugState.setUnit = unit
            self.debugState.setUnitResult = self.model:SetUnit(unit)

            local success = self.debugState.setUnitResult
            if issecretvalue and issecretvalue(success) then
                success = nil
            end

            if success ~= true then
                -- Secret units cannot provide a 3D model to addons.
                self.model:Hide()
                SetPortraitTexture(self.texture, unit)
                self.texture:Show()
                self.activeRenderer = "2d-fallback"
                self.retryPending = true
                self.debugState.activeRenderer = self.activeRenderer
                self.debugState.retryPending = self.retryPending

                if event == "PLAYER_ENTERING_WORLD" then
                    self:ScheduleInitialRetry()
                end

                return
            end

            self.activeRenderer = "3d"
            self.retryPending = false
            self.debugState.activeRenderer = self.activeRenderer
            self.debugState.retryPending = self.retryPending
            self.debugState.setPortraitZoom = true
            self.model:SetPortraitZoom(1)
            self.debugState.setPosition = true
            self.model:SetPosition(0, 0, 0)
            self.debugState.setCamDistanceScale = true
            self.model:SetCamDistanceScale(1)
            return
        end

        self.model:Hide()
        SetPortraitTexture(self.texture, unit)
        self.texture:Show()
        self.activeRenderer = "2d"
        self.retryPending = false
        self.retryAttempt = nil
        self.retryReason = nil
        self.debugState.activeRenderer = self.activeRenderer
        self.debugState.retryPending = self.retryPending
    end

    function container:PrintDebugState()
        local state = self.debugState or {}
        local target = "target"

        BFUF:Print("[BFUF Portrait] unit=" .. describeValue(self.unit))
        BFUF:Print("[BFUF Portrait] UnitGUID(target)=" .. describeValue(UnitGUID(target)))
        BFUF:Print("[BFUF Portrait] UnitIsPlayer(target)=" .. describeValue(UnitIsPlayer(target)))
        BFUF:Print("[BFUF Portrait] UnitCreatureType(target)=" .. describeValue(UnitCreatureType(target)))
        BFUF:Print("[BFUF Portrait] UnitClassification(target)=" .. describeValue(UnitClassification(target)))
        BFUF:Print("[BFUF Portrait] UnitExists(target)=" .. describeValue(UnitExists(target)))
        BFUF:Print("[BFUF Portrait] profileMode=" .. describeValue(self.mode))
        BFUF:Print("[BFUF Portrait] PlayerModel exists=" .. describeValue(self.model ~= nil))
        BFUF:Print(
            "[BFUF Portrait] model shown=" .. describeValue(self.model:IsShown())
                .. " visible=" .. describeValue(self.model:IsVisible())
                .. " width=" .. describeValue(self.model:GetWidth())
                .. " height=" .. describeValue(self.model:GetHeight())
        )
        BFUF:Print(
            "[BFUF Portrait] last refresh=" .. describeValue(state.event)
                .. " clearModel=" .. describeValue(state.clearModel)
                .. " CanSetUnit=" .. describeValue(state.canSetUnit)
                .. " setUnit=" .. describeValue(state.setUnit)
                .. " SetUnit result=" .. describeValue(state.setUnitResult)
                .. " activeRenderer=" .. describeValue(state.activeRenderer)
                .. " retryPending=" .. describeValue(state.retryPending)
                .. " retryAttempt=" .. describeValue(state.retryAttempt)
                .. " retryReason=" .. describeValue(state.retryReason)
                .. " zoom=" .. describeValue(state.setPortraitZoom)
                .. " position=" .. describeValue(state.setPosition)
                .. " fallback=" .. describeValue(state.usedFallback)
        )
    end

    function container:RegisterEvents()
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:RegisterEvent("PLAYER_TARGET_CHANGED")
        self:RegisterEvent("UNIT_PORTRAIT_UPDATE")
        self:RegisterEvent("UNIT_MODEL_CHANGED")
        self:RegisterEvent("PORTRAITS_UPDATED")
        self:RegisterEvent("UNIT_CONNECTION")

        self:SetScript("OnEvent", function(renderer, event, unit)
            local refreshed = false

            if event == "PLAYER_ENTERING_WORLD" or event == "PORTRAITS_UPDATED" then
                renderer:Update(event)
                refreshed = true
            elseif event == "PLAYER_TARGET_CHANGED" then
                if isTargetUnit(renderer.unit) then
                    renderer:Update(event)
                    refreshed = true
                end
            elseif unit == renderer.unit then
                renderer:Update(event)
                refreshed = true
            end

            if Portrait.debugEnabled and isTargetUnit(renderer.unit) then
                BFUF:Print(
                    "[BFUF Portrait] EVENT -> " .. event
                        .. " -> unit=" .. describeValue(unit)
                        .. " -> 3D refresh=" .. describeValue(refreshed)
                )
            end
        end)
    end

    container:RegisterEvents()
    return container
end


-- Temporary diagnostic command for the current Target portrait renderer.
SLASH_BFUFPORTRAITDEBUG1 = "/bfufportraitdebug"
SlashCmdList.BFUFPORTRAITDEBUG = function()
    Portrait.debugEnabled = true

    local root = BFUF.Framework.Registry:GetFrame("target")
    if not root or not root.portrait then
        BFUF:Print("[BFUF Portrait] Target portrait is not available.")
        return
    end

    root.portrait:PrintDebugState()
end

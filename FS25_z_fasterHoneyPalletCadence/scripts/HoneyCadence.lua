-- FS25: configure only the scheduler's idle cooldown; keep native spawning.
-- g_time is active mission time in milliseconds, independent of time scale.
local TAG = "[FasterHoneyCadence]"

if BeehiveSystem == nil or type(BeehiveSystem.update) ~= "function" then
    print(TAG .. " Disabled: BeehiveSystem.update is unavailable.")
    return
end

local originalUpdate = BeehiveSystem.update
local states = setmetatable({}, {__mode = "k"})

BeehiveSystem.update = function(self, ...)
    if self.mission == nil or not self.mission:getIsServer()
        or type(self.updateCooldown) ~= "number"
        or type(self.currentSpawnerUpdateIndex) ~= "number"
        or type(self.beehivePalletSpawners) ~= "table"
        or type(g_time) ~= "number" then
        return originalUpdate(self, ...)
    end

    local state = states[self]
    if state == nil then
        state = {startTime = g_time, revision = HoneyCadenceSettings.revision}
        states[self] = state
        print(string.format("%s Active: spawn interval %d ms; native COOLDOWN_DURATION=%s update calls.",
            TAG, HoneyCadenceSettings.intervals[HoneyCadenceSettings.state], tostring(BeehiveSystem.COOLDOWN_DURATION)))
    end

    if #self.beehivePalletSpawners == 0 or g_time < state.startTime
        or state.revision ~= HoneyCadenceSettings.revision then
        state.startTime = g_time
        state.revision = HoneyCadenceSettings.revision
    end

    if self.updateCooldown > 0 then
        local interval = HoneyCadenceSettings.intervals[HoneyCadenceSettings.state]
        -- Keep native frame countdown from expiring before a long selection.
        self.updateCooldown = g_time - state.startTime >= interval and 0 or 2
    end

    -- The native scheduler processes one spawner per update and then resets
    -- its cooldown. Observe that reset to start our next bounded wait.
    local before = self.updateCooldown
    originalUpdate(self, ...)
    if before <= 0 and self.updateCooldown > 0 then
        state.startTime = g_time
    end
end

-- Add clover to PF's perennial harvest tillage credit without changing
-- the fill type passed to nitrogen, pH, weed control or the original harvest.
CloverPFTillage = {}
CloverPFTillage.fillTypeNames = {"CLOVER", "CLOVER2", "CLOVER_WINDROW", "ALFALFA", "ALFALFA_WINDROW"}

function CloverPFTillage:loadMap()
    self.active = true
    self.retryTime = 0
    self.warned = false
    self:installHook()
end

function CloverPFTillage:installHook()
    if g_server == nil then
        return false
    end

    local pfEnv = _G["FS25_precisionFarming"]
    if pfEnv == nil then
        return false
    end

    local harvestClass = pfEnv.HarvestExtension or _G.HarvestExtension
    local tillageClass = pfEnv.EnvironmentalScoreTillage
    local pf = pfEnv.g_precisionFarming
    local scores = pf ~= nil and pf.environmentalScore or nil
    local tillage = scores ~= nil and scores.scoreObjects ~= nil
        and scores.scoreObjects["EnvironmentalScoreTillage"] or nil

    if harvestClass == nil or type(harvestClass.setLastScoringValues) ~= "function"
        or tillageClass == nil or tillageClass.TYPE_DIRECT_PLANTING == nil
        or tillage == nil or type(tillage.addWorkedArea) ~= "function" then
        return false
    end

    if self.hookedClass == harvestClass then
        return true
    end

    local previous = harvestClass.setLastScoringValues
    local listener = self
    harvestClass.setLastScoringValues = function(harvestExtension, area, farmlandId,
        nActual, nTarget, pHActual, pHTarget, ignoreOverfertilization, fillTypeIndex, ...)

        local function finish(...)
            if listener.active and g_server ~= nil and area ~= nil and area > 0
                and farmlandId ~= nil and fillTypeIndex ~= nil
                and g_fillTypeManager ~= nil then

                local isClover = false
                for _, name in ipairs(listener.fillTypeNames) do
                    local index = g_fillTypeManager:getFillTypeIndexByName(name)
                    if index ~= nil and index == fillTypeIndex then
                        isClover = true
                        break
                    end
                end

                -- Resolve the current mission's score object, not a saved instance.
                local currentPF = pfEnv.g_precisionFarming
                local currentScores = currentPF ~= nil and currentPF.environmentalScore or nil
                local currentTillage = currentScores ~= nil and currentScores.scoreObjects ~= nil
                    and currentScores.scoreObjects["EnvironmentalScoreTillage"] or nil
                if isClover and currentTillage ~= nil then
                    currentTillage:addWorkedArea(farmlandId, area, tillageClass.TYPE_DIRECT_PLANTING)
                end
            end
            return ...
        end

        -- Preserve every original argument and return value, including nil values.
        return finish(previous(harvestExtension, area, farmlandId, nActual, nTarget,
            pHActual, pHTarget, ignoreOverfertilization, fillTypeIndex, ...))
    end

    self.hookedClass = harvestClass
    Logging.info("[CloverPFTillage] Clover harvest tillage credit enabled.")
    return true
end

function CloverPFTillage:update(dt)
    if not self.active or g_server == nil or self.hookedClass ~= nil or self.warned then
        return
    end
    self.retryTime = (self.retryTime or 0) + dt
    if self:installHook() then
        return
    end
    if self.retryTime >= 30000 then
        self.warned = true
        Logging.warning("[CloverPFTillage] PF harvest/tillage API unavailable; no scoring changes applied.")
    end
end

function CloverPFTillage:deleteMap()
    self.active = false
end

addModEventListener(CloverPFTillage)

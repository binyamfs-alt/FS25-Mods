-- Copyright (C) 2026 BinyamFS. SPDX-License-Identifier: GPL-3.0-or-later
LivestockCapacityHUD = {}

function LivestockCapacityHUD.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(LivestockTrailer, specializations)
end

function LivestockCapacityHUD.registerOverwrittenFunctions(vehicleType)
    for _, name in ipairs({"getMaxNumOfAnimals", "getFillLevelInformation"}) do
        SpecializationUtil.registerOverwrittenFunction(vehicleType, name, LivestockCapacityHUD[name])
    end
end

function LivestockCapacityHUD.getLoad(vehicle)
    local count, types, firstSubType = 0, {}, nil
    local spec = vehicle.spec_livestockTrailer
    local animalSystem = g_currentMission and g_currentMission.animalSystem
    if spec == nil or spec.clusterSystem == nil or animalSystem == nil then
        return count, types, firstSubType
    end
    for _, cluster in ipairs(spec.clusterSystem:getClusters()) do
        local num = cluster:getNumAnimals()
        if num > 0 then
            local subType = animalSystem:getSubTypeByIndex(cluster:getSubTypeIndex())
            count = count + num
            if subType ~= nil then
                types[subType.typeIndex] = true
                firstSubType = firstSubType or subType
            end
        end
    end
    return count, types, firstSubType
end

function LivestockCapacityHUD.isTypeAllowed(vehicle, typeIndex)
    local _, types = LivestockCapacityHUD.getLoad(vehicle)
    for loadedType in pairs(types) do
        if loadedType ~= typeIndex then return false end
    end
    return true
end

function LivestockCapacityHUD.warn(vehicle)
    -- Capacity queries also run while browsing; throttle the red HUD warning.
    local now = g_time or 0
    if g_currentMission ~= nil and g_currentMission.showBlinkingWarning ~= nil
        and (vehicle.bfsLastAnimalWarning == nil or now - vehicle.bfsLastAnimalWarning > 3000) then
        vehicle.bfsLastAnimalWarning = now
        g_currentMission:showBlinkingWarning(g_i18n:getText("bfs_trailerLoaded"), 3000)
    end
end

function LivestockCapacityHUD:getMaxNumOfAnimals(superFunc, animalType)
    local requested = animalType or self:getCurrentAnimalType()
    if requested ~= nil and self.spec_livestockTrailer.animalTypeIndexToPlaces[requested.typeIndex] == nil then
        return 0
    end
    -- The dialog queries other types while opening and populating its lists.
    -- Reject only at the transfer action, never during these read-only queries.
    return superFunc(self, animalType)
end

function LivestockCapacityHUD:getFillLevelInformation(superFunc, display)
    superFunc(self, display)
    local count, types, subType = LivestockCapacityHUD.getLoad(self)
    local animalSystem = g_currentMission.animalSystem
    local capacity = 0
    if subType ~= nil then
        capacity = self:getMaxNumOfAnimals(animalSystem:getTypeByIndex(subType.typeIndex))
    else
        for typeIndex in pairs(self.spec_livestockTrailer.animalTypeIndexToPlaces or {}) do
            capacity = math.max(capacity, self:getMaxNumOfAnimals(animalSystem:getTypeByIndex(typeIndex)))
        end
    end
    if capacity <= 0 then return end
    local label = g_i18n:getText("bfs_animals")
    local numTypes = 0
    for _ in pairs(types) do numTypes = numTypes + 1 end
    if numTypes > 1 then label = g_i18n:getText("bfs_mixedAnimals") end
    local fillType = subType and subType.fillTypeIndex or FillType.UNKNOWN
    display:addFillLevel(fillType, count, capacity, 0, false, FillLevelsDisplay.TYPE_BAR, label)
    display.bfsAnimalRows = display.bfsAnimalRows or {}
    local key = tostring(fillType) .. ":" .. label
    local row = display.bfsAnimalRows[key] or {count=0, capacity=0}
    row.count, row.capacity = row.count + count, row.capacity + capacity
    display.bfsAnimalRows[key] = row
end

function LivestockCapacityHUD.updateDisplay(display, superFunc, ...)
    display.bfsAnimalRows = {}
    local result = superFunc(display, ...)
    for _, data in ipairs(display.fillLevelData or {}) do
        local row = display.bfsAnimalRows[tostring(data.fillType) .. ":" .. tostring(data.customFillTypeText)]
        if data.isValid and row ~= nil then
            local percent = math.floor(row.count / math.max(row.capacity, 1) * 100)
            data.fillLevelText = string.format("%s / %s (%d%%)",
                g_i18n:formatNumber(row.count, 0), g_i18n:formatNumber(row.capacity, 0), percent)
        end
    end
    return result
end


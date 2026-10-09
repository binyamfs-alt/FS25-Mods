-- Copyright (C) 2026 BinyamFS. SPDX-License-Identifier: GPL-3.0-or-later
local name = g_currentModName .. ".livestockCapacityHUD"
TypeManager.validateTypes = Utils.prependedFunction(TypeManager.validateTypes, function(manager)
    if manager.typeName ~= "vehicle" then return end
    local spec = manager.specializationManager:getSpecializationObjectByName(name)
    if spec == nil then return end
    for typeName, vehicleType in pairs(manager:getTypes()) do
        if spec.prerequisitesPresent(vehicleType.specializations)
            and not SpecializationUtil.hasSpecialization(spec, vehicleType.specializations) then
            manager:addSpecialization(typeName, name)
        end
    end
end)
if FillLevelsDisplay ~= nil then
    FillLevelsDisplay.update = Utils.overwrittenFunction(FillLevelsDisplay.update, function(display, superFunc, ...)
        local spec = g_specializationManager:getSpecializationObjectByName(name)
        if spec ~= nil then return spec.updateDisplay(display, superFunc, ...) end
        return superFunc(display, ...)
    end)
end

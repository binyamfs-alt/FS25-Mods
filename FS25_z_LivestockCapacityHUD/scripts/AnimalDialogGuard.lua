-- Copyright (C) 2026 BinyamFS. SPDX-License-Identifier: GPL-3.0-or-later
LivestockAnimalDialogGuard = {}
local G = LivestockAnimalDialogGuard
local specializationName = g_currentModName .. ".livestockCapacityHUD"

function G.installController(screen)
    local c = screen.controller
    if c == nil or c.trailer == nil or c.husbandry == nil or c.bfsGuardInstalled then return end
    c.bfsGuardInstalled = true
    for _, method in ipairs({"getSourceAnimalTypes", "getSourceData", "getTargetData", "initSourceItems", "initTargetItems"}) do
        local original = c[method]
        if type(original) == "function" then
            local label = method
            c[method] = function(controller, ...)
                local function pack(...) return {n=select("#", ...), ...} end
                local args, result = pack(...), pack(original(controller, ...))
                local parts = {}
                for i=1,args.n do table.insert(parts, "arg"..i.."="..tostring(args[i])) end
                for i=1,result.n do
                    local value = result[i]
                    if type(value) == "table" then
                        local fields = {}
                        for key, item in pairs(value) do
                            if #fields >= 12 then break end
                            table.insert(fields, tostring(key).."="..tostring(item))
                        end
                        table.insert(parts, "result"..i.."={"..table.concat(fields, ",").."}")
                    else table.insert(parts, "result"..i.."="..tostring(value)) end
                end
                print("[Livestock HUD Lookup] "..label.." "..table.concat(parts, " "))
                return unpack(result,1,result.n)
            end
        end
    end
    for _, method in ipairs({"applySource", "applyTarget"}) do
        local original = c[method]
        if type(original) == "function" then
            c[method] = function(controller, ...)
                local spec = g_specializationManager:getSpecializationObjectByName(specializationName)
                local animalType = controller.husbandry:getAnimalTypeIndex()
                if spec ~= nil and not spec.isTypeAllowed(controller.trailer, animalType) then
                    spec.warn(controller.trailer)
                    print("[Livestock HUD] Rejected incompatible husbandry/trailer transfer")
                    return false
                end
                return original(controller, ...)
            end
        end
    end
    -- Observed controller contract: true selects the trailer/unload view;
    -- false selects the pen. Only the trailer view uses its loaded types.
    local original = c.getSourceAnimalTypes
    if type(original) == "function" then
        c.getSourceAnimalTypes = function(controller, trailerView, ...)
            if trailerView then
                local spec = g_specializationManager:getSpecializationObjectByName(specializationName)
                if spec ~= nil then
                    local _, types = spec.getLoad(controller.trailer)
                    local result = {}
                    for typeIndex in pairs(types) do
                        local animalType = g_currentMission.animalSystem:getTypeByIndex(typeIndex)
                        if animalType ~= nil then table.insert(result, animalType) end
                    end
                    table.sort(result, function(a,b) return a.typeIndex < b.typeIndex end)
                    if #result > 0 then
                        print("[Livestock HUD] Trailer view uses loaded animal types")
                        return result
                    end
                end
            end
            return original(controller, trailerView, ...)
        end
    end
    print("[Livestock HUD] Installed controller transfer protection")
end

function G.preflight(screen, loading)
    local controller = screen.controller
    local trailer = controller and controller.trailer
    if trailer == nil or trailer.spec_livestockTrailer == nil then return true end
    local spec = g_specializationManager:getSpecializationObjectByName(specializationName)
    if spec == nil then return true end
    -- A rejected/full transfer must not reach native callbacks with an empty
    -- list or a stale selection; those callbacks dereference the selected cluster.
    local list = screen.sourceList
    if list ~= nil and list.getItemCount ~= nil then
        local count = list:getItemCount()
        local index = list.getSelectedIndex ~= nil and list:getSelectedIndex() or list.selectedIndex
        if count == 0 or (index ~= nil and (index < 1 or index > count)) then
            return false
        end
    end
    if loading then
        local selector = screen.sourceSelector
        local animalType = selector ~= nil and selector.getState ~= nil
            and (screen.sourceSelectorStateToAnimalType or {})[selector:getState()] or nil
        local typeIndex = type(animalType) == "table" and animalType.typeIndex or animalType
        if typeIndex ~= nil and not spec.isTypeAllowed(trailer, typeIndex) then
            spec.warn(trailer)
            return false
        end
        local count = spec.getLoad(trailer)
        local capacity = trailer:getMaxNumOfAnimals(trailer:getCurrentAnimalType())
        if count > 0 and count >= capacity then
            g_currentMission:showBlinkingWarning(g_i18n:getText("bfs_trailerFull"), 3000)
            return false
        end
    end
    return true
end

if AnimalScreen ~= nil then
    -- Native confirmation callbacks announce success independently of the
    -- controller's return value. Reject here before that success path runs.
    for _, method in ipairs({"onYesNoSource", "onYesNoTarget"}) do
        if type(AnimalScreen[method]) == "function" then
            AnimalScreen[method] = Utils.overwrittenFunction(AnimalScreen[method], function(screen, superFunc, yes, ...)
                local c = screen.controller
                local spec = g_specializationManager:getSpecializationObjectByName(specializationName)
                if yes and c ~= nil and c.trailer ~= nil and c.husbandry ~= nil
                    and spec ~= nil and not spec.isTypeAllowed(c.trailer, c.husbandry:getAnimalTypeIndex()) then
                    InfoDialog.show(g_i18n:getText("bfs_trailerLoaded"))
                    return
                end
                return superFunc(screen, yes, ...)
            end)
        end
    end
    for _, method in ipairs({"onClickBuyMode", "onClickSellMode"}) do
        if type(AnimalScreen[method]) == "function" then
            AnimalScreen[method] = Utils.prependedFunction(AnimalScreen[method], G.installController)
        end
    end
end

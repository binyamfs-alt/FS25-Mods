-- Credit registered delivery contracts in original-product liters before conversion.
ContractDeliveryFix = {}
local Fix = ContractDeliveryFix

local function finite(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function Fix.credit(station, farmId, fillType, liters)
    local candidates = {}
    for _, mission in pairs(station.missions or {}) do
        if type(mission) == "table" and mission.farmId == farmId
            and mission.status == MissionStatus.RUNNING and mission.sellingStation == station
            and type(mission.fillSold) == "function"
            and finite(mission.expectedLiters) and finite(mission.depositedLiters)
            and mission.expectedLiters > mission.depositedLiters then
            local matches = mission.fillTypeIndex == fillType
            if not matches and type(mission.acceptsMissionFillType) == "function" then
                matches = mission:acceptsMissionFillType(fillType) == true
            end
            if matches then candidates[#candidates + 1] = mission end
        end
    end
    -- Stable order across repeated unload ticks; zero-progress contracts are eligible.
    table.sort(candidates, function(a, b)
        return tostring(a.uniqueId or a.activeId or a.id or a) < tostring(b.uniqueId or b.activeId or b.id or b)
    end)
    local credited = 0
    for _, mission in ipairs(candidates) do
        local available = liters - credited
        if available <= 0 then break end
        local before = mission.depositedLiters
        local amount = math.min(available, mission.expectedLiters - before)
        -- Use the contract's own method for notifications, removal, and network updates.
        mission:fillSold(amount, fillType)
        local accepted = finite(mission.depositedLiters) and math.max(0, math.min(amount, mission.depositedLiters - before)) or 0
        credited = credited + accepted
        if accepted > 0 and not mission.contractDeliveryFixLogged then
            mission.contractDeliveryFixLogged = true
            Logging.info("[ContractDeliveryFix] Original product %s credited to contract %s at %s (farm %s)",
                tostring(g_fillTypeManager:getFillTypeNameByIndex(fillType)),
                tostring(mission.uniqueId or mission.activeId or "unknown"),
                tostring(station.owningPlaceable and station.owningPlaceable.configFileName or "assigned station"), tostring(farmId))
        end
    end
    return credited
end

function Fix.addFillUnitFillLevel(trigger, superFunc, farmId, fillUnitIndex, delta, fillType, toolType, fillPositionData, extraAttributes)
    local conversion = trigger.fillTypeConversions and trigger.fillTypeConversions[fillType]
    local station = trigger.target
    if g_server == nil or trigger.contractDeliveryFixActive or not finite(delta) or delta <= 0
        or conversion == nil or conversion.outgoingFillType == fillType
        or not finite(conversion.ratio) or conversion.ratio <= 0
        or station == nil or type(station.missions) ~= "table"
        or not trigger:getIsFillTypeAllowed(fillType) or not trigger:getIsToolTypeAllowed(toolType) then
        return superFunc(trigger, farmId, fillUnitIndex, delta, fillType, toolType, fillPositionData, extraAttributes)
    end
    trigger.contractDeliveryFixActive = true
    -- Always clear the recursion guard, including errors raised by another contract mod.
    local ok, result = pcall(function()
        local credited = Fix.credit(station, farmId, fillType, delta)
        local remainder = delta - credited
        if remainder <= 0 then return credited end
        local normal = superFunc(trigger, farmId, fillUnitIndex, remainder, fillType, toolType, fillPositionData, extraAttributes)
        return credited + (finite(normal) and math.max(0, math.min(remainder, normal)) or 0)
    end)
    trigger.contractDeliveryFixActive = nil
    if not ok then error(result) end
    return result
end

-- Hook before UnloadTrigger changes the fill type; do not replace station sale logic.
UnloadTrigger.addFillUnitFillLevel = Utils.overwrittenFunction(UnloadTrigger.addFillUnitFillLevel, Fix.addFillUnitFillLevel)

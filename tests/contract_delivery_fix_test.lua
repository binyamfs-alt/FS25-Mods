MissionStatus = {RUNNING = 1, FINISHED = 2}
g_server = {}
g_fillTypeManager = {getFillTypeNameByIndex = function(_, ft) return "PRODUCT_" .. tostring(ft) end}
Logging = {info = function() end}
Utils = {overwrittenFunction = function(original, replacement)
    return function(self, ...) return replacement(self, original, ...) end
end}
local calls = {}
UnloadTrigger = {addFillUnitFillLevel = function(self, farm, unit, delta, ft, tool, position, attributes)
    local c = self.fillTypeConversions and self.fillTypeConversions[ft]
    local ratio = c and c.ratio or 1
    calls[#calls + 1] = {farm = farm, delta = delta * ratio, ft = c and c.outgoingFillType or ft,
        tool = tool, position = position, attributes = attributes}
    return math.min(delta, self.normalCapacity or delta)
end}
dofile("FS25_z_ContractDeliveryFix/scripts/ContractDeliveryFix.lua")
local function trigger()
    calls = {}
    return setmetatable({target = {missions = {}}, fillTypeConversions = {[10] = {outgoingFillType = 20, ratio = 1.3}},
        getIsFillTypeAllowed = function(self) return not self.disallowed end,
        getIsToolTypeAllowed = function(self) return not self.disallowedTool end}, {__index = UnloadTrigger})
end
local function mission(t, id, expected, deposited, ft, farm)
    local m = {uniqueId = id, status = MissionStatus.RUNNING, farmId = farm or 1,
        sellingStation = t.target, fillTypeIndex = ft or 10, expectedLiters = expected,
        depositedLiters = deposited or 0, count = 0}
    function m:fillSold(delta, product)
        assert(product == self.fillTypeIndex or self:acceptsMissionFillType(product))
        self.count = self.count + 1
        self.depositedLiters = math.min(self.expectedLiters, self.depositedLiters + delta)
        if self.depositedLiters >= self.expectedLiters then self.sellingStation.missions[self] = nil end
    end
    t.target.missions[m] = m
    return m
end
local function unload(t, liters, farm, ft)
    return t:addFillUnitFillLevel(farm or 1, 1, liters, ft or 10, 5, "position", "attributes")
end
-- Original units, regardless of conversion ratio; no sale for credited liters.
local t = trigger(); local a = mission(t, "A", 100)
assert(unload(t, 40) == 40 and a.depositedLiters == 40 and #calls == 0)
assert(unload(t, 60) == 60 and a.depositedLiters == 100 and a.count == 2)
assert(unload(t, 10) == 10 and #calls == 1 and calls[1].ft == 20 and calls[1].delta == 13)
-- Split across matching contracts, and convert only surplus, preserving all arguments.
t = trigger(); local b = mission(t, "B", 50); a = mission(t, "A", 100, 80)
assert(unload(t, 100) == 100 and a.depositedLiters == 100 and b.depositedLiters == 50)
assert(#calls == 1 and calls[1].delta == 39 and calls[1].position == "position" and calls[1].attributes == "attributes")
-- Partial normal acceptance must not remove unaccepted surplus from the trailer.
t = trigger(); a = mission(t, "A", 20); t.normalCapacity = 5
assert(unload(t, 50) == 25 and a.depositedLiters == 20)
-- Wrong farm, product, station, inactive, and unsupported interfaces pass through.
for _, kind in ipairs({"farm", "product", "station", "inactive", "interface"}) do
    t = trigger(); a = mission(t, "A", 100)
    if kind == "farm" then a.farmId = 2
    elseif kind == "product" then a.fillTypeIndex = 11
    elseif kind == "station" then a.sellingStation = {}
    elseif kind == "inactive" then a.status = MissionStatus.FINISHED
    else a.depositedLiters = nil end
    assert(unload(t, 10) == 10 and #calls == 1 and a.count == 0, kind)
end
-- Contract-specific product acceptance is supported without product names.
t = trigger(); a = mission(t, "A", 100, 0, 11)
a.acceptsMissionFillType = function(_, ft) return ft == 10 end
assert(unload(t, 10) == 10 and a.depositedLiters == 10 and #calls == 0)
-- Zero-progress supply contracts are eligible (no progress-based filtering).
t = trigger(); a = mission(t, "A", 100); a.getCompletion = function() return 0 end
assert(unload(t, 10) == 10 and a.depositedLiters == 10)
-- No conversion and multiplayer clients never credit directly.
t = trigger(); a = mission(t, "A", 100); t.fillTypeConversions = {}
assert(unload(t, 10) == 10 and a.depositedLiters == 0 and #calls == 1)
t = trigger(); a = mission(t, "A", 100); g_server = nil
assert(unload(t, 10) == 10 and a.depositedLiters == 0 and #calls == 1); g_server = {}
for _, key in ipairs({"disallowed", "disallowedTool"}) do
    t = trigger(); a = mission(t, "A", 100); t[key] = true
    assert(unload(t, 10) == 10 and a.depositedLiters == 0)
end
-- A contract that accepts only part reports only the actual credited increase.
t = trigger(); a = mission(t, "A", 100)
a.fillSold = function(self, delta) self.depositedLiters = self.depositedLiters + delta / 2 end
assert(unload(t, 20) == 20 and a.depositedLiters == 10 and calls[1].delta == 13)
-- The same trigger cannot recursively credit an unload twice.
t = trigger(); a = mission(t, "A", 100)
a.fillSold = function(self, delta)
    assert(t.contractDeliveryFixActive)
    unload(t, 1)
    self.depositedLiters = self.depositedLiters + delta
end
assert(unload(t, 10) == 10 and a.depositedLiters == 10 and #calls == 1)
-- Errors propagate without leaving the guard set, or retrying the unload.
t = trigger(); a = mission(t, "A", 100); a.fillSold = function() error("callback failed") end
assert(not pcall(unload, t, 10) and t.contractDeliveryFixActive == nil and #calls == 0)
print("PASS: original-product credit, contract selection, multiple contracts, surplus, partial acceptance, client bypass, recursion and errors")

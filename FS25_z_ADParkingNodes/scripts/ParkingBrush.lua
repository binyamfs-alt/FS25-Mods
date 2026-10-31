ADParkingBrush = {}
local ADParkingBrush_mt = Class(ADParkingBrush, ConstructionBrush)

function ADParkingBrush.new(storeItem, cursor, customMt)
    -- ConstructionBrush.new takes the metatable, not storeItem/cursor. Passing
    -- the store item here made the engine use it as the object's metatable.
    local self = ConstructionBrush.new(customMt or ADParkingBrush_mt)
    setmetatable(self, customMt or ADParkingBrush_mt)
    self.storeItem = storeItem
    self.cursor = cursor
    self.isADParkingBrush = true
    self.supportsPrimaryButton = true
    self.supportsPrimaryDragging = false
    self.supportsSecondaryButton = true
    self.supportsSecondaryDragging = false
    self.supportsTertiaryButton = true
    self.supportsPrimaryAxis = true
    self.primaryAxisIsContinuous = false
    self.spacing = 5
    self.secondary = false
    return self
end

function ADParkingBrush:activate(...)
    self.anchor, self.preview, self.message = nil, nil, nil
    if ConstructionBrush.activate ~= nil then ConstructionBrush.activate(self, ...) end
end

function ADParkingBrush:deactivate(...)
    self.anchor, self.preview = nil, nil
    if ConstructionBrush.deactivate ~= nil then ConstructionBrush.deactivate(self, ...) end
end

function ADParkingBrush:getButtonPrimaryText() return self.anchor and "Place parking nodes" or "Set row start" end
function ADParkingBrush:getButtonSecondaryText() return self.anchor and "Cancel row" or "Exit parking tool" end
function ADParkingBrush:getButtonTertiaryText() return "Toggle primary / secondary nodes" end
function ADParkingBrush:getAxisPrimaryText() return "Node spacing (1-10 m)" end

function ADParkingBrush:update(dt)
    if ConstructionBrush.update ~= nil then ConstructionBrush.update(self, dt) end
    local x, y, z = self.cursor:getHitTerrainPosition()
    self.target = x ~= nil and z ~= nil and {x = x, z = z} or nil
    self.preview = nil
    if self.target ~= nil then
        local a = self.anchor or self.target
        self.preview, self.length = ADParkingRowPlanner.points(a.x, a.z, x, z, self.spacing)
    end
end

function ADParkingBrush:primary()
    if self.target == nil then return end
    if self.anchor == nil then
        self.anchor = {x = self.target.x, z = self.target.z}
        self.message = nil
        return
    end
    local points, length = ADParkingRowPlanner.points(self.anchor.x, self.anchor.z, self.target.x, self.target.z, self.spacing)
    if points == nil then self.message = length; return end
    local env = _G.FS25_AutoDrive
    local graph, ad = env ~= nil and env.ADGraphManager or nil, env ~= nil and env.AutoDrive or nil
    if graph == nil or ad == nil then self.message = "AutoDrive is not available"; return end
    local flags = self.secondary and ad.FLAG_SUBPRIO or ad.FLAG_NONE
    local count = ADParkingRowPlanner.create(graph, points, flags, function(x, z)
        return getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
    end)
    self.message = string.format("Placed %d unconnected %s nodes", count, self.secondary and "secondary" or "primary")
    self.anchor, self.preview = nil, nil
    Logging.info("[ADParkingNodes] %s; length %.2f m, maximum spacing %d m", self.message, length, self.spacing)
end

function ADParkingBrush:draw()
    local color = self.secondary and {1, 0.65, 0.1} or {0.1, 1, 0.25}
    local previous
    for _, p in ipairs(self.preview or {}) do
        local y = getTerrainHeightAtWorldPos(g_terrainNode, p.x, 0, p.z) + 0.15
        if previous ~= nil then
            drawDebugLine(previous.x, previous.y, previous.z, 0.7, 0.7, 0.7, p.x, y, p.z, 0.7, 0.7, 0.7)
        end
        previous = {x = p.x, y = y, z = p.z}
        drawDebugLine(p.x - 0.25, y, p.z, color[1], color[2], color[3], p.x + 0.25, y, p.z, color[1], color[2], color[3])
        drawDebugLine(p.x, y, p.z - 0.25, color[1], color[2], color[3], p.x, y, p.z + 0.25, color[1], color[2], color[3])
        drawDebugLine(p.x, y, p.z, color[1], color[2], color[3], p.x, y + 0.5, p.z, color[1], color[2], color[3])
    end
    local text = string.format("Parking nodes: %s | max gap %d m | %.1f m | %d nodes",
        self.secondary and "Secondary" or "Primary", self.spacing, self.length or 0, #(self.preview or {}))
    setTextColor(1, 1, 1, 1)
    renderText(0.36, 0.12, 0.017, text)
    renderText(0.36, 0.095, 0.015, self.message or "Click start, stretch row, click to place. Change spacing with brush size controls.")
end

ADParkingNodes = {}
local M = ADParkingNodes

function M.install()
    if M.installed then return true end
    local manager = g_constructionBrushTypeManager
    if manager == nil or ConstructionScreen == nil or ConstructionBrush == nil then return false end
    local resolver = manager.getClassObjectByTypeName
    if type(resolver) ~= "function" then return false end
    manager.getClassObjectByTypeName = function(self, name, ...)
        if name == "adParkingNodes" or name == "FS25_z_ADParkingNodes.adParkingNodes" then return ADParkingBrush end
        return resolver(self, name, ...)
    end
    local function route(name, callback)
        local previous = ConstructionScreen[name]
        assert(type(previous) == "function", "ConstructionScreen." .. name .. " unavailable")
        ConstructionScreen[name] = function(screen, ...)
            if screen.brush ~= nil and screen.brush.isADParkingBrush then return callback(screen, screen.brush, ...) end
            return previous(screen, ...)
        end
    end
    route("onButtonPrimary", function(screen, brush) brush:primary() end)
    route("onButtonSecondary", function(screen, brush)
        if brush.anchor ~= nil then brush.anchor, brush.preview = nil, nil
        else screen:setBrush(screen.selectorBrush, true) end
    end)
    route("onButtonTertiary", function(screen, brush) brush.secondary = not brush.secondary end)
    route("onAxisPrimary", function(screen, brush, actionName, value)
        if value ~= nil and value ~= 0 then brush.spacing = math.max(1, math.min(10, brush.spacing + (value > 0 and 1 or -1))) end
    end)
    M.installed = true
    Logging.info("[ADParkingNodes] Parking Node Row available in Decorations > Others.")
    return true
end

function M:loadMap() self.install() end
M.install()
addModEventListener(M)

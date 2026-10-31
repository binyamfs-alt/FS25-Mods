ADParkingNodes = {}
local M = ADParkingNodes

function M.install()
    if M.installed then return true end
    if ConstructionBrushPlaceable == nil or ConstructionScreen == nil or ConstructionBrush == nil then return false end
    local factory = ConstructionBrushPlaceable.new
    if type(factory) ~= "function" then return false end
    for _, name in ipairs({"onButtonPrimary", "onButtonSecondary", "onButtonTertiary", "onAxisPrimary"}) do
        if type(ConstructionScreen[name]) ~= "function" then
            Logging.warning("[ADParkingNodes] Required construction control unavailable: %s", name)
            return false
        end
    end
    -- The catalog validates brush types before asking for their class object.
    -- Use the registered placeable type, then select our brush only for our item.
    ConstructionBrushPlaceable.new = function(storeItem, cursor, ...)
        local filename = type(storeItem) == "table" and storeItem.xmlFilename or storeItem
        if type(filename) == "string" then
            filename = filename:gsub("\\", "/"):lower()
            if filename:match("/fs25_z_adparkingnodes/parkingnodes%.xml$") ~= nil then
                return ADParkingBrush.new(storeItem, cursor)
            end
        end
        return factory(storeItem, cursor, ...)
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
    Logging.info("[ADParkingNodes] Parking tool factory registered for Decorations > Others.")
    return true
end

function M:loadMap() self.install() end
M.install()
addModEventListener(M)

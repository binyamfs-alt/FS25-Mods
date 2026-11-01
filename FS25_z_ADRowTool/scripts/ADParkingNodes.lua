ADParkingNodes = {}
local M = ADParkingNodes

function M.newBrush(item, cursor)
    local brush = ADParkingBrush.new(item, cursor)
    for _, name in ipairs({"activate", "deactivate", "update", "draw", "primary"}) do
        assert(type(brush[name]) == "function", "Invalid parking brush: missing " .. name)
    end
    return brush
end

function M.setParkingBrush(screen, item)
    local ok, result = pcall(function()
        local brush = M.newBrush(item, screen.cursor)
        screen:setBrush(brush, true)
        return brush
    end)
    if not ok then
        M.activationFailed = true
        -- Never leave a broken brush in the active Construction screen.
        pcall(screen.setBrush, screen, screen.selectorBrush, true)
        Logging.error("[ADParkingNodes] Activation disabled; returned to selection: %s", tostring(result))
        return false
    end
    return true
end

function M.isOurItem(storeItem)
    local filename = storeItem
    if type(storeItem) == "table" then
        filename = storeItem.xmlFilename or storeItem.configFileName or storeItem.filename
        if filename == nil and storeItem.storeItem ~= nil then return M.isOurItem(storeItem.storeItem) end
    end
    if type(filename) ~= "string" then return false end
    filename = filename:gsub("\\", "/"):lower()
    return ("/" .. filename):match("/fs25_z_adrowtool/parkingnodes%.xml$") ~= nil
end

function M.activateFromPreview(screen)
    local current = screen.brush
    if M.activationFailed or current == nil or current.isADParkingBrush then return end
    local item = current.storeItem
    local placeholder = current.placeable
    if not M.isOurItem(item) and not M.isOurItem(placeholder) then return end
    if not M.isOurItem(item) or type(item) ~= "table" or item.xmlFilename == nil then
        local filename = placeholder ~= nil and placeholder.configFileName or nil
        if filename ~= nil and g_storeManager ~= nil then item = g_storeManager:getItemByXMLFilename(filename) end
    end
    if M.setParkingBrush(screen, item) then
        Logging.info("[ADParkingNodes] ACTIVE: parking row brush replaced its loaded catalog preview.")
    end
end

function M.install()
    if M.installed then return true end
    if ConstructionBrushPlaceable == nil or ConstructionScreen == nil or ConstructionBrush == nil then return false end
    local factory = ConstructionBrushPlaceable.new
    if type(factory) ~= "function" then return false end
    for _, name in ipairs({"onButtonPrimary", "onButtonSecondary", "onButtonTertiary", "onButtonFourth", "onAxisPrimary", "onAxisSecondary", "onButtonSnapping", "loadCurrentConfiguration"}) do
        if type(ConstructionScreen[name]) ~= "function" then
            Logging.warning("[ADParkingNodes] Required construction control unavailable: %s", name)
            return false
        end
    end
    -- The catalog validates brush types before asking for their class object.
    -- Use the registered placeable type, then select our brush only for our item.
    ConstructionBrushPlaceable.new = function(storeItem, cursor, ...)
        if M.isOurItem(storeItem) then
            return M.newBrush(storeItem, cursor)
        end
        return factory(storeItem, cursor, ...)
    end
    -- The standard screen often creates a reusable brush with a nil storeItem,
    -- then supplies the selected catalog entry here. Intercept before it loads
    -- the empty physical placeholder or registers purchase callbacks.
    local loadConfiguration = ConstructionScreen.loadCurrentConfiguration
    ConstructionScreen.loadCurrentConfiguration = function(screen, storeItem, ...)
        if M.isOurItem(storeItem) then
            if screen.brush == nil or not screen.brush.isADParkingBrush then
                if M.setParkingBrush(screen, storeItem) then
                    Logging.info("[ADParkingNodes] Parking row brush activated from catalog selection.")
                end
            end
            return
        end
        return loadConfiguration(screen, storeItem, ...)
    end
    -- The screen may use a cached selection callback and an existing placeable
    -- brush. Its draw path exposes the fully loaded placeable's configFileName.
    -- Inspect only; replace exclusively our own tool before any purchase input.
    if type(ConstructionScreen.draw) == "function" then
        local draw = ConstructionScreen.draw
        ConstructionScreen.draw = function(screen, ...)
            M.activateFromPreview(screen)
            return draw(screen, ...)
        end
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
    route("onButtonFourth", function(screen, brush)
        brush.connectionMode = (brush.connectionMode + 1) % 3
        -- Construction caches help text when registering the brush. Refresh
        -- its existing event instead of rebuilding controls or losing the row.
        if screen.fourthBrushEvent ~= nil and g_inputBinding ~= nil then
            g_inputBinding:setActionEventText(screen.fourthBrushEvent, brush:getButtonFourthText())
        end
    end)
    route("onButtonSnapping", function(screen, brush)
        brush.curveFlipped = not brush.curveFlipped
    end)
    route("onAxisPrimary", function(screen, brush, actionName, value)
        if value ~= nil and value ~= 0 then brush.spacing = math.max(1, math.min(10, brush.spacing + (value > 0 and 1 or -1))) end
    end)
    route("onAxisSecondary", function(screen, brush, actionName, value)
        if value ~= nil and value ~= 0 then
            brush.curveDegrees = math.max(0, math.min(180, brush.curveDegrees + (value > 0 and 5 or -5)))
        end
    end)
    M.installed = true
    Logging.info("[ADParkingNodes] Parking tool factory registered for Decorations > Others.")
    return true
end

function M:loadMap() self.install() end
M.install()
addModEventListener(M)

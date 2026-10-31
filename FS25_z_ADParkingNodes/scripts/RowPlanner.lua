ADParkingRowPlanner = {}

function ADParkingRowPlanner.points(x1, z1, x2, z2, spacing)
    if spacing < 1 or spacing > 10 then return nil, "Spacing must be between 1 and 10 m" end
    local dx, dz = x2 - x1, z2 - z1
    local length = math.sqrt(dx * dx + dz * dz)
    if length > 500 then return nil, "Maximum row length is 500 m" end
    if length < 0.1 then return {{x = x1, z = z1}}, length end
    local intervals = math.ceil(length / spacing)
    local points = {}
    for i = 0, intervals do
        local t = i / intervals
        points[#points + 1] = {x = x1 + dx * t, z = z1 + dz * t}
    end
    return points, length
end

function ADParkingRowPlanner.create(graph, points, flags, height)
    assert(type(graph.createWayPointWithConnections) == "function", "AutoDrive graph unavailable")
    -- Prepare the complete row before any graph mutations.
    local prepared = {}
    for _, point in ipairs(points) do
        local y = height(point.x, point.z)
        assert(type(y) == "number" and y == y, "Invalid terrain height")
        prepared[#prepared + 1] = {x = point.x, y = y, z = point.z}
    end
    for _, p in ipairs(prepared) do
        -- AutoDrive's own network event creates/saves nodes; empty connections.
        graph:createWayPointWithConnections(p.x, p.y, p.z, {}, {}, flags, false, false, false, true)
    end
    return #prepared
end

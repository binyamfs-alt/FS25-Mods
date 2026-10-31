ADParkingRowPlanner = {}

function ADParkingRowPlanner.points(x1, z1, x2, z2, spacing, degrees)
    if spacing < 1 or spacing > 10 then return nil, "Spacing must be between 1 and 10 m" end
    degrees = degrees or 0
    if degrees < 0 or degrees > 180 or degrees % 5 ~= 0 then
        return nil, "Curve must be 0-180 degrees in 5-degree steps"
    end
    local dx, dz = x2 - x1, z2 - z1
    local chord = math.sqrt(dx * dx + dz * dz)
    local theta = math.rad(degrees)
    local radius = degrees > 0 and chord / (2 * math.sin(theta / 2)) or nil
    local length = radius and radius * theta or chord
    if length > 500 then return nil, "Maximum path length is 500 m" end
    if chord < 0.1 then return {{x = x1, z = z1}}, length end
    local intervals = math.ceil(length / spacing)
    local points = {}
    for i = 0, intervals do
        local t = i / intervals
        local x, z
        if degrees == 0 then
            x, z = x1 + dx * t, z1 + dz * t
        else
            -- Chord-local circular arc. Endpoints stay under the two clicks;
            -- reversing their order mirrors the bend to the opposite side.
            local angle = theta * (t - 0.5)
            local along = chord / 2 + radius * math.sin(angle)
            local across = radius * (math.cos(theta / 2) - math.cos(angle))
            x = x1 + dx / chord * along - dz / chord * across
            z = z1 + dz / chord * along + dx / chord * across
        end
        points[#points + 1] = {x = x, z = z}
    end
    -- Exact endpoints avoid floating-point drift at joints.
    points[1] = {x = x1, z = z1}
    points[#points] = {x = x2, z = z2}
    return points, length
end

function ADParkingRowPlanner.create(graph, points, flags, height, mode)
    assert(type(graph.createWayPointWithConnections) == "function", "AutoDrive graph unavailable")
    mode = mode or 0 -- 0: unconnected, 1: one-way, 2: bidirectional
    assert(mode == 0 or mode == 1 or mode == 2, "Invalid connection mode")
    if mode ~= 0 then
        assert(g_server ~= nil, "Connected rows require the multiplayer host")
        assert(type(graph.getWayPointsCount) == "function", "AutoDrive node count unavailable")
    end
    -- Prepare the complete row before any graph mutations.
    local prepared = {}
    for _, point in ipairs(points) do
        local y = height(point.x, point.z)
        assert(type(y) == "number" and y == y, "Invalid terrain height")
        prepared[#prepared + 1] = {x = point.x, y = y, z = point.z}
    end
    local previousId
    for _, p in ipairs(prepared) do
        local connect = mode ~= 0 and previousId ~= nil
        local newId = mode ~= 0 and graph:getWayPointsCount() + 1 or nil
        -- Native AutoDrive events create the node and its link together. On the
        -- host these run synchronously; do not predict IDs on remote clients.
        graph:createWayPointWithConnections(p.x, p.y, p.z,
            connect and {newId} or {}, connect and {previousId} or {},
            flags, connect, false, mode == 2 and connect, true)
        previousId = newId
    end
    return #prepared
end

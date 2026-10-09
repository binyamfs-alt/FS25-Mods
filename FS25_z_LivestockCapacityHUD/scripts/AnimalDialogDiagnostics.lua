-- Copyright (C) 2026 BinyamFS. SPDX-License-Identifier: GPL-3.0-or-later
-- Temporary diagnostics: record the real controller contract without changing animals.
local function describe(value)
    if type(value) ~= "table" then return tostring(value) end
    local keys = {}
    for key, v in pairs(value) do
        if type(key) == "string" then
            if key == "spec_livestockTrailer" then return "livestockTrailer" end
            if type(v) ~= "function" and type(v) ~= "table" then
                table.insert(keys, key .. "=" .. tostring(v))
            else table.insert(keys, key .. ":" .. type(v)) end
        end
    end
    table.sort(keys)
    return "{" .. table.concat(keys, ",") .. "}"
end
local function report(screen, method)
    print("[Livestock HUD Dialog] " .. method .. " buyMode=" .. tostring(screen.isBuyMode)
        .. " selectionState=" .. tostring(screen.selectionState))
    local controller = screen.controller
    print("[Livestock HUD Dialog] controller=" .. describe(controller))
    if type(controller) == "table" then
        for key, value in pairs(controller) do
            if type(value) == "table" then print("[Livestock HUD Dialog] " .. tostring(key) .. "=" .. describe(value)) end
        end
        local mt = getmetatable(controller)
        print("[Livestock HUD Dialog] controllerMetatable=" .. describe(mt))
        if type(mt) == "table" and type(mt.__index) == "table" then
            print("[Livestock HUD Dialog] controllerMethods=" .. describe(mt.__index))
        end
    end
    print("[Livestock HUD Dialog] sourceTypes=" .. describe(screen.sourceSelectorStateToAnimalType))
    for _, field in ipairs({"sourceList", "targetList", "sourceSelector", "targetSelector"}) do
        local value = screen[field]
        if value ~= nil then
            print("[Livestock HUD Dialog] " .. field .. " selected=" .. tostring(value.selectedIndex)
                .. " state=" .. tostring(value.state) .. " data=" .. describe(value.data))
        end
    end
end
if AnimalScreen ~= nil then
    for _, name in ipairs({"onOpen", "onClickBuyMode", "onClickSellMode", "onClickBuy", "onClickSell", "onYesNoSource", "onYesNoTarget"}) do
        if type(AnimalScreen[name]) == "function" then
            local method = name
            AnimalScreen[name] = Utils.prependedFunction(AnimalScreen[name], function(screen) report(screen, method) end)
        end
    end
end

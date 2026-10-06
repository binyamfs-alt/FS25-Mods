-- Relative to the user's normal HUD scale. Change to 0.80 for 20% smaller.
local SCALE = 0.85

local fields = {
    "helpAnchorOffsetX", "helpAnchorOffsetY", "lineOffsetY", "textSize",
    "textOffsetX", "textOffsetY", "comboTextOffsetX", "comboTextOffsetY",
    "comboSeparatorOffsetX", "comboSeparatorOffsetY", "comboIconWidth", "comboIconHeight",
    "schemaOffsetX", "schemaOffsetY", "iconSizeX", "iconSizeY", "maxSchemaWidth"
}
local overlays = {
    "lineBg", "lineBgLeft", "lineBgScale", "lineBgRight", "comboBg",
    "separatorHorizontal", "separatorVertical"
}

local function scaleOverlay(overlay)
    if overlay ~= nil and type(overlay.width) == "number" and type(overlay.height) == "number" then
        overlay:setDimension(overlay.width * SCALE, overlay.height * SCALE)
    end
end

local function compact(display)
    -- The original routine rebuilds every value from pixel dimensions first.
    -- Appending here avoids cumulative shrinking and handles UI scale changes.
    for _, name in ipairs(fields) do
        if type(display[name]) == "number" then
            display[name] = display[name] * SCALE
        end
    end
    for _, name in ipairs(overlays) do
        scaleOverlay(display[name])
    end
    for _, overlay in pairs(display.vehicleSchemaOverlays or {}) do
        scaleOverlay(overlay)
    end
    local minWidth = display:scalePixelToScreenWidth(35) * SCALE
    display.keyButtonOverlay:setMinWidth(minWidth)
    display.glyphButtonOverlay:setMinWidth(minWidth)
end

if InputHelpDisplay ~= nil and InputHelpDisplay.storeScaledValues ~= nil then
    InputHelpDisplay.storeScaledValues = Utils.appendedFunction(InputHelpDisplay.storeScaledValues, compact)
    print("[CompactControls] Controls help panel scale: " .. tostring(SCALE))
else
    print("[CompactControls] InputHelpDisplay unavailable; no changes applied.")
end

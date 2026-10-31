-- Connect the foliage-painting brush to PerfectEdge's existing axis lock.
PerfectEdgeMeadow = {}
local M = PerfectEdgeMeadow

function M.install()
    if M.installed then return true end
    local env = _G.FS25_PerfectEdge
    local brush = ConstructionBrushFoliage
    if env == nil or env.ExtendedTerraforming == nil or brush == nil then return false end
    local hooks = {
        {name = "activate", callback = env.ExtendedTerraformingActivate},
        {name = "deactivate", callback = env.ExtendedTerraformingDactivate},
        {name = "update", callback = env.ExtendedTerraformingUpdate}
    }
    -- Validate the complete interface before changing any method.
    for _, hook in ipairs(hooks) do
        if type(brush[hook.name]) ~= "function" or type(hook.callback) ~= "function" then return false end
    end
    for _, hook in ipairs(hooks) do
        local previous = brush[hook.name]
        -- An inherited Paint implementation already has PerfectEdge's hook.
        if ConstructionBrushPaint == nil or previous ~= ConstructionBrushPaint[hook.name] then
            local callback = hook.callback
            brush[hook.name] = function(self, ...)
                -- Input registration belongs to the original PerfectEdge mod.
                if env.ExtendedTerraforming.InputEvent ~= nil then callback(self, ...) end
                return previous(self, ...)
            end
        end
    end
    M.installed = true
    Logging.info("[PerfectEdgeMeadow] PerfectEdge axis lock enabled for foliage painting, including meadow.")
    return true
end

function M:loadMap()
    if not self.install() then
        Logging.warning("[PerfectEdgeMeadow] PerfectEdge/foliage brush interface unavailable; no changes made.")
    end
end

-- Install before construction brushes are instantiated. Retry on map load if needed.
M.install()
addModEventListener(M)

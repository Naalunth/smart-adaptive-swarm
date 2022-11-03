---@meta
aura_env = {
    config = {},
}

WeakAuras = {
    ---@param unit UnitId
    ---@param checkVisible boolean?
    ---@return number? minRange nil if no range estimte could be determined
    ---@return number? maxRange nil if the unit is too far away
    ---@nodiscard
    GetRange = function(unit, checkVisible) end
}

---@return fun(): UnitId next
---@nodiscard
function WA_IterateGroupMembers() end

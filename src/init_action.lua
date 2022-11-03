aura_env.SPELL_ID = {
    GCD = 61304,
    SWARM_SPELL = 391888,
    SWARM_DAMAGE = 391889,
    SWARM_HEAL = 391891,
    FLOURISH = 197721,
}

aura_env.CONFIG = {
    ---@enum Config.Sound
    SOUND = {
        NEVER = 1,
        FOCUS = 2,
        ALL = 3,
    },
    ---@enum Config.Focus
    FOCUS = {
        NONE = 1,
        FOCUS = 2,
        TARGET = 3,
    },
}

---@enum Sound
aura_env.SOUND = {
    NONE = 0,
    COOLDOWN = 1,
    FOCUS = 2,
}

---The swarms currently on allies. Keys are the unit.
---@type {[string]: {unit: UnitId, count: integer, expirationTime: number}}
aura_env.swarms = {}

---Next time to update
aura_env.nextUpdateTime = 0

---The last time a swarm bounced away from an ally
aura_env.lastBounceFromAlly = GetTime()

---Get the cast priority on that unit
---@param count integer -- The amount of Adaptive Swarm stacks on the unit
---@return integer priority -- The priority of that specific unit
aura_env.priority = function(count)
    return ({
        [2] = 2,
        [1] = 1,
        [3] = 0
    })[count]
end

---The UnitId of the enemy to focus
---@type UnitId?
aura_env.focusTarget = ({
    [aura_env.CONFIG.FOCUS.NONE] = nil,
    [aura_env.CONFIG.FOCUS.FOCUS] = "focus",
    [aura_env.CONFIG.FOCUS.TARGET] = "target",
})[aura_env.config.focusTarget]

---@return UnitId? unit -- the lowest health ally to use Adaptive Swarm on
aura_env.getLowestHealthAlly = function()
    local lowest = nil
    local maximum = nil
    local hasNoAllies = true
    for unit in WA_IterateGroupMembers() do
        if not UnitIsDead(unit) then
            local health = UnitHealth(unit)
            local max = UnitHealthMax(unit)
            local ratio = 1
            if max > 0 then
                ratio = health / max
            end

            local swarm = aura_env.swarms[unit]

            if hasNoAllies or not swarm and ratio < lowest.ratio then
                lowest = { unit = unit, ratio = ratio }
            end
            if hasNoAllies or not swarm and max > maximum.max then
                maximum = { unit = unit, max = max }
            end

            hasNoAllies = false
        end
    end

    return lowest and (lowest.ratio <= 0.95 and lowest.unit or maximum.unit)
end

---Find the lowest duration running Adaptive Swarms
---@return integer duration
aura_env.lowestDuration = function()
    local lowest = 20
    for _, swarm in pairs(aura_env.swarms) do
        if swarm.count > 1 then
            lowest = math.min(swarm.expirationTime - GetTime(), lowest)
        end
    end
    return lowest
end

---Checks if we have enough time to refresh Adaptive Swarm on that unit
---@param unit UnitId
---@param expirationTime number
---@return boolean?
aura_env.canBeRefreshedInTime = function(unit, expirationTime)
    local _, distance = WeakAuras.GetRange(unit)
    return distance and aura_env.travelDuration(distance) + aura_env.config.delay <= expirationTime - GetTime()
end

---Calculate the time it takes for Adaptive Swarm to travel given distance
---@param distance number
---@return number duration
aura_env.travelDuration = function(distance)
    return distance * 0.0833 + 0.125
end

---Find the best ally to cast Adaptive Swarm on for maximum upkeep
---@return UnitId? unit
aura_env.getOptimalAlly = function()
    local bestSwarm = nil
    for _, swarm in pairs(aura_env.swarms) do
        if aura_env.canBeRefreshedInTime(swarm.unit, swarm.expirationTime) then
            local auraPriority = aura_env.priority(swarm.count)
            local bestPriority = bestSwarm and aura_env.priority(bestSwarm.count)
            if auraPriority and
                (not bestSwarm
                    or auraPriority > bestPriority
                    or auraPriority == bestPriority and swarm.expirationTime > bestSwarm.expirationTime)
            then
                bestSwarm = swarm
            end
        end
    end
    return bestSwarm and bestSwarm.unit
end

---Check if Adaptive Swarm should be cast on the focus target
---@return UnitId? unit -- The focus target or nil if we don't care about it
aura_env.getFocusTarget = function()
    if not aura_env.focusTarget or not UnitExists(aura_env.focusTarget) or
        not UnitCanAttack("player", aura_env.focusTarget) then
        return false
    end

    local hasSwarm = false
    local shouldRefresh = false
    AuraUtil.ForEachAura(aura_env.focusTarget, "HARMFUL PLAYER", nil, function(aura)
        if aura.spellId ~= aura_env.SPELL_ID.SWARM_DAMAGE then
            return false
        end
        hasSwarm = true
        local distance, _ = WeakAuras.GetRange(aura_env.focusTarget)
        local travelTime = distance and aura_env.travelDuration(distance)
        local durationLeft = aura.expirationTime - GetTime()
        if travelTime and travelTime + aura_env.config.delay > durationLeft
            or travelTime and durationLeft < 4 + travelTime and (aura.count or 1) <= 2
            or durationLeft < 6
        then
            shouldRefresh = true
        end
        return true
    end, true)

    if shouldRefresh or not hasSwarm and aura_env.lowestDuration() > 6 and GetTime() - aura_env.lastBounceFromAlly > 2 then
        return aura_env.focusTarget
    end
    return nil
end

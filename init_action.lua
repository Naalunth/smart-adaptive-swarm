aura_env.AURA_SWARM_HEAL = 391891
aura_env.AURA_SWARM_DAMAGE = 391889
aura_env.AURA_FLOURISH = 197721
aura_env.SPELL_SWARM = 391888
aura_env.SPELL_GCD = 61304

aura_env.CONFIG_SOUND_NEVER = 1
aura_env.CONFIG_SOUND_FOCUS = 2
aura_env.CONFIG_SOUND_ALL = 3

aura_env.CONFIG_FOCUS_NONE = 1
aura_env.CONFIG_FOCUS_FOCUS = 2
aura_env.CONFIG_FOCUS_TARGET = 3

aura_env.SOUND_NONE = 0
aura_env.SOUND_COOLDOWN = 1
aura_env.SOUND_FOCUS = 2

aura_env.swarms = { }
aura_env.nextUpdate = 0
aura_env.lastExp = GetTime()

-- maps from stack count to importance to cast on that specific unit
aura_env.priority = function(count)
	return ({
		[2] = 2,
		[1] = 1,
		[3] = 0
	})[count]
end

if aura_env.config.focusTarget == aura_env.CONFIG_FOCUS_NONE then
	aura_env.focusTarget = nil
elseif aura_env.config.focusTarget == aura_env.CONFIG_FOCUS_FOCUS then
	aura_env.focusTarget = "focus"
elseif aura_env.config.focusTarget == aura_env.CONFIG_FOCUS_TARGET then
	aura_env.focusTarget = "target"
end

-- returns the lowest health ally to use swarm on
aura_env.lowestHealth = function()
	local lowest = nil
	local maximum = nil
	local isFirstMember = true
	for unit in WA_IterateGroupMembers() do
		if not UnitIsDead(unit) then
			local health = UnitHealth(unit)
			local max = UnitHealthMax(unit)
			local ratio = 1
			if max > 0 then
				ratio = health / max
			end

			local hasSwarm = function()
				for _, swarm in pairs(aura_env.swarms) do
					if swarm.unit == unit then
						return true
					end
				end
				return false
			end
			
			if isFirstMember then
				isFirstMember = false
				lowest = {
					unit = unit,
					ratio = ratio
				}
				maximum = {
					unit = unit,
					max = max
				}
			elseif not hasSwarm() then
				if ratio < lowest.ratio then
					lowest = {
						unit = unit,
						ratio = ratio
					}
				end
				if max > maximum.max then
					maximum = {
						unit = unit,
						max = max
					}
				end
			end
		end
	end

	if not lowest then
		return nil
	elseif lowest.ratio <= 0.95 then
		return lowest.unit
	else
		return maximum.unit
	end
end

-- returns the lowest duration running swarm
aura_env.lowestDuration = function()
	local lowest = 20
	for _, swarm in pairs(aura_env.swarms) do
		if swarm.count > 1 then
			lowest = min(swarm.expirationTime - GetTime(), lowest)
		end
	end
	return lowest
end

-- checks if we have enough time to refresh swarm on that unit
aura_env.canBeRefreshedInTime = function(unit, expirationTime)
	local _, distance = WeakAuras.GetRange(unit)
	return distance and aura_env.travelTime(distance) + aura_env.config.delay <= expirationTime - GetTime()
end

-- the time it takes for swarm to travel given distance
aura_env.travelTime = function(distance)
	return distance * 0.0833 + 0.125
end

-- returns the best ally to cast swarm on for maximum upkeep
aura_env.optimalAlly = function()
	local bestAura = nil
	for _, swarm in pairs(aura_env.swarms) do
		if aura_env.canBeRefreshedInTime(swarm.unit, swarm.expirationTime) then
			local auraPriority = aura_env.priority(swarm.count)
			local bestPriority = nil
			if bestAura then
				bestPriority = aura_env.priority(bestAura.count)
			end
			if (auraPriority) and
				(not bestAura
				or auraPriority > bestPriority
				or auraPriority == bestPriority and swarm.expirationTime > bestAura.expirationTime)
			then
				bestAura = swarm
			end
		end
	end
	if bestAura then
		return bestAura.unit
	end
	return nil
end

-- returns the focus target or nil if we don't care about it now
aura_env.getFocusTarget = function()
	if not aura_env.focusTarget or not UnitExists(aura_env.focusTarget) or not UnitCanAttack("player", aura_env.focusTarget) then
		return false
	end

	local hasSwarm = false
	local result = false
	AuraUtil.ForEachAura(aura_env.focusTarget, "HARMFUL", nil, function(aura)
		if aura.spellId ~= aura_env.AURA_SWARM_DAMAGE then
			return false
		end
		hasSwarm = true
		local distance, _ = WeakAuras.GetRange(aura_env.focusTarget)
		local travelTime = aura_env.travelTime(distance)
		local durationLeft = aura.expirationTime - GetTime()
		if travelTime + aura_env.config.delay > durationLeft 
			or durationLeft < 4 + travelTime and (aura.count or 1) <= 2 
			or durationLeft < 6
		then
			result = true
		end
		return true
	end, true)
	if result or not hasSwarm and aura_env.lowestDuration() > 6 and GetTime() - aura_env.lastExp > 2 then
		return aura_env.focusTarget
	end
	return nil
end

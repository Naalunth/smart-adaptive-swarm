function(event, _, subEvent, _, _, sourceName, _, _, _, _, _, _, spellID)
	if not (spellID == aura_env.AURA_SWARM_HEAL and (subEvent == "SPELL_AURA_APPLIED" or subEvent == "SPELL_AURA_REMOVED" or subEvent == "SPELL_AURA_APPLIED_DOSE")
			or spellID == aura_env.AURA_FLOURISH and subEvent == "SPELL_AURA_APPLIED") then
		return
	end

	local prevSwarms = aura_env.swarms
	aura_env.swarms = { }
	for unit in WA_IterateGroupMembers() do
		AuraUtil.ForEachAura(unit, "HELPFUL", nil, function(aura)
			if aura.spellId ~= aura_env.AURA_SWARM_HEAL then
				return false
			end
			aura_env.swarms[#aura_env.swarms + 1] = {
				unit = unit,
				count = aura.count or 1,
				expirationTime = aura.expirationTime
			}
			return true
		end, true)
	end

	if #aura_env.swarms < #prevSwarms then
		for _, swarm in pairs(aura_env.swarms) do
			local found = false
			for _, prevSwarm in pairs(prevSwarms) do
				if swarm.unit == prevSwarm.unit then
					found = true
					break
				end
			end
			if not found then
				if swarm.count > 1 then
					aura_env.lastExp = GetTime()
				end
				break
			end
		end
	end
	return aura_env
end

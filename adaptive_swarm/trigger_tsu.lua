function(allStates, ...)
	if GetTime() <= aura_env.nextUpdate then
		return false
	end

	local getExpirationTime
	getExpirationTime = function(id)
		local start, duration = GetSpellCooldown(id)
		return start + duration
	end

	local swarmExpirationTime = getExpirationTime(aura_env.SPELL_SWARM)
	local gcdExpirationTime = getExpirationTime(aura_env.SPELL_GCD)
	local _, previousState = pairs(allStates)(allStates)

	local changeMade = false
	if swarmExpirationTime == gcdExpirationTime then
		aura_env.nextUpdate = GetTime() + aura_env.config.updateInterval

		-- figure out who we want to cast on
		local swarmUnit = aura_env.getFocusTarget()
		if not swarmUnit then
			swarmUnit = aura_env.optimalAlly()
		end
		if not swarmUnit then
			swarmUnit = aura_env.lowestHealth()
		end

		if swarmUnit then
			if previousState and swarmUnit == previousState.unit then
				previousState.changed = false
				return false
			end

			local sound = aura_env.SOUND_NONE
			if aura_env.config.sound ~= aura_env.CONFIG_SOUND_NEVER and swarmUnit == aura_env.focusTarget then
				sound = aura_env.SOUND_FOCUS
			elseif aura_env.config.sound == aura_env.CONFIG_SOUND_ALL and not previousState then
				sound = aura_env.SOUND_COOLDOWN
			end

			allStates[swarmUnit] = {
				show = true,
				changed = true,
				playSound = sound,
				unit = swarmUnit
			}
			changeMade = true
		end
	else
		aura_env.nextUpdate = swarmExpirationTime
	end
	if previousState then
		previousState.show = false
		previousState.changed = true
		changeMade = true
	end
	return changeMade
end

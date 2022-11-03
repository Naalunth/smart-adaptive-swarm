-- Event Type: TSU
-- Check On... Every Frame

---@diagnostic disable-next-line: miss-name
function(allStates)
    -- return early to avoid processing too much
    if GetTime() <= aura_env.nextUpdateTime then
        return false
    end

    local getExpirationTime = function(id)
        local start, duration = GetSpellCooldown(id)
        return start + duration
    end
    local swarmExpirationTime = getExpirationTime(aura_env.SPELL_ID.SWARM_SPELL)
    local gcdExpirationTime = getExpirationTime(aura_env.SPELL_ID.GCD)

    -- find the previous state
    local _, previousState = next(allStates)

    local changeMade = false
    if swarmExpirationTime ~= gcdExpirationTime then
        -- swarm isn't up, wait for the cooldown
        aura_env.nextUpdateTime = swarmExpirationTime
    else
        aura_env.nextUpdateTime = GetTime() + aura_env.config.updateInterval

        -- figure out who we want to cast on
        local swarmUnit = aura_env.getFocusTarget() or aura_env.getOptimalAlly() or aura_env.getLowestHealthAlly()

        if swarmUnit then
            if previousState and swarmUnit == previousState.unit then
                previousState.changed = false
                return false
            end

            local sound = aura_env.SOUND.NONE
            -- play the focus sound
            if aura_env.config.sound ~= aura_env.CONFIG.SOUND.NEVER and swarmUnit == aura_env.focusTarget then
                sound = aura_env.SOUND.FOCUS
            -- or cooldown sound
            elseif aura_env.config.sound == aura_env.CONFIG.SOUND.ALL and not previousState then
                sound = aura_env.SOUND.COOLDOWN
            end

            allStates[swarmUnit] = {
                show = true,
                changed = true,
                playSound = sound,
                unit = swarmUnit
            }
            changeMade = true
        end
    end

    -- finally clear the previous state
    if previousState then
        previousState.show = false
        previousState.changed = true
        changeMade = true
    end
    return changeMade
end

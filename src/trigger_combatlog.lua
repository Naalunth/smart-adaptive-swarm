-- Event Type: Status
-- Check On... Events: CLEU:SPELL_AURA_APPLIED:SPELL_AURA_REMOVED:SPELL_AURA_APPLIED_DOSE

---@param subEvent string
---@param spellID integer
---@diagnostic disable-next-line: miss-name
function(_, _, subEvent, _, _, _, _, _, _, _, _, _, spellID)
    if not (spellID == aura_env.SPELL_ID.SWARM_HEAL and (subEvent == "SPELL_AURA_APPLIED" or subEvent == "SPELL_AURA_REMOVED" or subEvent == "SPELL_AURA_APPLIED_DOSE")
            or spellID == aura_env.SPELL_ID.FLOURISH and subEvent == "SPELL_AURA_APPLIED") then
        return
    end

    -- update the state of the swarms
    local prevSwarms = aura_env.swarms
    aura_env.swarms = { }
    for unit in WA_IterateGroupMembers() do
        AuraUtil.ForEachAura(unit, "HELPFUL", nil, function(aura)
            if aura.spellId ~= aura_env.SPELL_ID.SWARM_HEAL then
                return false
            end
            aura_env.swarms[unit] = {
                unit = unit,
                count = aura.applications or 1,
                expirationTime = aura.expirationTime
            }
            return true
        end, true)
    end

    -- find out if a swarm expired on someone since last time
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
                    aura_env.lastBounceFromAlly = GetTime()
                end
                break
            end
        end
    end
end

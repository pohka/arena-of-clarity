hero_silence_modifier = class({})

function hero_silence_modifier:CheckState()
	local state = {
    [MODIFIER_STATE_SILENCED] = true
	}

	return state
end

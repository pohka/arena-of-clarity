hero_turn_rate_modifier = class({})

function hero_turn_rate_modifier:DeclareFunctions()
	local funcs = {
    MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE
	}

	return funcs
end

function hero_turn_rate_modifier:GetModifierTurnRate_Percentage()
  return 100
end


function hero_turn_rate_modifier:IsHidden()
  return true
end

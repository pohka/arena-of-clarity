sven_r_modifier = class({})

function sven_r_modifier:GetEffectName()
	return "particles/units/heroes/hero_sven/sven_spell_gods_strength.vpcf"
end


function sven_r_modifier:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end


function sven_r_modifier:GetStatusEffectName()
  return "particles/status_fx/status_effect_gods_strength.vpcf"
end

function sven_r_modifier:StatusEffectPriority()
  return 10
end
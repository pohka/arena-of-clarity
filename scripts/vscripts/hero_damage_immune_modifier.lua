hero_damage_immune_modifier = class({})

function hero_damage_immune_modifier:IsHidden()
  return false
end

function hero_damage_immune_modifier:GetTexture()
  return "item_black_king_bar"
end

function hero_damage_immune_modifier:GetEffectName()
	return "particles/items_fx/black_king_bar_avatar.vpcf"
end

function hero_damage_immune_modifier:CheckState()
	local state = {
    [MODIFIER_STATE_INVULNERABLE] = true
	}

	return state
end

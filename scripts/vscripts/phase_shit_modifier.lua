phase_shit_modifier = class({})

function phase_shit_modifier:CheckState()
  local state = {
    [MODIFIER_STATE_OUT_OF_GAME] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true
  }

  return state
end

function phase_shit_modifier:OnCreated()
  if IsServer() then
    local unit = self:GetParent()
    --unit:SetMoveCapability(DOTA_UNIT_CAP_MOVE_NONE)
    unit:SetModelScale(0.05)
    unit:EmitSound("Hero_Puck.Phase_Shift")
  end
end

function phase_shit_modifier:OnDestroy()
  if IsServer() then
    local unit = self:GetParent()
    --unit:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)
    unit:SetModelScale(1.0)
    unit:StopSound("Hero_Puck.Phase_Shift")
  end
end


function phase_shit_modifier:GetEffectName()
	return "particles/units/heroes/hero_puck/puck_phase_shift.vpcf"
end


function phase_shit_modifier:GetEffectAttachType()
	return PATTACH_ABSORIGIN
end

function phase_shit_modifier:GetStatusEffectName()
  return "particles/status_fx/status_effect_phase_shift.vpcf"
end

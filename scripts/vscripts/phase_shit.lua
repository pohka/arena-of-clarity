phase_shit = class({})
LinkLuaModifier("phase_shit_modifier", LUA_MODIFIER_MOTION_NONE)

function phase_shit:OnSpellStart()
  local caster = self:GetCaster()
  caster:AddNewModifier(
    caster,
    self,
    "phase_shit_modifier",
    {}
  )
  ProjectileManager:ProjectileDodge(caster)
end

function phase_shit:OnChannelFinish(interupted)
  local caster = self:GetCaster()
  caster:RemoveModifierByName("phase_shit_modifier")
end

function phase_shit:GetChannelTime()
  return self:GetSpecialValueFor("duration")
end
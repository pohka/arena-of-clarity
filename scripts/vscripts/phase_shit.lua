phase_shit = class({})
LinkLuaModifier("phase_shit_modifier", LUA_MODIFIER_MOTION_NONE)

function phase_shit:OnSpellStart()
  local caster = self:GetCaster()
  caster:AddNewModifier(
    caster,
    self,
    "phase_shit_modifier",
    { duration =  self:GetSpecialValueFor("duration") }
  )
  ProjectileManager:ProjectileDodge(caster)
end

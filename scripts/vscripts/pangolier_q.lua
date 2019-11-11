pangolier_q = class({})
LinkLuaModifier("pangolier_q_modifier", LUA_MODIFIER_MOTION_NONE)

function pangolier_q:OnSpellStart()
  local caster = self:GetCaster()
  local kv = { duration = self:GetSpecialValueFor("jump_time") }
  local target = self:GetCursorPosition()
  kv.x = target.x
  kv.y = target.y
  
  caster:AddNewModifier(caster, self, "pangolier_q_modifier", kv)
end

function pangolier_q:GetAOERadius()
  return self:GetSpecialValueFor("radius")
end
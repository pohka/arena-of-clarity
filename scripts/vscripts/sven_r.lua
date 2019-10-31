sven_r = class({})
LinkLuaModifier( "sven_r_modifier", LUA_MODIFIER_MOTION_NONE )

function sven_r:OnSpellStart()
  local caster = self:GetCaster()
  caster:EmitSound("Hero_Sven.GodsStrength")
  caster:StartGesture(ACT_DOTA_OVERRIDE_ABILITY_4)
  

  caster:AddNewModifier(
    caster,
    self, 
    "sven_r_modifier",
    { duration  = self:GetSpecialValueFor("duration") }
  )
end



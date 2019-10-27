sven_r = class({})
LinkLuaModifier( "sven_r_modifier", LUA_MODIFIER_MOTION_NONE )

function sven_r:OnSpellStart()
  local caster = self:GetCaster()

  caster:AddNewModifier(
    caster,
    self, 
    "sven_r_modifier",
    { duration  = 5.0 }
  )

  EmitSoundOn("Hero_Sven.GodsStrength", self:GetCaster())
  caster:StartGesture(ACT_DOTA_OVERRIDE_ABILITY_4)
end


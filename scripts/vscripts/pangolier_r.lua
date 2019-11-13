pangolier_r = class({})

require("query")
require("abil_helper")

function pangolier_r:OnSpellStart()
  local caster = self:GetCaster()
  local direction = AbilHelper:GetPointDirection(self)
  --start ability a little behind pango
  local offset = 100
  local startPt = caster:GetAbsOrigin() - (direction * offset)
  local range = self:GetSpecialValueFor("distance") + offset
  local units = Query:FindUnitsSector(
    caster:GetTeam(),
    startPt,
    direction,
    self:GetSpecialValueFor("angle"),
    nil,
    range,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false,
    nil
  )

  caster:SetForwardVector(direction)
  caster:MoveToPosition(caster:GetAbsOrigin() + direction)

  local fxRange = 600
  local rangeDiff = self:GetSpecialValueFor("distance") - fxRange
  local fxPoint = caster:GetAbsOrigin() + (direction * rangeDiff)

  local fxIndex = ParticleManager:CreateParticle(
    "particles/econ/items/sven/sven_ti7_sword/sven_ti7_sword_spell_great_cleave_gods_strength.vpcf",
    PATTACH_CUSTOMORIGIN,
    caster
  )
  ParticleManager:SetParticleControl(fxIndex, 0, fxPoint)
  ParticleManager:SetParticleControlForward(fxIndex, 0, direction)
  EmitSoundOn("Hero_Mars.Shield.Cast", caster)

  for _,unit in pairs(units) do
    ApplyDamage({
      victim = unit,
      attacker = caster,
      damage = self:GetAbilityDamage(),
      damage_type = self:GetAbilityDamageType(),
      damage_flags = DOTA_DAMAGE_FLAG_NONE,
      ability  = self
    })
  end
end

function pangolier_r:GetCastRange(vLocation, hTarget)
  return self:GetSpecialValueFor("distance")
end
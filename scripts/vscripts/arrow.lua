arrow = class({})
LinkLuaModifier("arrow_proj_modifier", LUA_MODIFIER_MOTION_NONE)

require("constants")
--require("task")
require("brew_projectile")

function arrow:OnSpellStart()
  local caster = self:GetCaster()
  
  local cursorPt = self:GetCursorPosition()
  local casterPt = caster:GetAbsOrigin()

  local direction = cursorPt - casterPt
  direction = direction:Normalized()

  local speed = self:GetSpecialValueFor("speed")

  local projID = BrewProjectile:CreateLinearProjectile({
    owner = caster,
    ability = self,
    speed = speed,
    direction = direction,
    spawnOrigin = caster:GetAbsOrigin(),
    radius = 256,
    maxDistance = 2000,
    deleteOnOwnerKilled = true,
    providesVision = true,
    visionRadius = 350,
    unitTargetType = DOTA_UNIT_TARGET_HERO
  })
  
  local projUnit = BrewProjectile:GetProjectilteUnit(projID)
  if projUnit ~= nil then
    projUnit:AddNewModifier(projUnit, self, "arrow_proj_modifier", {})
  end

  EmitSoundOn("Hero_Mirana.ArrowCast", caster)
end


function arrow:OnBrewProjectileHit(hTarget, vLocation)
 
  if hTarget ~= nil then
    print("hit target:" .. hTarget:GetName())
    ApplyDamage({
      victim = hTarget,
      attacker = self:GetCaster(),
      damage = self:GetAbilityDamage(),
      damage_type = self:GetAbilityDamageType(),
      ability = self
    })

    EmitSoundOn("Hero_Mirana.ArrowImpact", hTarget)
  end

  return true
end

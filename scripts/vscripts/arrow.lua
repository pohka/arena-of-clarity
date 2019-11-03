arrow = class({})

require("constants")
--require("task")
require("brew_projectile")

function arrow:OnSpellStart()
  local caster = self:GetCaster()
  
  local cursorPt = self:GetCursorPosition()
  local casterPt = caster:GetAbsOrigin()

  local direction = cursorPt - casterPt
  direction.z = 0
  direction = direction:Normalized()

  local speed = self:GetSpecialValueFor("speed")

  local projID = BrewProjectile:CreateLinearProjectile({
    owner = caster,
    ability = self,
    speed = speed,
    direction = direction,
    spawnOrigin = caster:GetAbsOrigin(),
    radius = 64,
    maxDistance = 5000,
    deleteOnOwnerKilled = true,
    providesVision = true,
    visionRadius = 350,
    unitTargetType = DOTA_UNIT_TARGET_HERO,
    effect = "particles/econ/items/omniknight/omni_ti8_head/omniknight_repel_buff_ti8_body_glow.vpcf",
    canBounce = true,
    maxDuration = 8.0
  })

  caster:EmitSound("Hero_Mirana.ArrowCast")
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

    hTarget:EmitSound("Hero_Mirana.ArrowImpact")
  end

  return true
end

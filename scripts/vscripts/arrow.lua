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

  local effect = "particles/disruptor_ti8_immortal_thunder_strike_buff_red.vpcf"
  if caster:GetTeam() == 	DOTA_TEAM_GOODGUYS then
    effect = "particles/econ/items/disruptor/disruptor_ti8_immortal_weapon/disruptor_ti8_immortal_thunder_strike_buff.vpcf"
  end

  local projID = BrewProjectile:CreateLinearProjectile({
    owner = caster,
    ability = self,
    speed = speed,
    direction = direction,
    spawnOrigin = caster:GetAbsOrigin(),
    radius = 64,
 --   maxDistance = 5000,
    deleteOnOwnerKilled = true,
    providesVision = true,
    visionRadius = 350,
    unitTargetType = DOTA_UNIT_TARGET_HERO,
    effect = effect,
    canBounce = true,
    maxDuration = 5.0,
    groundHeight = 40
  })

  caster:MoveToPosition(caster:GetAbsOrigin() + direction)

  caster:EmitSound("Hero_BountyHunter.Shuriken")
end


function arrow:OnBrewProjectileHit(hTarget, vLocation)
 
  if hTarget ~= nil then
    ApplyDamage({
      victim = hTarget,
      attacker = self:GetCaster(),
      damage = self:GetAbilityDamage(),
      damage_type = self:GetAbilityDamageType(),
      ability = self
    })

    local fxIndex = ParticleManager:CreateParticle(
      "particles/econ/items/tiny/tiny_prestige/tiny_prestige_lvl4_death_embers.vpcf",
      PATTACH_ABSORIGIN,
      hTarget
    )

    hTarget:EmitSound("BodyImpact_Common.Giant")
  end

  return true
end

function arrow:OnBrewProjectileHitWall(projID)
  local projUnit = BrewProjectile:GetProjectileUnit(projID)
  if projUnit ~= nil then
    EmitSoundOnLocationWithCaster(
      projUnit:GetAbsOrigin(),
      "Hero_BountyHunter.Shuriken.Impact",
      projUnit
    )
  end
end

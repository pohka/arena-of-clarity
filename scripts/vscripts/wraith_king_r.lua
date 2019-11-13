wraith_king_r = class({})

require("abil_helper")

function wraith_king_r:GetGesture()
  return ACT_DOTA_CAST_ABILITY_3
end

function wraith_king_r:OnOwnerSpawned()
  self:GetCaster():RemoveGesture(ACT_DOTA_CAST_ABILITY_3)
end

function wraith_king_r:OnSpellStart()
  local caster = self:GetCaster()
  caster:StartGestureWithPlaybackRate(self:GetGesture(), 1)
  local speed = self:GetSpecialValueFor("projectile_speed")
  local direction = AbilHelper:GetPointDirection(self)
  local angles = { 0, 45, 90 }
  local count = #angles - 1
  for i=-count, count do
    local dir = direction
    local index = math.abs(i) + 1
    local sign = 1
    if i < 0 then
      sign = -1
    end
    local angle = angles[index] * sign
    if angle ~= 0 then
      dir = vmath:RotateAround(dir, Vector(0,0,0), angle)
    end


    local projID = BrewProjectile:CreateLinearProjectile({
      owner = caster,
      ability = self,
      speed = speed,
      direction = dir,
      spawnOrigin = caster:GetAbsOrigin(),
      radius = 64,
     -- maxDistance = 5000,
      deleteOnOwnerKilled = false,
      providesVision = true,
      visionRadius = 350,
      unitTargetType = DOTA_UNIT_TARGET_HERO,
      effect = "particles/econ/items/disruptor/disruptor_ti8_immortal_weapon/disruptor_ti8_immortal_thunder_strike_buff.vpcf",
      canBounce = true,
      maxDuration = 8.0,
      groundHeight = 40
    })
  end

  EmitSoundOn("Hero_SkeletonKing.Reincarnate.Stinger", caster)
end

function wraith_king_r:OnBrewProjectileHit(hTarget, vLocation)
  if hTarget ~= nil then
    ApplyDamage({
      victim = hTarget,
      attacker = self:GetCaster(),
      damage = self:GetAbilityDamage(),
      damage_type = self:GetAbilityDamageType(),
      damage_flags = DOTA_DAMAGE_FLAG_NONE,
      ability  = self
    })

    hTarget:EmitSound("Hero_SkeletonKing.Hellfire_BlastImpact")
  end
end

function wraith_king_r:GetAbilityType()
  return DOTA_ABILITY_TYPE_ULTIMATE
end

function wraith_king_r:GetCastRange()
	return self:GetSpecialValueFor("radius")
end

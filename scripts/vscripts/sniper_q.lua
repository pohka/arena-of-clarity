sniper_q = class({})

require("abil_helper")
require("vmath")

function sniper_q:OnSpellStart()
  local direction = AbilHelper:GetPointDirection(self)
  local caster = self:GetCaster()
  local projCount = 3
  local angle = 30
  for i=1, projCount do
    local dir = direction
    if i == 1 then
      dir = vmath:RotateAround(dir, Vector(0,0,0), -angle)
    elseif i == 3 then
      dir = vmath:RotateAround(dir, Vector(0,0,0), angle)
    end


    BrewProjectile:CreateLinearProjectile({
      owner = caster,
      ability = self,
      speed = self:GetSpecialValueFor("projectile_speed"),
      direction = dir,
      spawnOrigin = caster:GetAbsOrigin(),
      radius = 32,
      effect = "particles/units/heroes/hero_tinker/tinker_rockets_arrow.vpcf",
      deleteOnHit = true,
      deleteOnOwnerKilled = false,
      deleteOnHitWall = true,
      maxDuration = 4.0,
      maxDistance = self:GetSpecialValueFor("max_range"),
      unitTargetType = DOTA_UNIT_TARGET_HERO
    })
  end

  EmitSoundOnLocationWithCaster(caster:GetAbsOrigin(), "Hero_Tinker.Heat-Seeking_Missile", caster)
end

function sniper_q:OnBrewProjectileHit(hTarget, hProjectile)
  if hTarget ~= nil then
    ApplyDamage({
      victim = hTarget,
      attacker = self:GetCaster(),
      damage = self:GetAbilityDamage(),
      damage_type = self:GetAbilityDamageType(),
      ability = self
    })

    EmitSoundOnLocationWithCaster(hTarget:GetAbsOrigin(), "Hero_Tinker.Heat-Seeking_Missile.Impact", self:GetCaster())
  end
end

function sniper_q:OnBrewProjectileHitWall(projectileID)
  local projUnit = BrewProjectile:GetProjectileUnit(projectileID)
  if projUnit ~= nil then
    EmitSoundOnLocationWithCaster(projUnit:GetAbsOrigin(), "Hero_Tinker.Heat-Seeking_Missile.Impact", self:GetCaster())
  end
  --EmitSoundOnLocationWithCaster(hTarget:GetAbsOrigin(), "Hero_Tinker.Heat-Seeking_Missile.Impact", caster)
end
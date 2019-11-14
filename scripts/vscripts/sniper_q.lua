sniper_q = class({})

require("abil_helper")
require("vmath")

function sniper_q:OnSpellStart()
  local direction = AbilHelper:GetPointDirection(self)
  local caster = self:GetCaster()

  if self.projGroups == nil then
    self.projGroups = {}
  end

  local projCount = 3
  local angle = 25
  local ids = {}

  --keep track of the entities hit by this group
  --only allowing 1 projectile hit per group
  local groupID = BrewProjectile:NextGroupID()
  self.projGroups[groupID] = {}

  for i=1, projCount do
    local dir = direction
    if i == 1 then
      dir = vmath:RotateAround(dir, Vector(0,0,0), -angle)
    elseif i == 3 then
      dir = vmath:RotateAround(dir, Vector(0,0,0), angle)
    end


    local projID = BrewProjectile:CreateLinearProjectile({
      owner = caster,
      ability = self,
      speed = self:GetSpecialValueFor("projectile_speed"),
      direction = dir,
      spawnOrigin = caster:GetAbsOrigin(),
      radius = 50,
      effect = "particles/units/heroes/hero_tinker/tinker_rockets_arrow.vpcf",
      deleteOnHit = true,
      deleteOnOwnerKilled = false,
      deleteOnHitWall = true,
      maxDuration = 4.0,
      maxDistance = self:GetSpecialValueFor("max_range"),
      unitTargetType = DOTA_UNIT_TARGET_HERO,
      groupID = groupID
    })
    

    local projInfo = BrewProjectile:GetProjectileInfo(projID)
    if projInfo ~= nil then
      local up = Vector(0,0,1)
      local right = up:Cross(dir)
      ParticleManager:SetParticleControlOrientation(projInfo.particleIndex, 0, dir, right, up)
    end
  end

  EmitSoundOnLocationWithCaster(caster:GetAbsOrigin(), "Hero_Tinker.Heat-Seeking_Missile", caster)
end

function sniper_q:OnBrewProjectileHit(hTarget, hProjectile)
  if hTarget ~= nil then

    local projID = hProjectile:GetProjectileID()
    local info = BrewProjectile:GetProjectileInfo(projID)
    if info ~= nil then
      local hitEnts = self.projGroups[info.groupID]
      local targetEntindex = hTarget:entindex()

     --check if one of the projectiles in this group has hit their target already
      local hasAlreadyHit = false
      for i=1, #hitEnts do
        if hitEnts[i] == targetEntindex then
          hasAlreadyHit = true
          break
        end
      end

      if hasAlreadyHit == false then
        table.insert(self.projGroups[info.groupID], targetEntindex)

        ApplyDamage({
          victim = hTarget,
          attacker = self:GetCaster(),
          damage = self:GetAbilityDamage(),
          damage_type = self:GetAbilityDamageType(),
          ability = self
        })

        EmitSoundOnLocationWithCaster(hTarget:GetAbsOrigin(), "Hero_Tinker.Heat-Seeking_Missile.Impact", self:GetCaster())

        return true
      end
    end
  end
  return false
end

function sniper_q:OnBrewProjectileHitWall(projectileID)
  local projUnit = BrewProjectile:GetProjectileUnit(projectileID)
  if projUnit ~= nil then
    EmitSoundOnLocationWithCaster(projUnit:GetAbsOrigin(), "Hero_Tinker.Heat-Seeking_Missile.Impact", self:GetCaster())
  end
end

function sniper_q:AbilityClear()
  if self.projGroups ~= nil then
    self.projGroups = {}
  end
end
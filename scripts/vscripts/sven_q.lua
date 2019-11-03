sven_q = class({})

_G.HIT_PROJECTILE = 0
_G.HIT_HERO = 0

require("brew_projectile")

function sven_q:OnSpellStart()
  local caster = self:GetCaster()
  local custorPos = self:GetCursorPosition()
  local direction = custorPos - caster:GetAbsOrigin()
  direction.z = 0
  direction = direction:Normalized()

  if self.hitData == nil then
    self.hitData = {}
    self.counter = 0
  end
  
  local projID = BrewProjectile:CreateLinearProjectile({
    owner = caster,
    ability = self,
    speed = self:GetSpecialValueFor("projectile_speed"),
    direction = direction,
    spawnOrigin = caster:GetAbsOrigin(),
    radius = 100,
    effect = "particles/items3_fx/lotus_orb_shield.vpcf",
    deleteOnHit = true,
    deleteOnOwnerKilled = false,
    maxDuration = 2.0,
    projectileFlags = PROJECTILE_FLAG_OTHERS_CANT_DISABLE
  })



  --local target = self:GetCursorTarget()

  --if target ~= nil then
    -- BrewProjectile:CreateTrackingProjectile({
    --   target = target,
    --   owner = caster,
    --   ability = self,
    --   effect = "particles/items3_fx/lotus_orb_shield.vpcf",
    --   --attachType = PATTACH_ABSORIGIN_FOLLOW,
    --   speed = self:GetSpecialValueFor("projectile_speed"),
    --  -- radius = 64, --optional (default = 32)
    --   isDodgeable = true,
    --   maxDuration = 10.0,
    --   providesVision = false,
    --   --visionRadius = 400,
    --   --groundHeight, --optional (default = 100)
    --   deleteOnOwnerKilled = true,
    --   spawnOrigin = caster:GetAbsOrigin()
    -- })

   -- caster:EmitSound("Hero_Sven.StormBolt")
  --end


end

function sven_q:OnBrewProjectileHit(hTarget, hProjectile)
  local caster = self:GetCaster()
  local teamID = caster:GetTeam()

  if hTarget ~= nil then
    print("hTarget:", hTarget:GetName())
    if hTarget:IsHero() then
      ApplyDamage({
        victim = hTarget,
        attacker = caster,
        damage = self:GetAbilityDamage(),
        damage_type = self:GetAbilityDamageType(),
        ability = self
      })
      EmitSoundOnLocationWithCaster(hTarget:GetAbsOrigin(), "Hero_Sven.StormBoltImpact", caster)
    elseif hTarget:IsProjectile() then

      local projID = hTarget:GetProjectileID()
      local targetInfo = BrewProjectile:GetProjectileInfo(projID)
      
      --if hit projectile can be disabled by others
      local flagCheck = (targetInfo.projectileFlags ~= PROJECTILE_FLAG_OTHERS_CANT_DISABLE)
      if flagCheck then
        EmitSoundOnLocationWithCaster(hTarget:GetAbsOrigin(), "Hero_Sven.StormBoltImpact", caster)
        
        --disable hit projectile
        local targetProjAbil = hTarget:GetAbilityByIndex(PROJECTILE_ABIL_INDEX)
        targetProjAbil:SetIsDisabled(true)

        local selfProjAbil = hProjectile:GetAbilityByIndex(PROJECTILE_ABIL_INDEX)
        print("selfProjAil:", selfProjAbil)
        selfProjAbil:SetIsDisabled(true)

        --move this projectile to projectile hit
        hProjectile:SetAbsOrigin(hTarget:GetAbsOrigin())

        --store hit data, to be used when projectile is destroyed
        local hit = {
          type = HIT_PROJECTILE, --type of hit data
          hTargetEntIndex = hTarget:entindex(), --entindex of target hit
          projectileID = selfProjAbil:GetProjectileID() --id of the projectile belonging to this ability
        }
        local i = self.counter
        self.hitData[i] = hit
        self.counter = self.counter + 1
      end

      return false
    end
  end

  return true
end

function sven_q:OnBrewProjectileDestroyed(projectileID)
  --release any projectiles that have been disabled
  for k,v in pairs(self.hitData) do
    if projectileID == v.projectileID then
      if v.type == HIT_PROJECTILE then
        local hTarget = EntIndexToHScript(v.hTargetEntIndex)
        
        if hTarget ~= nil then
          if hTarget:IsProjectile() then
            local abil = hTarget:GetAbilityByIndex(PROJECTILE_ABIL_INDEX)
            abil:SetIsDisabled(false)
          end
        end
      end

      self.hitData[k] = nil
    end
  end
end


function sven_q:GetAOERadius()
	return self:GetSpecialValueFor("aoe_radius")
end

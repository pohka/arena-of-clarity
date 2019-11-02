sven_q = class({})

require("brew_projectile")

function sven_q:OnSpellStart()
  local caster = self:GetCaster()
  local custorPos = self:GetCursorPosition()
  local direction = custorPos - caster:GetAbsOrigin()
  direction.z = 0
  direction = direction:Normalized()
  
  BrewProjectile:CreateLinearProjectile({
    owner = caster,
    ability = self,
    speed = self:GetSpecialValueFor("projectile_speed"),
    direction = direction,
    spawnOrigin = caster:GetAbsOrigin(),
    radius = 100,
    effect = "particles/items3_fx/lotus_orb_shield.vpcf",
    deleteOnHit = true,
    deleteOnOwnerKilled = false,
    maxDuration = 5.0
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

function sven_q:OnBrewProjectileHit(hTarget, vLocation)
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
    else
      if hTarget:IsProjectile() then
        EmitSoundOnLocationWithCaster(hTarget:GetAbsOrigin(), "Hero_Sven.StormBoltImpact", caster)
        print("hit projectile", hTarget:GetProjectileID())
        local projID = hTarget:GetProjectileID()
        BrewProjectile:RemoveProjectile(projID)
      end
    end
    --find all enemy units in radius
    -- local unitsHit = FindUnitsInRadius(
    --   teamID,
    --   hTarget:GetAbsOrigin(),
    --   nil,
    --   self:GetSpecialValueFor("aoe"),
    --   DOTA_UNIT_TARGET_TEAM_ENEMY,
    --   DOTA_UNIT_TARGET_ALL,
    --   DOTA_UNIT_TARGET_FLAG_NONE,
    --   FIND_ANY_ORDER,
    --   false
    -- )

    -- local damage = self:GetAbilityDamage()
    -- local damageType = self:GetAbilityDamageType()

    -- --apply damage to all
    -- for _,unit in pairs(unitsHit) do
      
    --   end
    -- end
    
    --hTarget:EmitSound("Hero_Sven.StormBoltImpact")
  end
end


function sven_q:GetAOERadius()
	return self:GetSpecialValueFor("aoe_radius")
end

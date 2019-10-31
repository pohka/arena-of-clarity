sven_q = class({})

require("brew_projectile")

function sven_q:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  if target ~= nil then
    BrewProjectile:CreateTrackingProjectile({
      target = target,
      owner = caster,
      ability = self,
      effect = "particles/items3_fx/lotus_orb_shield.vpcf",
      --attachType = PATTACH_ABSORIGIN_FOLLOW,
      speed = self:GetSpecialValueFor("projectile_speed"),
     -- radius = 64, --optional (default = 32)
      isDodgeable = true,
      maxDuration = 10.0,
      providesVision = false,
      --visionRadius = 400,
      --groundHeight, --optional (default = 100)
      deleteOnOwnerKilled = true,
      spawnOrigin = caster:GetAbsOrigin()
    })

    caster:EmitSound("Hero_Sven.StormBolt")
  end
end

function sven_q:OnBewProjectileHit(hTarget, vLocation)
  local caster = self:GetCaster()
  local teamID = caster:GetTeam()

  if hTarget ~= nil then
    --find all enemy units in radius
    local unitsHit = FindUnitsInRadius(
      teamID,
      hTarget:GetAbsOrigin(),
      nil,
      self:GetSpecialValueFor("aoe"),
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_ALL,
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_ANY_ORDER,
      false
    )

    local damage = self:GetAbilityDamage()
    local damageType = self:GetAbilityDamageType()

    --apply damage to all
    for _,unit in pairs(unitsHit) do
      ApplyDamage({
        victim = unit,
        attacker = caster,
        damage = damage,
        damage_type = damageType,
        ability = self
      })
    end
    
    hTarget:EmitSound("Hero_Sven.StormBoltImpact")
  end
end


function sven_q:GetAOERadius()
	return self:GetSpecialValueFor("aoe_radius")
end

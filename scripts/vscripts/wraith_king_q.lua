wraith_king_q = class({})

require("brew_projectile")

function wraith_king_q:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  if target ~= nil then
    BrewProjectile:CreateTrackingProjectile({
      target = target,
      owner = caster,
      ability = self,
      effect = "particles/units/heroes/hero_ember_spirit/ember_spirit_remnant_dash_rubick.vpcf",
      --attachType = PATTACH_ABSORIGIN_FOLLOW,
      speed = self:GetSpecialValueFor("projectile_speed"),
     -- radius = 64, --optional (default = 32)
      isDodgeable = true,
      maxDuration = 10.0,
      providesVision = false,
      visionRadius = 400,
      --groundHeight, --optional (default = 100)
      deleteOnOwnerKilled = true,
      spawnOrigin = caster:GetAbsOrigin()
    })

    caster:EmitSound("Hero_SkeletonKing.Hellfire_Blast")
  end
end

function wraith_king_q:OnBrewProjectileHit(hTarget, vLocation)
  if hTarget ~= nil then
    print("on target hit:", hTarget:GetName())
    local damageTable = {
      victim = hTarget,
      attacker = self:GetCaster(),
      damage = self:GetAbilityDamage(),
      damage_type = self:GetAbilityDamageType(),
      damage_flags = DOTA_DAMAGE_FLAG_NONE, --Optional.
      ability = self, --Optional.
    }
    
    ApplyDamage(damageTable)

    hTarget:EmitSound("Hero_SkeletonKing.Hellfire_BlastImpact")
  end
end

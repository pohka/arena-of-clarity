arrow = class({})

require("constants")


function arrow:OnSpellStart()
  local caster = self:GetCaster()
  --A Liner Projectile must have a table with projectile info
  
  local cursorPt = self:GetCursorPosition()
  local casterPt = caster:GetAbsOrigin()

  local direction = cursorPt - casterPt
  direction = direction:Normalized()

  local speed = self:GetSpecialValueFor("speed")

	local info = 
	{
		Ability = self,
    EffectName = "particles/econ/items/mirana/mirana_crescent_arrow/mirana_spell_crescent_arrow.vpcf", --particle effect
    vSpawnOrigin = caster:GetAbsOrigin(),
    fDistance = self:GetSpecialValueFor("max_distance"),
    fStartRadius = 64,
    fEndRadius = 64,
    Source = caster,
    bHasFrontalCone = true,
    bReplaceExisting = false,
    iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
    iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
    iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    fExpireTime = GameRules:GetGameTime() + 10.0,
		bDeleteOnHit = true,
		vVelocity = direction * speed,
		bProvidesVision = true,
		iVisionRadius = self:GetSpecialValueFor("vision_radius"),
		iVisionTeamNumber = caster:GetTeamNumber()
  }
  

  ProjectileManager:CreateLinearProjectile(info)

  EmitSoundOn("Hero_Mirana.ArrowCast", caster)
end

function arrow:OnProjectileHit(hTarget, vLocation)
 
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

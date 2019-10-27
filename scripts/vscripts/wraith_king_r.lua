wraith_king_r = class({})

function wraith_king_r:OnUpgrade()
  self.gesture = ACT_DOTA_ATTACK_EVENT
end

function wraith_king_r:OnAbilityPhaseStart()
  local caster = self:GetCaster()
  EmitSoundOn("Hero_SkeletonKing.Reincarnate.Stinger", caster)
  caster:StartGestureWithPlaybackRate(self.gesture, 1.6)
  return true
end

function wraith_king_r:OnAbilityPhaseInterrupted()
  self:GetCaster():RemoveGesture(self.gesture)
end

function wraith_king_r:OnOwnerSpawned()
  self:GetCaster():RemoveGesture(self.gesture)
end

function wraith_king_r:OnSpellStart()
  local caster = self:GetCaster()
  local radius = self:GetSpecialValueFor("radius")
  
  local units = FindUnitsInRadius(
    caster:GetTeam(),
    caster:GetAbsOrigin(), 
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_ALL,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  for i=1, #units do
    local info = 
    {
      Target = units[i],
      Source = caster,
      Ability = self,	
      EffectName = "particles/units/heroes/hero_skeletonking/skeletonking_hellfireblast.vpcf",
      iSourceAttachment = PATTACH_ABSORIGIN,
      iMoveSpeed = self:GetSpecialValueFor("projectile_speed"),
      bDodgeable = true,
      flExpireTime = GameRules:GetGameTime() + 10, 
      bProvidesVision = true,
      iVisionRadius = 300
    }
    projectile = ProjectileManager:CreateTrackingProjectile(info)
  end

  caster:RemoveGesture(self.gesture)
end

function wraith_king_r:OnProjectileHit(hTarget, vLocation)
  if hTarget ~= nil then
    ApplyDamage({
      victim = hTarget,
      attacker = self:GetCaster(),
      damage = self:GetAbilityDamage(),
      damage_type = self:GetAbilityDamageType(),
      damage_flags = DOTA_DAMAGE_FLAG_NONE,
      ability  = self
    })

    EmitSoundOn("Hero_SkeletonKing.Hellfire_BlastImpact", hTarget)
  end
end

function wraith_king_r:GetAbilityType()
  return DOTA_ABILITY_TYPE_ULTIMATE
end

function wraith_king_r:GetCastRange()
	return self:GetSpecialValueFor("radius")
end

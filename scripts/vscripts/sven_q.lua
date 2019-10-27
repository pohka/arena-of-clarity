sven_q = class({})

function sven_q:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  if target ~= nil then
    local info = 
    {
      Target = target,
      Source = caster,
      Ability = self,	
      EffectName = "particles/units/heroes/hero_sven/sven_spell_storm_bolt.vpcf",
      iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_2,
      iMoveSpeed = self:GetSpecialValueFor("projectile_speed"),
      bDodgeable = true,
      flExpireTime = GameRules:GetGameTime() + 10, 
      bProvidesVision = false
      --iVisionRadius = 400,
    }
    ProjectileManager:CreateTrackingProjectile(info)
    EmitSoundOn( "Hero_Sven.StormBolt", self:GetCaster() )
  end
end

function sven_q:OnProjectileHit(hTarget, vLocation)
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
    
    EmitSoundOn( "Hero_Sven.StormBoltImpact", hTarget )
  end
end


function sven_q:GetAOERadius()
	return self:GetSpecialValueFor("aoe_radius")
end

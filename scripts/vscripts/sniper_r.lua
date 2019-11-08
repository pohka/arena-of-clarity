sniper_r = class({})

require("abil_helper")

function sniper_r:OnSpellStart()
  local direction = AbilHelper:GetPointDirection(self)
  local caster = self:GetCaster()
  self.path_start = caster:GetAbsOrigin()
  self.path_end = caster:GetAbsOrigin()
  self.path_width = self:GetSpecialValueFor("path_width")

  
  local projID = BrewProjectile:CreateLinearProjectile({
    owner = caster,
    ability = self,
    speed = self:GetSpecialValueFor("projectile_speed"),
    direction = direction,
    spawnOrigin = caster:GetAbsOrigin(),
    radius = 64,
    effect = "particles/econ/courier/courier_trail_lava/courier_trail_lava_model_b.vpcf",
    attachType = PATTACH_OVERHEAD_FOLLOW,
    deleteOnHit = false,
    deleteOnOwnerKilled = false,
    deleteOnHitWall = false,
    maxDuration = 10.0,
    groundHeight = -40,
    maxDistance = self:GetSpecialValueFor("max_range"),
    unitTargetType = DOTA_UNIT_TARGET_HERO,
    model = "models/heroes/gyro/gyro_missile.vmdl"
  })

  local unit = BrewProjectile:GetProjectileUnit(projID)
  
end

function sniper_r:OnBrewProjectileHit(hTarget, hProjectile)
  --local projUnit = BrewProjectile:GetProjectileUnit(projectileID)
  local id = hProjectile:GetProjectileID()
  local proj = BrewProjectile:GetProjectileInfo(id)
  for k,v in pairs(proj) do print(k,v) end print("-----")
  if hTarget ~= nil then
    EmitSoundOnLocationWithCaster(hTarget:GetAbsOrigin(), "Hero_Tinker.Heat-Seeking_Missile.Impact", self:GetCaster())
  end
end

function sniper_r:OnBrewProjectileThink(projectileID)
  local tickRate = 0.33
  local projUnit = BrewProjectile:GetProjectileUnit(projectileID)
  --local proj = BrewProjectile:GetProjectileInfo(projectileID)
  if projUnit ~= nil then
    local caster = self:GetCaster()
    self.path_end = projUnit:GetAbsOrigin()

    --find units in path
    local units = FindUnitsInLine(
      caster:GetTeam(),
      self.path_start,
      self.path_end,
      caster,
      self.path_width,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_HERO,
      DOTA_UNIT_TARGET_FLAG_NONE
    )

    --apply damage
    for _,unit in pairs(units) do
      ApplyDamage({
        victim = unit,
        attacker = caster,
        damage = 1,
        damage_type = DAMAGE_TYPE_PURE,
        ability = self
      })
    end
  end
  return tickRate
end
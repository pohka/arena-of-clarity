sniper_r = class({})

require("abil_helper")
require("game_time")
require("task")
require("query")


function sniper_r:OnSpellStart()
  self:AbilityClear()
  local direction = AbilHelper:GetPointDirection(self)
  local caster = self:GetCaster()
  self.path_start = caster:GetAbsOrigin()
  self.path_end = caster:GetAbsOrigin()
  self.path_width = self:GetSpecialValueFor("path_width")
  self.damageTickRate = 0.33
  self.nextDamageTickTime = GameTime:GetTime() + self.damageTickRate
  local duration = self:GetSpecialValueFor("fire_duration")
  self.tick_rate = 0.06
  self.isProjectileAlive = true
  
  
  local projID = BrewProjectile:CreateLinearProjectile({
    owner = caster,
    ability = self,
    speed = self:GetSpecialValueFor("projectile_speed"),
    direction = direction,
    spawnOrigin = caster:GetAbsOrigin(),
    radius = 64,
    effect = "particles/econ/courier/courier_trail_lava/courier_trail_lava_model_b.vpcf",
    attachType = PATTACH_OVERHEAD_FOLLOW,
    deleteOnHit = true,
    deleteOnOwnerKilled = false,
    deleteOnHitWall = false,
    maxDuration = duration,
    groundHeight = -40,
    maxDistance = self:GetSpecialValueFor("max_range"),
    unitTargetType = DOTA_UNIT_TARGET_HERO,
    model = "models/heroes/gyro/gyro_missile.vmdl"
  })

  self.curProjID = projID

  --thinker params
  local params = {
    caster_entindex = caster:entindex(),
    projID = projID,
    end_time = GameTime:GetTime() + duration,
    tick_rate = self.tick_rate
  }

  local projUnit = BrewProjectile:GetProjectileUnit(projID)
  EmitSoundOn("Hero_Batrider.Firefly.loop", projUnit) --sound following projectile
  EmitSoundOn("Hero_Batrider.Flamebreak", caster) --cast sound
  
  self.taskID = Task:Interval(
    function(kv) --wrapper to call think functin
      local caster = EntIndexToHScript(kv.caster_entindex)
      if caster ~= nil then
        local abil = Query:FindAbilityByName(caster, "sniper_r")
        if abil ~= nil then
          abil:think(kv)
        else
          print("ability not found")
        end
      end

      local now = GameTime:GetTime()
      --end of interval duration
      if now >= kv.end_time then
        self:ClearParticles()
        return -1
      end

      return kv.tick_rate
    end,
    self.tick_rate,
    params
  )
end

--interval think function
function sniper_r:think( kv )
  local projUnit = BrewProjectile:GetProjectileUnit(kv.projID)
  local now = GameTime:GetTime()
  if projUnit ~= nil then
    self.path_end = projUnit:GetAbsOrigin()
  end
  
  local caster = self:GetCaster()
  
  --damage ticks differently to particle effect
  if now >= self.nextDamageTickTime then
    self.nextDamageTickTime = self.nextDamageTickTime + self.damageTickRate

    --find units in path
    local units = Query:FindUnitsInLine(
      caster:GetTeam(),
      self.path_start,
      self.path_end,
      caster,
      self.path_width,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_HERO,
      DOTA_UNIT_TARGET_FLAG_NONE,
      100
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

      EmitSoundOn("Hero_Batrider.Flamebreak.Impact", unit)
    end
  end

  --add a particle effect once each tick
  if self.isProjectileAlive then
    local pID = ParticleManager:CreateParticle(
      "particles/econ/items/batrider/batrider_ti8_immortal_mount/batrider_ti8_immortal_firefly.vpcf",
      PATTACH_CUSTOMORIGIN,
      caster
    )
    ParticleManager:SetParticleControl(pID, 0, self.path_end)
    table.insert(self.particles, pID)
  end
end

function sniper_r:OnBrewProjectileDestroyed(projID)
  self.isProjectileAlive = false
  local projUnit = BrewProjectile:GetProjectileUnit(projID)
  if projUnit ~= nil then
    StopSoundEvent("Hero_Batrider.Firefly.loop", projUnit)
  end
end

function sniper_r:OnBrewProjectileHit(hTarget, hProjectile)
  local id = hProjectile:GetProjectileID()
  local proj = BrewProjectile:GetProjectileInfo(id)
  for k,v in pairs(proj) do print(k,v) end print("-----")
  if hTarget ~= nil then
    ApplyDamage({
      victim = hTarget,
      attacker = self:GetCaster(),
      damage = self:GetAbilityDamage(),
      damage_type = DAMAGE_TYPE_PURE,
      ability = self
    })
    EmitSoundOnLocationWithCaster(hTarget:GetAbsOrigin(), "Hero_Tinker.Heat-Seeking_Missile.Impact", self:GetCaster())
  end
end

--destroys all particles
function sniper_r:ClearParticles()
  if self.particles ~= nil then
    for i=1, #self.particles do
      ParticleManager:DestroyParticle(self.particles[i], true)
    end
  end
  self.particles = {}
end

--cleans up projectiles, tasks and particles (also called the round ends)
function sniper_r:AbilityClear()
  if self.taskID ~= nil then
    Task:Interupt(self.taskID)
    self.taskID = nil
  end
  self:ClearParticles()
  if self.curProjID ~= nil then
    BrewProjectile:RemoveProjectile(self.curProjID)
    self.curProjID = nil
  end
end

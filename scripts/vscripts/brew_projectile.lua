--custom projectile system using dummy units

if BrewProjectile == nil then
 _G.BrewProjectile = class({})
 BrewProjectile.data = {}
 BrewProjectile.counter = 0
 BrewProjectile.lastThinkTime = 0.0
end


require("game_time")
require("task")
require("constants")

function BrewProjectile:init()
  BrewProjectile.lastThinkTime = GameTime:GetTime()
  Task:Interval(BrewProjectile.OnThink, 0.015, {})
  ListenToGameEvent("entity_killed", Dynamic_Wrap(self, "OnUnitKilled"), self)
end

--listen function, called when entity is killed
function BrewProjectile:OnUnitKilled( args )
    -- args:
  -- entindex_inflictor
  -- damagebits
  -- entindex_killed
  -- entindex_attacker
  -- splitscreenplayer
 
 for id, proj in pairs(BrewProjectile.data) do
  if proj.type == PROJECTILE_TYPE_LINEAR then
    --remove all owned linear projectiles if deleteOnOwnerKilled == true
    if proj.deleteOnOwnerKilled and proj.owner ~= nil and proj.owner:entindex() == args.entindex_killed then
      self:RemoveProjectile(id)
    end
  elseif proj.type == PROJECTILE_TYPE_TRACKING then
    local removeIDs = {}
    --remove all owned tracking projectiles if deleteOnOwnerKilled == true
    if proj.deleteOnOwnerKilled and proj.owner ~= nil and proj.owner:entindex() == args.entindex_killed then
      self:RemoveProjectile(id)
    --if target died, remove all tracking projectiles targeting them
    elseif proj.target ~= nil and proj.target:entindex() == args.entindex_killed then
      self:RemoveProjectile(id)
    end
  end
 end
end

--[[
  info table:
  ------------
  owner,
  ability,
  speed,
  direction,
  spawnOrigin,
  radius,
  effect, --particle effect string path
  attachType, --optional (default = PATTACH_ABSORIGIN_FOLLOW)
  deleteOnHit, --optional (default = true)
  deleteOnOwnerKilled, --option (default = false)
  providesVision, --optional (false = default)
  visionRadius, --only used if provides vision is true
  unitTargetTeam, --optional (DOTA_UNIT_TARGET_TEAM_ENEMY = default)
  unitTargetType, --optional (DOTA_UNIT_TARGET_ALL = default)
  unitTargetFlags, --optional (DOTA_UNIT_TARGET_FLAG_NONE = default)
  groundHeight, -- optional (100 = default)
  maxDistance, --optional
  maxDuration --optional
]]
--creates a linear projectile
function BrewProjectile:CreateLinearProjectile(info)
  info.teamID = info.owner:GetTeam()
  local dummy = CreateUnitByName("dummy_unit", info.spawnOrigin, true, nil, nil, info.teamID)

  if info.groundHeight == nil then
    info.groundHeight = 100
  end
  info.spawnOrigin.z = GetGroundHeight(dummy:GetAbsOrigin(), dummy) + info.groundHeight
  dummy:SetAbsOrigin(info.spawnOrigin)

  --attach particle effect
  if info.attachType == nil then
    ParticleManager:CreateParticle(info.effect, PATTACH_ABSORIGIN_FOLLOW, dummy)
  else
    ParticleManager:CreateParticle(info.effect, info.attachType, dummy)
  end
  info.attachType = nil
  
  
  --set default values

  info.entindex = dummy:entindex()
  if info.providesVision ~= nil and info.providesVision == true and info.visionRadius == nil then
    info.visionRadius = 0
  end

  if info.providesVision ~= nil and info.providesVision == true then
    dummy:SetDayTimeVisionRange(info.visionRadius)
  end

  

  if info.unitTargetTeam == nil then
    info.unitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
  end

  if info.unitTargetFlags == nil then
    info.unitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE
  end

  if info.unitTargetType == nil then
    info.unitTargetType = DOTA_UNIT_TARGET_ALL
  end

  if info.deleteOnHit == nil then
    info.deleteOnHit = true
  end


  if info.maxDistance == nil and info.maxDuration == nil then
    info.maxDuration = 10.0
  end

  if info.maxDuration ~= nil then
    info.endTime = GameTime:GetTime() + info.maxDuration
    info.maxDuration = nil
  end

  if info.deleteOnOwnerKilled == nil then
    info.deleteOnOwnerKilled = false
  end

  info.type = PROJECTILE_TYPE_LINEAR

  local id = BrewProjectile.counter
  BrewProjectile.counter = BrewProjectile.counter + 1
  
  self.data[id]  = info
  

  return id
end

--returns the dummy unit for the projectile
function BrewProjectile:GetProjectilteUnit(projectileID)
  local proj = self.data[projectileID]
  if proj ~= nil then
    local unit = EntIndexToHScript(proj.entindex)
    return unit
  end

  return nil
end

--thinker function for handling all of the projectiles each frame
function BrewProjectile:OnThink()
  local now = GameTime:GetTime()
  local delta = now - BrewProjectile.lastThinkTime
  local removedIDs = {}
  for id, proj in pairs(BrewProjectile.data) do
    if proj.endTime ~= nil and now > proj.endTime then
      table.insert(removedIDs, id)
    else
    
      local dummy = EntIndexToHScript(proj.entindex)
      if dummy ~= nil then
        --LINEAR 
        if proj.type == PROJECTILE_TYPE_LINEAR then
          --move projectile dummy
          local pos = dummy:GetAbsOrigin() + (proj.direction * proj.speed * delta)
          pos.z =  GetGroundHeight(pos, dummy) + proj.groundHeight
          dummy:SetAbsOrigin(pos)
          local projZ = pos.z

          --check if reached max distance
          local isRemoved = false
          if proj.maxDistance ~= nil then
            local diff = dummy:GetAbsOrigin() - proj.spawnOrigin
            local curDistanceTraveled = diff:Length2D()
            if curDistanceTraveled > proj.maxDistance then
              table.insert(removedIDs, id)
              isRemoved = true
            end
          end

          if isRemoved == false then
            --check if hit target
            local units = FindUnitsInRadius(
              proj.teamID,
              pos,
              nil,
              proj.radius,
              proj.unitTargetTeam,
              proj.unitTargetType,
              proj.unitTargetFlags,
              FIND_ANY_ORDER,
              false
            )

            local hasFoundTarget = false
            for _,target in pairs(units) do
              if hasFoundTarget == false then
                --check z-axis
                local targetPos = target:GetAbsOrigin()
                if targetPos.z - projZ < 1000 then
                  hasFoundTarget = true
                  
                  if proj.ability.OnBrewProjectileHit ~= nil then
                    proj.ability:OnBrewProjectileHit(target, dummy:GetAbsOrigin())
                  end

                  if proj.deleteOnHit == true then
                    table.insert(removedIDs, id)
                  end
                end
              end
            end
          end

         --TRACKING
        elseif proj.type == PROJECTILE_TYPE_TRACKING then
          local targetPos = proj.target:GetAbsOrigin()
          
          --move dummy
          local direction = targetPos - dummy:GetAbsOrigin()
          direction.z = 0
          direction = direction:Normalized()
          local nextPos = dummy:GetAbsOrigin() + (direction * proj.speed * delta)
          nextPos.z =  GetGroundHeight(nextPos, dummy) + proj.groundHeight
          dummy:SetAbsOrigin(nextPos)

          --check if hitting target
          local dist = (targetPos - nextPos):Length2D()
          if dist < proj.radius then
            if proj.ability.OnBrewProjectileHit ~= nil then
              proj.ability:OnBrewProjectileHit(proj.target, nextPos)
            end

            table.insert(removedIDs, id)
          end
        end
      end
    end
  end

  for i=1, #removedIDs do
    BrewProjectile:RemoveProjectile(removedIDs[i])
  end

  BrewProjectile.lastThinkTime = now
  return 0.015
end

--remove a projectile by id
function BrewProjectile:RemoveProjectile(projectileID)
  local proj = BrewProjectile.data[projectileID]
  if proj ~= nil then
    local dummy = EntIndexToHScript(proj.entindex)
    if dummy ~= nil then
      dummy:AddNoDraw()
      dummy:ForceKill(false)
      dummy:RemoveSelf()
      
      BrewProjectile.data[projectileID] = nil
    end
  end
end

--remove all projectiles
function BrewProjectile:RemoveAllProjectiles()
  for id, proj in pairs(BrewProjectile.data) do
    local entindex = BrewProjectile.data[id].entindex
    local dummy = EntIndexToHScript(entindex)
    if dummy ~= nil then
      dummy:AddNoDraw()
      dummy:ForceKill(false)
      dummy:RemoveSelf()
      BrewProjectile.data[id] = nil
    end
  end
end

--[[
  info table:
  ------------
  target,
  owner,
  ability,
  effect,
  attachType,
  speed,
  radius, --optional (default = 32)
  isDodgeable,
  maxDuration,
  providesVision,
  visionRadius,
  groundHeight, --optional (default = 100)
  deleteOnOwnerKilled,
  spawnOrigin 
]]
--creates a tracking projectile
function BrewProjectile:CreateTrackingProjectile(info)

  local proj = {}
  proj.teamID = info.owner:GetTeam()
  local dummy = CreateUnitByName("dummy_unit", info.spawnOrigin, true, nil, nil, proj.teamID)

  --set z offset
  if info.groundHeight == nil then
    proj.groundHeight = 100
  else
    proj.groundHeight = info.groundHeight
  end
  info.spawnOrigin.z = GetGroundHeight(dummy:GetAbsOrigin(), dummy) + proj.groundHeight
  dummy:SetAbsOrigin(info.spawnOrigin)

   --attach particle effect
  if info.attachType == nil then
    ParticleManager:CreateParticle(info.effect, PATTACH_ABSORIGIN_FOLLOW, dummy)
  else
    ParticleManager:CreateParticle(info.effect, info.attachType, dummy)
  end
  
  proj.entindex = dummy:entindex()
  proj.target = info.target
  proj.owner = info.owner
  proj.ability = info.ability
  proj.speed = info.speed
  proj.isDodgeable = info.isDodgeable
  proj.endTime = GameTime:GetTime() + info.maxDuration
  proj.deleteOnOwnerKilled = info.deleteOnOwnerKilled
  
  if info.radius == nil then
    proj.radius = 32
  else
    proj.radius = info.radius
  end

  if info.providesVision == nil then
    proj.providesVision = false
  else
    proj.providesVision = info.providesVision
  end

  if proj.providesVision and info.visionRadius ~= nil then
    dummy:SetDayTimeVisionRange(info.visionRadius)
  end

  proj.type = PROJECTILE_TYPE_TRACKING
  local id = BrewProjectile.counter
  BrewProjectile.counter = BrewProjectile.counter + 1
  self.data[id] = proj

end

--makes a unit disjoint tracking projectiles that are dodgeable
function BrewProjectile:Dodge(unit)
  local removedIDs = {}
  for id, proj in pairs(self.data) do
    if proj.type == PROJECTILE_TYPE_TRACKING and proj.isDodgeable then
      if proj.target ~= nil and proj.target:entindex() == unit:entindex() then
        table.insert(removedIDs, id)
      end
    end
  end

  for i=1, #removedIDs do
    self:RemoveProjectile(removedIDs[i])
  end
end
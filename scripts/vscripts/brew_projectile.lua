--custom projectile system using dummy units

if BrewProjectile == nil then
 _G.BrewProjectile = class({})
 _G.BrewProjectile.data = {}
 _G.BrewProjectile.counter = 0
 _G.BrewProjectile.lastThinkTime = 0.0
end


require("game_time")
require("task")


function BrewProjectile:init()
  BrewProjectile.lastThinkTime = GameTime:GetTime()
  Task:Interval(BrewProjectile.OnThink, 0.015, {})
  ListenToGameEvent("entity_killed", Dynamic_Wrap(self, "OnUnitKilled"), self)
end

function BrewProjectile:OnUnitKilled( args )
    -- args:
  -- entindex_inflictor
  -- damagebits
  -- entindex_killed
  -- entindex_attacker
  -- splitscreenplayer

 for id, proj in pairs(BrewProjectile.data) do
  if proj.deleteOnOwnerKilled and proj.owner:entindex() == args.entindex_killed then
    self:RemoveProjectile(id)
  end
 end
end

--[[
  owner,
  ability,
  speed,
  direction,
  spawnOrigin,
  radius,
  effect, --particle effect string path
  deleteOnHit, --optional (default is true)
  deleteOnOwnerKilled, --option (default is false)
  providesVision, --optional (false by default)
  visionRadius, --only used if provides vision is true
  unitTargetTeam, --optional (DOTA_UNIT_TARGET_TEAM_ENEMY by default)
  unitTargetType, --optional (DOTA_UNIT_TARGET_ALL by default)
  unitTargetFlags, --optional (DOTA_UNIT_TARGET_FLAG_NONE by default)
  groundHeight, -- optional (100 by default)
  maxDistance, --optional
  maxDuration --optional
]]
function BrewProjectile:CreateLinearProjectile(info)
  info.teamID = info.owner:GetTeam()
  local dummy = CreateUnitByName("dummy_unit", info.spawnOrigin, true, nil, nil, info.teamID)
  ParticleManager:CreateParticle(info.effect, PATTACH_ABSORIGIN_FOLLOW, dummy)
  
  --set default values

  info.entindex = dummy:entindex()
  if info.providesVision ~= nil and info.providesVision == true and info.visionRadius == nil then
    info.visionRadius = 0
  end

  if info.providesVision ~= nil and info.providesVision == true then
    dummy:SetDayTimeVisionRange(info.visionRadius)
  end

  if info.groundHeight == nil then
    info.groundHeight = 100
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

  

  local id = BrewProjectile.counter
  BrewProjectile.counter = BrewProjectile.counter + 1
  
  self.data[id]  = info
  

  return id
end

function BrewProjectile:GetProjectilteUnit(projectileID)
  local proj = self.data[projectileID]
  if proj ~= nil then
    local unit = EntIndexToHScript(proj.entindex)
    return unit
  end

  return nil
end


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
        
      end
    end
  end

  for i=1, #removedIDs do
    BrewProjectile:RemoveProjectile(removedIDs[i])
  end

  BrewProjectile.lastThinkTime = now
  return 0.015
end

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


function BrewProjectile:CreateTrackingProjectile(info)

end
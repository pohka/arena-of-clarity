--[[
  ================================================
  Custom projectile system using dummy units
  ================================================
  Main Features
  --------
  - replacement for linear and tracking projectiles as part of the dota API
  - Destroying projectiles at any time
  - Linear projectiles that bounce off walls
  

  INFO
  ----------
  All NPCs spawned will now have a function called IsProjectile()
  which will return true if its a projectile dummy unit

  All brew projectiles will now have a function called GetProjectileID()
  which then can be used to get projectile unit using 
  BrewProjectile:GetProjectileUnit() --returns the unit handle for the projectile dummy
  BrewProjectile:GetProjectileInfo() -- returns the raw info passed to the projectile

  all projectile dummy units have an ability called brew_projectil_abil
  this ability carries data that can be modified such as the state
  Once you have the dummy unit then you can get the ability using this function:
  local abil = projectileUnit:GetAbilityAtIndex(PROJECTILE_ABIL_INDEX)

  EVENTS
  ----------
  - OnBrewProjectileHit(hTarget, hProjectile)
  OnBrewProjectileHit will trigger once a collision has been entered for a unit target
  hTarget = handle for unit target hit
  hProjectile = handle unit for dummy projectile

  - OnBrewProjectileDestroyed(projectileID)
  Will trigger when the unit projectile is being destroyed
  projectileID = id of projectile being destroyed

  - OnBrewProjectileHitWall()


  - OnBrewProjectileThink(projectileID)
  must return value of interval time between each think
  e.g. return 1 will call the think once every second


  STATES
  -----------
  brew_projectile_abil as some states:
   if isDisabled = true then projectiles will not move or be used for collision
  

  SETUP REQUIREMENTS
  -------------
  - brew projectiles will only work with other brew projectiles and not with normal projectiles in dota api
  - you must have the unit brew_projectile specified in npc_units_custom.txt
  - you must have the abilities for brew_projectile_abil and dummy_unit_ability in npc_abilities_custom.txt


  
  LINEAR PROJECTILES BRIEF
  ----------------------------
  when creating linear projectiles you ca set canBounce = true
  then need to define the wall entity name that it can bounce off and the wall bounding box size
    (see CheckLinearCollisionWithWalls() for more info)
  
  currently only walls with increments of 90 degrees or 45 degrees will work i.e. (0, 45, 90, 135, 180, etc)

  TRACKING PROJECTILES BRIEF
  ----------------------------
  You can remove all types of brew projectiles using BrewProjectile:RemoveProjectile(projectileID)
  You can make a unit dodge a tracking projectiles using BrewProjectile:Dodge(unit)
  dodging will not work if the projectile is set to isDodgeable = false
]]

if BrewProjectile == nil then
 _G.BrewProjectile = class({})
 BrewProjectile.data = {}
 BrewProjectile.counter = 0
 BrewProjectile.lastThinkTime = 0.0

 _G.PROJECTILE_ABIL_INDEX = 1

 _G.PROJECTILE_FLAG_NONE = 0
 _G.PROJECTILE_FLAG_OTHERS_CANT_DISABLE = 1
end


require("game_time")
require("task")
require("constants")
require("vmath")

function BrewProjectile:init()
  BrewProjectile.lastThinkTime = GameTime:GetTime()
  Task:Interval(BrewProjectile.OnThink, 0.015, {})
  ListenToGameEvent("entity_killed", Dynamic_Wrap(self, "OnUnitKilled"), self)
  ListenToGameEvent("npc_spawned", Dynamic_Wrap(self, "OnUnitSpawned"), self)
end

function BrewProjectile:OnUnitSpawned(args) 
  local entH = EntIndexToHScript(args.entindex)
  if entH ~= nil then
    if entH.IsProjectile == nil then
      entH.IsProjectile = function() return false end
    end
  end
end

--[[
  info table:
  spawnOrigin,
  teamID
]]
--this is used to construct other projectiles
function BrewProjectile:CreateBaseProjectileEntity(info)
  local dummy = CreateUnitByName(
    "brew_projectile",
    info.spawnOrigin,
    true,
    nil,
    nil,
    info.teamID
  )


  local id = BrewProjectile.counter
  dummy.GetProjectileID = function() return id end
  dummy.IsProjectile = function() return true end
  
  local abil = dummy:GetAbilityByIndex(PROJECTILE_ABIL_INDEX)
  abil:init(id)

  BrewProjectile.counter = BrewProjectile.counter + 1
  

  --dummy.isDisabled = false
  --dummy:SetIntAttr("isDisabled", 1)
  -- dummy.GetIsDisabled = function()
  --   print("ent:", dummy:GetIntAttr("isDisabled"))
  --   return dummy.isDisabled
  -- end
  -- dummy.SetIsDisabled = function(isDisabled) 
  --   dummy.isDisabled = isDisabled 
  -- end 

  return dummy
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
      BrewProjectile:RemoveProjectile(id)
    end
  elseif proj.type == PROJECTILE_TYPE_TRACKING then
    local removeIDs = {}
    --remove all owned tracking projectiles if deleteOnOwnerKilled == true
    if proj.deleteOnOwnerKilled and proj.owner ~= nil and proj.owner:entindex() == args.entindex_killed then
      BrewProjectile:RemoveProjectile(id)
    --if target died, remove all tracking projectiles targeting them
    elseif proj.target ~= nil and proj.target:entindex() == args.entindex_killed then
      BrewProjectile:RemoveProjectile(id)
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
  direction, --normalized vector
  spawnOrigin,
  radius,
  model, --model name for dummy
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
  maxDuration, --optional (recommended)
  canBounce, --optional (default = false, if set to true it will allow bouncing)
  minTimeBetweenBounces -- optional (default = 100/speed),
  projectileFlags, -- optional (PROJECTILE_FLAG_NONE = default) bitwise flags for exception rules
  deleteOnHitWall, --optional (defaolt = false) will destroy projectile on hitting a wall, then calls OnBrewProjectileHitWall(projectileID)
]]
--creates a linear projectile
function BrewProjectile:CreateLinearProjectile(info)
  info.teamID = info.owner:GetTeam()
  --local dummy = CreateUnitByName("dummy_unit", info.spawnOrigin, true, nil, nil, info.teamID)
 -- dummy.IsProjectile = function() return true end

  local dummy = BrewProjectile:CreateBaseProjectileEntity({
    spawnOrigin = info.spawnOrigin,
    teamID = info.teamID
  })
  dummy:SetForwardVector(info.direction)

  
  if info.model ~= nil then
    dummy:SetModel(info.model)
  end

  
  if info.ability.OnBrewProjectileThink ~= nil then
    info.canThink = true
    info.nextThinkTime = GameTime:GetTime()
  else
    info.canThink = false
  end


  if info.groundHeight == nil then
    info.groundHeight = 100
  end
  info.spawnOrigin.z = GetGroundHeight(dummy:GetAbsOrigin(), dummy) + info.groundHeight
  dummy:SetAbsOrigin(info.spawnOrigin)

  --attach particle effect
  if info.attachType == nil then
    info.particleIndex = ParticleManager:CreateParticle(info.effect, PATTACH_ABSORIGIN_FOLLOW, dummy)
  else
    info.particleIndex = ParticleManager:CreateParticle(info.effect, info.attachType, dummy)
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

  if info.canBounce == nil then
    info.canBounce = false
  end

  info.lastBounceTime = 0.0
  if info.minTimeBetweenBounces == nil then
    info.minTimeBetweenBounces = 100 / info.speed
  end

  info.type = PROJECTILE_TYPE_LINEAR

  info.currentDistance = 0

  if info.projectileFlags == nil then
    info.projectileFlags = PROJECTILE_FLAG_NONE
  end

  if info.deleteOnHitWall == nil then
    info.deleteOnHitWall = false
  end
  
  local id = dummy:GetProjectileID()
  self.data[id]  = info
  

  return id
end

--returns the dummy unit for the projectile
function BrewProjectile:GetProjectileUnit(projectileID)
  local proj = self.data[projectileID]
  if proj ~= nil then
    local unit = EntIndexToHScript(proj.entindex)
    return unit
  end

  return nil
end

--returns the info table for the projectile
--be aware that changing values in this table will update the projectile
function BrewProjectile:GetProjectileInfo(projectileID)
  return self.data[projectileID]
end

--thinker function for handling all of the projectiles each frame
function BrewProjectile:OnThink()
  local now = GameTime:GetTime()
  local delta = now - BrewProjectile.lastThinkTime
  --local removedIDs = {}
  for id, proj in pairs(BrewProjectile.data) do
    if proj.endTime ~= nil and now > proj.endTime then
      --table.insert(removedIDs, id)
      BrewProjectile:RemoveProjectile(id)
    else
    
      local dummy = EntIndexToHScript(proj.entindex)
      if dummy ~= nil then
        local abil = dummy:GetAbilityByIndex(PROJECTILE_ABIL_INDEX)
        --LINEAR 
        if proj.type == PROJECTILE_TYPE_LINEAR then
          BrewProjectile:OnThinkLinear(dummy, id, proj, delta)

        --TRACKING
        elseif proj.type == PROJECTILE_TYPE_TRACKING then
          BrewProjectile:OnThinkTracking(dummy, id, proj, delta)
        end

        if proj.canThink == true and proj.nextThinkTime <= now then
          local result = proj.ability:OnBrewProjectileThink(id)
          if result ~= nil then
            proj.nextThinkTime = proj.nextThinkTime + result
          end
        end
      end
    end
  end

  BrewProjectile.lastThinkTime = now
  return 0.015
end

function BrewProjectile:OnThinkLinear(dummy, id, proj, delta)
  --move projectile dummy
  local pos = dummy:GetAbsOrigin() + (proj.direction * proj.speed * delta)
  pos.z =  GetGroundHeight(pos, dummy) + proj.groundHeight
  local projZ = pos.z

  local abil = dummy:GetAbilityByIndex(PROJECTILE_ABIL_INDEX)
  if abil:GetIsDisabled() == false then
    dummy:SetAbsOrigin(pos)
    local bounceCheck = proj.canBounce and GameTime:GetTime() - proj.lastBounceTime > proj.minTimeBetweenBounces
    if  bounceCheck or proj.deleteOnHitWall then
      BrewProjectile:CheckLinearCollisionWithWalls(dummy, proj, delta, id)
    end

    proj.currentDistance = proj.currentDistance + proj.speed * delta
  end

  --check if reached max distance
  local isRemoved = false
  if proj.maxDistance ~= nil and proj.currentDistance > proj.maxDistance then
    BrewProjectile:RemoveProjectile(id)
    isRemoved = true
  end

  if isRemoved == false and abil:GetIsDisabled() == false then
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

    local zMaxDiff = Z_MAX_DIFF
    

    local hasFoundTarget = false
    for _,target in pairs(units) do
      if hasFoundTarget == false then
        --check z-axis
        local targetPos = target:GetAbsOrigin()
        if targetPos.z - projZ < zMaxDiff then
          hasFoundTarget = true
          
          local isAllowedToDeleteOnHit = true

          if proj.ability.OnBrewProjectileHit ~= nil then
            local res = proj.ability:OnBrewProjectileHit(target, dummy)
            if res ~= nil and res == false then
              isAllowedToDeleteOnHit = res
            end
          end

          if proj.deleteOnHit == true and isAllowedToDeleteOnHit == true then
            --table.insert(removedIDs, id)
            BrewProjectile:RemoveProjectile(id)
          end
        end
      end
    end
  end
end


function BrewProjectile:OnThinkTracking(dummy, id, proj, delta)
  local targetPos = proj.target:GetAbsOrigin()
          
  --move dummy
  local direction = targetPos - dummy:GetAbsOrigin()
  direction.z = 0
  direction = direction:Normalized()
  local nextPos = dummy:GetAbsOrigin() + (direction * proj.speed * delta)
  nextPos.z =  GetGroundHeight(nextPos, dummy) + proj.groundHeight

  local abil = dummy:GetAbilityByIndex(PROJECTILE_ABIL_INDEX)
  if abil ~= nil then
    if abil:GetIsDisabled() == false then
      dummy:SetAbsOrigin(nextPos)

      --check if hitting target
      local dist = (targetPos - nextPos):Length2D()
      if dist < proj.radius then
        if proj.ability.OnBrewProjectileHit ~= nil then
          proj.ability:OnBrewProjectileHit(proj.target, dummy)
        end

        BrewProjectile:RemoveProjectile(id)
      end
    end
  end
end

function BrewProjectile:CheckLinearCollisionWithWalls(dummy, proj, delta, projID)
  local indexes = { 1, 2, 3, 4, 5 ,6 }

  local isDebug = false --set to true to enable debug lines

  if isDebug then
    DebugDrawSphere(dummy:GetAbsOrigin(), Vector(0,255,0), 255, proj.radius, false, delta)
  end
  
  local isRemoved = false
  for i=1, #indexes do
    local name = "wall_" .. indexes[i]
    local wall = Entities:FindByName(nil, name)
    if wall ~= nil then
      local angles = wall:GetAnglesAsVector()
      --print("angles", angles)
      local center = wall:GetAbsOrigin()
      local startingSize = Vector(32,256,128)
      local padding = 32
      local size = startingSize + Vector(padding, padding, 0)
      local minPt = center - size
      local maxPt = center + size

      local color = Vector(0,255,0)

      --rotate the dummy unit so it is axis aligned with wall bounding box
      local pos = vmath:RotateAround(dummy:GetAbsOrigin(), center, -angles.y)

      --true there is collision (checking bounding box in world space)
      if pos.x > minPt.x and pos.x < maxPt.x and pos.y > minPt.y and pos.y < maxPt.y then
        if proj.ability.OnBrewProjectileHitWall ~= nil then
          proj.ability:OnBrewProjectileHitWall(projID)
        end

        --delete on hit wall case
        if proj.deleteOnHitWall then
          BrewProjectile:RemoveProjectile(projID)
          break -- end loop

        --bouncing case
        else

          proj.lastBounceTime = GameTime:GetTime()
          local normal = nil

          -- if indexes[i] == 4 then
          --   print("Impact:")
          --   print("center:", center)
          --   print("rect pts: min:", minPt.x, minPt.y, " max:", maxPt.x, maxPt.y)
          --   print("rotated proj pos:", pos.x, pos.y)
          -- end

          --4 sided reflection (can be buggy at obtuse angles roughly 160-180 degrees)
          -- if pos.y > startingSize.y then
          --   normal = Vector(0, 1, 0)
          -- elseif pos.y < -startingSize.y then
          --   normal = Vector(0, -1, 0)
          -- elseif pos.x < 0 then
          --   normal = Vector(-1, 0, 0)
          -- else
          --   normal = Vector(1, 0, 0)
          -- end

          --2 sided reflection for 90 degree walls
          if pos.x < 0 then
            normal = Vector(-1, 0, 0)
          else
            normal = Vector(1, 0, 0)
          end

          --hack for 45 degree walls
          if angles.y % 90 > 1.0 then
            if pos.x < 0 then
              normal = Vector(0, -1, 0)
            else
              normal = Vector(0, 1, 0)
            end 
          end

          --rotate normal to be axis aligned (probably wrong because of 45 degree hack)
          normal = vmath:RotateAround(normal, Vector(0,0,0), -angles.y)
          --DebugDrawLine(dummy:GetAbsOrigin(), dummy:GetAbsOrigin() + normal * 400, 255, 0, 255, false, 5.0)

          if normal ~= nil then
            if isDebug == true then
              --draw normal (red line)
              DebugDrawLine(dummy:GetAbsOrigin(), dummy:GetAbsOrigin() + normal * 400, 255, 0, 0, false, 5.0)
              --draw in angle (green line)
              DebugDrawLine(dummy:GetAbsOrigin(), dummy:GetAbsOrigin() - proj.direction * 400, 0, 255, 0, false, 5.0)
            end
            local d = proj.direction
            local d_dot_n = d:Dot(normal)
            proj.direction = d - 2 * d_dot_n * normal --reflection formula d-2(d.n)*n

            if isDebug == true then
              --draw out angle (blue line)
              DebugDrawLine(dummy:GetAbsOrigin(), dummy:GetAbsOrigin() + proj.direction * 800, 0, 0, 255, false, 5.0)
              color = Vector(255,0,0)
            end
          end

          if isDebug then
            DebugDrawBoxDirection(center, -size, size, normal, color, 50, 2.0)
          end
        end
      end

      
      
    else
      print("not found:" .. name)
    end
  end
end

--remove a projectile by id
function BrewProjectile:RemoveProjectile(projectileID)
  local proj = BrewProjectile.data[projectileID]
  if proj ~= nil then
    local dummy = EntIndexToHScript(proj.entindex)
    if dummy ~= nil then
      --call event listener function
      if proj.ability.OnBrewProjectileDestroyed ~= nil then
        proj.ability:OnBrewProjectileDestroyed(projectileID)
      end
      
      if proj.particleIndex ~= nil then
        ParticleManager:DestroyParticle(proj.particleIndex, true)
      end
      
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
      --call event listener function
      if proj.ability.OnBrewProjectileDestroyed ~= nil then
        proj.ability:OnBrewProjectileDestroyed(id)
      end

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
  local dummy = BrewProjectile:CreateBaseProjectileEntity({
    spawnOrigin = info.spawnOrigin,
    teamID = proj.teamID
  })
  dummy:SetForwardVector(info.direction)

  if info.model ~= nil then
    dummy:SetModel(info.model)
  end

  
  

  if info.ability.OnBrewProjectileThink ~= nil then
    proj.canThink = true
    proj.nextThinkTime = GameTime:GetTime()
  else
    proj.canThink = false
  end

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
    proj.particleIndex = ParticleManager:CreateParticle(info.effect, PATTACH_ABSORIGIN_FOLLOW, dummy)
  else
    proj.particleIndex = ParticleManager:CreateParticle(info.effect, info.attachType, dummy)
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

  if info.projectileFlags == nil then
    proj.projectileFlags = PROJECTILE_FLAG_NONE
  else
    proj.projectileFlags = info.projectileFlags
  end

  proj.type = PROJECTILE_TYPE_TRACKING

  local id = dummy:GetProjectileID()
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
    BrewProjectile:RemoveProjectile(removedIDs[i])
  end
end
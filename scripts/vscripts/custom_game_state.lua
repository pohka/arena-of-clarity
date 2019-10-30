if CustomGameState == nil then
  _G.CustomGameState = class({})


  _G.STATE_DURATION_WARMUP = 60
  _G.STATE_DURATION_LOOT = 1
  _G.STATE_DURATION_FIGHT = 30
  _G.STATE_DURATION_POST_FIGHT = 3

  _G.STATE_DURATION_WARMUP_TOOLS = 15
  _G.STATE_DURATION_LOOT_TOOLS  = 1
  _G.STATE_DURATION_FIGHT_TOOLS  = 30
  _G.STATE_DURATION_POST_FIGHT_TOOLS  = 3


  _G.ROUNDS_TO_WIN = 10
end



require("camera")
require("constants")
require("game_time")
require("mana_potion_spawner")

function CustomGameState:init()
  if IsServer() then
    CustomNetTables:SetTableValue( "game_state", "state", { 
      value = 0,
      last_change = 0
    })
    CustomNetTables:SetTableValue( "game_state", "round", { value = 0 } )
    CustomNetTables:SetTableValue( "game_state", "score_team_1", { value = 0 } )
    CustomNetTables:SetTableValue( "game_state", "score_team_2", { value = 0 } )
    ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(self, "OnDefaultStateChange"), self)
  end
end

--thinker function
function CustomGameState:OnThink()
  if IsServer() then
    
    local lastStateChangeTime = self:GetLastStateChangeTime()
    local now = GameTime:GetTime()
    local curState = self:GetGameState()

    --check if game should end if there is only players on 1 team
    if curState > GAME_STATE_WARMUP and curState < GAME_STATE_POST_GAME then
      self:CheckConnectedPlayers()
    end

    if curState == GAME_STATE_WARMUP then
      local timeLeft = self:GetStateDuration(GAME_STATE_WARMUP) - now
      if timeLeft <= 0 then
        self:NextRound()
      else
        --warmup msgs
        local secs = math.ceil(timeLeft)
        if secs % 10 == 0 or secs < 4 then
          Say(nil, "Warm up ends in: " .. secs .. "s", true)
        end
      end
    elseif curState == GAME_STATE_LOOT then
      local roundEndTime = lastStateChangeTime + self:GetStateDuration(GAME_STATE_LOOT)
      if now >= roundEndTime then
        self:SetGameState(GAME_STATE_FIGHT)
      end
    elseif curState == GAME_STATE_FIGHT then
      local roundEndTime = lastStateChangeTime + self:GetStateDuration(GAME_STATE_FIGHT)
      if now >= roundEndTime then
        --draw round if players are idle
      end
    elseif curState == GAME_STATE_POST_FIGHT then
      local roundEndTime = lastStateChangeTime + self:GetStateDuration(GAME_STATE_POST_FIGHT)
      if now >= roundEndTime then
        self:NextRound()
      end
    end

    return 1
  end
end

function CustomGameState:GetStateDuration(state)
  if state == nil then
    print("state is nil")
  elseif state < GAME_STATE_WARMUP and state >= GAME_STATE_POST_GAME then
    print("state not valid:" .. state)
    return -1
  end

  --release mode
  if IsInToolsMode() == false or USE_RELEASE_BUILD then
    if state == GAME_STATE_WARMUP then
      return STATE_DURATION_WARMUP
    elseif state ==  GAME_STATE_LOOT then
      return STATE_DURATION_LOOT
    elseif state == GAME_STATE_FIGHT then
      return STATE_DURATION_FIGHT
    elseif state == GAME_STATE_POST_FIGHT then
      return STATE_DURATION_POST_FIGHT
    end
  --tools mode
  else 
    if state == GAME_STATE_WARMUP then
      return STATE_DURATION_WARMUP_TOOLS
    elseif state ==  GAME_STATE_LOOT then
      return STATE_DURATION_LOOT_TOOLS
    elseif state == GAME_STATE_FIGHT then
      return STATE_DURATION_FIGHT_TOOLS
    elseif state == GAME_STATE_POST_FIGHT then
      return STATE_DURATION_POST_FIGHT_TOOLS
    end
  end

  return 0
end

--start thinker when in_progress is reached
function CustomGameState:OnDefaultStateChange()
  if IsServer() then
    if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
      GameRules:GetGameModeEntity():SetThink( "OnThink", self, "GlobalThink", 1.0 )
      ManaPotionSpawner:init()
    end
  end
end

function CustomGameState:GetGameState()
  local table = CustomNetTables:GetTableValue("game_state", "state")
  return table.value
end

function CustomGameState:GetLastStateChangeTime()
  local table = CustomNetTables:GetTableValue("game_state", "state")
  return table.last_change
end

function CustomGameState:GetRound()
  local table = CustomNetTables:GetTableValue("game_state", "round")
  return table.value
end

function CustomGameState:SetGameState( state )
  if IsServer() then
    CustomNetTables:SetTableValue( "game_state", "state", { 
      value = state,
      last_change = GameTime:GetTime()
    })
    CustomGameState:OnGameStateChange( { state = state })
  end
end



function CustomGameState:NextRound()
  if IsServer() then
    local curRoundNum = self:GetRound()

    --trigger end of warm up
    if curRoundNum == 0 then
      self:OnWarmupEnd()
    end

    --set next round
    local nextRoundNum = curRoundNum + 1
    self:SetGameState(GAME_STATE_LOOT)
    CustomNetTables:SetTableValue( "game_state", "round", { value = nextRoundNum })
    local event = {
      round = nextRoundNum
    }
    self:OnNextRound( event )
  end
end

function CustomGameState:OnGameStateChange( )
  --print("state change:" .. self:GetGameState())
end

function CustomGameState:OnNextRound( event )
  if IsServer() then
    self:RespawnAll()
    local str = "Round "  .. event.round .. ": ( " .. self:GetTeamScore(DOTA_TEAM_GOODGUYS) .. "-" .. self:GetTeamScore(DOTA_TEAM_BADGUYS) .. " )"
    Say(nil, str, true)
    print(str)

    self:ClearAllPlayersInventory({
      "item_custom_blink"
    })
    self:DestroyPhysicalItems()
    self:SpawnItems()
    
    
    --CustomProjectileManager:DestroyAll()
  end

  print("Round " .. event.round .. " begin: ".. GameTime:GetTime())
end

function CustomGameState:OnWarmupEnd()
  if IsServer() then
    Say(nil, "Warm up OVER", false)
    --disable default respawning and buyback
    local GameMode = GameRules:GetGameModeEntity()
    GameRules:SetHeroRespawnEnabled(false)
    GameMode:SetFixedRespawnTime(1)
    ListenToGameEvent("entity_killed", Dynamic_Wrap(self, "OnUnitKilled"), self)
    
  end
end

function CustomGameState:OnUnitKilled( args )
  -- args:
  -- entindex_inflictor
  -- damagebits
  -- entindex_killed
  -- entindex_attacker
  -- splitscreenplayer

  if IsServer() then
    local state = self:GetGameState()

    if state == GAME_STATE_FIGHT then
      local killedUnit = EntIndexToHScript(args.entindex_killed)

      if killedUnit ~= nil then
        if killedUnit:IsHero() then
          killedUnit:GetTeamNumber()
          
          --give attacker mana
          local attacker = EntIndexToHScript(args.entindex_attacker)
          if attacker ~= nil then
            attacker:GiveMana(50)

            --refresh all of attacker's items and spells
            for i=0, attacker:GetAbilityCount()-1 do
              local abil = attacker:GetAbilityByIndex(i)
              if abil ~= nil then
                abil:EndCooldown()
              end
            end

            for i=DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
              local item = attacker:GetItemInSlot(i)
              if item ~= nil then
                item:EndCooldown()
              end
            end
          end

          --check for round victory condition
          -- Find all alive unit
          local allUnitsAlive = FindUnitsInRadius(
            killedUnit:GetTeamNumber(),
            Vector(0, 0, 0),
            nil,
            FIND_UNITS_EVERYWHERE,
            DOTA_UNIT_TARGET_TEAM_BOTH,
            DOTA_UNIT_TARGET_ALL,
            DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_ANY_ORDER,
            false)

          --check if more than 1 team is alive
          local lastTeamID = 0
          local hasMoreThanOneTeamAlive = false
          for _,unit in pairs(allUnitsAlive) do
            if unit:IsHero() then
              local teamID = unit:GetTeamNumber()
              if teamID ~= nil then --some units can have no team assigned
                if lastTeamID > 0 and lastTeamID ~= teamID then
                  hasMoreThanOneTeamAlive = true
                end
                lastTeamID = teamID
              end
            end
          end

          if hasMoreThanOneTeamAlive == false then
            self:SetRoundWinner(lastTeamID)
          end
        end
      end
    end
  end
end

function CustomGameState:SetRoundWinner( teamIDWinner )
  if IsServer() then
    --update score if not the warmup round
    local curRoundNum = self:GetRound()
    if curRoundNum > 0 then
      if teamIDWinner == nil then
        print("missing teamIDWinner for round:" .. curRoundNum)
        self:SetGameState(GAME_STATE_POST_FIGHT)
      elseif teamIDWinner >= TEAM_FIRST and teamIDWinner <= TEAM_LAST then
        local curTeamScore = self:GetTeamScore(teamIDWinner)
        local newTeamScore = curTeamScore+1
        local key = "score_team_" .. (teamIDWinner - 1)
        CustomNetTables:SetTableValue( "game_state", key, { value = newTeamScore })

        local teamName = "Left Team"
        if teamIDWinner == DOTA_TEAM_BADGUYS then
          teamName = "Right Team"
        end

        if newTeamScore == ROUNDS_TO_WIN then
          self:SetVictory(teamIDWinner)
        else
          local str = "Round Winner: " .. teamName
          Say(nil, str, true)
          self:SetGameState(GAME_STATE_POST_FIGHT)
        end
      else
        print("invalid teamIDWinner for round:" .. curRoundNum)
        self:SetGameState(GAME_STATE_POST_FIGHT)
      end

      
    end
  end
end

function CustomGameState:GetTeamScore( teamID )
  if teamID >= TEAM_FIRST and teamID <= TEAM_LAST then
    local key = "score_team_" .. (teamID - 1)
    local table = CustomNetTables:GetTableValue("game_state", key)
    return table.value
  end
  return 0
end

function CustomGameState:CheckConnectedPlayers()
  if IsInToolsMode() == false or USE_RELEASE_BUILD then --only run in release mode

    local connectedPlayersCount = {}

    for teamID=TEAM_FIRST, TEAM_LAST do
      --count connected players per team
      connectedPlayersCount[teamID] = 0
      for i=1, PLAYERS_PER_TEAM do
        local playerID = PlayerResource:GetNthPlayerIDOnTeam(teamID, i)
        if PlayerResource:IsValidPlayerID(playerID) then
          local connectionState = PlayerResource:GetConnectionState(playerID)
          if IsInToolsMode() and USE_RELEASE_BUILD == false then
            --1 == bot connected
            if connectionState == DOTA_CONNECTION_STATE_CONNECTED or connectionState == 1 then
              connectedPlayersCount[teamID] = connectedPlayersCount[teamID] + 1
            end
          else
            if connectionState == DOTA_CONNECTION_STATE_CONNECTED then
              connectedPlayersCount[teamID] = connectedPlayersCount[teamID] + 1
            end
          end
        end
      end
    end

    local totalTeamsConnected = 0
    local lastConnectedTeamID = 0
    for teamID=TEAM_FIRST, TEAM_LAST do
      if connectedPlayersCount[teamID] > 0 then
        lastConnectedTeamID = teamID
        totalTeamsConnected = totalTeamsConnected + 1
      end
    end

    if totalTeamsConnected == 1 then
      self:SetVictory(lastConnectedTeamID)
    elseif totalTeamsConnected == 0 then --draw ??
      self:SetVictory(DOTA_TEAM_GOODGUYS)
    end
  end
end

function CustomGameState:RespawnAll()
  local heroTable = {}
  for teamID=TEAM_FIRST, TEAM_LAST do
    for i=1, PLAYERS_PER_TEAM do
      local playerID = PlayerResource:GetNthPlayerIDOnTeam(teamID, i)
      if playerID ~= nil and playerID > -1 then
        local player = PlayerResource:GetPlayer(playerID)
        if player ~= nil then
          local hero = player:GetAssignedHero()
          if hero ~= nil and hero:IsHero() then
            table.insert(heroTable, hero:entindex())
            --kill disconnected players
            local connectionState = PlayerResource:GetConnectionState(playerID)
            --in tools mode, 1 == bot connected
            if IsInToolsMode() and connectionState ~= DOTA_CONNECTION_STATE_CONNECTED and connectionState ~= 1 then 
              if hero:IsAlive() then
                hero:ForceKill()
              end
            elseif IsInToolsMode() == false and connectionState ~= DOTA_CONNECTION_STATE_CONNECTED then
              if hero:IsAlive() then
                hero:ForceKill()
              end
            else
              hero:RespawnHero(false, false)
            end
          end
        end
      end
    end
  end
  

  --delay for facing all heroes forward and center camera
  Task:Delay(
    function(params)
      for i=1, #params do
        local hero = EntIndexToHScript(params[i])
        if hero ~= nil then
          if hero:IsAlive() then
            --point hero forward
            local pos = hero:GetAbsOrigin()
            local dir = Vector(-pos.x, 0, 0)
            dir = dir:Normalized()
            local nextPos = pos + dir
            hero:MoveToPosition(nextPos)
          end
        end
      end

      Camera:FocusHeroForAllPlayers()
  end, 0.04, heroTable)
end

function CustomGameState:SetVictory(teamID)
  self:SetGameState(GAME_STATE_POST_GAME)
  local teamName = "Left Team"
  if teamID == DOTA_TEAM_BADGUYS then
    teamName = "Right Team"
  end
  local victoryMsg = teamName .. " CHAMPIONS"
  GameRules:SetCustomVictoryMessage(victoryMsg)
  GameRules:SetGameWinner(teamID)
end

-- spawns random items of each type in random spawn point
-- the spawn points for each item is unique and all mirrored for each team
function CustomGameState:SpawnItems()
  --table of items to spawn
  local items = {
    "item_boots_tier_",
    "item_armor_tier_"
  }

  --item rarity
  local tier2Rate = 35
  local tier3Rate = 15

  --local lastTeam = DOTA_TEAM_GOODGUYS

  local totalSpawnPts = 10 -- total possible spawn locations
  local maxSpawns = PLAYERS_PER_TEAM+1 -- total number of item of each type spawned

  if totalSpawnPts < maxSpawns * #items then
    print("WARNING: more total spawn points needed")
  end

  --fill table with indexes
  local unusedSpawnIndexes = {}
  for i=1, totalSpawnPts do
    table.insert(unusedSpawnIndexes, i)
  end

  
  for itemIndex=1, #items do
    local spawnTables = {}
    
      --pick random indexes from unused indexes (each spawn point index is unique)
    while #spawnTables < maxSpawns do
      local tableIndex = RandomInt(1, #unusedSpawnIndexes)
      local spawnIndex = unusedSpawnIndexes[tableIndex]
      --table.insert(spawnPts, {spawnIndex)

      --random tier based on rarity
      local randomNum = RandomInt(1,100)
      local tier = 1
      if randomNum <= tier3Rate then
        tier = 3
      elseif randomNum <= tier2Rate+tier3Rate then
        tier = 2
      end

      table.insert( spawnTables,  {
        spawnIndex = spawnIndex,
        tier = tier
      })
      table.remove(unusedSpawnIndexes, tableIndex)
    end


    for teamID=TEAM_FIRST, TEAM_LAST do
      for i=1, #spawnTables do
        local table = spawnTables[i]
        --local spawnIndex = spawnPts[i]
        local spawnName = "item_spawn_" .. teamID .. "_" .. table.spawnIndex
        local spawnPointEnt = Entities:FindByName(nil, spawnName)
    
        if spawnPointEnt ~= nil then
          
    
          --mirror item spawns for each team
          local itemName = items[itemIndex] .. table.tier
          local item  = CreateItem(itemName, nil, nil)
          if item ~= nil then
            local point = spawnPointEnt:GetAbsOrigin()
            CreateItemOnPositionSync(point, item)
          else
              print("item was not able to be created: " .. itemName)
          end
        else
          print("spawn point not found: " .. spawnName)
        end
      end
    end
  end
end

function CustomGameState:ClearAllPlayersInventory( ignore )
  for teamID=TEAM_FIRST, TEAM_LAST do
    for i=1, PLAYERS_PER_TEAM do
      local playerID = PlayerResource:GetNthPlayerIDOnTeam(teamID, i)
      if PlayerResource:IsValidPlayerID(playerID) then
        local player = PlayerResource:GetPlayer(playerID)
        if player ~= nil then
          local hero = player:GetAssignedHero()
          if hero ~= nil then
            for a=DOTA_ITEM_SLOT_1, DOTA_STASH_SLOT_6 do
              local item = hero:GetItemInSlot(a)
              if item ~= nil then
                if ignore ~= nil then
                  local isMatchingIgnore = false
                  for i=1, #ignore do
                    if ignore[i] == item:GetName() then
                      isMatchingIgnore = true
                    end
                  end
                  if isMatchingIgnore == false then
                    hero:RemoveItem(item)
                  end
                else
                  hero:RemoveItem(item)
                end
              end
            end
          end
        end
      end
    end
  end
end

function CustomGameState:DestroyPhysicalItems()
  local items = Entities:FindAllByClassname("item_lua")
  if items ~= nil then
    for k,v in pairs(items) do
      local container = v:GetContainer() --get the physical item
      if container ~= nil then
        container:RemoveSelf()
      end
    end
  end
end


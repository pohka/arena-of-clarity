if CustomGameState == nil then
  CustomGameState = class({})
end

local GAME_STATE_WARMUP = 0
local GAME_STATE_LOOT = 1
local GAME_STATE_FIGHT = 2
local GAME_STATE_POST_FIGHT = 3

local STATE_DURATION_WARMUP = 5
local STATE_DURATION_LOOT = 5
local STATE_DURATION_FIGHT = 30
local STATE_DURATION_POST_FIGHT = 3

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
    local now = GameRules:GetGameTime()
    local curState = self:GetGameState()

    if curState == GAME_STATE_WARMUP then
      if now > STATE_DURATION_WARMUP then
        self:NextRound()
      end
    elseif curState == GAME_STATE_LOOT then
      local roundEndTime = lastStateChangeTime + STATE_DURATION_LOOT
      if now >= roundEndTime then
        self:SetGameState(GAME_STATE_FIGHT)
      end
    elseif curState == GAME_STATE_FIGHT then
      local roundEndTime = lastStateChangeTime + STATE_DURATION_FIGHT
      if now >= roundEndTime then
        --draw round if players are idle
      end
    elseif curState == GAME_STATE_POST_FIGHT then
      local roundEndTime = lastStateChangeTime + STATE_DURATION_POST_FIGHT
      if now >= roundEndTime then
        self:NextRound()
      end
    end
    return 1
  end
end

--start thinker when in_progress is reached
function CustomGameState:OnDefaultStateChange()
  if IsServer() then
    if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
      GameRules:GetGameModeEntity():SetThink( "OnThink", self, "GlobalThink", 1.0 )
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
      last_change = GameRules:GetGameTime()
    })
    CustomGameState:OnGameStateChange()
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

function CustomGameState:OnGameStateChange()
  print("state change:" .. self:GetGameState())
end

function CustomGameState:OnNextRound( event )
  if IsServer() then
    self:RespawnAll()
    local str = "Round "  .. event.round .. ": ( " .. self:GetTeamScore(DOTA_TEAM_GOODGUYS) .. "-" .. self:GetTeamScore(DOTA_TEAM_BADGUYS) .. " )"
    Say(nil, str, true)
    print(str)
  end
end

function CustomGameState:OnWarmupEnd()
  if IsServer() then
    Say(nil, "Warm up OVER", false)
    ListenToGameEvent("entity_killed", Dynamic_Wrap(self, "OnUnitKilled"), self)
  end
end

function CustomGameState:OnUnitKilled( args )
  if IsServer() then
    local state = self:GetGameState()

    if state == GAME_STATE_FIGHT then
      local killedUnit = EntIndexToHScript(args.entindex_killed)

      if killedUnit ~= nil then
        if killedUnit:IsHero() then
          print("killed hero:" .. killedUnit:GetName())
          killedUnit:GetTeamNumber()

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
      elseif teamIDWinner >= DOTA_TEAM_GOODGUYS and teamIDWinner <= DOTA_TEAM_BADGUYS then
        local curTeamScore = self:GetTeamScore(teamIDWinner)
        local key = "score_team_" .. (teamIDWinner - 1)
        CustomNetTables:SetTableValue( "game_state", key, { value = curTeamScore+1 })
      else
        print("invalid teamIDWinner for round:" .. curRoundNum)
      end

      self:SetGameState(GAME_STATE_POST_FIGHT)
    end
  end
end

function CustomGameState:GetTeamScore( teamID )
  if teamID >= DOTA_TEAM_GOODGUYS and teamID <= DOTA_TEAM_BADGUYS then
    local key = "score_team_" .. (teamID - 1)
    local table = CustomNetTables:GetTableValue("game_state", key)
    return table.value
  end
  return 0
end

function CustomGameState:RespawnAll()
  for teamID=DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS do
    for i=1, 5 do
      local playerID = PlayerResource:GetNthPlayerIDOnTeam(teamID, i)
      if playerID ~= nil and playerID > -1 then
        local player = PlayerResource:GetPlayer(playerID)
        if player ~= nil then
          local hero = player:GetAssignedHero()
          if hero ~= nil and hero:IsHero() then
            hero:RespawnHero(false, false)
          end
        end
      end
    end
  end
  
end
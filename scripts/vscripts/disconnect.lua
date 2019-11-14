if Disconnect == nil then
  _G.Disconnect = class({})
  _G.Disconnect.taskID = nil
  _G.Disconnect.IsPendingDisconnect = false
  _G.Disconnect.pendingDuration = 60
end

require("constants")
require("task")
require("game_time")

function Disconnect:CheckConnectedPlayers()
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
    --self:SetVictory(lastConnectedTeamID)
    Disconnect:BeginTimeout(lastConnectedTeamID)
  elseif totalTeamsConnected == 0 then --draw ??
    self:SetVictory(DOTA_TEAM_GOODGUYS)
    Disconnect:BeginTimeout(lastConnectedTeamID)
  elseif totalTeamsConnected > 1 and Disconnect.IsPendingDisconnect == true then
    Disconnect:CancelTimeout()
  end
end

function Disconnect:CancelTimeout()
  if Disconnect.IsPendingDisconnect == true then
    Task:Interupt(self.taskID)
    Disconnect.IsPendingDisconnect = false
    self.taskID = nil
  end
end

function Disconnect:BeginTimeout(winningTeamID)
  if Disconnect.IsPendingDisconnect == false then
    Disconnect.IsPendingDisconnect = true
    self.taskID = Task:Interval(
      function( kv )
        local timeLeft = kv.endTime - GameTime:GetTime()
        
        if timeLeft > 0 then
          local intTime = math.ceil(timeLeft)
          local msg = "Pause game or ending in " .. intTime .. "s"
          Say(nil, msg, true)
        else
          CustomGameState:SetVictory(kv.winningTeamID)
          return -1
        end
        return 1
      end,
      1,
      {
        endTime = Disconnect.pendingDuration + GameTime:GetTime(),
        winningTeamID = winningTeamID
      }
    )
  end
end
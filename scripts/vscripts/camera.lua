if Camera == nil then
  Camera = class({})
end

require("constants")
require("task")

--move all players camera to their hero
function Camera:FocusHeroForAllPlayers()
  print("startingID" .. TEAM_FIRST .. "-" .. TEAM_LAST)
  for teamID=TEAM_FIRST, TEAM_LAST do
    for i=1, PLAYERS_PER_TEAM do
      local playerID = PlayerResource:GetNthPlayerIDOnTeam(teamID, i)
      if PlayerResource:IsValidPlayerID(playerID) then
        local player = PlayerResource:GetPlayer(playerID)
        if player ~= nil then
          local hero = player:GetAssignedHero()
          if hero ~= nil then
            PlayerResource:SetCameraTarget(playerID, hero)
          end
        end
      end
    end
  end

  Task:Delay(Camera.OnRemoveFocus, 0.03, {})
end

function Camera:OnRemoveFocus()
  for teamID=TEAM_FIRST, TEAM_LAST do
    for i=1, PLAYERS_PER_TEAM do
      local playerID = PlayerResource:GetNthPlayerIDOnTeam(teamID, i)
      if PlayerResource:IsValidPlayerID(playerID) then
        PlayerResource:SetCameraTarget(playerID, nil)
      end
    end
  end
  return -1
end
if GameTime == nil then
  GameTime = class({})
  GameTime.inProgressStartTime = 0
end
--custom timer that starts counting at beginning of IN_PROGRESS 

function GameTime:init()
  ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(self, "OnGameStateChange"), self)
end

function GameTime:OnGameStateChange()
  if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
    GameTime.inProgressStartTime = GameRules:GetGameTime()
  end
end

--returns time since game started
function GameTime:GetTime()
  return GameRules:GetGameTime() - self.inProgressStartTime
end

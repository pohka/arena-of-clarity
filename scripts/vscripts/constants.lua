if Constants == nil then
  Constants = 0

  --teams and player count
  _G.TEAM_COUNT = 2
  _G.TEAM_FIRST = DOTA_TEAM_GOODGUYS
  _G.TEAM_LAST = TEAM_FIRST + TEAM_COUNT - 1
  _G.PLAYERS_PER_TEAM = 3

  --game states
  _G.GAME_STATE_WARMUP = 0
  _G.GAME_STATE_LOOT = 1
  _G.GAME_STATE_FIGHT = 2
  _G.GAME_STATE_POST_FIGHT = 3
  _G.GAME_STATE_POST_GAME = 4

  --types of projectiles
  _G.PROJECTILE_TYPE_LINEAR = 0
  _G.PROJECTILE_TYPE_TRACKING = 1


  _G.Z_MAX_DIFF = 150 --maximum distance between checks in z-axis
end
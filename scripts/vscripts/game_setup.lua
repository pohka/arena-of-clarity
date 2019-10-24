if GameSetup == nil then
  GameSetup = class({})
end

require("filters")
require("constants")

--nil will not force a hero selection
local forceHero = "skeleton_king"




function GameSetup:init()
  if IsInToolsMode() then  --debug build
    --skip all the starting game mode stages e.g picking screen, showcase, etc
    GameRules:EnableCustomGameSetupAutoLaunch(true)
    GameRules:SetCustomGameSetupAutoLaunchDelay(0)
    GameRules:SetHeroSelectionTime(10)
    GameRules:SetStrategyTime(0)
    GameRules:SetPreGameTime(0)
    GameRules:SetShowcaseTime(0)
    GameRules:SetPostGameTime(5)
    
    --disable some setting which are annoying then testing
    local GameMode = GameRules:GetGameModeEntity()
    GameMode:SetAnnouncerDisabled(true)
    GameMode:SetKillingSpreeAnnouncerDisabled(true)
    GameMode:SetDaynightCycleDisabled(true)
    GameMode:DisableHudFlip(true)
    GameMode:SetDeathOverlayDisabled(true)
    GameMode:SetWeatherEffectsDisabled(true)

    -- --disable music events
    GameRules:SetCustomGameAllowHeroPickMusic(false)
    GameRules:SetCustomGameAllowMusicAtGameStart(false)
    GameRules:SetCustomGameAllowBattleMusic(false)

    -- Remove starting TP scroll using inventroy filter
    -- GameRules:GetGameModeEntity():SetItemAddedToInventoryFilter(function(ctx, event)
    --     local item = EntIndexToHScript(event.item_entindex_const)
    --     if item:GetAbilityName() == "item_tpscroll" and item:GetPurchaser() == nil then 
    --       return false
    --     end
    --     return true
    -- end, self)



    Filters:AddAll()

    --multiple players can pick the same hero
    GameRules:SetSameHeroSelectionEnabled(true)

    --disable default respawning and buyback
    GameRules:SetHeroRespawnEnabled(false)
    GameMode:SetBuybackEnabled(false)
    GameMode:SetFixedRespawnTime(1)

    --force single hero selection (optional)
    if forceHero ~= nil then
      GameMode:SetCustomGameForceHero(forceHero)
    end
    
    --listen to game state event
    ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(self, "OnStateChange"), self)

    GameRules:SetUseUniversalShopMode(true)
    
    
    
  else --release build

    --put your rules here

  end
end



function GameSetup:OnStateChange()
  --random hero once we reach strategy phase
  if GameRules:State_Get() == DOTA_GAMERULES_STATE_STRATEGY_TIME then
    GameSetup:RandomForNoHeroSelected()
  elseif GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then

    
  end
end

-- -- spawns random items of each type in random spawn point
-- -- the spawn points for each item is unique and all mirrored for each team
-- function GameSetup:SpawnItems()
--   print("spawning items")

--   --table of items to spawn
--   local items = {
--     "item_boots_tier_",
--     "item_armor_tier_"
--   }

--   --item rarity
--   local tier2Rate = 35
--   local tier3Rate = 15

--   --local lastTeam = DOTA_TEAM_GOODGUYS

--   local totalSpawnPts = 10 -- total possible spawn locations
--   local maxSpawns = PLAYERS_PER_TEAM+1 -- total number of item of each type spawned

--   if totalSpawnPts < maxSpawns * #items then
--     print("WARNING: more total spawn points needed")
--   end

--   --fill table with indexes
--   local unusedSpawnIndexes = {}
--   for i=1, totalSpawnPts do
--     table.insert(unusedSpawnIndexes, i)
--   end

  
--   for itemIndex=1, #items do
--     --table for spawnIndexes for this item
--     local spawnPts = {}
    
--      --pick random indexes from unused indexes (each spawn point index is unique)
--     while #spawnPts < maxSpawns do
--       local tableIndex = RandomInt(1, #unusedSpawnIndexes)
--       local spawnIndex = unusedSpawnIndexes[tableIndex]
--       table.insert(spawnPts, spawnIndex)
--       table.remove(unusedSpawnIndexes, tableIndex)
--     end

--     for teamID=TEAM_FIRST, TEAM_FIRST do
--       for i=1, #spawnPts do
--         local spawnIndex = spawnPts[i]
--         local spawnName = "item_spawn_" .. teamID .. "_" .. spawnIndex
--         local spawnPointEnt = Entities:FindByName(nil, spawnName)
    
--         if spawnPointEnt ~= nil then
--           --random tier based on rarity
--           local randomNum = RandomInt(1,100)
--           local tier = 1
--           if randomNum < tier3Rate then
--             tier = 3
--           elseif randomNum < tier2Rate+tier3Rate then
--             tier = 2
--           end
    
--           --mirror item spawns for each team
--           for teamID=TEAM_FIRST, TEAM_LAST do
--             local itemName = items[itemIndex] .. tier
--             local item  = CreateItem(itemName, nil, nil)
--             if item ~= nil then
--               local point = spawnPointEnt:GetAbsOrigin()
--               CreateItemOnPositionSync(point, item)
--             else
--                 print("item was not able to be created: " .. itemName)
--             end
--           end
--         else
--           print("spawn point not found: " .. spawnName)
--         end
--       end
--     end
--   end
-- end


function GameSetup:RandomForNoHeroSelected()
    --NOTE: GameRules state must be in HERO_SELECTION or STRATEGY_TIME to pick heroes
    --loop through each player on every team and random a hero if they haven't picked
  for teamNum = TEAM_FIRST, TEAM_LAST do
    for i=1, PLAYERS_PER_TEAM do
      local playerID = PlayerResource:GetNthPlayerIDOnTeam(teamNum, i)
      if PlayerResource:IsValidPlayerID(playerID) then
        if not PlayerResource:HasSelectedHero(playerID) then
          local hPlayer = PlayerResource:GetPlayer(playerID)
          if hPlayer ~= nil then
            hPlayer:MakeRandomHeroSelection()
          end
        end
      end
    end
  end
end

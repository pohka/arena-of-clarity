if ManaPotionSpawner == nil then
 _G.ManaPotionSpawner = class({})
 ManaPotionSpawner.recentSpawns = {} --buffer of recent spawn indexes used
end

require("task")

function ManaPotionSpawner:init()
  if IsServer() then
    Task:Interval(ManaPotionSpawner.OnThink, 6.0, {})
  end
end

function ManaPotionSpawner:OnThink()
  if IsServer() then
    local largeRarity = 15
    local maxSpawns = 10

    if IsServer() then
      local randomNum = RandomInt(1,100)
      local itemName = "item_mana_small"
      if randomNum <= largeRarity then
        itemName = "item_mana_large"
      end

      --spawn at different locations each time
      local spawnIndex = -1
      if #ManaPotionSpawner.recentSpawns == 0 then
        spawnIndex = RandomInt(1,maxSpawns)
      else
        --fill table
        local unusedSpawnIndexes = {}
        for i=1, maxSpawns do
          local isUsed = false
          local a=1
          while a <= #ManaPotionSpawner.recentSpawns and isUsed == false do
            if i == ManaPotionSpawner.recentSpawns[a] then
              isUsed = true
            end
            a = a + 1
          end

          if isUsed == false then
            table.insert(unusedSpawnIndexes, i)
          end
        end

        --random from unused indexes, so the spawns don't always happen at the same points
        randomIndex = RandomInt(1,#unusedSpawnIndexes)
        spawnIndex = unusedSpawnIndexes[randomIndex]
      end

      table.insert(ManaPotionSpawner.recentSpawns, spawnIndex)
      if #ManaPotionSpawner.recentSpawns > 5 then
        table.remove(ManaPotionSpawner.recentSpawns, 1)
      end

      local spawnName = "mana_spawn_" .. spawnIndex
 
      local pointEnt = Entities:FindByName(nil, spawnName)
      if pointEnt ~= nil then
        local item = CreateItem(itemName, nil, nil)
        local pos = pointEnt:GetAbsOrigin() + RandomVector(RandomFloat(40,90))
        CreateItemOnPositionSync(pos, item)
      end
    end
  end

  return 8.0
end
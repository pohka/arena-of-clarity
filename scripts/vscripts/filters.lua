if Filters == nil then
  Filters = class({})
end

function Filters:AddAll()
  Filters:AddXPFilter()
  Filters:AddInventroyFilter()
end

function Filters:AddXPFilter()
	local GameMode = GameRules:GetGameModeEntity()
	GameMode:SetModifyExperienceFilter(
		function(ctx, event)
			local unit  = EntIndexToHScript(event.hero_entindex_const)
			if unit ~= nil then
				unit:GiveMana(50)
			end

			return false --disable default expeirence
		end
		, self)
end

 --  1. removes starting teleport
  --  2. drops lower tier item of same type from inventory
function Filters:AddInventroyFilter()
  local GameMode = GameRules:GetGameModeEntity()
  GameMode:SetItemAddedToInventoryFilter(
		function(ctx, event)
			local item = EntIndexToHScript(event.item_entindex_const)

			--remove starting teleport scroll
			if item:GetAbilityName() == "item_tpscroll" and item:GetPurchaser() == nil then 
				return false
			end
			
			local unitPickUpIndex = event.inventory_parent_entindex_const
			local unit = EntIndexToHScript(unitPickUpIndex)
			--local unit = item:GetOwner()
			if unit ~= nil then
				local itemPos = item:GetAbsOrigin()

				local itemName = item:GetName()
        local sub = string.sub(itemName, 1, -2)
        
        --table of items to spawn
        local itemPrefixs = {
          "item_boots_tier_",
          "item_armor_tier_"
        }

        for i=1, #itemPrefixs do
          local itemPrefix = itemPrefixs[i]

          if sub == itemPrefix then
            local num = string.sub(itemName, -1)
            local tier = tonumber(num)

            --get current tier by name
            local currentTier = 0
            if unit:HasItemInInventory(itemPrefix .. "1") then
              currentTier = 1
            elseif unit:HasItemInInventory(itemPrefix .. "2") then
              currentTier = 2
            elseif unit:HasItemInInventory(itemPrefix .. "3") then
              currentTier = 3
            end

            if currentTier < tier then
              --drop current item if new item tier is higher
              if currentTier > 0 then
                local curItemName = itemPrefix .. currentTier
                local curItem = Query:findItemByName(unit, curItemName)
                if curItem ~= nil then
                  unit:RemoveItem(curItem)
                  local itemCopy = CreateItem(curItemName, nil, nil)
                  local pos = unit:GetAbsOrigin()
                  local drop = CreateItemOnPositionSync( pos, itemCopy )
                  local pos_launch = pos+RandomVector(RandomFloat(30,50))
                  itemCopy:LaunchLoot(false, 250, 0.75, pos_launch)
                end
              end
            --drop item because we currently have a higher or equal item
            elseif currentTier >= tier then
              local pos = unit:GetAbsOrigin()
              local drop = CreateItemOnPositionSync( pos, item )
              local pos_launch = pos+RandomVector(RandomFloat(30,50))
              item:LaunchLoot(false, 250, 0.75, pos_launch)
              return false
            end
          end --end of item loop
				end
			end

      --this event is broken in dota, so calling it from here instead
      if item.OnItemEquipped ~= nil then
        item:OnItemEquipped(item)
      end
		  return true
		end,
		self)
end

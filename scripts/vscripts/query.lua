if Query == nil then
  Query = class({})
end

function Query:findItemByName(unit, itemName)
  if unit ~= nil and unit:HasInventory() then
    for i=DOTA_ITEM_SLOT_1, DOTA_STASH_SLOT_6 do
      local item = unit:GetItemInSlot(i);
      if item:GetName() == itemName then
        return item
      end
    end
  end
  return nil
end

function Query:FindAbilityByName(unit, abilityName)
  local count = unit:GetAbilityCount() - 1
  for i=0, count do
    local abil = unit:GetAbilityByIndex(i)
    if abil ~= nil then
      if abil:GetName() == abilityName then
        return abil
      end
    end
  end
  return nil
end

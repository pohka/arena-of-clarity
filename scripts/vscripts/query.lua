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


function Query:FindUnitsInLine(teamNumber, startPt, endPt, cacheUnit, width, teamFilter, typeFilter, flagFilter, zMaxDiff)
  local units = FindUnitsInLine(
    teamNumber,
    startPt,
    endPt,
    cacheUnit,
    width,
    teamFilter,
    typeFilter,
    flagFilter
  )

  if zMaxDiff == nil then
    return units
  end

  local result = {}
  for _,unit in pairs(units) do
    local groundH = GetGroundHeight(unit:GetAbsOrigin(), unit)
    local currentH = unit:GetAbsOrigin().z

    if currentH - groundH <= zMaxDiff then
      table.insert(result, unit)
    end
  end

  return result
end

function Query:FindUnitsRadius(teamNumber, position, cacheUnit, radius, teamFilter, typeFilter, flagFilter, order, cacheCanGrow, zMaxDiff)
  local units = FindUnitsInRadius(
    teamNumber,
    position,
    cacheUnit,
    radius,
    teamFilter,
    typeFilter,
    flagFilter,
    order,
    cacheCanGrow
  )

  if zMaxDiff == nil then
    return units
  end

  local result = {}
  for _,unit in pairs(units) do
    local groundH = GetGroundHeight(unit:GetAbsOrigin(), unit)
    local currentH = unit:GetAbsOrigin().z

    if currentH - groundH <= zMaxDiff then
      table.insert(result, unit)
    end
  end

  return result
end

--find units in sector shape (e.g. 90 degrees is a semi circle)
--angle in degrees from 0-180
function Query:FindUnitsSector(teamNumber, position, forward, angle, cacheUnit, radius, teamFilter, typeFilter, flagFilter, order, cacheCanGrow, zMaxDiff)
  local units = FindUnitsInRadius(
    teamNumber,
    position,
    cacheUnit,
    radius,
    teamFilter,
    typeFilter,
    flagFilter,
    order,
    cacheCanGrow
  )

  local result = {}
  for _,unit in pairs(units) do
    local isValid = true
    if zMaxDiff ~= nil then
      local groundH = GetGroundHeight(unit:GetAbsOrigin(), unit)
      local currentH = unit:GetAbsOrigin().z

      if currentH - groundH <= zMaxDiff == false then
        --table.insert(result, unit)
        isValid = false
      end
    end

    if isValid == true then
      local diff = unit:GetAbsOrigin() - position
      diff.z = 0
      local dir = diff:Normalized()
      local dot = dir:Dot(forward)
      local angleDiff = math.deg(math.acos(dot)) --arccos and then converting from radians to degrees
      if angleDiff <= angle then
        table.insert(result, unit)
      end
    end
  end

  return result
end
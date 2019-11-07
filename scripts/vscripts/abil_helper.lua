if AbilHelper == nil then
 _G.AbilHelper = class({})
end

--returns a normalized direction vector from caster position to cursor position
function AbilHelper:GetPointDirection(ability)
  local caster = ability:GetCaster()
  local custorPos = ability:GetCursorPosition()
  local direction = custorPos - caster:GetAbsOrigin()
  direction.z = 0
  direction = direction:Normalized()
  return direction
end
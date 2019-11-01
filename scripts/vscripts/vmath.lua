if vmath == nil then
  _G.vmath = class({})
end

--rotate a world space point around another point in world space (origin) on the z-axis by a given angle
function vmath:RotateAround(point, origin, angle)
  local pos = point - origin

  local x = (pos.x * math.cos(angle)) - (-pos.y * math.sin(angle))
  local y = (-pos.y * math.cos(angle)) - (pos.x * math.sin(angle))

  local result = Vector(
    x + origin.x,
    y + origin.y,
    point.z
  )
  return result
end

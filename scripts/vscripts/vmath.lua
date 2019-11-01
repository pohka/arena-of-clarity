if vmath == nil then
  _G.vmath = class({})
end

--rotate a world space point around another point in world space (origin) on the z-axis by a given angle (degrees)
function vmath:RotateAround(point, origin, angle)
  local rAngle = math.rad(angle)

  local pos = point - origin
  local x = (pos.x * math.cos(rAngle)) - (pos.y * math.sin(rAngle))
  local y = (pos.x * math.sin(rAngle)) + (pos.y * math.cos(rAngle))

  local result = Vector(
    x + origin.x,
    y + origin.y,
    point.z
  )

  return result
end

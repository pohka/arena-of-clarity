hero_spawn_booter_modifier = class({})

function hero_spawn_booter_modifier:OnDestroy()
  if IsServer() then
    local hero = self:GetParent()
    hero:SetMana(0)
  end
end

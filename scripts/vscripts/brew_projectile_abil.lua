brew_projectile_abil = class({})


function brew_projectile_abil:init(id)
  self.id = id
  self.isDisabled = false
end

function brew_projectile_abil:GetProjectileID()
  return self.id
end

function brew_projectile_abil:GetIsDisabled()
  return self.isDisabled
end


function brew_projectile_abil:SetIsDisabled(bIsDisabled)
  self.isDisabled = bIsDisabled
end
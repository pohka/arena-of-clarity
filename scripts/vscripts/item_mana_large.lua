item_mana_large = class({})

function item_mana_large:IsConsumedOnPickup()
  return true
end

function item_mana_large:OnConsume(unit)
  local mana = self:GetSpecialValueFor("mana")
  unit:GiveMana(mana)
  EmitSoundOn("DOTA_Item.Mango.Activate", unit)
end

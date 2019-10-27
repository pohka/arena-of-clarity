item_mana_small = class({})

function item_mana_small:IsConsumedOnPickup()
  return true
end

function item_mana_small:OnConsume(unit)
  local mana = self:GetSpecialValueFor("mana")
  unit:GiveMana(mana)
  EmitSoundOn("DOTA_Item.Mango.Activate", unit)
end

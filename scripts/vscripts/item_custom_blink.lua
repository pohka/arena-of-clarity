item_custom_blink = class({})

require("brew_projectile")

function item_custom_blink:OnSpellStart()
  local caster = self:GetCaster()
  local point = self:GetCursorPosition()
  local casterPt = caster:GetAbsOrigin()

  if point ~= nil and casterPt ~= nil then
    local diff = point - casterPt
    diff.z = 0
    local direction = diff:Normalized()
    local castDistance = diff:Length2D()

    local maxRange = self:GetSpecialValueFor("max_range")

    
    local fxIndex = ParticleManager:CreateParticle(
      "particles/econ/events/nexon_hero_compendium_2014/blink_dagger_start_nexon_hero_cp_2014.vpcf",
      PATTACH_POINT,
      caster
    )
    ParticleManager:SetParticleControl(fxIndex, 0, casterPt)

    --dodge projectile
    BrewProjectile:Dodge(caster)

    --move unit based on ranges
    local position = nil
    if castDistance > maxRange then
      position = caster:GetAbsOrigin() + (direction * maxRange)
    else
      position = caster:GetAbsOrigin() + (direction * castDistance)
    end

    ParticleManager:CreateParticle(
      "particles/econ/events/nexon_hero_compendium_2014/blink_dagger_end_glow_nexon_hero_cp_2014.vpcf",
      PATTACH_ABSORIGIN,
      caster
    )

    
    caster:EmitSound( "DOTA_Item.BlinkDagger.Activate")
    --EmitSoundOnLocationWithCaster(caster:GetAbsOrigin(), "DOTA_Item.BlinkDagger.Activate", caster)

    FindClearSpaceForUnit(caster, position, true)


    --caster:EmitSound( "DOTA_Item.BlinkDagger.Activate", 0, 0.5, 0)
    --EmitSoundOnLocationWithCaster(position, "DOTA_Item.BlinkDagger.Activate", caster)

    --face forward
    caster:MoveToPosition(position + direction)
  end
end

function item_custom_blink:GetCastRange()
  return self:GetSpecialValueFor("max_range")
end

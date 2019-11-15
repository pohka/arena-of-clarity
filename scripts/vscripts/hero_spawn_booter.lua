hero_spawn_booter = class({})
LinkLuaModifier("hero_spawn_booter_modifier",  LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("hero_turn_rate_modifier",  LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("hero_silence_modifier",  LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("hero_damage_immune_modifier",  LUA_MODIFIER_MOTION_NONE )

require("constants")


function hero_spawn_booter:OnUpgrade()
 local caster = self:GetCaster()

 caster:AddNewModifier(caster, self, "hero_spawn_booter_modifier", { duration = 0.06 })
 caster:AddNewModifier(caster, self, "hero_turn_rate_modifier", { })
end

function hero_spawn_booter:OnOwnerSpawned()
  local caster = self:GetCaster()
  caster:AddNewModifier(caster, self, "hero_turn_rate_modifier", { })

  --add immunity to damage when spawning
  local table = CustomNetTables:GetTableValue("game_state", "state")
  local isDamageImmuneSet = false
  if table ~= nil then
    local state = table.value
    if state == GAME_STATE_WARMUP then
      caster:AddNewModifier(caster, self, "hero_damage_immune_modifier", { duration = 3.0 })
      isDamageImmuneSet = true
    end
  end

  if isDamageImmuneSet == false then
    caster:AddNewModifier(caster, self, "hero_damage_immune_modifier", { duration = 1.5 })
  end
end

function hero_spawn_booter:OnPostFightState()
  local caster = self:GetCaster()
  caster:AddNewModifier(unit, self, "hero_silence_modifier", { duration = 10 })
end
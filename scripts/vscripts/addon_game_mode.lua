-- Generated from template

if BattleArena == nil then
	BattleArena = class({})
end

require("game_setup")
require("query")
require("custom_game_state")
require("task")
require("game_time")
require("brew_projectile")


function Precache( context )
	--[[
		Precache things we know we'll use.  Possible file types include (but not limited to):
			PrecacheResource( "model", "*.vmdl", context )
			PrecacheResource( "soundfile", "*.vsndevts", context )
			PrecacheResource( "particle", "*.vpcf", context )
			PrecacheResource( "particle_folder", "particles/folder", context )
	]]

	PrecacheResource( "model", "models/props_gameplay/boots_of_speed.vmdl", context )
	PrecacheResource( "model", "models/props_gameplay/mango.vmdl", context )
	PrecacheResource( "model", "models/props_gameplay/bottle_mango001.vmdl", context )
	PrecacheResource( "model", "models/heroes/gyro/gyro_missile.vmdl", context )
	
	

	PrecacheResource( "particle", "particles/wk_r.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_ember_spirit/ember_spirit_remnant_dash_rubick.vpcf", context )
	PrecacheResource( "particle", "particles/econ/items/ember_spirit/ember_ti9/ember_ti9_flameguard.vpcf", context )
	PrecacheResource( "particle", "particles/econ/items/silencer/silencer_ti6/silencer_last_word_status_ti6_ring_ember.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_silencer/silencer_last_word_status_ring_ember.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_sven/sven_spell_storm_bolt.vpcf", context )
	PrecacheResource( "particle", "particles/status_fx/status_effect_gods_strength.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_sven/sven_spell_gods_strength.vpcf", context )
	PrecacheResource( "particle", "particles/disruptor_ti8_immortal_thunder_strike_buff_red.vpcf", context )
	PrecacheResource( "particle", "particles/econ/items/disruptor/disruptor_ti8_immortal_weapon/disruptor_ti8_immortal_thunder_strike_buff.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_tinker/tinker_rockets_arrow.vpcf", context )
	PrecacheResource( "particle", "particles/econ/items/batrider/batrider_ti8_immortal_mount/batrider_ti8_immortal_firefly.vpcf", context )
	PrecacheResource( "particle", "particles/econ/items/disruptor/disruptor_ti8_immortal_weapon/disruptor_ti8_immortal_thunder_strike_buff.vpcf", context )
	PrecacheResource( "particle", "particles/econ/items/pangolier/pangolier_ti8_immortal/pangolier_ti8_immortal_shield_crash.vpcf", context )
	PrecacheResource( "particle", "particles/disruptor_ti8_immortal_thunder_strike_buff_red.vpcf", context )
	PrecacheResource( "particle", "particles/items_fx/black_king_bar_avatar.vpcf", context )
	PrecacheResource( "particle", "particles/econ/items/dark_seer/dark_seer_ti8_immortal_arms/dark_seer_ti8_immortal_ion_shell.vpcf", context )
	PrecacheResource( "particle", "particles/econ/items/tiny/tiny_prestige/tiny_prestige_lvl4_death_embers.vpcf", context )
	PrecacheResource( "particle", "particles/econ/items/earthshaker/earthshaker_arcana/earthshaker_arcana_target_death.vpcf", context )
	
	
	

	PrecacheResource( "soundfile", "soundevents/game_sounds_items.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_puck.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_sven.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_skeleton_king.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_mirana.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_sniper.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_tinker.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_batrider.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_bounty_hunter.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_pangolier.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_mars.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds.vsndevts", context )
end

-- Create the game mode when we activate
function Activate()
	GameRules.AddonTemplate = BattleArena()
	GameRules.AddonTemplate:InitGameMode()
end


function BattleArena:InitGameMode()
	print( "BattleArena InitGameMode" )

	GameSetup:init()
	GameTime:init()
	CustomGameState:init()
	Task:init()
	BrewProjectile:init()
	

	ListenToGameEvent("npc_spawned", Dynamic_Wrap(self, "OnUnitSpawned"), self)
end



function BattleArena:OnUnitSpawned( args )
	local entH = EntIndexToHScript(args.entindex)
	if entH ~= nil then
		local count = entH:GetAbilityCount()
		if entH:IsHero() then
			local hero = entH

			--level up all abilities to max and clear cooldowns
			local i = 0
			while i < 24 or i < count do
				local abil = hero:GetAbilityByIndex(i)
				if abil ~= nil then
					local maxLevel = abil:GetMaxLevel()
					if abil:GetLevel() ~= maxLevel then
						abil:SetLevel(maxLevel);
					end
					abil:EndCooldown()
				end
				i = i + 1
			end

			--remove all modifiers (except ignored modifiers)
			local ignoreModifiers = {
				"hero_spawn_booter_modifier"
			}
			for n=0, hero:GetModifierCount() - 1 do
				local modifierName = hero:GetModifierNameByIndex(n)
				local a=1
				local isMatchingIgnore = false
				while a <= #ignoreModifiers and isMatchingIgnore == false do
					if ignoreModifiers[a] == modifierName then
						isMatchingIgnore = true
					end
					a = a + 1
				end

				if isMatchingIgnore == false then
					hero:RemoveModifierByName(modifierName)
				end
			end

			--add warmup items
			local customState = CustomGameState:GetGameState()
			if customState == GAME_STATE_WARMUP then
				local warmupItems = {
					"item_armor_tier_1",
					"item_boots_tier_2",
					"item_custom_blink"
				}

				for i=1, #warmupItems do
					if hero:HasItemInInventory(warmupItems[i]) == false then
						hero:AddItemByName(warmupItems[i])
					end
				end
			end

			--disable hero collsion with other players
			hero:NoUnitCollision()
		end
	end
end

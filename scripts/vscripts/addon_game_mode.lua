-- Generated from template

if BattleArena == nil then
	BattleArena = class({})
end

require("game_setup")
require("query")
require("custom_game_state")
require("task")
require("game_time")


function Precache( context )
	--[[
		Precache things we know we'll use.  Possible file types include (but not limited to):
			PrecacheResource( "model", "*.vmdl", context )
			PrecacheResource( "soundfile", "*.vsndevts", context )
			PrecacheResource( "particle", "*.vpcf", context )
			PrecacheResource( "particle_folder", "particles/folder", context )
	]]

	PrecacheResource( "model", "models/props_gameplay/boots_of_speed.vmdl", context )

	PrecacheResource( "particle", "particles/econ/items/mirana/mirana_crescent_arrow/mirana_spell_crescent_arrow.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_skeletonking/skeletonking_hellfireblast.vpcf", context )
	PrecacheResource( "particle", "particles/items3_fx/lotus_orb_shield.vpcf", context )
	PrecacheResource( "particle", "particles/econ/items/silencer/silencer_ti6/silencer_last_word_status_ti6_ring_ember.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_silencer/silencer_last_word_status_ring_ember.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_sven/sven_spell_storm_bolt.vpcf", context )
	

	PrecacheResource( "soundfile", "soundevents/game_sounds_items.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_puck.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_sven.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/soundevents/game_sounds_heroes/game_sounds_skeleton_king.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/soundevents/game_sounds_heroes/game_sounds_mirana.vsndevts", context )
end

-- Create the game mode when we activate
function Activate()
	GameRules.AddonTemplate = BattleArena()
	GameRules.AddonTemplate:InitGameMode()
end


function BattleArena:InitGameMode()
	print( "BattleArena Init" )

	GameSetup:init()
	GameTime:init()
	CustomGameState:init()
	Task:init()
	

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
					abil:SetLevel(maxLevel);
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

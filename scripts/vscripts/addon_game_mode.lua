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

			local customState = CustomGameState:GetGameState()

			--add warmup items
			if customState == GAME_STATE_WARMUP then
				if hero:HasItemInInventory("item_armor_tier_1") == false then
					hero:AddItemByName("item_armor_tier_1")
				end

				if hero:HasItemInInventory("item_boots_tier_2") == false then
					hero:AddItemByName("item_boots_tier_2")
				end
			end

			--level up all abilities to max
			local i = 0
			while i < 24 or i < count do
				local abil = hero:GetAbilityByIndex(i)
				if abil ~= nil then
					local maxLevel = abil:GetMaxLevel()
					abil:SetLevel(maxLevel);
				end
				i = i + 1
			end
		end
	end
end

local json = require("json")

local mod = RegisterMod("ROCK&STONE", 1)
local game = Game()
local sfx = SFXManager()

local tauntTime = 8
local tauntLockout = 12

local tauntEffect = Isaac.GetEntityVariantByName("Taunt Spark")

local tauntSound = Isaac.GetSoundIdByName("ROCK")

local tauntPlayers = {}

-- Will credit individual taunts in comments here
local tauntList = {
	"dab",
	"famguy",
	"soy",
	"smooth",
	"bitches",
	"silly",
	"nerd",
	"fruit",
	"itseems",
	"ass",
	"boys",
	"promotion",
	"kaz",
	"grim", -- Czar Khasm
	"beast", -- Czar Khasm
	"akuma", -- Czar Khasm
	-- GLoDi offered some resprites of the mod's original sprites (And they're really good resprites! Defo better than my programmer art lol)
	-- But I didn't wanna replace the originals so I offered to just add any original sprites they made
	-- I may build an API for extending the mod's sprite list if there's enough demand though
	"doobie", -- GLoDi169
	"hurk", -- GLoDi169
	"yippee", -- GLoDi169
	"grad", -- GLoDi169
	"sadge", -- GLoDi169
	"meat", -- GLoDi169
	"juice", -- flippin egg
	"dontcare", -- flippin egg
	"doctor" -- flippin egg
}

-- Ingame credits display
local creditList = { 
	"Ruberoid"
}

local settings = {
	kbBind = Keyboard.KEY_V,
	ctBind = 10
}

function mod:saveConfig()

	local jsonString = json.encode(settings)
	mod:SaveData(jsonString)

end

function mod:loadConfig()
	
	if not mod:HasData() then
		return
	end
	
	local jsonString = mod:LoadData()
	settings = json.decode(jsonString)
	
end

mod:loadConfig()

-- Mod config menu stuff
function mod:setupConfigMenu()
	if ModConfigMenu == nil then
		return
	end
	
	local MOD_NAME = "Taunts"
	
	ModConfigMenu.AddTitle(MOD_NAME, "Info", "Taunts!")
	ModConfigMenu.AddText(MOD_NAME, "Info", "Mod made by Barney")
	ModConfigMenu.AddText(MOD_NAME, "Info", "Follow me on twitter @CouldBeBarney")
	ModConfigMenu.AddText(MOD_NAME, "Info", "I post bangers on there")
	
	-- This is on a separate page so you can actually look at it lmao
	-- If too many artists get added to this list I'll separate them out
	-- And if there's too many for me to crunch it down, I'll add a system that lets you view who made what
	ModConfigMenu.AddTitle(MOD_NAME, "Credits", "Additional Credits")
	ModConfigMenu.AddText(MOD_NAME, "Credits", "Additional taunts provided by these artists:")
	
	for i = 1, #creditList do
		ModConfigMenu.AddText(MOD_NAME, "Credits", creditList[i])
	end
	
	ModConfigMenu.AddSpace(MOD_NAME, "Settings")
	ModConfigMenu.AddSetting(MOD_NAME, "Settings", {
		Type = ModConfigMenu.OptionType.KEYBIND_KEYBOARD,
		CurrentSetting = function()
			return settings.kbBind
		end,
		Display = function()
			return "Keyboard button: " .. InputHelper.KeyboardToString[settings.kbBind]
		end,
		OnChange = function(button)
			settings.kbBind = button or -1
			mod:saveConfig()
		end,
		
		-- Popup stuff isn't documented, this is stolen from EID
		PopupGfx = ModConfigMenu.PopupGfx.WIDE_SMALL,
		PopupWidth = 280,
		Popup = function()
			local currentValue = settings.kbBind
			local keepSettingString = ""
			if currentValue > -1 then
				local currentSettingString = InputHelper.KeyboardToString[currentValue]
				keepSettingString = "This setting is currently set to \"" .. currentSettingString .. "\".$newlinePress this button to keep it unchanged.$newline$newline"
			end
			return "Press a button on your keyboard to change this setting.$newline$newline" .. keepSettingString .. "Press ESCAPE to go back and clear this setting."				
		end
	})
	ModConfigMenu.AddSetting(MOD_NAME, "Settings", {
		Type = ModConfigMenu.OptionType.KEYBIND_CONTROLLER,
		CurrentSetting = function()
			return settings.ctBind
		end,
		Display = function()
			return "Controller button: " .. (InputHelper.ControllerToString[settings.ctBind] or "N/A")
		end,
		OnChange = function(button)
			settings.ctBind = button or -1
			mod:saveConfig()
		end,
		PopupGfx = ModConfigMenu.PopupGfx.WIDE_SMALL,
		PopupWidth = 280,
		Popup = function()
			local currentValue = settings.ctBind
			local keepSettingString = ""
			if currentValue > -1 then
				local currentSettingString = (InputHelper.ControllerToString[currentValue] or "N/A")
				keepSettingString = "This setting is currently set to \"" .. currentSettingString .. "\".$newlinePress this button to keep it unchanged.$newline$newline"
			end
			return "Press a button on your controller to change this setting.$newline$newline" .. keepSettingString .. "Press BACK to go back and clear this setting."				
		end
	})
end

mod:setupConfigMenu()

function mod:clearPlayerTable()
	tauntPlayers = {}
end

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.clearPlayerTable)
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.clearPlayerTable)

function mod:doTaunt(player)

	tauntPlayer = mod:getTauntPlayer(player.Index)

	tauntPlayer.vel = player.Velocity
	tauntPlayer.pos = player.Position
	tauntPlayer.tauntSpark = Isaac.Spawn(1000, tauntEffect, 0, player.Position, Vector(0, 0), nil)
	tauntPlayer.tauntTimer = tauntLockout
	
	player.Velocity = Vector(0, 0)
	
	-- TODO: This can be redone by just swapping out the sprites with SPRITEOBJECT:ReplaceSpritesheet()
	-- Not sure if this would become a disaster for memory but it'd remove the need for the anm2 editor in the workflow
	-- Sprites would need a consistent size though, which'd become a nightmare if a taunt is too big
	local sparkSprite = tauntPlayer.tauntSpark:GetSprite()
	sparkSprite:Play(tauntList[math.random(1, #tauntList)], true)
	
	sfx:Play(tauntSound, 2, 0, false, 0.9 + (math.random() / 5), 0)
	player.Visible = false
end

function mod:addNewPlayer(player)

	local tauntPlayer = {
		player = player,
		vel = Vector(0, 0),
		pos = Vector(0, 0),
		tauntSpark = 0,
		tauntTimer = 0
	}
	table.insert(tauntPlayers, tauntPlayer)
	
	return tauntPlayer

end

function mod:getTauntPlayer(index)

	for i, tauntPlayer in ipairs(tauntPlayers) do
		if index == tauntPlayer.player.Index then
			return tauntPlayer
		end
	end
	
	return nil

end

-- I love reusing VATS code
function mod:onInput(entity, hook, action)

	if entity == nil then
		return
	end

	local tauntPlayer = mod:getTauntPlayer(entity.Index)

	if tauntPlayer == nil then
		tauntPlayer = mod:addNewPlayer(entity)
	end

	if tauntPlayer.tauntTimer <= 0 then
		if hook == InputHook.IS_ACTION_PRESSED then
			if action == ButtonAction.ACTION_DROP then
				if Input.IsButtonTriggered(settings.kbBind, entity:ToPlayer().ControllerIndex) or Input.IsButtonTriggered(settings.ctBind, entity:ToPlayer().ControllerIndex) then
					mod:doTaunt(entity)
					return false
				end
			end
		end
	else
		if not entity == nil then
			if hook == InputHook.IS_ACTION_PRESSED then
				return false
			elseif hook == InputHook.GET_ACTION_VALUE then
				return 0.0
			end
		end
	end
end

mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, mod.onInput)

function mod:onUpdate()

	local room = game:GetRoom()
	local roomEntities = room:GetEntities()

	for i, tauntPlayer in ipairs(tauntPlayers) do
		local entity = tauntPlayer.player

		if tauntPlayer.tauntTimer > 0 then
			tauntPlayer.tauntTimer = tauntPlayer.tauntTimer - 1
			
			if tauntPlayer.tauntTimer >= tauntLockout - tauntTime then
				entity.Position = tauntPlayer.pos
				entity.Velocity = Vector(0, 0)
			
				if tauntPlayer.tauntTimer <= tauntLockout - tauntTime then
					entity.Velocity = tauntPlayer.vel
					entity.Visible = true
					tauntPlayer.tauntSpark:Remove()
				end
			end
		end
		
		tauntPlayers[i] = tauntPlayer
	
	end
end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.onUpdate)

function mod:newRoom()

	for i, tauntPlayer in ipairs(tauntPlayers) do
		if tauntPlayer.tauntTimer > 0 then
			tauntPlayer.tauntTimer = 0
			tauntPlayer.tauntSpark:Remove()
		end
	end
	
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.newRoom)
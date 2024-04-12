local json = require("json")

local mod = RegisterMod("ROCK&STONE", 1)
local game = Game()
local sfx = SFXManager()

local rocktime = 18
local rockLockout = 30

local rockEffect = Isaac.GetEntityVariantByName("RockStone")

local rockSound = Isaac.GetSoundIdByName("ROCK")

local rockPlayers = {}

-- There may be other dwarf sprites here
local stoneList = {
	"StoneScout"
}


local settings = {
	kbBind = Keyboard.KEY_V,
	ctBind = 10,
	volume = 4
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
	
	local MOD_NAME = "Rock&Stone"
	
	ModConfigMenu.AddTitle(MOD_NAME, "Info", "Press the treasured button")
	ModConfigMenu.AddTitle(MOD_NAME, "Info", "to express all your emotions!")
	ModConfigMenu.AddTitle(MOD_NAME, "Info", "Rock and stone!")
	ModConfigMenu.AddText(MOD_NAME, "Info", "Mod made by Ruberoid")
	ModConfigMenu.AddText(MOD_NAME, "Info", "Don't forget to check out my other mods")
	
	ModConfigMenu.AddSpace(MOD_NAME, "Settings")

	ModConfigMenu.AddSetting(MOD_NAME, "Settings", {
		Type = ModConfigMenu.OptionType.NUMBER,
		CurrentSetting = function()
			return settings.volume
		end,
		Minimum = 0,
		Maximum = 4,
		Display = function()
			if settings.volume == nil then
				settings.volume = 0
			end
		    return settings.volume
		end,

		OnChange = function(currentNum)
			settings.volume = currentNum
			mod:saveConfig()
		end,
		Info = {"Put a bolt in ur dick"},
	})

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
		
		-- Popup panel
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
	rockPlayers = {}
end

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.clearPlayerTable)
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.clearPlayerTable)

function mod:doStone(player)

	stoneplayer = mod:getstoneplayer(player.Index)

	stoneplayer.vel = player.Velocity
	stoneplayer.pos = player.Position
	stoneplayer.stonespark = Isaac.Spawn(1000, rockEffect, 0, player.Position, Vector(0, 0), nil)
	stoneplayer.rocktimer = rockLockout
	
	player.Velocity = Vector(0, 0)
	
	-- TODO: This can be redone by just swapping out the sprites with SPRITEOBJECT:ReplaceSpritesheet()
	-- Not sure if this would become a disaster for memory but it'd remove the need for the anm2 editor in the workflow
	-- Sprites would need a consistent size though, which'd become a nightmare if a taunt is too big
	local sparkSprite = stoneplayer.stonespark:GetSprite()
	sparkSprite:Play(stoneList[math.random(1, #stoneList)], true)
	
	sfx:Play(rockSound, settings.volume, 0, false, 1, 0)
	player.Visible = false
end

function mod:addNewPlayer(player)

	local stoneplayer = {
		player = player,
		vel = Vector(0, 0),
		pos = Vector(0, 0),
		stonespark = 0,
		rocktimer = 0
	}
	table.insert(rockPlayers, stoneplayer)
	
	return stoneplayer

end

function mod:getstoneplayer(index)

	for i, stoneplayer in ipairs(rockPlayers) do
		if index == stoneplayer.player.Index then
			return stoneplayer
		end
	end
	
	return nil

end

-- I love reusing VATS code
function mod:onInput(entity, hook, action)

	if entity == nil then
		return
	end

	local stoneplayer = mod:getstoneplayer(entity.Index)

	if stoneplayer == nil then
		stoneplayer = mod:addNewPlayer(entity)
	end

	if stoneplayer.rocktimer <= 0 then
		if hook == InputHook.IS_ACTION_PRESSED then
			if action == ButtonAction.ACTION_DROP then
				if Input.IsButtonTriggered(settings.kbBind, entity:ToPlayer().ControllerIndex) or Input.IsButtonTriggered(settings.ctBind, entity:ToPlayer().ControllerIndex) then
					mod:doStone(entity)
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

	for i, stoneplayer in ipairs(rockPlayers) do
		local entity = stoneplayer.player

		if stoneplayer.rocktimer > 0 then
			stoneplayer.rocktimer = stoneplayer.rocktimer - 1
			
			if stoneplayer.rocktimer >= rockLockout - rocktime then
				entity.Position = stoneplayer.pos
				entity.Velocity = Vector(0, 0)
			
				if stoneplayer.rocktimer <= rockLockout - rocktime then
					entity.Velocity = stoneplayer.vel
					entity.Visible = true
					stoneplayer.stonespark:Remove()
				end
			end
		end
		
		rockPlayers[i] = stoneplayer
	
	end
end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.onUpdate)

function mod:newRoom()

	for i, stoneplayer in ipairs(rockPlayers) do
		if stoneplayer.rocktimer > 0 then
			stoneplayer.rocktimer = 0
			stoneplayer.stonespark:Remove()
		end
	end
	
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.newRoom)
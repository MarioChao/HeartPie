--!strict

-- Default Hit Effects


---------- Imports  ----------

local EffectsList = require(script.Parent.Parent:WaitForChild("EffectsList"))


---------- Types ----------

type EffectParameter = {
	throwerCharacter: Model,
	hitCharacter: Model?,
	pieMainPart: BasePart,
	hitPart: BasePart?,
}

type EffectFunction = (param: EffectParameter) -> ()

type EffectInfo = {
	ServerHit: EffectFunction?,
	ClientHit: EffectFunction?,
	ClientUseServer: boolean,
	HitCharacter: EffectFunction?,
}


---------- Module ----------

local PieEffects: {[string]: EffectInfo} = {}


----- General effects definition -----

local function dummy(param: EffectParameter)
end

local function damage5(param: EffectParameter)
	if param.hitCharacter then
		EffectsList.damageCharacter(param.hitCharacter, 5)
	end
end


----- Effects definition -----

PieEffects["Ten-Mou"] = {
	ServerHit = function(param: EffectParameter)
		EffectsList.orbEffectAtPart(param.pieMainPart, Color3.new(0.42, 0.76, 0.95), {0, 0}, {4, 8}, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	end,
	ClientUseServer = true,
	HitCharacter = damage5,
}

PieEffects["Moon"] = {
	ServerHit = function(param: EffectParameter)
		EffectsList.orbEffectAtPart(param.pieMainPart, Color3.new(0.95, 0.63, 0), {0, 0}, {4, 8}, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	end,
	ClientUseServer = true,
	HitCharacter = damage5,
}

PieEffects["Eye"] = {
	ServerHit = function(param: EffectParameter)
		EffectsList.orbEffectAtPart(param.pieMainPart, Color3.new(0.48, 0.41, 0.64), {0, 0}, {4, 8}, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	end,
	ClientUseServer = true,
	HitCharacter = damage5,
}

PieEffects["Stealth"] = {
	ServerHit = function(param: EffectParameter)
		EffectsList.orbEffectAtPart(param.pieMainPart, Color3.new(0.70, 0.14, 0.22), {0, 0}, {4, 8}, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	end,
	ClientUseServer = true,
	HitCharacter = damage5,
}

PieEffects["Cherry"] = {
	ServerHit = function(param: EffectParameter)
		EffectsList.orbEffectAtPart(param.pieMainPart, Color3.new(0.94, 0.61, 0.61), {0}, {6}, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	end,
	ClientUseServer = true,
	HitCharacter = damage5,
}

PieEffects["PumpkinPi"] = {
	ServerHit = function(param: EffectParameter)
		EffectsList.orbEffectAtPart(param.pieMainPart, Color3.new(0.95, 0.63, 0), {4, 8}, {0, 0}, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	end,
	ClientUseServer = true,
	HitCharacter = damage5,
}

PieEffects["Rhubarb"] = {
	ServerHit = function(param: EffectParameter)
		EffectsList.orbEffectAtPart(param.pieMainPart, Color3.new(0.992156, 0.568627, 1), {3}, {0}, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	end,
	ClientUseServer = true,
	HitCharacter = damage5,
}

PieEffects["Heart"] = {
	ServerHit = function(param: EffectParameter)
		EffectsList.orbEffectAtPart(param.pieMainPart, Color3.new(1, 0.54, 0.78), {0, 0}, {8, 4}, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	end,
	ClientUseServer = true,
	HitCharacter = damage5,
}

---------- Return module ----------

table.freeze(PieEffects)
return PieEffects

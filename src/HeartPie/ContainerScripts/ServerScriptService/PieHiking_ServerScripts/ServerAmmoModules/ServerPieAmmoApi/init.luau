--!strict

-- Server Pie Ammo Api


---------- Constants ----------

local Constants = {}

Constants.apiBindableEvent = script:WaitForChild("ApiBindableEvent")

table.freeze(Constants)


---------- Module ----------

local Module = {}


----- Module fields -----

function Module.createAndLaunch(ammoModel: Model, player: Player)
	Constants.apiBindableEvent:Fire("Create and Launch", ammoModel, player)
end

function Module.stickServerPieToPart(throwPieMainPart: BasePart, hitPart: BasePart, hitCFrame: CFrame, relativeCFrame: CFrame)
	Constants.apiBindableEvent:Fire("Stick Server Pie to Part", throwPieMainPart, hitPart, hitCFrame, relativeCFrame)
end

function Module.runPieHitCharacterEffect(throwerCharacter: Model, hitCharacter: Model, pieMainPart: BasePart)
	Constants.apiBindableEvent:Fire("Run Pie Hit Character Effect", throwerCharacter, hitCharacter, pieMainPart)
end

function Module.unstickServerPie(mainPart: BasePart)
	Constants.apiBindableEvent:Fire("Unstick", mainPart)
end

function Module.removeServerPie(mainPart: BasePart)
	Constants.apiBindableEvent:Fire("Remove", mainPart)
end


---------- Return module ----------

table.freeze(Module)
return Module

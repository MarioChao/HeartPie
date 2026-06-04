--!strict

-- Ammo Util


---------- Modules ----------

local Module = {}


----- Module fields -----

function Module.getConnectedCharacter(instance: Instance?): Model?
	-- Find a player's character by looking through root parts and parent instances
	local loopCount = 0
	local rootTable = {instance}
	while instance and loopCount < 20 do
		-- Check if instance is a character with a humanoid
		if instance:IsA("Model") and instance:FindFirstChildOfClass("Humanoid") then
			return instance
		end

		-- Update variables
		local parent: Instance? = instance.Parent
		if instance:IsA("BasePart") then
			-- Check the root part only if not checked yet
			if not table.find(rootTable, instance.AssemblyRootPart) then
				parent = instance.AssemblyRootPart
				table.insert(rootTable, instance.AssemblyRootPart)
			end
		end
		instance = parent
		loopCount += 1
	end
	return nil
end

function Module.checkCanHitCharacter(characterThrow: Model?, characterHit: Model?): boolean
	-- Check existence
	if not (characterThrow and characterHit) then
		return false
	end

	-- Check for hitting enemy npc
	local hitHumanoid = characterHit:FindFirstChildOfClass("Humanoid")
	if not hitHumanoid then
		return false
	end
	if hitHumanoid.Name == "Path" then
		-- (Enemy NPCs of Dream Game)
		return true
	end

	-- Check for pvp value
	if characterThrow:FindFirstChild("pvp") and characterHit:FindFirstChild("pvp") then
		return true
	end

	return false
end

function Module.getPieModel(instance: Instance?): Model?
	-- Find a pie model by looking through the parent instances
	local loopCount = 0
	while instance and loopCount < 20 do
		-- Check if instance is a pie model
		if instance:IsA("Model") and instance.Name == "PieModel" and instance:FindFirstChild("MainPart") then
			return instance
		end

		-- Update variables
		local parent: Instance? = instance:FindFirstAncestorWhichIsA("Model")
		instance = parent
		loopCount += 1
	end
	return nil
end

function Module.getDescendantParts(instance: Instance): {BasePart}
	local descendantParts: {BasePart} = {}
	for _, part in instance:GetDescendants() do
		if part:IsA("BasePart") then
			table.insert(descendantParts, part)
		end
	end
	return descendantParts
end

function Module.isPieAClientPie(pieModel: Model)
	local pieMainPart = pieModel and pieModel:FindFirstChild("MainPart")
	local pieUniqueId = pieModel and pieModel:FindFirstChild("UniquePieId")
	local pieTag = pieUniqueId and pieUniqueId:IsA("StringValue") and pieUniqueId.Value
	local _isClientPie = pieMainPart and pieMainPart:IsA("BasePart") and pieTag and typeof(pieTag) == "string"
	return _isClientPie == true
end

-- canCollide: Nil for originalCanCollide
function Module.setPieCollision(pieModel: Model, canCollide: boolean?)
	for _, part in Module.getDescendantParts(pieModel) do
		-- Collision
		if canCollide == nil then
			local originalCanCollide = part:FindFirstChild("OriginalCanCollide")
			if originalCanCollide and originalCanCollide:IsA("BoolValue") then
				part.CanCollide = originalCanCollide.Value
			end
		else
			part.CanCollide = canCollide
		end
	end
end


---------- Return module ----------

table.freeze(Module)
return Module

--!strict

-- Client Tool Visual


---------- Services ----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")


---------- Imports ----------

local _PieHiking_SharedStorage = ReplicatedStorage:WaitForChild("PieHiking_SharedStorage")
local _Modules = _PieHiking_SharedStorage:WaitForChild("Modules")
local BelovedRemote = require(_Modules:WaitForChild("BelovedRemote"))

local _ToolScripts = script.Parent.Parent.Parent
local Tooling = require(_ToolScripts:WaitForChild("Tooling"))


---------- Constants ----------

local Constants = {}

Constants.apiBindableEvent = script.Parent:WaitForChild("ApiBindableEvent")

table.freeze(Constants)


---------- Globals ----------

local Globals = {}

Globals.currentTransparency = nil :: number?


---------- Local functions ----------

local setPieModelTransparency
local onServerDoneSettingPieTransparency


----- Transparency -----

setPieModelTransparency = function(transparency: number?)
	-- Validate
	if not (transparency == nil or tonumber(transparency)) then
		return
	end

	-- Change transparency
	Globals.currentTransparency = transparency
	BelovedRemote.fire_toServer("Server Set Pie Transparency", transparency)
	for _, part in Tooling.pieModel:GetDescendants() do
		if part:IsA("BasePart") then
			local originalTransparency = part:FindFirstChild("OriginalTransparency")
			if transparency then
				part.Transparency = transparency
			elseif originalTransparency and originalTransparency:IsA("NumberValue") then
				part.Transparency = originalTransparency.Value
			end
		end
	end
end

onServerDoneSettingPieTransparency = function(transparency: number?)
	-- Set transparency back to current value for the Client
	for _, part in Tooling.pieModel:GetDescendants() do
		if part:IsA("BasePart") then
			-- Client's transparency
			local originalTransparency = part:FindFirstChild("OriginalTransparency")
			local clientTransparency: number? = nil
			if tonumber(Globals.currentTransparency) then
				clientTransparency = Globals.currentTransparency
			elseif originalTransparency and originalTransparency:IsA("NumberValue") then
				clientTransparency = originalTransparency.Value
			end

			-- Server's transparency
			local serverTransparency: number? = nil
			if tonumber(transparency) then
				serverTransparency = transparency
			elseif originalTransparency and originalTransparency:IsA("NumberValue") then
				serverTransparency = originalTransparency.Value
			end

			-- Change transparency if different
			if clientTransparency and clientTransparency ~= serverTransparency then
				part.Transparency = clientTransparency
			end
		end
	end
end


----- Main -----

local function main()
	Constants.apiBindableEvent.Event:Connect(function(mode: string, ...)
		if mode == "Set Pie Transparency" then
			setPieModelTransparency(...)
		end
	end)

	-- Remote events
	BelovedRemote.connect_toClient("Done Setting Pie Transparency", onServerDoneSettingPieTransparency)
	BelovedRemote.belovePlayer_RE_toServer("Done Setting Pie Transparency")

	task.defer(function()
		while not Tooling.pieModel:FindFirstChild("PieSkin") do
			task.wait()
		end
		setPieModelTransparency(nil)
	end)
end


---------- Calling function ----------

main()

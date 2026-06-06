--!strict

-- Tool Initializer

-- Sets the reference properties of the tool's instances


---------- Services ----------

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")


---------- Constants ----------

local Constants = {}

Constants.isCommandBar = not script
Constants.tool = (not Constants.isCommandBar and script.Parent.Parent) or Selection:Get()[1] :: typeof(script.Parent.Parent)
if not (Constants.tool and Constants.tool:IsA("Tool")) then
	return
end

Constants.pieModel = Constants.tool:WaitForChild("PieModel")
Constants.pieMainPart = Constants.pieModel:WaitForChild("MainPart")
Constants.pieAttachment = Constants.pieMainPart:WaitForChild("PieAttachment")
Constants.pieRightGripAttachment = Constants.pieMainPart:WaitForChild("PieRightGripAttachment")

Constants.pieSkinsFolder = Constants.tool:WaitForChild("CurrentPieSkins")

Constants.handle = Constants.tool:WaitForChild("Handle")
Constants.rightGripAttachment = Constants.handle:WaitForChild("RightGripAttachment")

table.freeze(Constants)


---------- Local functions ----------

local setUpPieSkin
local setUpPieSkinsReferences
local setUpPieModelReferences
local setUpReferenceProperties


----- Set up -----

setUpPieSkin = function(skin: Model)
	-- Validate skin main part
	local skinMainPart = skin:FindFirstChild("SkinMainPart")
	if not (skinMainPart and skinMainPart:IsA("BasePart")) then
		return
	end

	-- Get attachment
	local skinAttachment = skinMainPart:FindFirstChild("PieSkinAttachment")
	if not (skinAttachment and skinAttachment:IsA("Attachment")) then
		warn(`[Initializer]: No skin attachment found for skin {skin}.`)
		return
	end

	-- Set up rigid constraint
	local rigidConstraint = skinMainPart:FindFirstChild("RigidConstraint")
	if rigidConstraint and rigidConstraint:IsA("RigidConstraint") then
		rigidConstraint.Attachment0 = skinAttachment
		rigidConstraint.Attachment1 = Constants.pieAttachment
	else
		warn(`[Initializer]: No rigid constraint found for skin {skin}.`)
	end

	-- Set up mass
	for _, part in skin:GetDescendants() do
		if part:IsA("BasePart") then
			part.Massless = true
		end
	end
end

setUpPieSkinsReferences = function()
	for _, pieSkin in Constants.pieSkinsFolder:GetChildren() do
		setUpPieSkin(pieSkin)
	end
end

setUpPieModelReferences = function()
	-- Model primary part
	Constants.pieModel.PrimaryPart = Constants.pieMainPart

	-- Align orientation
	local alignOrientation = Constants.pieMainPart:WaitForChild("AlignOrientation")
	alignOrientation.Attachment0 = Constants.pieAttachment

	-- Rigid constraint
	local rigidConstraint = Constants.pieMainPart:WaitForChild("RigidConstraint")
	rigidConstraint.Attachment0 = Constants.pieRightGripAttachment
	rigidConstraint.Attachment1 = Constants.rightGripAttachment

	-- Upwards force
	local upwardsForce = Constants.pieMainPart:WaitForChild("UpwardsForce")
	upwardsForce.Attachment0 = Constants.pieAttachment
end

setUpReferenceProperties = function()
	if Constants.isCommandBar then
		ChangeHistoryService:SetWaypoint("Setting up pie reference properties")
		setUpPieModelReferences()
		setUpPieSkinsReferences()
		ChangeHistoryService:SetWaypoint("Set up pie reference properties")
	else
		task.defer(setUpPieModelReferences)
	end
end


----- Main -----

local function main()
	setUpReferenceProperties()
end


---------- Calling function ----------

main()

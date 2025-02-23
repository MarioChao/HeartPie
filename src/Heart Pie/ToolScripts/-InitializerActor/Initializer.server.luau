--!strict
--[[
Tool Initializer Script

Tasks:
- Set the reference properties of the tool's instances
]]

---------- Services ----------

local Selection = game:GetService("Selection")

---------- Instances ----------

local Tool = (script and script.Parent.Parent.Parent) or Selection:Get()[1]
if not Tool then
    return
end

local PieModel = Tool:WaitForChild("PieModel")
local PieMainPart = PieModel:WaitForChild("MainPart")
local PieAttachment = PieMainPart:WaitForChild("PieAttachment")
local PieRightGripAttachment = PieMainPart:WaitForChild("PieRightGripAttachment")

local Handle = Tool:WaitForChild("Handle")
local RightGripAttachment = Handle:WaitForChild("RightGripAttachment")

---------- Local functions ----------

local function setUpPieModelReferences()
    -- Model primary part
    PieModel.PrimaryPart = PieMainPart

    -- Align orientation
    local alignOrientation = PieMainPart:WaitForChild("AlignOrientation")
    alignOrientation.Attachment0 = PieAttachment

    -- Rigid constraint
    local rigidConstraint = PieMainPart:WaitForChild("RigidConstraint")
    rigidConstraint.Attachment0 = PieRightGripAttachment
    rigidConstraint.Attachment1 = RightGripAttachment

    -- Upwards force
    local upwardsForce = PieMainPart:WaitForChild("UpwardsForce")
    upwardsForce.Attachment0 = PieAttachment
end

local function setUpRefernceProperties()
    task.defer(setUpPieModelReferences)
end

---------- Calling / connecting functions----------

task.defer(setUpRefernceProperties)

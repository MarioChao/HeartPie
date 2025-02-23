--!strict
--[[
Tool Initializer Script

Tasks:
- Set the reference properties of the tool's instances
]]

---------- Services ----------

local Selection = game:GetService("Selection")

---------- Instances ----------

local isCommandBar = not script
local Tool = (script and script.Parent.Parent.Parent) or Selection:Get()[1]
if not Tool then
    return
end

local PieModel = Tool:WaitForChild("PieModel")
local PieMainPart = PieModel:WaitForChild("MainPart")
local PieAttachment = PieMainPart:WaitForChild("PieAttachment")
local PieRightGripAttachment = PieMainPart:WaitForChild("PieRightGripAttachment")

local PieSkins = Tool:WaitForChild("PieSkins")

local Handle = Tool:WaitForChild("Handle")
local RightGripAttachment = Handle:WaitForChild("RightGripAttachment")

---------- Local functions ----------

local function setUpSkinReferences(skin: Model)
    -- Validate skin main part
    local skinMainPart = skin:FindFirstChild("SkinMainPart")
    if not (skinMainPart and skinMainPart:IsA("Part")) then
        return
    end

    -- Get attachment
    local skinAttachment = skinMainPart:WaitForChild("PieSkinAttachment")

    -- Set up rigid constraint
    local rigidConstraint = skinMainPart:WaitForChild("RigidConstraint")
    rigidConstraint.Attachment0 = skinAttachment
    rigidConstraint.Attachment1 = PieAttachment
end

local function setUpPieSkinsReferences()
    for _, pieSkin in PieSkins:GetChildren() do
        setUpSkinReferences(pieSkin)
    end
end

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
    if isCommandBar then
        task.defer(setUpPieSkinsReferences)
    end
end

---------- Calling / connecting functions----------

task.defer(setUpRefernceProperties)

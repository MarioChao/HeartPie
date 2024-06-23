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

local PieSkins = Tool:WaitForChild("PieSkins")

local PieModel = Tool:WaitForChild("PieModel")
local PieMainPart = PieModel:WaitForChild("MainPart")
local PieAttachment = PieMainPart:WaitForChild("PieAttachment")
local PieRightGripAttachment = PieMainPart:WaitForChild("PieRightGripAttachment")

local Handle = Tool:WaitForChild("Handle")
local RightGripAttachment = Handle:WaitForChild("RightGripAttachment")

---------- Functions ----------
local function setUpSkinReferences(skin: Instance)
    -- Validate model
    if not skin:IsA("Model") then
        return
    end

    -- Validate skin main part
    local skinMainPart = skin:WaitForChild("SkinMainPart")
    if not (skinMainPart and skinMainPart:IsA("Part")) then
        return
    end

    -- Get attachment
    local skinAttachment = skinMainPart:WaitForChild("PieSkinAttachment")

    -- Rigid constraint
    local rigidConstraint = skinMainPart:WaitForChild("RigidConstraint")
    rigidConstraint.Attachment0 = skinAttachment
    rigidConstraint.Attachment1 = PieAttachment
end

local function setUpPieSkinsReferences()
    task.defer(function()
        for _, skin in PieSkins:GetChildren() do
            setUpSkinReferences(skin)
        end
    end)
    local connection = PieSkins.ChildAdded:Connect(setUpSkinReferences)
    task.wait(5)
    connection:Disconnect()
end

local function setUpPieModelReferences()
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

    task.defer(setUpPieSkinsReferences)
    task.defer(setUpPieModelReferences)
end

---------- Calling / connecting functions----------
task.defer(setUpRefernceProperties)

--!strict

-- Skin Util


---------- Types ----------

type SkinConfig = {
    doNotLoad: boolean,
    skinId: number,
    toolTextureId: string,
    toolTip: string,
}


---------- Local functions ----------

local getAttributeAssertType

----- Attributes -----

--- Function copied from ContainerEvent https://github.com/MarioChao/container-event
getAttributeAssertType = function(object: Instance, attributeName: string, expectedTypeOf: string)
    local attributeValue = object:GetAttribute(attributeName)
    local actualTypeOf = typeof(attributeValue)
    if actualTypeOf ~= expectedTypeOf then
        warn(
            `[Skin Util]: Attribute '{attributeName}' of '{object}' is type '{actualTypeOf}', ` ..
            `but expected '{expectedTypeOf}'.`
        )
    end
    return attributeValue
end


---------- Module ----------

local Module = {}


----- Module fields -----

function Module.getIsSkinModel(skinModel: Model)
    local skinConfig = Module.getSkinConfig(skinModel)
    local result = skinModel:IsA("Model") and skinConfig ~= nil
    return result
end

function Module.getSkinConfig(skinModel: Model)
    local skinConfigInstance = skinModel:FindFirstChild("SkinConfig")
    local result: SkinConfig?
    if skinConfigInstance then
        result = {
            doNotLoad = skinConfigInstance:GetAttribute("DoNotLoad") == true,
            skinId = tonumber(getAttributeAssertType(skinConfigInstance, "SkinId", "number")) or 0,
            toolTextureId = tostring(getAttributeAssertType(skinConfigInstance, "ToolTextureId", "string") or ""),
            toolTip = tostring(getAttributeAssertType(skinConfigInstance, "ToolTip", "string") or ""),
        }
    end
    return result
end


---------- Return module ----------

table.freeze(Module)
return Module

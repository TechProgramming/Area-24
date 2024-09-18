local module = {}

local LimbAttachments = {
	["Head"] =  {
		[1] = "FaceCenterAttachment",
		[2] = "FaceFrontAttachment",
		[3] = "HairAttachment",
		[4] = "HatAttachment",
		[5] = "NeckRigAttachment"
	},
	["HumanoidRootPart"] =  {
		[1] = "RootRigAttachment"
	},
	["LeftFoot"] =  {
		[1] = "LeftAnkleRigAttachment"
	},
	["LeftHand"] =  {
		[1] = "LeftWristRigAttachment",
		[2] = "LeftGripAttachment"
	},
	["LeftLowerArm"] =  {
		[1] = "LeftElbowRigAttachment",
		[2] = "LeftWristRigAttachment"
	},
	["LeftLowerLeg"] =  {
		[1] = "LeftKneeRigAttachment",
		[2] = "LeftAnkleRigAttachment"
	},
	["LeftUpperArm"] =  {
		[1] = "LeftShoulderRigAttachment",
		[2] = "LeftElbowRigAttachment",
		[3] = "LeftShoulderAttachment"
	},
	["LeftUpperLeg"] =  {
		[1] = "LeftHipRigAttachment",
		[2] = "LeftKneeRigAttachment"
	},
	["LowerTorso"] =  {
		[1] = "RootRigAttachment",
		[2] = "WaistRigAttachment",
		[3] = "LeftHipRigAttachment",
		[4] = "RightHipRigAttachment",
		[5] = "WaistCenterAttachment",
		[6] = "WaistFrontAttachment",
		[7] = "WaistBackAttachment"
	},
	["RightFoot"] =  {
		[1] = "RightAnkleRigAttachment"
	},
	["RightHand"] =  {
		[1] = "RightWristRigAttachment",
		[2] = "RightGripAttachment"
	},
	["RightLowerArm"] =  {
		[1] = "RightElbowRigAttachment",
		[2] = "RightWristRigAttachment"
	},
	["RightLowerLeg"] =  {
		[1] = "RightKneeRigAttachment",
		[2] = "RightAnkleRigAttachment"
	},
	["RightUpperArm"] =  {
		[1] = "RightShoulderRigAttachment",
		[2] = "RightElbowRigAttachment",
		[3] = "RightShoulderAttachment"
	},
	["RightUpperLeg"] =  {
		[1] = "RightHipRigAttachment",
		[2] = "RightKneeRigAttachment"
	},
	["UpperTorso"] =  {
		[1] = "WaistRigAttachment",
		[2] = "NeckRigAttachment",
		[3] = "LeftShoulderRigAttachment",
		[4] = "RightShoulderRigAttachment",
		[5] = "BodyFrontAttachment",
		[6] = "BodyBackAttachment",
		[7] = "LeftCollarAttachment",
		[8] = "RightCollarAttachment",
		[9] = "NeckAttachment"
	}
}

function module.getCharHumanoid(model)
	local curParent, lastParent = model, nil
	local hum = curParent:FindFirstChildOfClass("Humanoid")
	while curParent ~= workspace and hum == nil do
		lastParent = curParent
		curParent = curParent.Parent
		if curParent == nil then return nil, nil end
		
		hum = curParent:FindFirstChildOfClass("Humanoid")
	end
	local limb
	if hum then
		if lastParent:IsA("BasePart") then
			limb = lastParent
		elseif lastParent:IsA("Accessory") and lastParent:FindFirstChild("Handle") and lastParent.Handle:FindFirstChildWhichIsA("Attachment") then
			local orgAttachment = lastParent.Handle:FindFirstChildWhichIsA("Attachment")
			for limbName, v in ipairs(LimbAttachments) do
				for _, attchName in ipairs(v) do
					if attchName == orgAttachment.Name then
						limb = model[limbName]
						break
					end
				end
			end
		end
		if limb == nil then
			limb = hum.Parent.HumanoidRootPart
		end
	end
	if hum ~= nil and hum.Parent:IsA("Model") then
		return hum, limb
	else
		return nil
	end
end

function module.applyWeaponSkin(weapon)
	
end

return module
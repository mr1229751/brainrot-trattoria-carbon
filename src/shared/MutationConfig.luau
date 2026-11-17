-- MutationConfig.luau
-- Mutation definitions, probability rolls, and primitive/material visual transformers.

local MutationConfig = {}

MutationConfig.Types = {
	None = {
		id = "None",
		displayName = "",
		badgeText = "",
		multiplier = 1,
		chance = 0,
		color = Color3.fromRGB(230, 230, 240),
		order = 0,
	},
	Radioactive = {
		id = "Radioactive",
		displayName = "RADIOACTIVE",
		badgeText = "[RADIOACTIVE 3x]",
		shortBadge = "RAD 3x",
		multiplier = 3,
		chance = 0.10,
		color = Color3.fromRGB(95, 255, 65),
		order = 1,
	},
	Golden = {
		id = "Golden",
		displayName = "GOLDEN",
		badgeText = "[GOLDEN 8x]",
		shortBadge = "GOLD 8x",
		multiplier = 8,
		chance = 0.02,
		color = Color3.fromRGB(255, 212, 48),
		order = 2,
	},
	Void = {
		id = "Void",
		displayName = "VOID",
		badgeText = "[VOID 25x]",
		shortBadge = "VOID 25x",
		multiplier = 25,
		chance = 0.002,
		color = Color3.fromRGB(215, 65, 255),
		order = 3,
	},
}

MutationConfig.OrderedNames = { "Radioactive", "Golden", "Void" }

function MutationConfig.getMutationInfo(mutationName: string?)
	if not mutationName or not MutationConfig.Types[mutationName] then
		return MutationConfig.Types.None
	end
	return MutationConfig.Types[mutationName]
end

function MutationConfig.getMultiplier(mutationName: string?): number
	return MutationConfig.getMutationInfo(mutationName).multiplier
end

-- Rolls Void (0.2%) -> Golden (2%) -> Radioactive (10%) -> None, scaled by rebirth luck
function MutationConfig.rollMutation(luckMultiplier: number?): string
	local luck = math.clamp(luckMultiplier or 1, 1, 5)
	local roll = math.random()

	local voidThreshold = MutationConfig.Types.Void.chance * luck
	local goldenThreshold = voidThreshold + (MutationConfig.Types.Golden.chance * luck)
	local radThreshold = goldenThreshold + (MutationConfig.Types.Radioactive.chance * math.min(luck, 2.2))

	if roll < voidThreshold then
		return "Void"
	elseif roll < goldenThreshold then
		return "Golden"
	elseif roll < radThreshold then
		return "Radioactive"
	end
	return "None"
end

local function createOrbitStar(parent: Instance, index: number, centerCFrame: CFrame): Model
	local starModel = Instance.new("Model")
	starModel.Name = "OrbitStar_" .. tostring(index)

	local angle = (index - 1) * ((math.pi * 2) / 3)
	local offset = Vector3.new(math.cos(angle) * 2.8, 2.4, math.sin(angle) * 2.8)
	local starCF = centerCFrame * CFrame.new(offset)

	local p1 = Instance.new("Part")
	p1.Name = "StarCore"
	p1.Size = Vector3.new(0.65, 0.65, 0.22)
	p1.Material = Enum.Material.Neon
	p1.Color = Color3.fromRGB(255, 236, 95)
	p1.Anchored = true
	p1.CanCollide = false
	p1.CanQuery = false
	p1.CanTouch = false
	p1.CastShadow = false
	p1.CFrame = starCF * CFrame.Angles(0, 0, math.rad(45))
	p1.Parent = starModel

	local p2 = p1:Clone()
	p2.Name = "StarCross"
	p2.CFrame = starCF
	p2.Parent = starModel

	starModel.PrimaryPart = p1
	starModel:SetAttribute("OrbitIndex", index)
	starModel.Parent = parent
	return starModel
end

function MutationConfig.applyMutationVisuals(model: Model, mutationName: string?)
	local info = MutationConfig.getMutationInfo(mutationName)
	model:SetAttribute("Mutation", info.id)
	if info.id == "None" then
		return
	end

	local root = model.PrimaryPart
	if not root then
		return
	end

	-- Remove any existing rarity highlight so mutation highlight takes clean precedence
	local existingHighlight = model:FindFirstChildOfClass("Highlight")
	if existingHighlight then
		existingHighlight:Destroy()
	end

	if info.id == "Radioactive" then
		for _, inst in ipairs(model:GetDescendants()) do
			if inst:IsA("BasePart") and inst ~= root and not inst:GetAttribute("FaceDetail") then
				inst.Material = Enum.Material.Neon
				inst.Color = Color3.fromRGB(92, 255, 62)
			end
		end

		local hl = Instance.new("Highlight")
		hl.Name = "MutationHighlight"
		hl.FillColor = Color3.fromRGB(75, 255, 55)
		hl.FillTransparency = 0.62
		hl.OutlineColor = Color3.fromRGB(195, 255, 145)
		hl.OutlineTransparency = 0.08
		hl.Parent = model

		local att = Instance.new("Attachment")
		att.Name = "RadEmitterAtt"
		att.Position = Vector3.new(0, 2.2, 0)
		att.Parent = root

		local bubbles = Instance.new("ParticleEmitter")
		bubbles.Name = "RadioactiveBubbles"
		bubbles.Color = ColorSequence.new(Color3.fromRGB(95, 255, 65), Color3.fromRGB(210, 255, 165))
		bubbles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.25),
			NumberSequenceKeypoint.new(0.6, 0.55),
			NumberSequenceKeypoint.new(1, 0),
		})
		bubbles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.15),
			NumberSequenceKeypoint.new(0.8, 0.35),
			NumberSequenceKeypoint.new(1, 1),
		})
		bubbles.LightEmission = 0.9
		bubbles.Lifetime = NumberRange.new(0.9, 1.5)
		bubbles.Rate = 18
		bubbles.Speed = NumberRange.new(2.2, 4.8)
		bubbles.SpreadAngle = Vector2.new(35, 35)
		bubbles.Acceleration = Vector3.new(0, 5.5, 0)
		bubbles.Parent = att

		local glow = Instance.new("PointLight")
		glow.Name = "MutationLight"
		glow.Color = Color3.fromRGB(95, 255, 65)
		glow.Brightness = 2.2
		glow.Range = 14
		glow.Parent = root

	elseif info.id == "Golden" then
		local idx = 0
		for _, inst in ipairs(model:GetDescendants()) do
			if inst:IsA("BasePart") and inst ~= root and not inst:GetAttribute("FaceDetail") then
				idx += 1
				inst.Material = if idx % 3 == 0 then Enum.Material.Glass else Enum.Material.Foil
				inst.Reflectance = 0.42
				inst.Color = if idx % 2 == 0
					then Color3.fromRGB(255, 206, 45)
					else Color3.fromRGB(255, 224, 92)
			end
		end

		local hl = Instance.new("Highlight")
		hl.Name = "MutationHighlight"
		hl.FillColor = Color3.fromRGB(255, 210, 48)
		hl.FillTransparency = 0.68
		hl.OutlineColor = Color3.fromRGB(255, 248, 175)
		hl.OutlineTransparency = 0.05
		hl.Parent = model

		local orbitFolder = Instance.new("Folder")
		orbitFolder.Name = "OrbitStars"
		orbitFolder.Parent = model
		for i = 1, 3 do
			createOrbitStar(orbitFolder, i, root.CFrame)
		end

		local glow = Instance.new("PointLight")
		glow.Name = "MutationLight"
		glow.Color = Color3.fromRGB(255, 215, 70)
		glow.Brightness = 2.6
		glow.Range = 16
		glow.Parent = root

	elseif info.id == "Void" then
		for _, inst in ipairs(model:GetDescendants()) do
			if inst:IsA("BasePart") and inst ~= root and not inst:GetAttribute("FaceDetail") then
				inst.Material = Enum.Material.ForceField
				inst.Color = Color3.fromRGB(24, 8, 42)
				inst.Transparency = 0.12
			end
		end

		-- Pulsing purple neon Void core inside chest
		local voidCore = Instance.new("Part")
		voidCore.Name = "VoidNeonCore"
		voidCore.Shape = Enum.PartType.Ball
		voidCore.Size = Vector3.new(2.1, 2.1, 2.1)
		voidCore.Material = Enum.Material.Neon
		voidCore.Color = Color3.fromRGB(175, 42, 255)
		voidCore.Anchored = true
		voidCore.CanCollide = false
		voidCore.CanQuery = false
		voidCore.CanTouch = false
		voidCore.CastShadow = false
		voidCore.CFrame = root.CFrame * CFrame.new(0, 2.4, 0)
		voidCore:SetAttribute("BaseOffset", Vector3.new(0, 2.4, 0))
		voidCore.Parent = model

		local hl = Instance.new("Highlight")
		hl.Name = "MutationHighlight"
		hl.FillColor = Color3.fromRGB(130, 22, 235)
		hl.FillTransparency = 0.55
		hl.OutlineColor = Color3.fromRGB(255, 65, 235)
		hl.OutlineTransparency = 0.04
		hl.Parent = model

		-- Magenta Void Trail
		local att0 = Instance.new("Attachment")
		att0.Name = "VoidTrailTop"
		att0.Position = Vector3.new(0, 3.6, 0)
		att0.Parent = root

		local att1 = Instance.new("Attachment")
		att1.Name = "VoidTrailBottom"
		att1.Position = Vector3.new(0, 0.9, 0)
		att1.Parent = root

		local trail = Instance.new("Trail")
		trail.Name = "VoidMagentaTrail"
		trail.Attachment0 = att0
		trail.Attachment1 = att1
		trail.Color = ColorSequence.new(Color3.fromRGB(255, 55, 230), Color3.fromRGB(115, 20, 255))
		trail.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.12),
			NumberSequenceKeypoint.new(1, 1),
		})
		trail.LightEmission = 1
		trail.Lifetime = 0.65
		trail.MinLength = 0.05
		trail.FaceCamera = true
		trail.Parent = root

		local glow = Instance.new("PointLight")
		glow.Name = "MutationLight"
		glow.Color = Color3.fromRGB(215, 55, 255)
		glow.Brightness = 2.8
		glow.Range = 18
		glow.Parent = root
	end
end

return MutationConfig

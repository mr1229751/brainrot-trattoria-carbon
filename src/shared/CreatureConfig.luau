-- CreatureConfig.luau
-- Roster of 18 original 3D primitive-built Brainrot creatures across 7 rarities,
-- complete with rarity ladder styling, procedural geometry builders, auras, and BillboardGuis.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FormatUtil = require(ReplicatedStorage:WaitForChild("FormatUtil"))
local MutationConfig = require(ReplicatedStorage:WaitForChild("MutationConfig"))

local CreatureConfig = {}

CreatureConfig.Rarities = {
	Common = {
		name = "Common",
		order = 1,
		color = Color3.fromRGB(190, 196, 210),
		bgColor = Color3.fromRGB(44, 46, 58),
		glowIntensity = 0,
		hasParticles = false,
	},
	Uncommon = {
		name = "Uncommon",
		order = 2,
		color = Color3.fromRGB(75, 238, 118),
		bgColor = Color3.fromRGB(24, 62, 38),
		glowIntensity = 0,
		hasParticles = false,
	},
	Rare = {
		name = "Rare",
		order = 3,
		color = Color3.fromRGB(65, 175, 255),
		bgColor = Color3.fromRGB(22, 48, 86),
		glowIntensity = 1.4,
		hasParticles = true,
	},
	Epic = {
		name = "Epic",
		order = 4,
		color = Color3.fromRGB(198, 92, 255),
		bgColor = Color3.fromRGB(58, 24, 88),
		glowIntensity = 1.9,
		hasParticles = true,
	},
	Legendary = {
		name = "Legendary",
		order = 5,
		color = Color3.fromRGB(255, 206, 45),
		bgColor = Color3.fromRGB(78, 56, 14),
		glowIntensity = 2.4,
		hasParticles = true,
	},
	Mythic = {
		name = "Mythic",
		order = 6,
		color = Color3.fromRGB(255, 65, 132),
		bgColor = Color3.fromRGB(84, 18, 46),
		glowIntensity = 2.8,
		hasParticles = true,
	},
	Secret = {
		name = "Secret",
		order = 7,
		color = Color3.fromRGB(255, 115, 245),
		bgColor = Color3.fromRGB(48, 18, 76),
		glowIntensity = 3.3,
		hasParticles = true,
		isRainbow = true,
	},
}

CreatureConfig.RarityOrder = {
	"Common",
	"Uncommon",
	"Rare",
	"Epic",
	"Legendary",
	"Mythic",
	"Secret",
}

-- Primitive helper functions (Front of creature is -Z in Roblox CFrame space)
local function addPart(
	model: Model,
	root: BasePart,
	name: string,
	shape: Enum.PartType,
	size: Vector3,
	offsetCF: CFrame,
	color: Color3,
	material: Enum.Material?,
	isFaceDetail: boolean?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = true
	p.CFrame = root.CFrame * offsetCF
	if isFaceDetail then
		p:SetAttribute("FaceDetail", true)
	end
	p.Parent = model
	return p
end

local function addWedge(
	model: Model,
	root: BasePart,
	name: string,
	size: Vector3,
	offsetCF: CFrame,
	color: Color3,
	material: Enum.Material?,
	isFaceDetail: boolean?
): WedgePart
	local w = Instance.new("WedgePart")
	w.Name = name
	w.Size = size
	w.Color = color
	w.Material = material or Enum.Material.SmoothPlastic
	w.Anchored = true
	w.CanCollide = false
	w.CanQuery = false
	w.CanTouch = false
	w.CastShadow = true
	w.CFrame = root.CFrame * offsetCF
	if isFaceDetail then
		w:SetAttribute("FaceDetail", true)
	end
	w.Parent = model
	return w
end

local function addGoofyEyes(model: Model, root: BasePart, y: number, z: number, spread: number, scale: number?)
	local s = scale or 1
	local white = Color3.fromRGB(250, 250, 255)
	local pupil = Color3.fromRGB(20, 18, 28)
	addPart(model, root, "EyeL", Enum.PartType.Ball, Vector3.new(0.52, 0.58, 0.32) * s, CFrame.new(-spread, y, z), white, Enum.Material.SmoothPlastic, true)
	addPart(model, root, "EyeR", Enum.PartType.Ball, Vector3.new(0.52, 0.58, 0.32) * s, CFrame.new(spread, y, z), white, Enum.Material.SmoothPlastic, true)
	addPart(model, root, "PupilL", Enum.PartType.Ball, Vector3.new(0.26, 0.3, 0.22) * s, CFrame.new(-spread + 0.04, y + 0.02, z - 0.12 * s), pupil, Enum.Material.SmoothPlastic, true)
	addPart(model, root, "PupilR", Enum.PartType.Ball, Vector3.new(0.26, 0.3, 0.22) * s, CFrame.new(spread - 0.04, y - 0.02, z - 0.12 * s), pupil, Enum.Material.SmoothPlastic, true)
end

local function addBrows(model: Model, root: BasePart, y: number, z: number, spread: number, tiltDeg: number, color: Color3?)
	local c = color or Color3.fromRGB(32, 24, 42)
	addPart(model, root, "BrowL", Enum.PartType.Block, Vector3.new(0.55, 0.14, 0.18), CFrame.new(-spread, y, z) * CFrame.Angles(0, 0, math.rad(-tiltDeg)), c, Enum.Material.SmoothPlastic, true)
	addPart(model, root, "BrowR", Enum.PartType.Block, Vector3.new(0.55, 0.14, 0.18), CFrame.new(spread, y, z) * CFrame.Angles(0, 0, math.rad(tiltDeg)), c, Enum.Material.SmoothPlastic, true)
end

-- Roster of 18 unique original Brainrot creatures
CreatureConfig.Roster = {
	-- ==================== COMMON ====================
	{
		CreatureID = "rigatoni_rex",
		DisplayName = "Rigatoni Rex",
		Rarity = "Common",
		PurchasePrice = 25,
		IncomePerSecond = 3,
		SpawnWeight = 320,
		WalkSpeed = 10.5,
		HeightStuds = 4.6,
		Description = "A pasta-tube dinosaur with tiny arms and zero thoughts behind those eyes.",
		AnimationSettings = { bobAmplitude = 0.18, bobFrequency = 3.2, spinSpeed = 0, tiltAmount = 4 },
		Builder = function(model: Model, root: BasePart)
			local pasta = Color3.fromRGB(250, 206, 72)
			local pastaDark = Color3.fromRGB(218, 165, 42)
			local basil = Color3.fromRGB(62, 205, 85)
			addPart(model, root, "LegL", Enum.PartType.Block, Vector3.new(0.65, 1.2, 0.75), CFrame.new(-0.65, 0.6, 0), pastaDark)
			addPart(model, root, "LegR", Enum.PartType.Block, Vector3.new(0.65, 1.2, 0.75), CFrame.new(0.65, 0.6, 0), pastaDark)
			addPart(model, root, "TubeBody", Enum.PartType.Cylinder, Vector3.new(2.6, 2.1, 2.1), CFrame.new(0, 2.3, 0) * CFrame.Angles(0, 0, math.rad(90)), pasta)
			addPart(model, root, "TubeHole", Enum.PartType.Cylinder, Vector3.new(2.66, 1.1, 1.1), CFrame.new(0, 2.3, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(95, 58, 22), Enum.Material.SmoothPlastic, true)
			addPart(model, root, "Snout", Enum.PartType.Block, Vector3.new(1.55, 0.95, 1.2), CFrame.new(0, 3.05, -1.05), pasta)
			addPart(model, root, "Tooth1", Enum.PartType.Block, Vector3.new(0.28, 0.32, 0.16), CFrame.new(-0.28, 2.5, -1.55), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, true)
			addPart(model, root, "Tooth2", Enum.PartType.Block, Vector3.new(0.28, 0.32, 0.16), CFrame.new(0.28, 2.5, -1.55), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, true)
			addPart(model, root, "TinyArmL", Enum.PartType.Block, Vector3.new(0.32, 0.32, 0.75), CFrame.new(-1.05, 2.15, -0.85) * CFrame.Angles(math.rad(-20), 0, 0), pastaDark)
			addPart(model, root, "TinyArmR", Enum.PartType.Block, Vector3.new(0.32, 0.32, 0.75), CFrame.new(1.05, 2.15, -0.85) * CFrame.Angles(math.rad(-20), 0, 0), pastaDark)
			addWedge(model, root, "DinoTail", Vector3.new(0.85, 1.1, 1.8), CFrame.new(0, 1.5, 1.55) * CFrame.Angles(0, math.rad(180), 0), pastaDark)
			addPart(model, root, "BasilLeaf1", Enum.PartType.Ball, Vector3.new(0.95, 0.28, 0.55), CFrame.new(-0.35, 3.78, -0.2) * CFrame.Angles(0, 0, math.rad(22)), basil)
			addPart(model, root, "BasilLeaf2", Enum.PartType.Ball, Vector3.new(0.95, 0.28, 0.55), CFrame.new(0.35, 3.78, -0.2) * CFrame.Angles(0, 0, math.rad(-22)), basil)
			addGoofyEyes(model, root, 3.45, -1.15, 0.48, 1.05)
		end,
	},
	{
		CreatureID = "espresso_goblin",
		DisplayName = "Signor Espresso",
		Rarity = "Common",
		PurchasePrice = 65,
		IncomePerSecond = 7,
		SpawnWeight = 250,
		WalkSpeed = 12.5,
		HeightStuds = 4.4,
		Description = "Runs on 47 shots of dark roast and vibrates through solid concrete.",
		AnimationSettings = { bobAmplitude = 0.24, bobFrequency = 5.5, spinSpeed = 0, tiltAmount = 6 },
		Builder = function(model: Model, root: BasePart)
			local cup = Color3.fromRGB(245, 242, 250)
			local red = Color3.fromRGB(235, 58, 72)
			local coffee = Color3.fromRGB(72, 38, 22)
			addPart(model, root, "ShoeL", Enum.PartType.Block, Vector3.new(0.68, 0.45, 1.05), CFrame.new(-0.6, 0.22, -0.15), red)
			addPart(model, root, "ShoeR", Enum.PartType.Block, Vector3.new(0.68, 0.45, 1.05), CFrame.new(0.6, 0.22, -0.15), red)
			addPart(model, root, "LegL", Enum.PartType.Cylinder, Vector3.new(0.8, 0.35, 0.35), CFrame.new(-0.6, 0.75, 0) * CFrame.Angles(0, 0, math.rad(90)), cup)
			addPart(model, root, "LegR", Enum.PartType.Cylinder, Vector3.new(0.8, 0.35, 0.35), CFrame.new(0.6, 0.75, 0) * CFrame.Angles(0, 0, math.rad(90)), cup)
			addPart(model, root, "CupTorso", Enum.PartType.Cylinder, Vector3.new(2.1, 2.35, 2.35), CFrame.new(0, 2.1, 0) * CFrame.Angles(0, 0, math.rad(90)), cup)
			addPart(model, root, "StripeBand", Enum.PartType.Cylinder, Vector3.new(0.36, 2.42, 2.42), CFrame.new(0, 1.85, 0) * CFrame.Angles(0, 0, math.rad(90)), red)
			addPart(model, root, "EspressoTop", Enum.PartType.Cylinder, Vector3.new(0.22, 2.15, 2.15), CFrame.new(0, 3.12, 0) * CFrame.Angles(0, 0, math.rad(90)), coffee, Enum.Material.SmoothPlastic, true)
			addPart(model, root, "SaucerHat", Enum.PartType.Cylinder, Vector3.new(0.2, 2.9, 2.9), CFrame.new(0, 3.45, 0.1) * CFrame.Angles(math.rad(-12), 0, math.rad(90)), cup)
			addPart(model, root, "WhippedSwirl", Enum.PartType.Ball, Vector3.new(1.1, 0.9, 1.1), CFrame.new(0, 3.85, 0.1), Color3.fromRGB(255, 248, 225))
			addPart(model, root, "CupHandle", Enum.PartType.Cylinder, Vector3.new(0.32, 1.25, 1.25), CFrame.new(1.25, 2.15, 0), cup)
			addGoofyEyes(model, root, 2.45, -1.16, 0.46, 1.2)
			addBrows(model, root, 2.88, -1.18, 0.48, -14)
			addPart(model, root, "JitterMouth", Enum.PartType.Block, Vector3.new(0.75, 0.22, 0.18), CFrame.new(0, 1.85, -1.2), coffee, Enum.Material.SmoothPlastic, true)
		end,
	},
	{
		CreatureID = "garlic_goober",
		DisplayName = "Garlic Goober",
		Rarity = "Common",
		PurchasePrice = 140,
		IncomePerSecond = 14,
		SpawnWeight = 195,
		WalkSpeed = 10.0,
		HeightStuds = 4.3,
		Description = "Smells from three bases away. Proudly wields Nonna's wooden spoon.",
		AnimationSettings = { bobAmplitude = 0.2, bobFrequency = 3.0, spinSpeed = 0, tiltAmount = 5 },
		Builder = function(model: Model, root: BasePart)
			local bulb = Color3.fromRGB(248, 240, 222)
			local clove = Color3.fromRGB(232, 216, 195)
			local rootPurple = Color3.fromRGB(132, 72, 168)
			addPart(model, root, "BootL", Enum.PartType.Ball, Vector3.new(0.85, 0.6, 1.1), CFrame.new(-0.62, 0.3, -0.1), rootPurple)
			addPart(model, root, "BootR", Enum.PartType.Ball, Vector3.new(0.85, 0.6, 1.1), CFrame.new(0.62, 0.3, -0.1), rootPurple)
			addPart(model, root, "MainBulb", Enum.PartType.Ball, Vector3.new(2.5, 2.4, 2.4), CFrame.new(0, 1.85, 0), bulb)
			addPart(model, root, "CloveL", Enum.PartType.Ball, Vector3.new(1.5, 2.0, 1.8), CFrame.new(-0.75, 1.75, 0.1), clove)
			addPart(model, root, "CloveR", Enum.PartType.Ball, Vector3.new(1.5, 2.0, 1.8), CFrame.new(0.75, 1.75, 0.1), clove)
			addPart(model, root, "Sprout", Enum.PartType.Cylinder, Vector3.new(1.0, 0.45, 0.45), CFrame.new(0, 3.25, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(115, 215, 78))
			addGoofyEyes(model, root, 2.15, -1.15, 0.45, 1.05)
			addPart(model, root, "Unibrow", Enum.PartType.Block, Vector3.new(1.35, 0.2, 0.22), CFrame.new(0, 2.52, -1.18), rootPurple, Enum.Material.SmoothPlastic, true)
			addPart(model, root, "DerpTongue", Enum.PartType.Ball, Vector3.new(0.45, 0.55, 0.35), CFrame.new(0.18, 1.48, -1.22), Color3.fromRGB(255, 105, 145), Enum.Material.SmoothPlastic, true)
			-- Wooden spoon wand
			addPart(model, root, "SpoonShaft", Enum.PartType.Cylinder, Vector3.new(2.3, 0.2, 0.2), CFrame.new(1.45, 2.0, -0.55) * CFrame.Angles(math.rad(25), 0, math.rad(75)), Color3.fromRGB(185, 128, 72))
			addPart(model, root, "SpoonBowl", Enum.PartType.Ball, Vector3.new(0.65, 0.85, 0.3), CFrame.new(1.62, 3.05, -0.95), Color3.fromRGB(185, 128, 72))
		end,
	},

	-- ==================== UNCOMMON ====================
	{
		CreatureID = "vespa_pigeon",
		DisplayName = "Scooter Piccione",
		Rarity = "Uncommon",
		PurchasePrice = 350,
		IncomePerSecond = 28,
		SpawnWeight = 135,
		WalkSpeed = 13.5,
		HeightStuds = 4.7,
		Description = "Stole a tiny red scooter in Rome and refuses to yield to anyone.",
		AnimationSettings = { bobAmplitude = 0.14, bobFrequency = 4.5, spinSpeed = 0, tiltAmount = 3 },
		Builder = function(model: Model, root: BasePart)
			local scooterRed = Color3.fromRGB(238, 48, 68)
			local pigeonTeal = Color3.fromRGB(88, 152, 185)
			local wheelDark = Color3.fromRGB(28, 26, 36)
			addPart(model, root, "WheelFront", Enum.PartType.Cylinder, Vector3.new(0.45, 1.15, 1.15), CFrame.new(0, 0.58, -1.25), wheelDark)
			addPart(model, root, "WheelRear", Enum.PartType.Cylinder, Vector3.new(0.45, 1.15, 1.15), CFrame.new(0, 0.58, 1.15), wheelDark)
			addPart(model, root, "ScooterDeck", Enum.PartType.Block, Vector3.new(1.2, 0.42, 2.7), CFrame.new(0, 0.72, -0.05), scooterRed)
			addPart(model, root, "FrontShield", Enum.PartType.Block, Vector3.new(1.15, 1.65, 0.35), CFrame.new(0, 1.55, -1.2) * CFrame.Angles(math.rad(-14), 0, 0), scooterRed)
			addPart(model, root, "Handlebar", Enum.PartType.Cylinder, Vector3.new(1.75, 0.2, 0.2), CFrame.new(0, 2.35, -1.05), Color3.fromRGB(220, 225, 235), Enum.Material.Metal)
			addPart(model, root, "Headlight", Enum.PartType.Ball, Vector3.new(0.48, 0.48, 0.35), CFrame.new(0, 2.25, -1.35), Color3.fromRGB(255, 240, 130), Enum.Material.Neon, true)
			addPart(model, root, "Seat", Enum.PartType.Block, Vector3.new(1.1, 0.65, 1.25), CFrame.new(0, 1.2, 0.55), wheelDark)
			-- Pigeon rider
			addPart(model, root, "PigeonBody", Enum.PartType.Ball, Vector3.new(1.65, 1.85, 1.75), CFrame.new(0, 2.25, 0.35), pigeonTeal)
			addPart(model, root, "PigeonHead", Enum.PartType.Ball, Vector3.new(1.25, 1.25, 1.25), CFrame.new(0, 3.35, 0.05), Color3.fromRGB(110, 185, 210))
			addWedge(model, root, "Beak", Vector3.new(0.45, 0.38, 0.7), CFrame.new(0, 3.25, -0.78) * CFrame.Angles(math.rad(90), 0, 0), Color3.fromRGB(255, 165, 35), Enum.Material.SmoothPlastic, true)
			addPart(model, root, "GoggleL", Enum.PartType.Cylinder, Vector3.new(0.25, 0.5, 0.5), CFrame.new(-0.34, 3.68, -0.48) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(65, 235, 255), Enum.Material.Neon, true)
			addPart(model, root, "GoggleR", Enum.PartType.Cylinder, Vector3.new(0.25, 0.5, 0.5), CFrame.new(0.34, 3.68, -0.48) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(65, 235, 255), Enum.Material.Neon, true)
			addGoofyEyes(model, root, 3.38, -0.52, 0.34, 0.85)
		end,
	},
	{
		CreatureID = "mozzarella_monk",
		DisplayName = "Mozzarella Boss",
		Rarity = "Uncommon",
		PurchasePrice = 800,
		IncomePerSecond = 60,
		SpawnWeight = 98,
		WalkSpeed = 9.8,
		HeightStuds = 4.6,
		Description = "Freshly stretched cheese don in a fedora. Runs the dairy syndicate.",
		AnimationSettings = { bobAmplitude = 0.16, bobFrequency = 2.6, spinSpeed = 0, tiltAmount = 3 },
		Builder = function(model: Model, root: BasePart)
			local cheese = Color3.fromRGB(252, 248, 240)
			local suit = Color3.fromRGB(115, 28, 56)
			local hatBlack = Color3.fromRGB(32, 24, 42)
			local gold = Color3.fromRGB(255, 205, 52)
			addPart(model, root, "ShoeL", Enum.PartType.Block, Vector3.new(0.72, 0.45, 1.1), CFrame.new(-0.65, 0.22, -0.1), hatBlack)
			addPart(model, root, "ShoeR", Enum.PartType.Block, Vector3.new(0.72, 0.45, 1.1), CFrame.new(0.65, 0.22, -0.1), hatBlack)
			addPart(model, root, "SuitLower", Enum.PartType.Cylinder, Vector3.new(1.3, 2.35, 2.35), CFrame.new(0, 1.2, 0) * CFrame.Angles(0, 0, math.rad(90)), suit)
			addPart(model, root, "CheeseSphere", Enum.PartType.Ball, Vector3.new(2.55, 2.35, 2.45), CFrame.new(0, 2.35, 0), cheese)
			addPart(model, root, "GoldChain", Enum.PartType.Cylinder, Vector3.new(0.22, 1.85, 1.85), CFrame.new(0, 1.65, -0.35) * CFrame.Angles(math.rad(25), 0, math.rad(90)), gold, Enum.Material.Metal)
			addPart(model, root, "FedoraBrim", Enum.PartType.Cylinder, Vector3.new(0.18, 2.85, 2.85), CFrame.new(0, 3.45, -0.05) * CFrame.Angles(math.rad(6), 0, math.rad(90)), hatBlack)
			addPart(model, root, "FedoraCrown", Enum.PartType.Cylinder, Vector3.new(0.9, 1.8, 1.8), CFrame.new(0, 3.9, -0.05) * CFrame.Angles(math.rad(6), 0, math.rad(90)), hatBlack)
			addPart(model, root, "FedoraBand", Enum.PartType.Cylinder, Vector3.new(0.22, 1.86, 1.86), CFrame.new(0, 3.6, -0.05) * CFrame.Angles(math.rad(6), 0, math.rad(90)), gold)
			-- Floating tomato bodyguards
			addPart(model, root, "TomatoL", Enum.PartType.Cylinder, Vector3.new(0.28, 0.95, 0.95), CFrame.new(-1.85, 2.4, 0) * CFrame.Angles(0, 0, math.rad(25)), Color3.fromRGB(240, 52, 52))
			addPart(model, root, "TomatoR", Enum.PartType.Cylinder, Vector3.new(0.28, 0.95, 0.95), CFrame.new(1.85, 2.4, 0) * CFrame.Angles(0, 0, math.rad(-25)), Color3.fromRGB(240, 52, 52))
			addGoofyEyes(model, root, 2.68, -1.16, 0.46, 1.0)
			addBrows(model, root, 3.0, -1.2, 0.46, 12, hatBlack)
		end,
	},
	{
		CreatureID = "gelato_giraffe",
		DisplayName = "Gelato Giraffe",
		Rarity = "Uncommon",
		PurchasePrice = 1750,
		IncomePerSecond = 125,
		SpawnWeight = 74,
		WalkSpeed = 10.5,
		HeightStuds = 5.8,
		Description = "Triple-scoop waffle tower risking total meltdown for extra cash.",
		AnimationSettings = { bobAmplitude = 0.22, bobFrequency = 2.8, spinSpeed = 0, tiltAmount = 5 },
		Builder = function(model: Model, root: BasePart)
			local cone = Color3.fromRGB(224, 168, 96)
			local pistachio = Color3.fromRGB(138, 232, 142)
			local strawberry = Color3.fromRGB(255, 128, 175)
			local mango = Color3.fromRGB(255, 202, 68)
			addPart(model, root, "LegFL", Enum.PartType.Cylinder, Vector3.new(1.3, 0.36, 0.36), CFrame.new(-0.55, 0.65, -0.45) * CFrame.Angles(0, 0, math.rad(90)), cone)
			addPart(model, root, "LegFR", Enum.PartType.Cylinder, Vector3.new(1.3, 0.36, 0.36), CFrame.new(0.55, 0.65, -0.45) * CFrame.Angles(0, 0, math.rad(90)), cone)
			addPart(model, root, "LegBL", Enum.PartType.Cylinder, Vector3.new(1.3, 0.36, 0.36), CFrame.new(-0.55, 0.65, 0.55) * CFrame.Angles(0, 0, math.rad(90)), cone)
			addPart(model, root, "LegBR", Enum.PartType.Cylinder, Vector3.new(1.3, 0.36, 0.36), CFrame.new(0.55, 0.65, 0.55) * CFrame.Angles(0, 0, math.rad(90)), cone)
			addPart(model, root, "WaffleBody", Enum.PartType.Block, Vector3.new(1.6, 1.1, 2.0), CFrame.new(0, 1.55, 0.05), cone)
			addPart(model, root, "WaffleNeck", Enum.PartType.Cylinder, Vector3.new(1.75, 0.95, 0.95), CFrame.new(0, 2.75, -0.35) * CFrame.Angles(0, 0, math.rad(90)), cone)
			addPart(model, root, "Scoop1", Enum.PartType.Ball, Vector3.new(1.75, 1.45, 1.75), CFrame.new(0, 3.65, -0.35), pistachio)
			addPart(model, root, "Scoop2", Enum.PartType.Ball, Vector3.new(1.5, 1.35, 1.5), CFrame.new(0, 4.55, -0.35), strawberry)
			addPart(model, root, "Scoop3", Enum.PartType.Ball, Vector3.new(1.2, 1.1, 1.2), CFrame.new(0, 5.3, -0.35), mango)
			addPart(model, root, "CherryTop", Enum.PartType.Ball, Vector3.new(0.5, 0.5, 0.5), CFrame.new(0, 5.95, -0.35), Color3.fromRGB(245, 32, 58), Enum.Material.Neon)
			addPart(model, root, "WaferStraw", Enum.PartType.Cylinder, Vector3.new(1.4, 0.24, 0.24), CFrame.new(0.65, 5.45, -0.35) * CFrame.Angles(0, 0, math.rad(55)), cone)
			addGoofyEyes(model, root, 3.75, -1.16, 0.38, 0.95)
		end,
	},

	-- ==================== RARE ====================
	{
		CreatureID = "accordion_crab",
		DisplayName = "Maestro Crostaceo",
		Rarity = "Rare",
		PurchasePrice = 4200,
		IncomePerSecond = 290,
		SpawnWeight = 48,
		WalkSpeed = 11.0,
		HeightStuds = 4.6,
		Description = "Pinches thieves in 3/4 waltz time while squeezing an electric accordion.",
		AnimationSettings = { bobAmplitude = 0.22, bobFrequency = 3.6, spinSpeed = 0, tiltAmount = 7 },
		Builder = function(model: Model, root: BasePart)
			local crabBlue = Color3.fromRGB(48, 155, 255)
			local bellowRed = Color3.fromRGB(235, 55, 88)
			local pearl = Color3.fromRGB(245, 245, 255)
			for side = -1, 1, 2 do
				for k = -1, 1 do
					addPart(model, root, "CrabLeg", Enum.PartType.Block, Vector3.new(0.95, 0.28, 0.28), CFrame.new(side * 1.45, 0.55, k * 0.55) * CFrame.Angles(0, 0, math.rad(side * -32)), crabBlue)
				end
			end
			-- Accordion pleated chest
			addPart(model, root, "EndCapL", Enum.PartType.Block, Vector3.new(0.45, 1.85, 1.55), CFrame.new(-1.25, 1.85, 0), pearl)
			addPart(model, root, "EndCapR", Enum.PartType.Block, Vector3.new(0.45, 1.85, 1.55), CFrame.new(1.25, 1.85, 0), pearl)
			for p = -2, 2 do
				local col = if p % 2 == 0 then bellowRed else Color3.fromRGB(38, 28, 52)
				addPart(model, root, "Pleat", Enum.PartType.Block, Vector3.new(0.36, 1.65, 1.35), CFrame.new(p * 0.4, 1.85, 0), col)
			end
			-- Big raised claws
			addPart(model, root, "ClawArmL", Enum.PartType.Cylinder, Vector3.new(1.2, 0.4, 0.4), CFrame.new(-1.75, 2.75, -0.35) * CFrame.Angles(0, 0, math.rad(65)), crabBlue)
			addPart(model, root, "ClawL", Enum.PartType.Ball, Vector3.new(1.15, 1.35, 0.95), CFrame.new(-2.05, 3.45, -0.45), bellowRed)
			addPart(model, root, "ClawArmR", Enum.PartType.Cylinder, Vector3.new(1.2, 0.4, 0.4), CFrame.new(1.75, 2.75, -0.35) * CFrame.Angles(0, 0, math.rad(-65)), crabBlue)
			addPart(model, root, "ClawR", Enum.PartType.Ball, Vector3.new(1.15, 1.35, 0.95), CFrame.new(2.05, 3.45, -0.45), bellowRed)
			-- Eye stalks & mustache
			addPart(model, root, "StalkL", Enum.PartType.Cylinder, Vector3.new(0.7, 0.24, 0.24), CFrame.new(-0.48, 3.05, -0.35) * CFrame.Angles(0, 0, math.rad(90)), crabBlue)
			addPart(model, root, "StalkR", Enum.PartType.Cylinder, Vector3.new(0.7, 0.24, 0.24), CFrame.new(0.48, 3.05, -0.35) * CFrame.Angles(0, 0, math.rad(90)), crabBlue)
			addGoofyEyes(model, root, 3.48, -0.42, 0.48, 1.1)
			addPart(model, root, "MustacheL", Enum.PartType.Ball, Vector3.new(0.85, 0.28, 0.28), CFrame.new(-0.42, 2.15, -0.82) * CFrame.Angles(0, 0, math.rad(16)), Color3.fromRGB(24, 20, 32), Enum.Material.SmoothPlastic, true)
			addPart(model, root, "MustacheR", Enum.PartType.Ball, Vector3.new(0.85, 0.28, 0.28), CFrame.new(0.42, 2.15, -0.82) * CFrame.Angles(0, 0, math.rad(-16)), Color3.fromRGB(24, 20, 32), Enum.Material.SmoothPlastic, true)
		end,
	},
	{
		CreatureID = "cannoli_cannon",
		DisplayName = "Capitano Cannoli",
		Rarity = "Rare",
		PurchasePrice = 9500,
		IncomePerSecond = 640,
		SpawnWeight = 34,
		WalkSpeed = 9.5,
		HeightStuds = 4.8,
		Description = "Heavy pastry artillery loaded with sweet ricotta and high-caliber profit.",
		AnimationSettings = { bobAmplitude = 0.14, bobFrequency = 3.8, spinSpeed = 0, tiltAmount = 2 },
		Builder = function(model: Model, root: BasePart)
			local pastry = Color3.fromRGB(224, 162, 84)
			local cream = Color3.fromRGB(252, 248, 242)
			local tread = Color3.fromRGB(42, 48, 66)
			addPart(model, root, "TreadL", Enum.PartType.Block, Vector3.new(0.65, 0.85, 2.8), CFrame.new(-1.15, 0.42, 0), tread, Enum.Material.Metal)
			addPart(model, root, "TreadR", Enum.PartType.Block, Vector3.new(0.65, 0.85, 2.8), CFrame.new(1.15, 0.42, 0), tread, Enum.Material.Metal)
			addPart(model, root, "Chassis", Enum.PartType.Block, Vector3.new(1.85, 0.75, 2.3), CFrame.new(0, 0.95, 0), Color3.fromRGB(58, 125, 215), Enum.Material.Metal)
			-- Cannoli shell barrel aligned front-to-back
			addPart(model, root, "PastryShell", Enum.PartType.Cylinder, Vector3.new(2.9, 2.05, 2.05), CFrame.new(0, 2.2, 0) * CFrame.Angles(0, math.rad(90), 0), pastry)
			addPart(model, root, "RicottaFront", Enum.PartType.Ball, Vector3.new(1.85, 1.85, 1.0), CFrame.new(0, 2.2, -1.35), cream)
			addPart(model, root, "RicottaBack", Enum.PartType.Ball, Vector3.new(1.85, 1.85, 1.0), CFrame.new(0, 2.2, 1.35), cream)
			addPart(model, root, "ToqueBase", Enum.PartType.Cylinder, Vector3.new(0.75, 1.35, 1.35), CFrame.new(0, 3.45, -0.1) * CFrame.Angles(0, 0, math.rad(90)), cream)
			addPart(model, root, "ToquePuff", Enum.PartType.Ball, Vector3.new(1.75, 1.15, 1.75), CFrame.new(0, 4.05, -0.1), cream)
			addPart(model, root, "MuzzleGlow", Enum.PartType.Cylinder, Vector3.new(0.18, 0.85, 0.85), CFrame.new(0, 1.85, -1.82) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(65, 195, 255), Enum.Material.Neon, true)
			addGoofyEyes(model, root, 2.55, -1.72, 0.44, 1.0)
			addBrows(model, root, 2.9, -1.75, 0.44, 15)
		end,
	},
	{
		CreatureID = "gondola_gator",
		DisplayName = "Gondola Gator",
		Rarity = "Rare",
		PurchasePrice = 22000,
		IncomePerSecond = 1450,
		SpawnWeight = 25,
		WalkSpeed = 11.2,
		HeightStuds = 4.9,
		Description = "Sings romantic serenades while chomping through rival bank accounts.",
		AnimationSettings = { bobAmplitude = 0.25, bobFrequency = 2.9, spinSpeed = 0, tiltAmount = 5 },
		Builder = function(model: Model, root: BasePart)
			local emerald = Color3.fromRGB(42, 188, 108)
			local stripeRed = Color3.fromRGB(235, 52, 68)
			local straw = Color3.fromRGB(245, 212, 118)
			addPart(model, root, "FootL", Enum.PartType.Block, Vector3.new(0.75, 0.45, 1.15), CFrame.new(-0.7, 0.22, -0.15), emerald)
			addPart(model, root, "FootR", Enum.PartType.Block, Vector3.new(0.75, 0.45, 1.15), CFrame.new(0.7, 0.22, -0.15), emerald)
			addPart(model, root, "ShirtTorso", Enum.PartType.Block, Vector3.new(1.85, 1.9, 1.55), CFrame.new(0, 1.55, 0), Color3.fromRGB(248, 248, 252))
			for s = -1, 1 do
				addPart(model, root, "RedStripe", Enum.PartType.Block, Vector3.new(1.9, 0.26, 1.6), CFrame.new(0, 1.55 + s * 0.55, 0), stripeRed)
			end
			addWedge(model, root, "GatorTail", Vector3.new(0.95, 0.9, 2.1), CFrame.new(0, 0.95, 1.75) * CFrame.Angles(0, math.rad(180), 0), emerald)
			addPart(model, root, "GatorHead", Enum.PartType.Block, Vector3.new(1.55, 1.05, 1.45), CFrame.new(0, 3.05, -0.1), emerald)
			addPart(model, root, "LongSnout", Enum.PartType.Block, Vector3.new(1.25, 0.62, 1.55), CFrame.new(0, 2.88, -1.35), emerald)
			addPart(model, root, "TeethRow", Enum.PartType.Block, Vector3.new(1.1, 0.18, 1.3), CFrame.new(0, 2.55, -1.3), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, true)
			addPart(model, root, "BoaterBrim", Enum.PartType.Cylinder, Vector3.new(0.16, 2.5, 2.5), CFrame.new(0, 3.68, -0.05) * CFrame.Angles(0, 0, math.rad(90)), straw)
			addPart(model, root, "BoaterTop", Enum.PartType.Cylinder, Vector3.new(0.65, 1.55, 1.55), CFrame.new(0, 4.02, -0.05) * CFrame.Angles(0, 0, math.rad(90)), straw)
			addPart(model, root, "HatRibbon", Enum.PartType.Cylinder, Vector3.new(0.2, 1.6, 1.6), CFrame.new(0, 3.82, -0.05) * CFrame.Angles(0, 0, math.rad(90)), stripeRed)
			-- Golden Gondola Oar
			addPart(model, root, "GoldenOar", Enum.PartType.Cylinder, Vector3.new(4.2, 0.22, 0.22), CFrame.new(1.35, 2.35, -0.25) * CFrame.Angles(math.rad(18), 0, math.rad(76)), Color3.fromRGB(255, 208, 52), Enum.Material.Metal)
			addPart(model, root, "OarBlade", Enum.PartType.Block, Vector3.new(0.18, 1.15, 0.55), CFrame.new(1.85, 0.65, 0.35), Color3.fromRGB(255, 208, 52), Enum.Material.Metal)
			addGoofyEyes(model, root, 3.35, -0.82, 0.44, 1.0)
		end,
	},

	-- ==================== EPIC ====================
	{
		CreatureID = "lasagna_mech",
		DisplayName = "Mecha Lasagna 9000",
		Rarity = "Epic",
		PurchasePrice = 55000,
		IncomePerSecond = 3500,
		SpawnWeight = 15,
		WalkSpeed = 9.5,
		HeightStuds = 5.6,
		Description = "Five armored layers of pasta, cyber-ricotta, and dual parmesan blasters.",
		AnimationSettings = { bobAmplitude = 0.22, bobFrequency = 2.6, spinSpeed = 0, tiltAmount = 3 },
		Builder = function(model: Model, root: BasePart)
			local pasta = Color3.fromRGB(250, 204, 65)
			local sauce = Color3.fromRGB(255, 58, 72)
			local ricotta = Color3.fromRGB(248, 244, 255)
			local steel = Color3.fromRGB(52, 42, 78)
			addPart(model, root, "MechBootL", Enum.PartType.Block, Vector3.new(0.95, 1.35, 1.25), CFrame.new(-0.85, 0.68, 0), steel, Enum.Material.Metal)
			addPart(model, root, "MechBootR", Enum.PartType.Block, Vector3.new(0.95, 1.35, 1.25), CFrame.new(0.85, 0.68, 0), steel, Enum.Material.Metal)
			-- 5 stacked lasagna layers
			local layerColors = { pasta, sauce, ricotta, pasta, sauce }
			for i, col in ipairs(layerColors) do
				local mat = if col == sauce then Enum.Material.Neon else Enum.Material.SmoothPlastic
				addPart(model, root, "Layer" .. i, Enum.PartType.Block, Vector3.new(2.65, 0.44, 2.05), CFrame.new(0, 1.25 + i * 0.44, 0), col, mat)
			end
			addPart(model, root, "MechHead", Enum.PartType.Block, Vector3.new(1.65, 1.15, 1.45), CFrame.new(0, 4.25, 0), steel, Enum.Material.Metal)
			addPart(model, root, "CyberVisor", Enum.PartType.Block, Vector3.new(1.35, 0.42, 0.22), CFrame.new(0, 4.28, -0.72), Color3.fromRGB(65, 240, 255), Enum.Material.Neon, true)
			addPart(model, root, "ShoulderPodL", Enum.PartType.Block, Vector3.new(0.9, 0.9, 1.45), CFrame.new(-1.8, 3.55, -0.2), steel, Enum.Material.Metal)
			addPart(model, root, "ShoulderPodR", Enum.PartType.Block, Vector3.new(0.9, 0.9, 1.45), CFrame.new(1.8, 3.55, -0.2), steel, Enum.Material.Metal)
			addPart(model, root, "BlasterMuzzleL", Enum.PartType.Cylinder, Vector3.new(0.6, 0.55, 0.55), CFrame.new(-1.8, 3.55, -1.05) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(205, 95, 255), Enum.Material.Neon, true)
			addPart(model, root, "BlasterMuzzleR", Enum.PartType.Cylinder, Vector3.new(0.6, 0.55, 0.55), CFrame.new(1.8, 3.55, -1.05) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(205, 95, 255), Enum.Material.Neon, true)
		end,
	},
	{
		CreatureID = "opera_octopus",
		DisplayName = "Diva Tentacolo",
		Rarity = "Epic",
		PurchasePrice = 135000,
		IncomePerSecond = 8400,
		SpawnWeight = 10.5,
		WalkSpeed = 10.5,
		HeightStuds = 5.0,
		Description = "Hits high C loud enough to shatter windows while counting stacks with 8 arms.",
		AnimationSettings = { bobAmplitude = 0.32, bobFrequency = 3.1, spinSpeed = 0.4, tiltAmount = 6 },
		Builder = function(model: Model, root: BasePart)
			local violet = Color3.fromRGB(168, 68, 248)
			local magenta = Color3.fromRGB(245, 78, 195)
			local gold = Color3.fromRGB(255, 210, 58)
			for t = 0, 7 do
				local ang = math.rad(t * 45)
				addWedge(model, root, "Tentacle" .. t, Vector3.new(0.65, 0.85, 1.65), CFrame.new(math.cos(ang) * 1.45, 0.45, math.sin(ang) * 1.45) * CFrame.Angles(0, -ang + math.rad(90), 0), magenta)
			end
			addPart(model, root, "OctoMantle", Enum.PartType.Ball, Vector3.new(2.75, 2.95, 2.65), CFrame.new(0, 2.45, 0), violet)
			addPart(model, root, "BowtieL", Enum.PartType.Block, Vector3.new(0.55, 0.38, 0.22), CFrame.new(-0.32, 1.35, -1.25) * CFrame.Angles(0, 0, math.rad(18)), Color3.fromRGB(25, 20, 35), Enum.Material.SmoothPlastic, true)
			addPart(model, root, "BowtieR", Enum.PartType.Block, Vector3.new(0.55, 0.38, 0.22), CFrame.new(0.32, 1.35, -1.25) * CFrame.Angles(0, 0, math.rad(-18)), Color3.fromRGB(25, 20, 35), Enum.Material.SmoothPlastic, true)
			addPart(model, root, "OperaCrown", Enum.PartType.Cylinder, Vector3.new(0.55, 1.3, 1.3), CFrame.new(0, 4.05, 0) * CFrame.Angles(0, 0, math.rad(90)), gold, Enum.Material.Neon)
			addGoofyEyes(model, root, 2.75, -1.24, 0.52, 1.15)
			addPart(model, root, "Monocle", Enum.PartType.Cylinder, Vector3.new(0.14, 0.82, 0.82), CFrame.new(0.52, 2.75, -1.36) * CFrame.Angles(0, math.rad(90), 0), gold, Enum.Material.Neon, true)
			addPart(model, root, "SingingMouth", Enum.PartType.Cylinder, Vector3.new(0.24, 0.72, 0.72), CFrame.new(0, 1.98, -1.28) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(35, 12, 42), Enum.Material.SmoothPlastic, true)
			-- Golden Microphone stand
			addPart(model, root, "MicStand", Enum.PartType.Cylinder, Vector3.new(2.2, 0.16, 0.16), CFrame.new(-1.45, 1.65, -0.95) * CFrame.Angles(0, 0, math.rad(90)), gold, Enum.Material.Metal)
			addPart(model, root, "MicHead", Enum.PartType.Ball, Vector3.new(0.55, 0.65, 0.55), CFrame.new(-1.45, 2.85, -0.95), gold, Enum.Material.Neon)
		end,
	},
	{
		CreatureID = "truffle_boar",
		DisplayName = "Barone Tartufo",
		Rarity = "Epic",
		PurchasePrice = 320000,
		IncomePerSecond = 19500,
		SpawnWeight = 7.5,
		WalkSpeed = 10.8,
		HeightStuds = 4.9,
		Description = "Aristocratic truffle-hunting hog draped in velvet and pure luxury.",
		AnimationSettings = { bobAmplitude = 0.24, bobFrequency = 3.2, spinSpeed = 0, tiltAmount = 4 },
		Builder = function(model: Model, root: BasePart)
			local plum = Color3.fromRGB(108, 48, 148)
			local capeRed = Color3.fromRGB(215, 38, 92)
			local gold = Color3.fromRGB(255, 210, 55)
			local snoutPink = Color3.fromRGB(255, 145, 185)
			for sx = -1, 1, 2 do
				for sz = -1, 1, 2 do
					addPart(model, root, "Hoof", Enum.PartType.Block, Vector3.new(0.6, 0.85, 0.6), CFrame.new(sx * 0.72, 0.42, sz * 0.75), gold, Enum.Material.Metal)
				end
			end
			addPart(model, root, "BoarBody", Enum.PartType.Ball, Vector3.new(2.55, 2.15, 2.95), CFrame.new(0, 1.85, 0.1), plum)
			addPart(model, root, "RoyalCape", Enum.PartType.Block, Vector3.new(2.35, 1.8, 0.35), CFrame.new(0, 1.95, 1.55) * CFrame.Angles(math.rad(18), 0, 0), capeRed)
			addPart(model, root, "Snout", Enum.PartType.Cylinder, Vector3.new(0.65, 1.15, 1.15), CFrame.new(0, 1.95, -1.45) * CFrame.Angles(0, math.rad(90), 0), snoutPink, Enum.Material.SmoothPlastic, true)
			addWedge(model, root, "TuskL", Vector3.new(0.28, 0.85, 0.42), CFrame.new(-0.72, 2.15, -1.45) * CFrame.Angles(math.rad(-15), 0, math.rad(18)), gold, Enum.Material.Neon)
			addWedge(model, root, "TuskR", Vector3.new(0.28, 0.85, 0.42), CFrame.new(0.72, 2.15, -1.45) * CFrame.Angles(math.rad(-15), 0, math.rad(-18)), gold, Enum.Material.Neon)
			-- Levitating diamond Truffle Crown
			addPart(model, root, "TruffleGem", Enum.PartType.Block, Vector3.new(1.05, 1.05, 1.05), CFrame.new(0, 3.85, -0.15) * CFrame.Angles(math.rad(45), math.rad(45), 0), Color3.fromRGB(195, 85, 255), Enum.Material.Neon)
			addGoofyEyes(model, root, 2.55, -1.28, 0.48, 1.05)
			addBrows(model, root, 2.92, -1.32, 0.5, 18, gold)
		end,
	},

	-- ==================== LEGENDARY ====================
	{
		CreatureID = "vesuvius_drake",
		DisplayName = "Don Vesuvio",
		Rarity = "Legendary",
		PurchasePrice = 850000,
		IncomePerSecond = 52000,
		SpawnWeight = 4.2,
		WalkSpeed = 10.2,
		HeightStuds = 5.5,
		Description = "Volcanic magma boss wearing obsidian shades and wielding the Golden Fork.",
		AnimationSettings = { bobAmplitude = 0.28, bobFrequency = 2.8, spinSpeed = 0, tiltAmount = 5 },
		Builder = function(model: Model, root: BasePart)
			local obsidian = Color3.fromRGB(36, 26, 52)
			local magma = Color3.fromRGB(255, 145, 28)
			local gold = Color3.fromRGB(255, 212, 52)
			addPart(model, root, "DrakeLegL", Enum.PartType.Block, Vector3.new(0.85, 1.15, 1.05), CFrame.new(-0.8, 0.58, 0), obsidian, Enum.Material.Slate)
			addPart(model, root, "DrakeLegR", Enum.PartType.Block, Vector3.new(0.85, 1.15, 1.05), CFrame.new(0.8, 0.58, 0), obsidian, Enum.Material.Slate)
			addPart(model, root, "VolcanoTorso", Enum.PartType.Ball, Vector3.new(2.75, 2.65, 2.55), CFrame.new(0, 2.2, 0), obsidian, Enum.Material.Slate)
			addPart(model, root, "LavaBelly", Enum.PartType.Ball, Vector3.new(1.95, 1.95, 1.25), CFrame.new(0, 2.1, -0.82), magma, Enum.Material.Neon)
			addPart(model, root, "CraterHead", Enum.PartType.Cylinder, Vector3.new(1.25, 1.85, 1.85), CFrame.new(0, 3.75, -0.1) * CFrame.Angles(0, 0, math.rad(90)), obsidian, Enum.Material.Slate)
			addPart(model, root, "CraterLava", Enum.PartType.Cylinder, Vector3.new(0.28, 1.45, 1.45), CFrame.new(0, 4.3, -0.1) * CFrame.Angles(0, 0, math.rad(90)), gold, Enum.Material.Neon)
			addWedge(model, root, "WingL", Vector3.new(0.32, 1.65, 1.95), CFrame.new(-1.75, 2.65, 0.45) * CFrame.Angles(0, math.rad(-65), math.rad(25)), magma, Enum.Material.Neon)
			addWedge(model, root, "WingR", Vector3.new(0.32, 1.65, 1.95), CFrame.new(1.75, 2.65, 0.45) * CFrame.Angles(0, math.rad(65), math.rad(-25)), magma, Enum.Material.Neon)
			-- Cool shades
			addPart(model, root, "ShadesBar", Enum.PartType.Block, Vector3.new(1.65, 0.42, 0.32), CFrame.new(0, 3.75, -0.98), Color3.fromRGB(14, 12, 20), Enum.Material.SmoothPlastic, true)
			addPart(model, root, "ShadesTrim", Enum.PartType.Block, Vector3.new(1.7, 0.1, 0.35), CFrame.new(0, 3.95, -0.98), gold, Enum.Material.Neon, true)
			-- Golden Pasta Fork Trident
			addPart(model, root, "TridentShaft", Enum.PartType.Cylinder, Vector3.new(3.8, 0.24, 0.24), CFrame.new(1.65, 2.55, -0.55) * CFrame.Angles(0, 0, math.rad(82)), gold, Enum.Material.Neon)
			for prong = -1, 1 do
				addPart(model, root, "Prong" .. prong, Enum.PartType.Block, Vector3.new(0.16, 0.85, 0.16), CFrame.new(1.78 + prong * 0.26, 4.55, -0.55), gold, Enum.Material.Neon)
			end
		end,
	},
	{
		CreatureID = "colosseum_golem",
		DisplayName = "Gladiatore Grande",
		Rarity = "Legendary",
		PurchasePrice = 2200000,
		IncomePerSecond = 135000,
		SpawnWeight = 2.6,
		WalkSpeed = 9.2,
		HeightStuds = 5.9,
		Description = "Ancient marble-and-gold arena colossus armed with a blazing pizza cutter.",
		AnimationSettings = { bobAmplitude = 0.2, bobFrequency = 2.4, spinSpeed = 0, tiltAmount = 2 },
		Builder = function(model: Model, root: BasePart)
			local marble = Color3.fromRGB(244, 238, 226)
			local gold = Color3.fromRGB(255, 205, 48)
			local crimson = Color3.fromRGB(238, 45, 72)
			addPart(model, root, "PillarLegL", Enum.PartType.Cylinder, Vector3.new(1.5, 0.9, 0.9), CFrame.new(-0.85, 0.75, 0) * CFrame.Angles(0, 0, math.rad(90)), marble, Enum.Material.Marble)
			addPart(model, root, "PillarLegR", Enum.PartType.Cylinder, Vector3.new(1.5, 0.9, 0.9), CFrame.new(0.85, 0.75, 0) * CFrame.Angles(0, 0, math.rad(90)), marble, Enum.Material.Marble)
			addPart(model, root, "FortressChest", Enum.PartType.Block, Vector3.new(2.9, 2.35, 2.0), CFrame.new(0, 2.65, 0), marble, Enum.Material.Marble)
			addPart(model, root, "GoldBelt", Enum.PartType.Block, Vector3.new(3.05, 0.38, 2.12), CFrame.new(0, 1.65, 0), gold, Enum.Material.Metal)
			addPart(model, root, "ArchCore", Enum.PartType.Cylinder, Vector3.new(0.4, 1.35, 1.35), CFrame.new(0, 2.75, -0.92) * CFrame.Angles(0, math.rad(90), 0), gold, Enum.Material.Neon)
			addPart(model, root, "HelmHead", Enum.PartType.Block, Vector3.new(1.65, 1.35, 1.55), CFrame.new(0, 4.45, 0), gold, Enum.Material.Metal)
			addPart(model, root, "PlumeCrest", Enum.PartType.Block, Vector3.new(0.42, 0.95, 1.95), CFrame.new(0, 5.45, 0.1), crimson, Enum.Material.Neon)
			addPart(model, root, "EyeGlowL", Enum.PartType.Ball, Vector3.new(0.38, 0.32, 0.25), CFrame.new(-0.42, 4.45, -0.78), Color3.fromRGB(65, 240, 255), Enum.Material.Neon, true)
			addPart(model, root, "EyeGlowR", Enum.PartType.Ball, Vector3.new(0.38, 0.32, 0.25), CFrame.new(0.42, 4.45, -0.78), Color3.fromRGB(65, 240, 255), Enum.Material.Neon, true)
			-- Round Roman Shield & Pizza-Cutter Halberd
			addPart(model, root, "RomanShield", Enum.PartType.Cylinder, Vector3.new(0.32, 2.25, 2.25), CFrame.new(-1.85, 2.65, -0.45), gold, Enum.Material.Metal)
			addPart(model, root, "CutterPole", Enum.PartType.Cylinder, Vector3.new(3.8, 0.24, 0.24), CFrame.new(1.85, 2.75, -0.35) * CFrame.Angles(0, 0, math.rad(90)), gold, Enum.Material.Metal)
			addPart(model, root, "PizzaWheel", Enum.PartType.Cylinder, Vector3.new(0.22, 1.55, 1.55), CFrame.new(1.85, 4.85, -0.35), crimson, Enum.Material.Neon)
		end,
	},

	-- ==================== MYTHIC ====================
	{
		CreatureID = "pasta_seraph",
		DisplayName = "Serafino Spaghetto",
		Rarity = "Mythic",
		PurchasePrice = 6500000,
		IncomePerSecond = 410000,
		SpawnWeight = 1.15,
		WalkSpeed = 11.5,
		HeightStuds = 6.0,
		Description = "Biblically accurate levitating noodle seraph with six blazing neon wings.",
		AnimationSettings = { bobAmplitude = 0.45, bobFrequency = 2.8, spinSpeed = 0.75, tiltAmount = 6 },
		Builder = function(model: Model, root: BasePart)
			local noodleGold = Color3.fromRGB(255, 218, 78)
			local mythicPink = Color3.fromRGB(255, 62, 138)
			local cyan = Color3.fromRGB(75, 245, 255)
			addPart(model, root, "HoverCore", Enum.PartType.Ball, Vector3.new(2.25, 2.25, 2.25), CFrame.new(0, 3.1, 0), noodleGold, Enum.Material.Neon)
			addPart(model, root, "OuterRing1", Enum.PartType.Cylinder, Vector3.new(0.28, 3.6, 3.6), CFrame.new(0, 3.1, 0) * CFrame.Angles(math.rad(35), 0, math.rad(35)), noodleGold, Enum.Material.Metal)
			addPart(model, root, "OuterRing2", Enum.PartType.Cylinder, Vector3.new(0.28, 3.6, 3.6), CFrame.new(0, 3.1, 0) * CFrame.Angles(math.rad(-35), 0, math.rad(-35)), mythicPink, Enum.Material.Neon)
			-- 6 radiant wing blades
			for side = -1, 1, 2 do
				for w = -1, 1 do
					addWedge(model, root, "SeraphWing", Vector3.new(0.24, 0.85, 2.65), CFrame.new(side * 2.15, 3.15 + w * 0.85, 0.35) * CFrame.Angles(0, math.rad(side * -85), math.rad(side * w * 24)), mythicPink, Enum.Material.Neon)
				end
			end
			-- Three cosmic eyes
			addPart(model, root, "ThirdEye", Enum.PartType.Ball, Vector3.new(0.55, 0.55, 0.35), CFrame.new(0, 3.65, -1.12), cyan, Enum.Material.Neon, true)
			addGoofyEyes(model, root, 3.05, -1.12, 0.52, 1.05)
			addPart(model, root, "Halo", Enum.PartType.Cylinder, Vector3.new(0.2, 2.2, 2.2), CFrame.new(0, 5.15, 0) * CFrame.Angles(0, 0, math.rad(90)), noodleGold, Enum.Material.Neon)
		end,
	},
	{
		CreatureID = "cyber_cappuccino_shark",
		DisplayName = "Squalo Macchiato",
		Rarity = "Mythic",
		PurchasePrice = 18000000,
		IncomePerSecond = 1150000,
		SpawnWeight = 0.65,
		WalkSpeed = 12.2,
		HeightStuds = 5.8,
		Description = "Jet-propelled cybernetic hammerhead shark powered by nuclear cappuccino foam.",
		AnimationSettings = { bobAmplitude = 0.34, bobFrequency = 3.4, spinSpeed = 0, tiltAmount = 6 },
		Builder = function(model: Model, root: BasePart)
			local sharkCobalt = Color3.fromRGB(48, 118, 225)
			local neonRose = Color3.fromRGB(255, 58, 138)
			local chrome = Color3.fromRGB(225, 232, 248)
			addPart(model, root, "CyberLegL", Enum.PartType.Block, Vector3.new(0.8, 1.35, 1.15), CFrame.new(-0.85, 0.68, 0), chrome, Enum.Material.Metal)
			addPart(model, root, "CyberLegR", Enum.PartType.Block, Vector3.new(0.8, 1.35, 1.15), CFrame.new(0.85, 0.68, 0), chrome, Enum.Material.Metal)
			addPart(model, root, "SharkTorso", Enum.PartType.Ball, Vector3.new(2.45, 2.75, 2.55), CFrame.new(0, 2.45, 0), sharkCobalt, Enum.Material.Metal)
			addPart(model, root, "BellyPlate", Enum.PartType.Ball, Vector3.new(1.85, 2.15, 1.2), CFrame.new(0, 2.35, -0.82), chrome)
			-- Hammerhead visor bar
			addPart(model, root, "HammerHead", Enum.PartType.Block, Vector3.new(3.35, 0.95, 1.35), CFrame.new(0, 3.85, -0.45), sharkCobalt, Enum.Material.Metal)
			addPart(model, root, "SharkEyeL", Enum.PartType.Ball, Vector3.new(0.55, 0.55, 0.55), CFrame.new(-1.58, 3.88, -0.65), neonRose, Enum.Material.Neon, true)
			addPart(model, root, "SharkEyeR", Enum.PartType.Ball, Vector3.new(0.55, 0.55, 0.55), CFrame.new(1.58, 3.88, -0.65), neonRose, Enum.Material.Neon, true)
			addPart(model, root, "SharkGrin", Enum.PartType.Block, Vector3.new(1.55, 0.32, 0.25), CFrame.new(0, 3.28, -1.18), Color3.fromRGB(255, 255, 255), Enum.Material.Neon, true)
			-- Dorsal fin & Cappuccino froth crown
			addWedge(model, root, "DorsalFin", Vector3.new(0.28, 1.65, 1.45), CFrame.new(0, 3.45, 1.35) * CFrame.Angles(0, math.rad(180), 0), neonRose, Enum.Material.Neon)
			addPart(model, root, "CoffeeCrown", Enum.PartType.Cylinder, Vector3.new(0.85, 1.55, 1.55), CFrame.new(0, 4.65, -0.25) * CFrame.Angles(0, 0, math.rad(90)), chrome)
			addPart(model, root, "FoamTop", Enum.PartType.Ball, Vector3.new(1.55, 0.95, 1.55), CFrame.new(0, 5.15, -0.25), Color3.fromRGB(255, 245, 222))
			addPart(model, root, "JetTurbineL", Enum.PartType.Cylinder, Vector3.new(1.6, 0.72, 0.72), CFrame.new(-1.55, 2.55, 0.55) * CFrame.Angles(0, 0, math.rad(90)), neonRose, Enum.Material.Neon)
			addPart(model, root, "JetTurbineR", Enum.PartType.Cylinder, Vector3.new(1.6, 0.72, 0.72), CFrame.new(1.55, 2.55, 0.55) * CFrame.Angles(0, 0, math.rad(90)), neonRose, Enum.Material.Neon)
		end,
	},

	-- ==================== SECRET ====================
	{
		CreatureID = "imperatore_cosmico",
		DisplayName = "Imperatore Cosmico",
		Rarity = "Secret",
		PurchasePrice = 60000000,
		IncomePerSecond = 3800000,
		SpawnWeight = 0.18,
		WalkSpeed = 11.8,
		HeightStuds = 6.5,
		Description = "Supreme cosmic pasta emperor hovering upon a starlight saucer throne!",
		AnimationSettings = { bobAmplitude = 0.48, bobFrequency = 2.6, spinSpeed = 0.55, tiltAmount = 5 },
		Builder = function(model: Model, root: BasePart)
			local cosmicIndigo = Color3.fromRGB(72, 34, 155)
			local gold = Color3.fromRGB(255, 215, 58)
			local rainbowSeed = Color3.fromRGB(255, 95, 245)
			-- Levitating saucer throne
			local saucerRim = addPart(model, root, "SaucerRim", Enum.PartType.Cylinder, Vector3.new(0.42, 3.85, 3.85), CFrame.new(0, 1.05, 0) * CFrame.Angles(0, 0, math.rad(90)), rainbowSeed, Enum.Material.Neon)
			CollectionService:AddTag(saucerRim, "RainbowPart")
			addPart(model, root, "ThroneBase", Enum.PartType.Cylinder, Vector3.new(0.85, 2.85, 2.85), CFrame.new(0, 1.45, 0) * CFrame.Angles(0, 0, math.rad(90)), gold, Enum.Material.Metal)
			addPart(model, root, "ThroneBack", Enum.PartType.Block, Vector3.new(2.55, 3.45, 0.42), CFrame.new(0, 3.25, 1.15), gold, Enum.Material.Metal)
			-- Cosmic Emperor figure
			addPart(model, root, "EmperorRobe", Enum.PartType.Ball, Vector3.new(2.35, 2.65, 2.25), CFrame.new(0, 2.85, -0.05), cosmicIndigo)
			addPart(model, root, "EmperorHead", Enum.PartType.Ball, Vector3.new(1.65, 1.65, 1.65), CFrame.new(0, 4.45, -0.1), Color3.fromRGB(112, 62, 225))
			-- Triple-tier crown
			addPart(model, root, "CrownTier1", Enum.PartType.Cylinder, Vector3.new(0.45, 1.75, 1.75), CFrame.new(0, 5.35, -0.1) * CFrame.Angles(0, 0, math.rad(90)), gold, Enum.Material.Neon)
			addPart(model, root, "CrownTier2", Enum.PartType.Cylinder, Vector3.new(0.45, 1.25, 1.25), CFrame.new(0, 5.8, -0.1) * CFrame.Angles(0, 0, math.rad(90)), rainbowSeed, Enum.Material.Neon)
			local crownStar = addPart(model, root, "CrownApex", Enum.PartType.Block, Vector3.new(0.75, 0.75, 0.75), CFrame.new(0, 6.35, -0.1) * CFrame.Angles(math.rad(45), math.rad(45), 0), gold, Enum.Material.Neon)
			CollectionService:AddTag(crownStar, "RainbowPart")
			-- Dual floating cosmic scepters
			for side = -1, 1, 2 do
				addPart(model, root, "ScepterShaft", Enum.PartType.Cylinder, Vector3.new(2.8, 0.22, 0.22), CFrame.new(side * 2.15, 3.25, -0.35) * CFrame.Angles(0, 0, math.rad(90)), gold, Enum.Material.Metal)
				local orb = addPart(model, root, "ScepterOrb", Enum.PartType.Ball, Vector3.new(0.85, 0.85, 0.85), CFrame.new(side * 2.15, 4.75, -0.35), rainbowSeed, Enum.Material.Neon)
				CollectionService:AddTag(orb, "RainbowPart")
			end
			addPart(model, root, "CosmicEyeL", Enum.PartType.Ball, Vector3.new(0.48, 0.36, 0.28), CFrame.new(-0.42, 4.5, -0.88), Color3.fromRGB(95, 250, 255), Enum.Material.Neon, true)
			addPart(model, root, "CosmicEyeR", Enum.PartType.Ball, Vector3.new(0.48, 0.36, 0.28), CFrame.new(0.42, 4.5, -0.88), Color3.fromRGB(95, 250, 255), Enum.Material.Neon, true)
		end,
	},
	{
		CreatureID = "omni_nonna_prime",
		DisplayName = "Nonna Omnipotente",
		Rarity = "Secret",
		PurchasePrice = 180000000,
		IncomePerSecond = 12000000,
		SpawnWeight = 0.08,
		WalkSpeed = 12.0,
		HeightStuds = 6.6,
		Description = "Transcendent galaxy cyber-Nonna! Nobody leaves her base hungry—or with stolen loot!",
		AnimationSettings = { bobAmplitude = 0.5, bobFrequency = 2.9, spinSpeed = 0.65, tiltAmount = 5 },
		Builder = function(model: Model, root: BasePart)
			local royalViolet = Color3.fromRGB(132, 54, 235)
			local silver = Color3.fromRGB(235, 240, 255)
			local gold = Color3.fromRGB(255, 215, 55)
			local runeRing = addPart(model, root, "RuneRing", Enum.PartType.Cylinder, Vector3.new(0.24, 4.1, 4.1), CFrame.new(0, 0.85, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(95, 245, 255), Enum.Material.Neon)
			CollectionService:AddTag(runeRing, "RainbowPart")
			addPart(model, root, "ApronMech", Enum.PartType.Cylinder, Vector3.new(2.55, 2.55, 2.55), CFrame.new(0, 2.55, 0) * CFrame.Angles(0, 0, math.rad(90)), royalViolet, Enum.Material.Metal)
			addPart(model, root, "ApronFront", Enum.PartType.Block, Vector3.new(1.75, 2.1, 0.32), CFrame.new(0, 2.45, -1.2), silver)
			addPart(model, root, "NonnaHead", Enum.PartType.Ball, Vector3.new(1.75, 1.75, 1.75), CFrame.new(0, 4.45, 0), Color3.fromRGB(255, 218, 190))
			addPart(model, root, "SilverBun", Enum.PartType.Ball, Vector3.new(1.25, 1.25, 1.25), CFrame.new(0, 5.45, 0.35), silver)
			local halo = addPart(model, root, "NonnaHalo", Enum.PartType.Cylinder, Vector3.new(0.22, 2.65, 2.65), CFrame.new(0, 6.15, 0.1) * CFrame.Angles(0, 0, math.rad(90)), gold, Enum.Material.Neon)
			CollectionService:AddTag(halo, "RainbowPart")
			-- Glowing spectacles
			addPart(model, root, "SpecL", Enum.PartType.Cylinder, Vector3.new(0.2, 0.68, 0.68), CFrame.new(-0.44, 4.48, -0.84) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(85, 248, 255), Enum.Material.Neon, true)
			addPart(model, root, "SpecR", Enum.PartType.Cylinder, Vector3.new(0.2, 0.68, 0.68), CFrame.new(0.44, 4.48, -0.84) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(85, 248, 255), Enum.Material.Neon, true)
			-- Giant levitating Golden Rolling Pin of Destiny across front/overhead
			addPart(model, root, "RollingPinBody", Enum.PartType.Cylinder, Vector3.new(3.4, 0.72, 0.72), CFrame.new(0, 3.35, -1.75), gold, Enum.Material.Neon)
			addPart(model, root, "RollingPinHandleL", Enum.PartType.Cylinder, Vector3.new(0.75, 0.32, 0.32), CFrame.new(-2.0, 3.35, -1.75), Color3.fromRGB(255, 65, 135), Enum.Material.Neon)
			addPart(model, root, "RollingPinHandleR", Enum.PartType.Cylinder, Vector3.new(0.75, 0.32, 0.32), CFrame.new(2.0, 3.35, -1.75), Color3.fromRGB(255, 65, 135), Enum.Material.Neon)
		end,
	},
}

CreatureConfig.ById = {}
CreatureConfig.TotalWeight = 0
for index, creature in ipairs(CreatureConfig.Roster) do
	creature.CatalogOrder = index
	CreatureConfig.ById[creature.CreatureID] = creature
	CreatureConfig.TotalWeight += creature.SpawnWeight
end

function CreatureConfig.getCreature(creatureId: string)
	return CreatureConfig.ById[creatureId]
end

function CreatureConfig.getRarityInfo(rarityName: string)
	return CreatureConfig.Rarities[rarityName] or CreatureConfig.Rarities.Common
end

function CreatureConfig.rollWeightedCreatureId(minRarityOrder: number?): string
	local minOrder = minRarityOrder or 1
	local pool = {}
	local weightSum = 0

	for _, c in ipairs(CreatureConfig.Roster) do
		local rInfo = CreatureConfig.getRarityInfo(c.Rarity)
		if rInfo.order >= minOrder then
			table.insert(pool, c)
			weightSum += c.SpawnWeight
		end
	end

	if #pool == 0 then
		return CreatureConfig.Roster[1].CreatureID
	end

	local pick = math.random() * weightSum
	local cursor = 0
	for _, c in ipairs(pool) do
		cursor += c.SpawnWeight
		if pick <= cursor then
			return c.CreatureID
		end
	end
	return pool[#pool].CreatureID
end

local function applyRarityEffects(model: Model, root: BasePart, rarityInfo)
	if rarityInfo.glowIntensity > 0 then
		local light = Instance.new("PointLight")
		light.Name = "RarityLight"
		light.Color = rarityInfo.color
		light.Brightness = rarityInfo.glowIntensity
		light.Range = 12 + rarityInfo.order * 1.5
		light.Parent = root

		local hl = Instance.new("Highlight")
		hl.Name = "RarityHighlight"
		hl.FillColor = rarityInfo.color
		hl.FillTransparency = if rarityInfo.order >= 6 then 0.68 else 0.80
		hl.OutlineColor = rarityInfo.color
		hl.OutlineTransparency = 0.12
		hl.Parent = model
		if rarityInfo.isRainbow then
			CollectionService:AddTag(hl, "RainbowHighlight")
		end
	end

	if rarityInfo.hasParticles then
		local att = Instance.new("Attachment")
		att.Name = "RaritySparkleAtt"
		att.Position = Vector3.new(0, 2.4, 0)
		att.Parent = root

		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Name = "RarityParticles"
		sparkles.Color = ColorSequence.new(rarityInfo.color, Color3.fromRGB(255, 255, 255))
		sparkles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.5, 0.42),
			NumberSequenceKeypoint.new(1, 0),
		})
		sparkles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(1, 1),
		})
		sparkles.LightEmission = 1
		sparkles.Lifetime = NumberRange.new(0.7, 1.3)
		sparkles.Rate = 5 + rarityInfo.order * 2
		sparkles.Speed = NumberRange.new(1.5, 3.8)
		sparkles.SpreadAngle = Vector2.new(180, 180)
		sparkles.Parent = att
	end
end

function CreatureConfig.buildCreatureModel(creatureId: string, mutationName: string?): Model?
	local data = CreatureConfig.getCreature(creatureId)
	if not data then
		return nil
	end
	local rarityInfo = CreatureConfig.getRarityInfo(data.Rarity)

	local model = Instance.new("Model")
	model.Name = data.CreatureID
	model:SetAttribute("CreatureID", data.CreatureID)
	model:SetAttribute("Rarity", data.Rarity)
	model:SetAttribute("Mutation", mutationName or "None")

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2.2, 0.2, 2.2)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = true
	root.CanTouch = false
	root.CFrame = CFrame.new(0, 0.1, 0)
	root.Parent = model
	model.PrimaryPart = root

	data.Builder(model, root)
	applyRarityEffects(model, root, rarityInfo)
	MutationConfig.applyMutationVisuals(model, mutationName)
	CollectionService:AddTag(model, "BrainrotCreature")

	return model
end

-- Creates high-contrast overhead BillboardGui showing MUTATION, NAME, RARITY, $INCOME/S, and PRICE/STATUS
function CreatureConfig.createCreatureBillboard(
	model: Model,
	creatureId: string,
	mutationName: string?,
	mode: string, -- "conveyor" | "traveling" | "slot" | "stealing"
	incomeMultiplier: number?,
	customBottomText: string?
): BillboardGui?
	local data = CreatureConfig.getCreature(creatureId)
	local root = model.PrimaryPart
	if not data or not root then
		return nil
	end

	local existing = model:FindFirstChild("CreatureInfoBillboard")
	if existing then
		existing:Destroy()
	end

	local rarityInfo = CreatureConfig.getRarityInfo(data.Rarity)
	local mutInfo = MutationConfig.getMutationInfo(mutationName)
	local effectiveIncome = math.max(1, math.floor(data.IncomePerSecond * mutInfo.multiplier * (incomeMultiplier or 1) + 0.5))

	local bb = Instance.new("BillboardGui")
	bb.Name = "CreatureInfoBillboard"
	bb.Adornee = root
	bb.StudsOffset = Vector3.new(0, (data.HeightStuds or 5.0) + 1.85, 0)
	bb.Size = UDim2.new(0, 230, 0, if mutInfo.id ~= "None" then 108 else 88)
	bb.MaxDistance = 145
	bb.LightInfluence = 0
	bb.AlwaysOnTop = false
	bb.Parent = model

	local container = Instance.new("Frame")
	container.Name = "Card"
	container.Size = UDim2.fromScale(1, 1)
	container.BackgroundColor3 = Color3.fromRGB(20, 12, 34)
	container.BackgroundTransparency = 0.14
	container.BorderSizePixel = 0
	container.Parent = bb

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = container

	local stroke = Instance.new("UIStroke")
	stroke.Color = if mutInfo.id ~= "None" then mutInfo.color else rarityInfo.color
	stroke.Thickness = 2.5
	stroke.Parent = container
	if rarityInfo.isRainbow and mutInfo.id == "None" then
		CollectionService:AddTag(stroke, "RainbowStroke")
	end

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 1)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = container

	local function makeRow(name: string, order: number, textStr: string, color: Color3, heightScale: number, font: Enum.Font?): TextLabel
		local lbl = Instance.new("TextLabel")
		lbl.Name = name
		lbl.LayoutOrder = order
		lbl.Size = UDim2.new(0.94, 0, heightScale, 0)
		lbl.BackgroundTransparency = 1
		lbl.Font = font or Enum.Font.GothamBlack
		lbl.Text = textStr
		lbl.TextColor3 = color
		lbl.TextScaled = true
		lbl.Parent = container

		local ts = Instance.new("UIStroke")
		ts.Color = Color3.fromRGB(8, 4, 16)
		ts.Thickness = 1.8
		ts.Parent = lbl
		return lbl
	end

	if mutInfo.id ~= "None" then
		makeRow("MutationLabel", 1, mutInfo.badgeText, mutInfo.color, 0.20)
	end

	makeRow("NameLabel", 2, string.upper(data.DisplayName), Color3.fromRGB(255, 255, 255), 0.25)

	local rarityLbl = makeRow("RarityLabel", 3, string.upper(rarityInfo.name), rarityInfo.color, 0.20)
	if rarityInfo.isRainbow then
		CollectionService:AddTag(rarityLbl, "RainbowText")
	end

	makeRow("IncomeLabel", 4, FormatUtil.formatRate(effectiveIncome), Color3.fromRGB(82, 255, 132), 0.22)

	local bottomText = customBottomText
	local bottomColor = Color3.fromRGB(255, 218, 68)
	if not bottomText then
		if mode == "conveyor" then
			bottomText = "PRICE: " .. FormatUtil.formatCash(data.PurchasePrice)
		elseif mode == "traveling" then
			bottomText = "WALKING TO BASE..."
			bottomColor = Color3.fromRGB(95, 245, 255)
		elseif mode == "stealing" then
			bottomText = "[STEALING!]"
			bottomColor = Color3.fromRGB(255, 58, 75)
		else
			bottomText = "EARNING IN BASE"
			bottomColor = Color3.fromRGB(195, 175, 255)
		end
	end
	makeRow("BottomLabel", 5, bottomText, bottomColor, 0.21)

	return bb
end

return CreatureConfig

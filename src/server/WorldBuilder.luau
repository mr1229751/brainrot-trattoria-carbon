-- WorldBuilder.luau
-- Constructs the complete 3D purple industrial arena, central conveyor, striped shop stalls,
-- NPC characters, Golden Rebirth Shrine, Hall of Legends displays, boundaries, and bright Future lighting.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CreatureConfig = require(ReplicatedStorage:WaitForChild("CreatureConfig"))
local FormatUtil = require(ReplicatedStorage:WaitForChild("FormatUtil"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))

local WorldBuilder = {}

local function makePart(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	canCollide: boolean?,
	shape: Enum.PartType?
): Part
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = true
	p.CanCollide = if canCollide == nil then true else canCollide
	p.Parent = parent
	return p
end

local function makeSurfaceSign(
	adornee: BasePart,
	face: Enum.NormalId,
	titleText: string,
	subText: string?,
	titleColor: Color3?,
	bgColor: Color3?
)
	local sg = Instance.new("SurfaceGui")
	sg.Name = "SignGui_" .. face.Name
	sg.Face = face
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 36
	sg.LightInfluence = 0
	sg.Adornee = adornee
	sg.Parent = adornee

	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = bgColor or Color3.fromRGB(24, 14, 42)
	bg.BorderSizePixel = 0
	bg.Parent = sg

	local stroke = Instance.new("UIStroke")
	stroke.Color = titleColor or Color3.fromRGB(255, 208, 52)
	stroke.Thickness = 5
	stroke.Parent = bg

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.94, 0, if subText then 0.58 else 0.84, 0)
	title.Position = UDim2.new(0.03, 0, if subText then 0.06 else 0.08, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.Text = titleText
	title.TextColor3 = titleColor or Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Parent = bg

	local tStroke = Instance.new("UIStroke")
	tStroke.Color = Color3.fromRGB(10, 5, 20)
	tStroke.Thickness = 2.5
	tStroke.Parent = title

	if subText then
		local sub = Instance.new("TextLabel")
		sub.Size = UDim2.new(0.92, 0, 0.30, 0)
		sub.Position = UDim2.new(0.04, 0, 0.64, 0)
		sub.BackgroundTransparency = 1
		sub.Font = Enum.Font.GothamBold
		sub.Text = subText
		sub.TextColor3 = Color3.fromRGB(225, 205, 255)
		sub.TextScaled = true
		sub.Parent = bg
	end
end

-- Builds an expressive primitive NPC character at a given world CFrame
function WorldBuilder.buildPrimitiveNPC(
	parent: Instance,
	name: string,
	roleTitle: string,
	worldCF: CFrame,
	torsoColor: Color3,
	accentColor: Color3,
	hatStyle: string
): Model
	local npc = Instance.new("Model")
	npc.Name = name

	local root = makePart(npc, "HumanoidRootPart", Vector3.new(2, 0.2, 2), worldCF * CFrame.new(0, 0.1, 0), torsoColor, Enum.Material.SmoothPlastic, false)
	root.Transparency = 1
	npc.PrimaryPart = root

	local skin = Color3.fromRGB(255, 214, 178)
	local pants = Color3.fromRGB(36, 26, 56)

	makePart(npc, "LegL", Vector3.new(0.92, 1.9, 0.95), worldCF * CFrame.new(-0.52, 0.95, 0), pants)
	makePart(npc, "LegR", Vector3.new(0.92, 1.9, 0.95), worldCF * CFrame.new(0.52, 0.95, 0), pants)
	makePart(npc, "Torso", Vector3.new(2.0, 2.0, 1.05), worldCF * CFrame.new(0, 2.9, 0), torsoColor)
	makePart(npc, "ApronAccent", Vector3.new(1.5, 1.6, 0.15), worldCF * CFrame.new(0, 2.8, -0.56), accentColor, Enum.Material.Neon, false)
	makePart(npc, "ArmL", Vector3.new(0.85, 1.85, 0.85), worldCF * CFrame.new(-1.48, 2.9, 0), torsoColor)
	makePart(npc, "ArmR", Vector3.new(0.85, 1.85, 0.85), worldCF * CFrame.new(1.48, 3.35, -0.35) * CFrame.Angles(math.rad(135), 0, math.rad(-15)), torsoColor)
	makePart(npc, "Head", Vector3.new(1.5, 1.5, 1.5), worldCF * CFrame.new(0, 4.65, 0), skin, Enum.Material.SmoothPlastic, true, Enum.PartType.Ball)

	-- Primitive face details (front is -Z)
	makePart(npc, "EyeL", Vector3.new(0.24, 0.3, 0.15), worldCF * CFrame.new(-0.3, 4.75, -0.7), Color3.fromRGB(22, 18, 32), Enum.Material.SmoothPlastic, false, Enum.PartType.Ball)
	makePart(npc, "EyeR", Vector3.new(0.24, 0.3, 0.15), worldCF * CFrame.new(0.3, 4.75, -0.7), Color3.fromRGB(22, 18, 32), Enum.Material.SmoothPlastic, false, Enum.PartType.Ball)
	makePart(npc, "Smile", Vector3.new(0.55, 0.14, 0.15), worldCF * CFrame.new(0, 4.38, -0.7), Color3.fromRGB(225, 68, 92), Enum.Material.SmoothPlastic, false)

	if hatStyle == "chef" then
		makePart(npc, "ToqueBand", Vector3.new(0.65, 1.45, 1.45), worldCF * CFrame.new(0, 5.55, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(250, 250, 255), Enum.Material.SmoothPlastic, false, Enum.PartType.Cylinder)
		makePart(npc, "ToqueTop", Vector3.new(1.85, 1.15, 1.85), worldCF * CFrame.new(0, 6.15, 0), Color3.fromRGB(250, 250, 255), Enum.Material.SmoothPlastic, false, Enum.PartType.Ball)
	elseif hatStyle == "scholar" then
		makePart(npc, "CapBoard", Vector3.new(2.1, 0.18, 2.1), worldCF * CFrame.new(0, 5.55, 0), Color3.fromRGB(38, 24, 68), Enum.Material.SmoothPlastic, false)
		makePart(npc, "Tassel", Vector3.new(0.2, 0.65, 0.2), worldCF * CFrame.new(0.95, 5.25, -0.55), accentColor, Enum.Material.Neon, false)
	elseif hatStyle == "crown" then
		makePart(npc, "CrownRing", Vector3.new(0.6, 1.55, 1.55), worldCF * CFrame.new(0, 5.55, 0) * CFrame.Angles(0, 0, math.rad(90)), accentColor, Enum.Material.Neon, false, Enum.PartType.Cylinder)
		makePart(npc, "CrownGem", Vector3.new(0.65, 0.65, 0.65), worldCF * CFrame.new(0, 6.15, 0) * CFrame.Angles(math.rad(45), math.rad(45), 0), Color3.fromRGB(255, 255, 190), Enum.Material.Neon, false)
	end

	local bb = Instance.new("BillboardGui")
	bb.Name = "NPCTag"
	bb.Adornee = root
	bb.StudsOffset = Vector3.new(0, 7.1, 0)
	bb.Size = UDim2.new(0, 200, 0, 54)
	bb.MaxDistance = 95
	bb.LightInfluence = 0
	bb.Parent = npc

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(24, 14, 44)
	frame.BackgroundTransparency = 0.15
	frame.Parent = bb
	local cr = Instance.new("UICorner")
	cr.CornerRadius = UDim.new(0, 8)
	cr.Parent = frame
	local st = Instance.new("UIStroke")
	st.Color = accentColor
	st.Thickness = 2
	st.Parent = frame

	local lbl1 = Instance.new("TextLabel")
	lbl1.Size = UDim2.new(0.94, 0, 0.54, 0)
	lbl1.Position = UDim2.new(0.03, 0, 0.04, 0)
	lbl1.BackgroundTransparency = 1
	lbl1.Font = Enum.Font.GothamBlack
	lbl1.Text = name
	lbl1.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl1.TextScaled = true
	lbl1.Parent = frame

	local lbl2 = Instance.new("TextLabel")
	lbl2.Size = UDim2.new(0.94, 0, 0.38, 0)
	lbl2.Position = UDim2.new(0.03, 0, 0.58, 0)
	lbl2.BackgroundTransparency = 1
	lbl2.Font = Enum.Font.GothamBold
	lbl2.Text = roleTitle
	lbl2.TextColor3 = accentColor
	lbl2.TextScaled = true
	lbl2.Parent = frame

	npc.Parent = parent
	return npc
end

local function configureLighting()
	Lighting.Ambient = Color3.fromRGB(204, 198, 220)
	Lighting.OutdoorAmbient = Color3.fromRGB(218, 212, 230)
	Lighting.Brightness = 3.2
	Lighting.ExposureCompensation = 0.35
	Lighting.ClockTime = 13.8
	Lighting.ColorShift_Top = Color3.fromRGB(255, 252, 248)
	Lighting.ColorShift_Bottom = Color3.fromRGB(218, 212, 232)
	Lighting.EnvironmentDiffuseScale = 0.85
	Lighting.EnvironmentSpecularScale = 0.85
	Lighting.GlobalShadows = true

	for _, child in ipairs(Lighting:GetChildren()) do
		child:Destroy()
	end

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "DaylightCrispGrading"
	cc.Brightness = 0.04
	cc.Contrast = 0.08
	cc.Saturation = 0.04
	cc.TintColor = Color3.fromRGB(255, 253, 255)
	cc.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "NeonGlowBloom"
	bloom.Intensity = 0.34
	bloom.Size = 18
	bloom.Threshold = 1.35
	bloom.Parent = Lighting

	local atmo = Instance.new("Atmosphere")
	atmo.Name = "ClearDaylightAtmosphere"
	atmo.Density = 0.03
	atmo.Offset = 0.0
	atmo.Color = Color3.fromRGB(244, 240, 255)
	atmo.Decay = Color3.fromRGB(232, 226, 250)
	atmo.Glare = 0.0
	atmo.Haze = 0.0
	atmo.Parent = Lighting
end

local function buildFloorAndWalkways(mapFolder: Folder)
	local pal = GameConfig.Palette
	local w = GameConfig.Arena.HalfWidthX * 2
	local l = GameConfig.Arena.HalfLengthZ * 2

	-- Main purple industrial ground slab (top at Y = 0)
	makePart(mapFolder, "ArenaMainFloor", Vector3.new(w + 20, 4, l + 20), CFrame.new(0, -2, 0), pal.FloorPrimary, Enum.Material.SmoothPlastic)

	-- Lighter purple pedestrian promenades alongside the conveyor
	makePart(mapFolder, "PromenadeWest", Vector3.new(34, 0.16, 276), CFrame.new(-28, 0.08, 0), pal.FloorWalkway, Enum.Material.SmoothPlastic)
	makePart(mapFolder, "PromenadeEast", Vector3.new(34, 0.16, 276), CFrame.new(28, 0.08, 0), pal.FloorWalkway, Enum.Material.SmoothPlastic)

	-- Neon lane border lines along promenades
	for _, xLine in ipairs({ -10.5, -45.2, 10.5, 45.2 }) do
		makePart(mapFolder, "PromenadeNeonStrip", Vector3.new(0.45, 0.2, 268), CFrame.new(xLine, 0.1, 0), pal.WallTrim, Enum.Material.Neon, false)
	end

	-- Cross-walkway carpets into each of the 8 bases
	for _, b in ipairs(GameConfig.Bases) do
		local sideSign = if b.frontX < 0 then -1 else 1
		makePart(mapFolder, "BaseEntryWalk_" .. b.id, Vector3.new(36, 0.22, 16), CFrame.new(sideSign * 28, 0.11, b.centerZ), pal.FloorSecondary)
		makePart(mapFolder, "BaseEntryTrimN_" .. b.id, Vector3.new(35, 0.25, 0.45), CFrame.new(sideSign * 28, 0.12, b.centerZ - 8.2), b.accent, Enum.Material.Neon, false)
		makePart(mapFolder, "BaseEntryTrimS_" .. b.id, Vector3.new(35, 0.25, 0.45), CFrame.new(sideSign * 28, 0.12, b.centerZ + 8.2), b.accent, Enum.Material.Neon, false)
	end

	-- North Spawn Plaza & South Shrine Plaza floor inlays
	makePart(mapFolder, "NorthPlazaFloor", Vector3.new(170, 0.18, 38), CFrame.new(0, 0.09, -153), pal.FloorSecondary)
	makePart(mapFolder, "SouthPlazaFloor", Vector3.new(170, 0.18, 38), CFrame.new(0, 0.09, 153), pal.FloorSecondary)
end

local function buildCentralConveyor(mapFolder: Folder)
	local convFolder = Instance.new("Folder")
	convFolder.Name = "CentralConveyor"
	convFolder.Parent = mapFolder

	local pal = GameConfig.Palette
	local cfg = GameConfig.Conveyor
	local beltLen = (cfg.EndZ - cfg.StartZ) + 12

	-- Dark purple/black conveyor bed
	makePart(convFolder, "ConveyorBed", Vector3.new(cfg.BeltWidth, cfg.BeltTopY, beltLen), CFrame.new(0, cfg.BeltTopY * 0.5, 0), pal.ConveyorSurface, Enum.Material.Metal)

	-- Bright golden illuminated side borders
	for _, side in ipairs({ -1, 1 }) do
		local bx = side * (cfg.BeltWidth * 0.5 + 0.85)
		makePart(convFolder, "GoldBorderBase", Vector3.new(1.7, 1.15, beltLen + 2), CFrame.new(bx, 0.575, 0), pal.ConveyorBorderGold, Enum.Material.Metal)
		makePart(convFolder, "GoldBorderNeon", Vector3.new(0.55, 0.35, beltLen + 2), CFrame.new(bx, 1.22, 0), pal.ConveyorArrowNeon, Enum.Material.Neon, false)
	end

	-- Repeating transverse belt ribs & directional neon chevrons pointing +Z
	local arrowIdx = 0
	for z = cfg.StartZ + 6, cfg.EndZ - 6, 12 do
		arrowIdx += 1
		makePart(convFolder, "BeltRib", Vector3.new(cfg.BeltWidth - 0.6, 0.06, 1.4), CFrame.new(0, cfg.BeltTopY + 0.03, z), pal.ConveyorStripe, Enum.Material.SmoothPlastic, false)

		local chevL = makePart(
			convFolder,
			"ChevronL_" .. arrowIdx,
			Vector3.new(0.65, 0.1, 4.6),
			CFrame.new(-1.55, cfg.BeltTopY + 0.05, z + 3) * CFrame.Angles(0, math.rad(-36), 0),
			pal.ConveyorArrowNeon,
			Enum.Material.Neon,
			false
		)
		chevL:SetAttribute("ArrowOrder", arrowIdx)
		CollectionService:AddTag(chevL, "ConveyorArrow")

		local chevR = makePart(
			convFolder,
			"ChevronR_" .. arrowIdx,
			Vector3.new(0.65, 0.1, 4.6),
			CFrame.new(1.55, cfg.BeltTopY + 0.05, z + 3) * CFrame.Angles(0, math.rad(36), 0),
			pal.ConveyorArrowNeon,
			Enum.Material.Neon,
			false
		)
		chevR:SetAttribute("ArrowOrder", arrowIdx)
		CollectionService:AddTag(chevR, "ConveyorArrow")
	end

	-- North Spawn Portal Gantry Arch (Z = -134)
	local northZ = cfg.StartZ - 6
	makePart(convFolder, "NorthPillarL", Vector3.new(3.2, 18, 3.2), CFrame.new(-10.5, 9, northZ), pal.WallDark, Enum.Material.Metal)
	makePart(convFolder, "NorthPillarR", Vector3.new(3.2, 18, 3.2), CFrame.new(10.5, 9, northZ), pal.WallDark, Enum.Material.Metal)
	makePart(convFolder, "NorthPillarTrimL", Vector3.new(0.6, 17, 0.6), CFrame.new(-8.7, 9, northZ + 1.5), pal.ConveyorBorderGold, Enum.Material.Neon, false)
	makePart(convFolder, "NorthPillarTrimR", Vector3.new(0.6, 17, 0.6), CFrame.new(8.7, 9, northZ + 1.5), pal.ConveyorBorderGold, Enum.Material.Neon, false)
	local northCurtain = makePart(convFolder, "NorthPortalCurtain", Vector3.new(16.5, 13.5, 0.6), CFrame.new(0, 7.2, northZ), Color3.fromRGB(165, 95, 255), Enum.Material.ForceField, false)
	northCurtain.Transparency = 0.78

	local northHeader = makePart(convFolder, "NorthArchSign", Vector3.new(25, 4.8, 2.4), CFrame.new(0, 19.5, northZ), pal.WallDark, Enum.Material.Metal)
	makeSurfaceSign(northHeader, Enum.NormalId.Back, "BRAINROT CONVEYOR", "HOLD [E] TO BUY CREATURES!", pal.ConveyorBorderGold)
	makeSurfaceSign(northHeader, Enum.NormalId.Front, "BRAINROT CONVEYOR", "FRESH CREATURES SPAWN HERE!", pal.ConveyorBorderGold)

	-- South Void Recycler Portal Arch (Z = +134, raised cleanly to frame the Golden Rebirth Shrine behind it)
	local southZ = cfg.EndZ + 6
	makePart(convFolder, "SouthPillarL", Vector3.new(3.2, 22, 3.2), CFrame.new(-11.5, 11, southZ), pal.WallDark, Enum.Material.Metal)
	makePart(convFolder, "SouthPillarR", Vector3.new(3.2, 22, 3.2), CFrame.new(11.5, 11, southZ), pal.WallDark, Enum.Material.Metal)
	local southCurtain = makePart(convFolder, "SouthPortalCurtain", Vector3.new(17.5, 10.5, 0.6), CFrame.new(0, 5.8, southZ), Color3.fromRGB(255, 72, 138), Enum.Material.ForceField, false)
	southCurtain.Transparency = 0.82

	local southHeader = makePart(convFolder, "SouthArchSign", Vector3.new(26, 4.2, 2.2), CFrame.new(0, 23.8, southZ), pal.WallDark, Enum.Material.Metal)
	makeSurfaceSign(southHeader, Enum.NormalId.Front, "VOID RECYCLER", "UNBOUGHT CREATURES VANISH!", Color3.fromRGB(255, 82, 130))
	makeSurfaceSign(southHeader, Enum.NormalId.Back, "VOID RECYCLER", "GOLDEN SHRINE AHEAD!", Color3.fromRGB(255, 205, 55))
end

local function buildStripedStall(
	parent: Instance,
	name: string,
	originCF: CFrame,
	stripeA: Color3,
	stripeB: Color3,
	headerTitle: string,
	headerSub: string
): Folder
	local stall = Instance.new("Folder")
	stall.Name = name
	stall.Parent = parent

	-- Platform & counter
	makePart(stall, "StallDeck", Vector3.new(28, 0.5, 16), originCF * CFrame.new(0, 0.25, 0), Color3.fromRGB(166, 138, 214))
	makePart(stall, "CounterFront", Vector3.new(24, 3.4, 2.4), originCF * CFrame.new(0, 1.95, -4.5), Color3.fromRGB(136, 102, 198))
	makePart(stall, "CounterTop", Vector3.new(24.8, 0.45, 3.1), originCF * CFrame.new(0, 3.75, -4.5), Color3.fromRGB(255, 208, 58), Enum.Material.Metal)

	-- Support poles
	for _, sx in ipairs({ -12.5, 12.5 }) do
		for _, sz in ipairs({ -6.5, 6.5 }) do
			makePart(stall, "Pole", Vector3.new(0.8, 12.5, 0.8), originCF * CFrame.new(sx, 6.5, sz), Color3.fromRGB(235, 235, 245), Enum.Material.Metal)
		end
	end

	-- Striped canopy awning (9 alternating colorful slats tilted forward)
	for i = -4, 4 do
		local col = if i % 2 == 0 then stripeA else stripeB
		makePart(
			stall,
			"CanopyStripe_" .. tostring(i + 5),
			Vector3.new(3.15, 0.55, 16.5),
			originCF * CFrame.new(i * 3.12, 12.9, -0.4) * CFrame.Angles(math.rad(10), 0, 0),
			col,
			Enum.Material.SmoothPlastic
		)
		-- Scalloped front valance flap
		makePart(
			stall,
			"Valance_" .. tostring(i + 5),
			Vector3.new(3.1, 1.35, 0.4),
			originCF * CFrame.new(i * 3.12, 10.95, -8.4),
			col,
			Enum.Material.SmoothPlastic
		)
	end

	local signBoard = makePart(stall, "StallSign", Vector3.new(22, 3.6, 0.9), originCF * CFrame.new(0, 14.9, -4.5), Color3.fromRGB(26, 16, 46), Enum.Material.Metal)
	makeSurfaceSign(signBoard, Enum.NormalId.Front, headerTitle, headerSub, stripeA)
	makeSurfaceSign(signBoard, Enum.NormalId.Back, headerTitle, headerSub, stripeA)

	local stallLight = Instance.new("PointLight")
	stallLight.Color = Color3.fromRGB(255, 244, 218)
	stallLight.Brightness = 2.2
	stallLight.Range = 28
	stallLight.Parent = signBoard

	return stall
end

local function buildSpawnAndShopPlaza(mapFolder: Folder, hooks: any)
	local plaza = Instance.new("Folder")
	plaza.Name = "NorthSpawnAndShop"
	plaza.Parent = mapFolder

	-- Glowing Main Spawn Pad facing South (+Z) down the central conveyor
	local spawnPos = GameConfig.SpawnArea.Position
	local spawnBase = makePart(plaza, "SpawnRingOuter", Vector3.new(1.2, 18, 18), CFrame.new(spawnPos.X, 0.35, spawnPos.Z) * CFrame.Angles(0, 0, math.rad(90)), GameConfig.Palette.ConveyorBorderGold, Enum.Material.Neon, true, Enum.PartType.Cylinder)
	spawnBase.CanCollide = true

	local spawner = Instance.new("SpawnLocation")
	spawner.Name = "MainSpawnLocation"
	spawner.Size = Vector3.new(14, 1, 14)
	spawner.CFrame = CFrame.lookAt(Vector3.new(spawnPos.X, 0.55, spawnPos.Z), Vector3.new(spawnPos.X, 0.55, spawnPos.Z + 20))
	spawner.Anchored = true
	spawner.Neutral = true
	spawner.Duration = 0
	spawner.Color = Color3.fromRGB(142, 108, 206)
	spawner.Material = Enum.Material.SmoothPlastic
	spawner.TopSurface = Enum.SurfaceType.Smooth
	spawner.Parent = plaza

	-- West Striped-Canopy Equipment Shop Stall (facing South-East toward spawn/promenade)
	local equipOrigin = CFrame.lookAt(GameConfig.SpawnArea.EquipmentStallPos, GameConfig.SpawnArea.EquipmentStallPos + Vector3.new(0.25, 0, 1))
	local equipStall = buildStripedStall(
		plaza,
		"EquipmentShopStall",
		equipOrigin,
		Color3.fromRGB(255, 68, 138),
		Color3.fromRGB(255, 232, 95),
		"EQUIPMENT & TOOLS SHOP",
		"SLAP GLOVES • SPEED COILS • LASER TRAPS"
	)

	WorldBuilder.buildPrimitiveNPC(
		equipStall,
		"Chef Volt",
		"EQUIPMENT DEALER",
		equipOrigin * CFrame.new(0, 0.5, -1.5),
		Color3.fromRGB(235, 58, 125),
		Color3.fromRGB(255, 220, 68),
		"chef"
	)

	-- Place 3D interactive display pedestals for every Shop item in front of the stall
	hooks.shopDisplayPrompts = {}
	for idx, item in ipairs(ShopConfig.Items) do
		local xOff = (idx - 3) * 5.2
		local pedCF = equipOrigin * CFrame.new(xOff, 1.2, -8.5)
		local ped = makePart(equipStall, "ItemPedestal_" .. item.id, Vector3.new(2.4, 2.4, 2.4), pedCF * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(132, 102, 194), Enum.Material.Metal, true, Enum.PartType.Cylinder)
		makePart(equipStall, "ItemRim_" .. item.id, Vector3.new(0.24, 2.65, 2.65), pedCF * CFrame.new(0, 1.15, 0) * CFrame.Angles(0, 0, math.rad(90)), item.accentColor, Enum.Material.Neon, false, Enum.PartType.Cylinder)

		local disp = ShopConfig.buildDisplayModel(item.id, pedCF * CFrame.new(0, 2.25, 0))
		if disp then
			disp.Parent = equipStall
		end

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "BuyToolPrompt"
		prompt.ActionText = "Buy " .. FormatUtil.formatCash(item.price)
		prompt.ObjectText = item.name
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0.25
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Parent = ped

		table.insert(hooks.shopDisplayPrompts, {
			itemId = item.id,
			prompt = prompt,
		})
	end

	-- East Striped-Canopy Collection & Mutation Info Stall
	local indexOrigin = CFrame.lookAt(GameConfig.SpawnArea.IndexStallPos, GameConfig.SpawnArea.IndexStallPos + Vector3.new(-0.25, 0, 1))
	local indexStall = buildStripedStall(
		plaza,
		"CollectionInfoStall",
		indexOrigin,
		Color3.fromRGB(58, 215, 255),
		Color3.fromRGB(185, 88, 255),
		"RARITY & MUTATION LAB",
		"RADIOACTIVE 3x • GOLDEN 8x • VOID 25x"
	)

	WorldBuilder.buildPrimitiveNPC(
		indexStall,
		"Prof. Pasta",
		"COLLECTION CURATOR",
		indexOrigin * CFrame.new(0, 0.5, -1.5),
		Color3.fromRGB(68, 145, 235),
		Color3.fromRGB(85, 245, 255),
		"scholar"
	)

	-- Mutation odds board right beside Prof. Pasta
	local mutBoard = makePart(indexStall, "MutationBoard", Vector3.new(16, 4.8, 0.8), indexOrigin * CFrame.new(0, 6.8, 4.2), Color3.fromRGB(22, 14, 38), Enum.Material.Metal)
	makeSurfaceSign(
		mutBoard,
		Enum.NormalId.Front,
		"MUTATION ODDS",
		"RAD 10% (3x) • GOLD 2% (8x) • VOID 0.2% (25x)",
		Color3.fromRGB(95, 255, 85)
	)
end

local function buildGoldenRebirthShrine(mapFolder: Folder, hooks: any)
	local shrineFolder = Instance.new("Folder")
	shrineFolder.Name = "GoldenRebirthShrine"
	shrineFolder.Parent = mapFolder

	local pos = GameConfig.Shrine.Position
	local gold = GameConfig.Palette.ShrineGold
	local neonGold = GameConfig.Palette.ShrineAccent

	-- 3-step golden ziggurat dais
	makePart(shrineFolder, "ShrineStep1", Vector3.new(34, 1.2, 26), CFrame.new(pos.X, 0.6, pos.Z), Color3.fromRGB(195, 142, 28), Enum.Material.Marble)
	makePart(shrineFolder, "ShrineStep2", Vector3.new(27, 1.2, 20), CFrame.new(pos.X, 1.8, pos.Z), gold, Enum.Material.Foil)
	makePart(shrineFolder, "ShrineStep3", Vector3.new(20, 1.2, 14), CFrame.new(pos.X, 3.0, pos.Z), neonGold, Enum.Material.Neon)

	-- 4 golden columns with glowing braziers
	for _, sx in ipairs({ -12, 12 }) do
		for _, sz in ipairs({ -8, 8 }) do
			local colPos = Vector3.new(pos.X + sx, 10.2, pos.Z + sz)
			makePart(shrineFolder, "GoldColumn", Vector3.new(16, 2.4, 2.4), CFrame.new(colPos) * CFrame.Angles(0, 0, math.rad(90)), gold, Enum.Material.Foil, true, Enum.PartType.Cylinder)
			local brazier = makePart(shrineFolder, "GoldBrazier", Vector3.new(2.2, 2.2, 2.2), CFrame.new(pos.X + sx, 19.2, pos.Z + sz), neonGold, Enum.Material.Neon, false, Enum.PartType.Ball)

			local att = Instance.new("Attachment")
			att.Parent = brazier
			local sparks = Instance.new("ParticleEmitter")
			sparks.Color = ColorSequence.new(gold, Color3.fromRGB(255, 255, 255))
			sparks.Size = NumberSequence.new(0.45, 0)
			sparks.LightEmission = 1
			sparks.Lifetime = NumberRange.new(0.8, 1.4)
			sparks.Rate = 14
			sparks.Speed = NumberRange.new(3, 6)
			sparks.Acceleration = Vector3.new(0, 5, 0)
			sparks.Parent = att
		end
	end

	-- Grand golden arch & rotating emblem above altar
	local shrineHeader = makePart(shrineFolder, "ShrineArchSign", Vector3.new(26, 4.6, 2.2), CFrame.new(pos.X, 20.5, pos.Z - 7.5), Color3.fromRGB(36, 22, 12), Enum.Material.Metal)
	makeSurfaceSign(shrineHeader, Enum.NormalId.Front, "GOLDEN REBIRTH SHRINE", "PERMANENT CASH MULTIPLIER + SPEED + LUCK!", gold)
	makeSurfaceSign(shrineHeader, Enum.NormalId.Back, "GOLDEN REBIRTH SHRINE", "ASCEND YOUR TRATTORIA EMPIRE!", gold)

	local altarPedestal = makePart(shrineFolder, "RebirthAltar", Vector3.new(5.5, 3.2, 5.5), CFrame.new(pos.X, 5.2, pos.Z - 1), gold, Enum.Material.Foil)
	local crownCore = makePart(shrineFolder, "RebirthCrownOrb", Vector3.new(3.2, 3.2, 3.2), CFrame.new(pos.X, 9.2, pos.Z - 1) * CFrame.Angles(math.rad(45), math.rad(45), 0), neonGold, Enum.Material.Neon, false)
	local altarLight = Instance.new("PointLight")
	altarLight.Color = gold
	altarLight.Brightness = 3.2
	altarLight.Range = 34
	altarLight.Parent = crownCore

	-- Shrine Guardian NPC facing North (-Z) toward arena
	WorldBuilder.buildPrimitiveNPC(
		shrineFolder,
		"Aurelio the Eternal",
		"REBIRTH GUARDIAN",
		CFrame.lookAt(Vector3.new(pos.X + 5.5, 3.6, pos.Z + 1.5), Vector3.new(pos.X + 5.5, 3.6, pos.Z - 20)),
		Color3.fromRGB(255, 192, 42),
		Color3.fromRGB(255, 248, 165),
		"crown"
	)

	local rebirthPrompt = Instance.new("ProximityPrompt")
	rebirthPrompt.Name = "RebirthShrinePrompt"
	rebirthPrompt.ActionText = "Rebirth Now"
	rebirthPrompt.ObjectText = "Golden Rebirth Shrine"
	rebirthPrompt.KeyboardKeyCode = Enum.KeyCode.E
	rebirthPrompt.HoldDuration = 0.6
	rebirthPrompt.MaxActivationDistance = 18
	rebirthPrompt.RequiresLineOfSight = false
	rebirthPrompt.Parent = altarPedestal
	hooks.rebirthShrinePrompt = rebirthPrompt

	-- Flanking Character Display Areas (Hall of Rarities statues on South Plaza)
	local showcasePairs = {
		{ pos = GameConfig.Shrine.HallWestPos + Vector3.new(-8, 0, 0), id = "vesuvius_drake", mut = "None" },
		{ pos = GameConfig.Shrine.HallWestPos + Vector3.new(8, 0, 0), id = "pasta_seraph", mut = "Radioactive" },
		{ pos = GameConfig.Shrine.HallEastPos + Vector3.new(-8, 0, 0), id = "cyber_cappuccino_shark", mut = "None" },
		{ pos = GameConfig.Shrine.HallEastPos + Vector3.new(8, 0, 0), id = "omni_nonna_prime", mut = "Void" },
	}
	for idx, entry in ipairs(showcasePairs) do
		local ped = makePart(shrineFolder, "HallPedestal_" .. idx, Vector3.new(2.2, 6.5, 6.5), CFrame.new(entry.pos + Vector3.new(0, 1.1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(228, 222, 240), Enum.Material.Marble, true, Enum.PartType.Cylinder)
		makePart(shrineFolder, "HallRim_" .. idx, Vector3.new(0.28, 6.9, 6.9), CFrame.new(entry.pos + Vector3.new(0, 2.25, 0)) * CFrame.Angles(0, 0, math.rad(90)), gold, Enum.Material.Neon, false, Enum.PartType.Cylinder)
		local statue = CreatureConfig.buildCreatureModel(entry.id, entry.mut)
		if statue then
			statue.Name = "HallDisplay_" .. entry.id
			statue:PivotTo(CFrame.lookAt(entry.pos + Vector3.new(0, 2.25, 0), entry.pos + Vector3.new(0, 2.25, -20)))
			CreatureConfig.createCreatureBillboard(statue, entry.id, entry.mut, "slot", 1, "HALL OF LEGENDS")
			statue.Parent = ped
		end
	end
end

local function buildBoundariesAndDecor(mapFolder: Folder)
	local decor = Instance.new("Folder")
	decor.Name = "BoundariesAndDecor"
	decor.Parent = mapFolder

	local pal = GameConfig.Palette
	local hx = GameConfig.Arena.HalfWidthX
	local hz = GameConfig.Arena.HalfLengthZ
	local wh = GameConfig.Arena.WallHeight

	-- Four perimeter purple industrial walls
	makePart(decor, "BoundaryNorth", Vector3.new(hx * 2 + 8, wh, 4), CFrame.new(0, wh * 0.5, -hz), pal.WallPrimary, Enum.Material.Metal)
	makePart(decor, "BoundarySouth", Vector3.new(hx * 2 + 8, wh, 4), CFrame.new(0, wh * 0.5, hz), pal.WallPrimary, Enum.Material.Metal)
	makePart(decor, "BoundaryWest", Vector3.new(4, wh, hz * 2 + 8), CFrame.new(-hx, wh * 0.5, 0), pal.WallPrimary, Enum.Material.Metal)
	makePart(decor, "BoundaryEast", Vector3.new(4, wh, hz * 2 + 8), CFrame.new(hx, wh * 0.5, 0), pal.WallPrimary, Enum.Material.Metal)

	-- Neon crown trim along perimeter walls
	makePart(decor, "TrimNorth", Vector3.new(hx * 2, 0.9, 4.6), CFrame.new(0, wh - 1.5, -hz), pal.WallTrim, Enum.Material.Neon, false)
	makePart(decor, "TrimSouth", Vector3.new(hx * 2, 0.9, 4.6), CFrame.new(0, wh - 1.5, hz), pal.ConveyorBorderGold, Enum.Material.Neon, false)
	makePart(decor, "TrimWest", Vector3.new(4.6, 0.9, hz * 2), CFrame.new(-hx, wh - 1.5, 0), pal.WallTrim, Enum.Material.Neon, false)
	makePart(decor, "TrimEast", Vector3.new(4.6, 0.9, hz * 2), CFrame.new(hx, wh - 1.5, 0), pal.WallTrim, Enum.Material.Neon, false)

	-- Architectural ribbed wall buttresses every 35 studs
	for z = -140, 140, 35 do
		for _, sx in ipairs({ -1, 1 }) do
			makePart(decor, "WallButtress", Vector3.new(3.2, wh + 2, 3.2), CFrame.new(sx * (hx - 1.5), wh * 0.5 + 1, z), pal.WallDark, Enum.Material.Metal)
			makePart(decor, "ButtressNeon", Vector3.new(0.6, wh - 4, 0.8), CFrame.new(sx * (hx - 3.2), wh * 0.5, z), pal.NeonCyan, Enum.Material.Neon, false)
		end
	end

	-- Illuminated promenade lamppost towers along central walkways (never obstructing paths)
	for _, zPos in ipairs({ -118, -60, 0, 60, 118 }) do
		for _, xSide in ipairs({ -12.8, 12.8 }) do
			local pole = makePart(decor, "PromenadeLamp", Vector3.new(0.85, 16, 0.85), CFrame.new(xSide, 8, zPos), pal.WallDark, Enum.Material.Metal)
			local armSign = if xSide < 0 then -1 else 1
			makePart(decor, "LampArm", Vector3.new(3.6, 0.55, 0.55), CFrame.new(xSide + armSign * 1.4, 15.8, zPos), pal.WallDark, Enum.Material.Metal)
			local bulb = makePart(decor, "LampGlow", Vector3.new(1.8, 0.65, 1.8), CFrame.new(xSide + armSign * 2.6, 15.3, zPos), Color3.fromRGB(255, 240, 200), Enum.Material.Neon, false)

			local pLight = Instance.new("PointLight")
			pLight.Color = Color3.fromRGB(255, 236, 215)
			pLight.Brightness = 1.9
			pLight.Range = 36
			pLight.Parent = bulb
			pole.CanCollide = true
		end
	end

	-- Decorative neon cyber-planters along alleys between bases
	for _, zAlley in ipairs({ -120, -60, 0, 60, 120 }) do
		for _, sx in ipairs({ -1, 1 }) do
			local px = sx * 44.5
			makePart(decor, "PlanterBox", Vector3.new(3.2, 2.2, 5.2), CFrame.new(px, 1.1, zAlley), pal.WallDark, Enum.Material.Metal)
			makePart(decor, "PlanterBush", Vector3.new(2.8, 2.6, 4.4), CFrame.new(px, 3.0, zAlley), Color3.fromRGB(142, 68, 235), Enum.Material.SmoothPlastic, false, Enum.PartType.Ball)
			makePart(decor, "PlanterCrystal", Vector3.new(0.9, 2.2, 0.9), CFrame.new(px, 4.3, zAlley) * CFrame.Angles(0, math.rad(35), math.rad(12)), pal.ConveyorBorderGold, Enum.Material.Neon, false)
		end
	end
end

function WorldBuilder.buildWorld()
	configureLighting()

	local defaultBaseplate = Workspace:FindFirstChild("Baseplate")
	if defaultBaseplate then
		defaultBaseplate:Destroy()
	end

	local existingMap = Workspace:FindFirstChild("ArenaMap")
	if existingMap then
		existingMap:Destroy()
	end

	local mapFolder = Instance.new("Folder")
	mapFolder.Name = "ArenaMap"
	mapFolder.Parent = Workspace

	local hooks = {
		shopDisplayPrompts = {},
		rebirthShrinePrompt = nil,
	}

	buildFloorAndWalkways(mapFolder)
	buildCentralConveyor(mapFolder)
	buildSpawnAndShopPlaza(mapFolder, hooks)
	buildGoldenRebirthShrine(mapFolder, hooks)
	buildBoundariesAndDecor(mapFolder)

	return hooks
end

return WorldBuilder

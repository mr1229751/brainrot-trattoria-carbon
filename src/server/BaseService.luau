-- BaseService.luau
-- Constructs and manages all 8 player bases: ownership, PhysicsService laser security gates,
-- lock button countdowns, green cash platforms, and 10 interior creature display slots.

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CreatureConfig = require(ReplicatedStorage:WaitForChild("CreatureConfig"))
local EconomyConfig = require(ReplicatedStorage:WaitForChild("EconomyConfig"))
local FormatUtil = require(ReplicatedStorage:WaitForChild("FormatUtil"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local CreatureService = require(script.Parent:WaitForChild("CreatureService"))
local NotificationService = require(script.Parent:WaitForChild("NotificationService"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

local BaseService = {}

local basesById: { [number]: any } = {}
local baseIdByUserId: { [number]: number } = {}
local stealAttemptCallback: ((Player, number, number) -> ())? = nil

local function safeRegisterCollisionGroup(groupName: string)
	pcall(function()
		PhysicsService:RegisterCollisionGroup(groupName)
	end)
end

local function setupCollisionGroups()
	safeRegisterCollisionGroup("DefaultPlayers")
	for _, b in ipairs(GameConfig.Bases) do
		local ownerGroup = "BaseOwner_" .. tostring(b.id)
		local gateGroup = "LaserGate_" .. tostring(b.id)
		safeRegisterCollisionGroup(ownerGroup)
		safeRegisterCollisionGroup(gateGroup)
	end

	for _, b in ipairs(GameConfig.Bases) do
		local gateGroup = "LaserGate_" .. tostring(b.id)
		pcall(function()
			PhysicsService:CollisionGroupSetCollidable(gateGroup, "Default", true)
			PhysicsService:CollisionGroupSetCollidable(gateGroup, "DefaultPlayers", true)
		end)
		for _, other in ipairs(GameConfig.Bases) do
			local ownerGroup = "BaseOwner_" .. tostring(other.id)
			local shouldCollide = (other.id ~= b.id)
			pcall(function()
				PhysicsService:CollisionGroupSetCollidable(gateGroup, ownerGroup, shouldCollide)
			end)
		end
	end
end

function BaseService.applyCharacterCollisionGroup(player: Player, character: Model?)
	local char = character or player.Character
	if not char then
		return
	end
	local baseId = baseIdByUserId[player.UserId]
	local groupName = if baseId then ("BaseOwner_" .. tostring(baseId)) else "DefaultPlayers"
	for _, inst in ipairs(char:GetDescendants()) do
		if inst:IsA("BasePart") then
			pcall(function()
				inst.CollisionGroup = groupName
			end)
		end
	end
end

local function makeBasePart(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?,
	canCollide: boolean?,
	transparency: number?,
	shape: Enum.PartType?
): Part
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = true
	p.CanCollide = if canCollide == nil then true else canCollide
	p.Parent = parent
	return p
end

local function constructSingleBase(basesFolder: Folder, def: any)
	local pal = GameConfig.Palette
	local dim = GameConfig.BaseDimensions
	local outwardDir = Vector3.new(-def.inwardSignX, 0, 0)
	local inwardDir = Vector3.new(def.inwardSignX, 0, 0)

	local model = Instance.new("Model")
	model.Name = "PlayerBase_" .. tostring(def.id)
	model.Parent = basesFolder

	local function posAt(depth: number, zOff: number, y: number): Vector3
		return GameConfig.getBaseWorldPosition(def, depth, zOff, y)
	end

	-- Interior industrial floor deck (mid lavender-slate, never clipped white)
	makeBasePart(
		model,
		"BaseFloor",
		Vector3.new(dim.DepthX, 0.3, dim.WidthZ),
		CFrame.new(posAt(dim.DepthX * 0.5, 0, 0.15)),
		Color3.fromRGB(118, 106, 152),
		Enum.Material.Concrete
	)
	-- Center aisle carpet strip (mid lavender-gray matching promenades)
	makeBasePart(
		model,
		"CenterAisle",
		Vector3.new(dim.DepthX - 6, 0.34, 14),
		CFrame.new(posAt(dim.DepthX * 0.5 + 1, 0, 0.17)),
		Color3.fromRGB(136, 126, 160),
		Enum.Material.Concrete
	)

	-- Back & Side industrial walls
	makeBasePart(
		model,
		"BackWall",
		Vector3.new(1.8, dim.WallHeight, dim.WidthZ + 1.8),
		CFrame.new(posAt(dim.DepthX, 0, dim.WallHeight * 0.5)),
		pal.WallPrimary,
		Enum.Material.Metal
	)
	makeBasePart(
		model,
		"NorthWall",
		Vector3.new(dim.DepthX, dim.WallHeight, 1.8),
		CFrame.new(posAt(dim.DepthX * 0.5, -dim.WidthZ * 0.5, dim.WallHeight * 0.5)),
		pal.WallPrimary,
		Enum.Material.Metal
	)
	makeBasePart(
		model,
		"SouthWall",
		Vector3.new(dim.DepthX, dim.WallHeight, 1.8),
		CFrame.new(posAt(dim.DepthX * 0.5, dim.WidthZ * 0.5, dim.WallHeight * 0.5)),
		pal.WallPrimary,
		Enum.Material.Metal
	)

	-- Front wall columns, panoramic front windows, and upper lintel
	for _, zSide in ipairs({ -1, 1 }) do
		-- Lower sill under window
		makeBasePart(
			model,
			"WindowSill",
			Vector3.new(1.8, 3.2, 16.5),
			CFrame.new(posAt(0, zSide * 16.25, 1.6)),
			pal.WallDark,
			Enum.Material.Metal
		)
		-- Large front clear glass window so interior displays are clearly visible
		makeBasePart(
			model,
			"FrontWindow",
			Vector3.new(0.6, 12.5, 15.8),
			CFrame.new(posAt(0, zSide * 16.25, 9.45)),
			Color3.fromRGB(210, 236, 255),
			Enum.Material.Glass,
			true,
			0.78
		)
		-- Upper wall fascia above window
		makeBasePart(
			model,
			"FrontFascia",
			Vector3.new(1.8, 6.3, 16.5),
			CFrame.new(posAt(0, zSide * 16.25, 18.85)),
			pal.WallPrimary,
			Enum.Material.Metal
		)
		-- Gate frame steel pillar
		makeBasePart(
			model,
			"GatePillar",
			Vector3.new(2.4, dim.WallHeight + 1, 2.2),
			CFrame.new(posAt(0, zSide * 7.6, (dim.WallHeight + 1) * 0.5)),
			pal.WallDark,
			Enum.Material.Metal
		)
	end

	-- Center header over laser gate
	makeBasePart(
		model,
		"GateHeaderWall",
		Vector3.new(2.0, dim.WallHeight - dim.DoorHeightY, dim.DoorWidthZ + 1.5),
		CFrame.new(posAt(0, 0, dim.DoorHeightY + (dim.WallHeight - dim.DoorHeightY) * 0.5)),
		pal.WallDark,
		Enum.Material.Metal
	)

	-- Open industrial skylight roof trusses & bright ceiling lights (keeps interiors bright & screenshot-friendly)
	for d = 10, 54, 14 do
		makeBasePart(
			model,
			"RoofTruss",
			Vector3.new(1.6, 1.2, dim.WidthZ + 1),
			CFrame.new(posAt(d, 0, dim.WallHeight + 0.6)),
			pal.WallDark,
			Enum.Material.Metal
		)
		local lightStrip = makeBasePart(
			model,
			"CeilingLight",
			Vector3.new(1.1, 0.4, 26),
			CFrame.new(posAt(d, 0, dim.WallHeight - 0.15)),
			Color3.fromRGB(255, 246, 228),
			Enum.Material.Neon,
			false
		)
		local cLight = Instance.new("PointLight")
		cLight.Color = Color3.fromRGB(255, 242, 230)
		cLight.Brightness = 1.65
		cLight.Range = 34
		cLight.Parent = lightStrip
	end

	-- Exterior neon accent cornice
	makeBasePart(
		model,
		"FrontAccentNeon",
		Vector3.new(0.65, 0.75, dim.WidthZ + 1),
		CFrame.new(posAt(-0.8, 0, dim.WallHeight + 0.8)),
		def.accent,
		Enum.Material.Neon,
		false
	)

	-- Large Exterior Owner & Base Sign facing the Central Conveyor (transparent floating text, 0.7x scale)
	local mainSignPos = posAt(-1.1, 0, dim.WallHeight + 4.2)
	local mainSignPart = makeBasePart(
		model,
		"MainOwnerSign",
		Vector3.new(19.6, 3.92, 0.4),
		CFrame.lookAt(mainSignPos, mainSignPos + outwardDir),
		Color3.fromRGB(22, 14, 38),
		Enum.Material.SmoothPlastic,
		false,
		1
	)

	local ownerSg = Instance.new("SurfaceGui")
	ownerSg.Name = "OwnerSignGui"
	ownerSg.Face = Enum.NormalId.Front
	ownerSg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	ownerSg.PixelsPerStud = 36
	ownerSg.LightInfluence = 0
	ownerSg.Adornee = mainSignPart
	ownerSg.Parent = mainSignPart

	local signBg = Instance.new("Frame")
	signBg.Size = UDim2.fromScale(1, 1)
	signBg.BackgroundTransparency = 1
	signBg.BorderSizePixel = 0
	signBg.Parent = ownerSg

	local baseTitleLabel = Instance.new("TextLabel")
	baseTitleLabel.Name = "BaseTitle"
	baseTitleLabel.Size = UDim2.new(0.94, 0, 0.46, 0)
	baseTitleLabel.Position = UDim2.new(0.03, 0, 0.04, 0)
	baseTitleLabel.BackgroundTransparency = 1
	baseTitleLabel.Font = Enum.Font.GothamBlack
	baseTitleLabel.Text = def.name
	baseTitleLabel.TextColor3 = def.accent
	baseTitleLabel.TextScaled = true
	baseTitleLabel.Parent = signBg
	local btStroke = Instance.new("UIStroke")
	btStroke.Color = Color3.fromRGB(6, 3, 14)
	btStroke.Thickness = 3.0
	btStroke.Parent = baseTitleLabel

	local ownerNameLabel = Instance.new("TextLabel")
	ownerNameLabel.Name = "OwnerName"
	ownerNameLabel.Size = UDim2.new(0.94, 0, 0.44, 0)
	ownerNameLabel.Position = UDim2.new(0.03, 0, 0.52, 0)
	ownerNameLabel.BackgroundTransparency = 1
	ownerNameLabel.Font = Enum.Font.GothamBlack
	ownerNameLabel.Text = "UNCLAIMED BASE"
	ownerNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	ownerNameLabel.TextScaled = true
	ownerNameLabel.Parent = signBg
	local onStroke = Instance.new("UIStroke")
	onStroke.Color = Color3.fromRGB(6, 3, 14)
	onStroke.Thickness = 3.0
	onStroke.Parent = ownerNameLabel

	-- Gate Lock Countdown Sign directly over doorway (transparent floating text, 0.7x scale)
	local gateSignPos = posAt(-1.15, 0, dim.DoorHeightY + 2.3)
	local gateSignPart = makeBasePart(
		model,
		"GateStatusSign",
		Vector3.new(10.85, 2.24, 0.4),
		CFrame.lookAt(gateSignPos, gateSignPos + outwardDir),
		Color3.fromRGB(20, 12, 34),
		Enum.Material.SmoothPlastic,
		false,
		1
	)

	local gateSg = Instance.new("SurfaceGui")
	gateSg.Name = "GateStatusGui"
	gateSg.Face = Enum.NormalId.Front
	gateSg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gateSg.PixelsPerStud = 38
	gateSg.LightInfluence = 0
	gateSg.Adornee = gateSignPart
	gateSg.Parent = gateSignPart

	local gateBg = Instance.new("Frame")
	gateBg.Size = UDim2.fromScale(1, 1)
	gateBg.BackgroundTransparency = 1
	gateBg.BorderSizePixel = 0
	gateBg.Parent = gateSg
	local gateStroke = Instance.new("UIStroke")
	gateStroke.Color = Color3.fromRGB(65, 245, 115)
	gateStroke.Thickness = 0
	gateStroke.Transparency = 1
	gateStroke.Parent = gateBg

	local gateStatusLabel = Instance.new("TextLabel")
	gateStatusLabel.Name = "StatusText"
	gateStatusLabel.Size = UDim2.new(0.94, 0, 0.86, 0)
	gateStatusLabel.Position = UDim2.new(0.03, 0, 0.07, 0)
	gateStatusLabel.BackgroundTransparency = 1
	gateStatusLabel.Font = Enum.Font.GothamBlack
	gateStatusLabel.Text = "UNLOCKED"
	gateStatusLabel.TextColor3 = Color3.fromRGB(75, 255, 125)
	gateStatusLabel.TextScaled = true
	gateStatusLabel.Parent = gateBg
	local gsStroke = Instance.new("UIStroke")
	gsStroke.Color = Color3.fromRGB(6, 3, 14)
	gsStroke.Thickness = 3.0
	gsStroke.Parent = gateStatusLabel

	-- Red Laser Security Gate Beams + Invisible PhysicsService Collision Barrier
	local laserBars = {}
	for i = 1, 5 do
		local yBar = i * 2.45
		local bar = makeBasePart(
			model,
			"LaserBeam_" .. tostring(i),
			Vector3.new(0.38, 0.38, dim.DoorWidthZ - 0.6),
			CFrame.new(posAt(0, 0, yBar)),
			pal.LaserRed,
			Enum.Material.Neon,
			false,
			0.86
		)
		table.insert(laserBars, bar)
	end

	local gateBarrier = makeBasePart(
		model,
		"LaserGateBarrier",
		Vector3.new(1.4, dim.DoorHeightY, dim.DoorWidthZ),
		CFrame.new(posAt(0, 0, dim.DoorHeightY * 0.5)),
		pal.LaserRed,
		Enum.Material.ForceField,
		false,
		1
	)
	pcall(function()
		gateBarrier.CollisionGroup = "LaserGate_" .. tostring(def.id)
	end)

	-- Big Lock Button Pedestal right inside entrance
	local lockPedPos = posAt(dim.LockButtonDepth, dim.LockButtonZOffset, 1.6)
	makeBasePart(model, "LockPedestal", Vector3.new(3.6, 3.2, 3.6), CFrame.new(lockPedPos), pal.WallDark, Enum.Material.Metal)
	local lockButtonPart = makeBasePart(
		model,
		"LockButtonOrb",
		Vector3.new(0.9, 2.8, 2.8),
		CFrame.new(lockPedPos + Vector3.new(0, 1.9, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(65, 235, 115),
		Enum.Material.Neon,
		true,
		0,
		Enum.PartType.Cylinder
	)

	local lockPrompt = Instance.new("ProximityPrompt")
	lockPrompt.Name = "LockBasePrompt"
	lockPrompt.ActionText = "Lock Base (60s)"
	lockPrompt.ObjectText = "Laser Security System"
	lockPrompt.KeyboardKeyCode = Enum.KeyCode.F
	lockPrompt.HoldDuration = 0
	lockPrompt.MaxActivationDistance = 12
	lockPrompt.RequiresLineOfSight = false
	lockPrompt.Parent = lockButtonPart

	local lockBb = Instance.new("BillboardGui")
	lockBb.Name = "LockButtonGui"
	lockBb.Adornee = lockButtonPart
	lockBb.StudsOffset = Vector3.new(0, 3.2, 0)
	lockBb.Size = UDim2.new(0, 165, 0, 52)
	lockBb.MaxDistance = 210
	lockBb.LightInfluence = 0
	lockBb.Parent = lockButtonPart

	local lockBbFrame = Instance.new("Frame")
	lockBbFrame.Size = UDim2.fromScale(1, 1)
	lockBbFrame.BackgroundTransparency = 1
	lockBbFrame.BorderSizePixel = 0
	lockBbFrame.Parent = lockBb

	local lockButtonLabel = Instance.new("TextLabel")
	lockButtonLabel.Size = UDim2.new(0.96, 0, 0.88, 0)
	lockButtonLabel.Position = UDim2.new(0.02, 0, 0.06, 0)
	lockButtonLabel.BackgroundTransparency = 1
	lockButtonLabel.Font = Enum.Font.GothamBlack
	lockButtonLabel.Text = "LOCK LASERS\n[F] READY"
	lockButtonLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	lockButtonLabel.TextScaled = true
	lockButtonLabel.Parent = lockBbFrame
	local lbStroke = Instance.new("UIStroke")
	lbStroke.Color = Color3.fromRGB(6, 3, 14)
	lbStroke.Thickness = 2.6
	lbStroke.Parent = lockButtonLabel

	-- Green Cash Collection Platform inside entrance
	local cashPadPos = posAt(dim.CashPadDepth, dim.CashPadZOffset, 0.45)
	makeBasePart(
		model,
		"CashPadBorder",
		dim.CashPadSize + Vector3.new(1.1, -0.15, 1.1),
		CFrame.new(cashPadPos - Vector3.new(0, 0.08, 0)),
		pal.CashPadBorder,
		Enum.Material.Metal
	)
	local cashPadPart = makeBasePart(
		model,
		"GreenCashPlatform",
		dim.CashPadSize,
		CFrame.new(cashPadPos),
		pal.CashPadGreen,
		Enum.Material.Neon
	)

	local cashBb = Instance.new("BillboardGui")
	cashBb.Name = "CashPlatformGui"
	cashBb.Adornee = cashPadPart
	cashBb.StudsOffset = Vector3.new(0, 4.2, 0)
	cashBb.Size = UDim2.new(0, 200, 0, 64)
	cashBb.MaxDistance = 260
	cashBb.LightInfluence = 0
	cashBb.Parent = cashPadPart

	local cashFrame = Instance.new("Frame")
	cashFrame.Size = UDim2.fromScale(1, 1)
	cashFrame.BackgroundTransparency = 1
	cashFrame.BorderSizePixel = 0
	cashFrame.Parent = cashBb

	local cashTitle = Instance.new("TextLabel")
	cashTitle.Size = UDim2.new(0.96, 0, 0.36, 0)
	cashTitle.Position = UDim2.new(0.02, 0, 0.04, 0)
	cashTitle.BackgroundTransparency = 1
	cashTitle.Font = Enum.Font.GothamBlack
	cashTitle.Text = "COLLECT CASH"
	cashTitle.TextColor3 = Color3.fromRGB(110, 255, 152)
	cashTitle.TextScaled = true
	cashTitle.Parent = cashFrame
	local ctStroke = Instance.new("UIStroke")
	ctStroke.Color = Color3.fromRGB(6, 3, 14)
	ctStroke.Thickness = 2.4
	ctStroke.Parent = cashTitle

	local cashAmountLabel = Instance.new("TextLabel")
	cashAmountLabel.Name = "AmountLabel"
	cashAmountLabel.Size = UDim2.new(0.96, 0, 0.54, 0)
	cashAmountLabel.Position = UDim2.new(0.02, 0, 0.42, 0)
	cashAmountLabel.BackgroundTransparency = 1
	cashAmountLabel.Font = Enum.Font.GothamBlack
	cashAmountLabel.Text = "$0"
	cashAmountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	cashAmountLabel.TextScaled = true
	cashAmountLabel.Parent = cashFrame
	local caStroke = Instance.new("UIStroke")
	caStroke.Color = Color3.fromRGB(6, 3, 14)
	caStroke.Thickness = 2.8
	caStroke.Parent = cashAmountLabel

	-- 10 Interior Character Display Pedestals (Slots 1-5 North, Slots 6-10 South)
	local slots = {}
	for sIdx = 1, dim.SlotCount do
		local slotTopPos, slotFaceDir = GameConfig.getSlotTransform(def, sIdx)
		local pedCenter = Vector3.new(slotTopPos.X, dim.PedestalTopY * 0.5, slotTopPos.Z)

		local pedPart = makeBasePart(
			model,
			"SlotPedestal_" .. tostring(sIdx),
			Vector3.new(dim.PedestalTopY - 0.15, 5.4, 5.4),
			CFrame.new(pedCenter) * CFrame.Angles(0, 0, math.rad(90)),
			Color3.fromRGB(158, 146, 188),
			Enum.Material.Marble,
			true,
			0,
			Enum.PartType.Cylinder
		)
		local rimPart = makeBasePart(
			model,
			"SlotRim_" .. tostring(sIdx),
			Vector3.new(0.18, 5.75, 5.75),
			CFrame.new(slotTopPos - Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color3.fromRGB(145, 108, 212),
			Enum.Material.Neon,
			false,
			0,
			Enum.PartType.Cylinder
		)

		-- Floor slot plaque facing center aisle (transparent floating text, 0.7x scale)
		local plaquePos = slotTopPos + slotFaceDir * 3.1 - Vector3.new(0, 0.65, 0)
		local plaquePart = makeBasePart(
			model,
			"SlotPlaque_" .. tostring(sIdx),
			Vector3.new(2.66, 0.70, 0.25),
			CFrame.lookAt(plaquePos, plaquePos + slotFaceDir + Vector3.new(0, 0.45, 0)),
			Color3.fromRGB(24, 15, 42),
			Enum.Material.SmoothPlastic,
			false,
			1
		)

		local pSg = Instance.new("SurfaceGui")
		pSg.Face = Enum.NormalId.Front
		pSg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		pSg.PixelsPerStud = 42
		pSg.LightInfluence = 0
		pSg.Adornee = plaquePart
		pSg.Parent = plaquePart

		local plaqueLabel = Instance.new("TextLabel")
		plaqueLabel.Size = UDim2.fromScale(0.96, 0.90)
		plaqueLabel.Position = UDim2.fromScale(0.02, 0.05)
		plaqueLabel.BackgroundTransparency = 1
		plaqueLabel.Font = Enum.Font.GothamBlack
		plaqueLabel.Text = "SLOT #" .. tostring(sIdx) .. " • EMPTY"
		plaqueLabel.TextColor3 = Color3.fromRGB(220, 210, 248)
		plaqueLabel.TextScaled = true
		plaqueLabel.Parent = pSg
		local plStroke = Instance.new("UIStroke")
		plStroke.Color = Color3.fromRGB(6, 3, 14)
		plStroke.Thickness = 2.6
		plStroke.Parent = plaqueLabel

		-- Prompt A: Owner Sell Prompt
		local sellPrompt = Instance.new("ProximityPrompt")
		sellPrompt.Name = "OwnerSellPrompt"
		sellPrompt.ActionText = "Sell Creature"
		sellPrompt.ObjectText = "Slot #" .. tostring(sIdx)
		sellPrompt.KeyboardKeyCode = Enum.KeyCode.R
		sellPrompt.HoldDuration = 0.55
		sellPrompt.MaxActivationDistance = 10
		sellPrompt.RequiresLineOfSight = false
		sellPrompt.Enabled = false
		sellPrompt:SetAttribute("PromptRole", "OwnerSell")
		sellPrompt:SetAttribute("BaseId", def.id)
		sellPrompt:SetAttribute("SlotIndex", sIdx)
		sellPrompt.Parent = pedPart

		-- Prompt B: Rival Steal Prompt ("E — STEAL")
		local stealPrompt = Instance.new("ProximityPrompt")
		stealPrompt.Name = "RivalStealPrompt"
		stealPrompt.ActionText = "E — STEAL"
		stealPrompt.ObjectText = "Unlocked Slot"
		stealPrompt.KeyboardKeyCode = Enum.KeyCode.E
		stealPrompt.HoldDuration = 0.65
		stealPrompt.MaxActivationDistance = 12
		stealPrompt.RequiresLineOfSight = false
		stealPrompt.Enabled = false
		stealPrompt:SetAttribute("PromptRole", "RivalSteal")
		stealPrompt:SetAttribute("BaseId", def.id)
		stealPrompt:SetAttribute("SlotIndex", sIdx)
		stealPrompt.Parent = pedPart

		slots[sIdx] = {
			index = sIdx,
			worldPos = slotTopPos,
			faceDir = slotFaceDir,
			pedPart = pedPart,
			rimPart = rimPart,
			plaqueLabel = plaqueLabel,
			sellPrompt = sellPrompt,
			stealPrompt = stealPrompt,
			occupied = false,
			reservedForTravel = false,
			beingStolen = false,
			creatureId = nil,
			mutation = "None",
			creatureUid = nil,
			accumulatedDisplay = 0,
		}
	end

	return {
		id = def.id,
		def = def,
		model = model,
		inwardDir = inwardDir,
		outwardDir = outwardDir,
		ownerUserId = nil,
		ownerName = nil,
		isShowcaseNpc = false,
		showcaseStatusOverride = nil,
		isLocked = false,
		lockRemaining = 0,
		lockCooldown = 0,
		flashTimer = 0,
		uncollectedCash = 0,
		ownerNameLabel = ownerNameLabel,
		gateStatusLabel = gateStatusLabel,
		gateBg = gateBg,
		gateStroke = gateStroke,
		laserBars = laserBars,
		gateBarrier = gateBarrier,
		lockButtonPart = lockButtonPart,
		lockButtonLabel = lockButtonLabel,
		lockPrompt = lockPrompt,
		cashPadPart = cashPadPart,
		cashAmountLabel = cashAmountLabel,
		slots = slots,
	}
end

local function refreshBaseSecurityVisuals(base)
	if base.showcaseStatusOverride then
		base.gateStatusLabel.Text = base.showcaseStatusOverride
		base.gateStatusLabel.TextColor3 = Color3.fromRGB(110, 255, 135)
		base.gateBg.BackgroundColor3 = Color3.fromRGB(18, 42, 28)
		base.gateStroke.Color = Color3.fromRGB(85, 255, 130)
		base.gateBarrier.CanCollide = false
		for _, bar in ipairs(base.laserBars) do
			bar.Transparency = 0.86
		end
	elseif base.isLocked then
		local timerText = FormatUtil.formatTimer(base.lockRemaining)
		base.gateStatusLabel.Text = "LOCKED " .. timerText
		base.gateStatusLabel.TextColor3 = Color3.fromRGB(255, 78, 95)
		base.gateBg.BackgroundColor3 = Color3.fromRGB(48, 12, 24)
		base.gateStroke.Color = GameConfig.Palette.LaserRed
		base.gateBarrier.CanCollide = true
		for _, bar in ipairs(base.laserBars) do
			bar.Transparency = 0.04
			bar.Color = GameConfig.Palette.LaserRed
		end
		base.lockButtonPart.Color = GameConfig.Palette.LaserRed
		base.lockButtonLabel.Text = "LASERS ON\n" .. timerText
		base.lockPrompt.ActionText = "Unlock Lasers Early"
	else
		base.gateStatusLabel.Text = "UNLOCKED"
		base.gateStatusLabel.TextColor3 = Color3.fromRGB(78, 255, 128)
		base.gateBg.BackgroundColor3 = Color3.fromRGB(16, 40, 26)
		base.gateStroke.Color = Color3.fromRGB(68, 245, 118)
		base.gateBarrier.CanCollide = false
		for _, bar in ipairs(base.laserBars) do
			bar.Transparency = 0.88
		end
		if base.lockCooldown > 0 then
			base.lockButtonPart.Color = Color3.fromRGB(255, 175, 48)
			base.lockButtonLabel.Text = "RECHARGING\n" .. FormatUtil.formatTimer(base.lockCooldown)
			base.lockPrompt.ActionText = "Cooldown (" .. tostring(math.ceil(base.lockCooldown)) .. "s)"
		else
			base.lockButtonPart.Color = Color3.fromRGB(65, 235, 115)
			base.lockButtonLabel.Text = "LOCK LASERS\n[F] READY"
			local dur = EconomyConfig.DefaultLockDuration
			if base.ownerUserId and base.ownerUserId > 0 then
				local pData = PlayerDataService.getDataByUserId(base.ownerUserId)
				if pData then
					dur = EconomyConfig.getLockDuration(pData.rebirths)
				end
			end
			base.lockPrompt.ActionText = "Lock Base (" .. tostring(dur) .. "s)"
		end
	end

	-- Update StealPrompt availability across slots whenever lock state changes
	for _, slot in ipairs(base.slots) do
		local canBeStolen = slot.occupied and (not slot.beingStolen) and (not base.isLocked) and (base.ownerUserId ~= nil)
		slot.stealPrompt.Enabled = canBeStolen
		slot.sellPrompt.Enabled = slot.occupied and (not slot.beingStolen) and (not base.isShowcaseNpc)
	end
end

local function syncBaseSlotsToProfile(base)
	if not base.ownerUserId or base.isShowcaseNpc then
		return
	end
	local serialized = {}
	for _, slot in ipairs(base.slots) do
		if slot.occupied and slot.creatureId and not slot.beingStolen then
			table.insert(serialized, {
				id = slot.creatureId,
				mutation = slot.mutation or "None",
				slot = slot.index,
			})
		end
	end
	PlayerDataService.syncOwnedSlotsFromBase(base.ownerUserId, serialized)
end

function BaseService.updateSlotVisuals(base, slotIndex: number)
	local slot = base.slots[slotIndex]
	if not slot then
		return
	end

	if not slot.occupied or not slot.creatureId then
		slot.rimPart.Color = Color3.fromRGB(115, 78, 175)
		slot.plaqueLabel.Text = "SLOT #" .. tostring(slotIndex) .. " • EMPTY"
		slot.plaqueLabel.TextColor3 = Color3.fromRGB(220, 210, 248)
		slot.sellPrompt.Enabled = false
		slot.stealPrompt.Enabled = false
		return
	end

	local cDef = CreatureConfig.getCreature(slot.creatureId)
	local rInfo = CreatureConfig.getRarityInfo(cDef.Rarity)
	local rebMult = 1
	if base.ownerUserId and not base.isShowcaseNpc then
		local pData = PlayerDataService.getDataByUserId(base.ownerUserId)
		if pData then
			rebMult = pData.incomeMultiplier or 1
		end
	end
	local rate = EconomyConfig.computeSlotIncome(cDef.IncomePerSecond, slot.mutation, rebMult)
	local refund = math.floor(cDef.PurchasePrice * EconomyConfig.SellRefundFraction)

	slot.rimPart.Color = rInfo.color
	local mutTag = if slot.mutation and slot.mutation ~= "None" then ("[" .. string.upper(slot.mutation) .. "] ") else ""
	slot.plaqueLabel.Text = mutTag .. cDef.DisplayName .. " • " .. FormatUtil.formatRate(rate)
	slot.plaqueLabel.TextColor3 = rInfo.color

	slot.sellPrompt.ObjectText = cDef.DisplayName
	slot.sellPrompt.ActionText = "Sell (+" .. FormatUtil.formatCash(refund) .. ")"
	slot.sellPrompt.Enabled = (not slot.beingStolen) and (not base.isShowcaseNpc)

	slot.stealPrompt.ObjectText = mutTag .. cDef.DisplayName .. " (" .. cDef.Rarity .. ")"
	slot.stealPrompt.ActionText = "E — STEAL"
	slot.stealPrompt.Enabled = (not slot.beingStolen) and (not base.isLocked) and (base.ownerUserId ~= nil)

	if slot.creatureUid then
		local rec = CreatureService.getRecord(slot.creatureUid)
		if rec and rec.model then
			rec.model:SetAttribute("TagHeightBonus", if slotIndex % 2 == 0 then 2.6 else 0)
			local statusTxt = "SLOT #" .. tostring(slotIndex) .. " • +" .. FormatUtil.formatCash(slot.accumulatedDisplay)
			CreatureConfig.createCreatureBillboard(rec.model, slot.creatureId, slot.mutation, "slot", rebMult, statusTxt)
		end
	end
end

function BaseService.placeCreatureInSlot(baseId: number, slotIndex: number, creatureId: string, mutationName: string?, existingUid: string?): boolean
	local base = basesById[baseId]
	if not base then
		return false
	end
	local slot = base.slots[slotIndex]
	if not slot then
		return false
	end

	if slot.creatureUid and slot.creatureUid ~= existingUid then
		CreatureService.destroyCreature(slot.creatureUid)
	end

	local rebMult = 1
	if base.ownerUserId and not base.isShowcaseNpc then
		local pData = PlayerDataService.getDataByUserId(base.ownerUserId)
		if pData then
			rebMult = pData.incomeMultiplier or 1
		end
	end

	local uid = existingUid
	if uid then
		local rec = CreatureService.getRecord(uid)
		if rec then
			rec.mode = "slot"
			rec.position = slot.worldPos
			rec.lookDir = slot.faceDir
			rec.waypoints = nil
			rec.reserved = false
			if rec.model then
				rec.model:PivotTo(CFrame.lookAt(slot.worldPos, slot.worldPos + slot.faceDir))
			end
		else
			uid = nil
		end
	end

	if not uid then
		local spawned = CreatureService.spawnCreatureInstance(
			creatureId,
			mutationName or "None",
			slot.worldPos,
			slot.faceDir,
			"slot",
			rebMult
		)
		if not spawned then
			return false
		end
		uid = spawned.uid
	end

	slot.occupied = true
	slot.reservedForTravel = false
	slot.beingStolen = false
	slot.creatureId = creatureId
	slot.mutation = mutationName or "None"
	slot.creatureUid = uid
	slot.accumulatedDisplay = 0

	BaseService.updateSlotVisuals(base, slotIndex)
	syncBaseSlotsToProfile(base)
	return true
end

function BaseService.reserveFreeSlot(baseId: number): number?
	local base = basesById[baseId]
	if not base then
		return nil
	end
	for _, slot in ipairs(base.slots) do
		if not slot.occupied and not slot.reservedForTravel then
			slot.reservedForTravel = true
			return slot.index
		end
	end
	return nil
end

function BaseService.cancelSlotReservation(baseId: number, slotIndex: number)
	local base = basesById[baseId]
	if base and base.slots[slotIndex] then
		base.slots[slotIndex].reservedForTravel = false
	end
end

function BaseService.findFreeSlotUnreserved(baseId: number): number?
	local base = basesById[baseId]
	if not base then
		return nil
	end
	for _, slot in ipairs(base.slots) do
		if not slot.occupied and not slot.reservedForTravel then
			return slot.index
		end
	end
	return nil
end

function BaseService.detachSlotForSteal(baseId: number, slotIndex: number)
	local base = basesById[baseId]
	if not base then
		return nil
	end
	local slot = base.slots[slotIndex]
	if not slot or not slot.occupied or slot.beingStolen then
		return nil
	end

	local snapshot = {
		creatureId = slot.creatureId,
		mutation = slot.mutation,
		creatureUid = slot.creatureUid,
		originBaseId = baseId,
		originSlotIndex = slotIndex,
	}

	slot.occupied = false
	slot.beingStolen = false
	slot.creatureId = nil
	slot.mutation = "None"
	slot.creatureUid = nil
	slot.accumulatedDisplay = 0

	BaseService.updateSlotVisuals(base, slotIndex)
	syncBaseSlotsToProfile(base)
	return snapshot
end

function BaseService.clearAllBaseSlots(baseId: number)
	local base = basesById[baseId]
	if not base then
		return
	end
	for _, slot in ipairs(base.slots) do
		if slot.creatureUid then
			CreatureService.destroyCreature(slot.creatureUid)
		end
		slot.occupied = false
		slot.reservedForTravel = false
		slot.beingStolen = false
		slot.creatureId = nil
		slot.mutation = "None"
		slot.creatureUid = nil
		slot.accumulatedDisplay = 0
		BaseService.updateSlotVisuals(base, slot.index)
	end
	base.uncollectedCash = 0
	base.cashAmountLabel.Text = "$0"
	syncBaseSlotsToProfile(base)
end

function BaseService.tryToggleLock(player: Player)
	local baseId = baseIdByUserId[player.UserId]
	if not baseId then
		return
	end
	local base = basesById[baseId]
	if not base or base.ownerUserId ~= player.UserId then
		return
	end

	if base.isLocked then
		base.isLocked = false
		base.lockRemaining = 0
		base.lockCooldown = EconomyConfig.LockCooldownSeconds
		refreshBaseSecurityVisuals(base)
		NotificationService.send(player, "warning", "Base lasers deactivated! Recharging security...")
	else
		if base.lockCooldown > 0 then
			NotificationService.send(player, "warning", "Laser gate recharging: " .. tostring(math.ceil(base.lockCooldown)) .. "s left!", 1.5)
			return
		end
		local pData = PlayerDataService.getData(player)
		local duration = EconomyConfig.getLockDuration(if pData then pData.rebirths else 0)
		base.isLocked = true
		base.lockRemaining = duration
		base.flashTimer = 0.6
		refreshBaseSecurityVisuals(base)
		PlayerDataService.advanceTutorial(player, "lock_base")
		NotificationService.send(player, "success", "BASE LOCKED! Red laser security active for " .. tostring(duration) .. "s!")
	end

	local pData = PlayerDataService.getData(player)
	if pData then
		pData._baseLocked = base.isLocked
		pData._lockRemaining = math.ceil(base.lockRemaining)
		pData._lockCooldown = math.ceil(base.lockCooldown)
		PlayerDataService.syncToClient(player)
	end
end

local function handleSellCreature(player: Player, baseId: number, slotIndex: number)
	local base = basesById[baseId]
	if not base or base.ownerUserId ~= player.UserId or base.isShowcaseNpc then
		NotificationService.send(player, "error", "You can only sell creatures in your own base!", 1.5)
		return
	end
	local slot = base.slots[slotIndex]
	if not slot or not slot.occupied or slot.beingStolen or not slot.creatureId then
		return
	end
	local cDef = CreatureConfig.getCreature(slot.creatureId)
	if not cDef then
		return
	end

	local refund = math.max(1, math.floor(cDef.PurchasePrice * EconomyConfig.SellRefundFraction))
	if slot.creatureUid then
		CreatureService.destroyCreature(slot.creatureUid)
	end

	slot.occupied = false
	slot.reservedForTravel = false
	slot.beingStolen = false
	slot.creatureId = nil
	slot.mutation = "None"
	slot.creatureUid = nil
	slot.accumulatedDisplay = 0

	BaseService.updateSlotVisuals(base, slotIndex)
	syncBaseSlotsToProfile(base)
	PlayerDataService.addCash(player, refund, false)
	NotificationService.send(player, "cash", "Sold " .. cDef.DisplayName .. " for " .. FormatUtil.formatCash(refund) .. "!")
end

function BaseService.assignBaseToPlayer(player: Player): any?
	local existingId = baseIdByUserId[player.UserId]
	if existingId then
		return basesById[existingId]
	end

	local chosenBase = nil
	for _, candidateId in ipairs(GameConfig.BaseAssignOrder) do
		local b = basesById[candidateId]
		if b and b.ownerUserId == nil and not b.isShowcaseNpc then
			chosenBase = b
			break
		end
	end

	if not chosenBase then
		return nil
	end

	chosenBase.ownerUserId = player.UserId
	chosenBase.ownerName = player.Name
	chosenBase.ownerNameLabel.Text = "OWNER: " .. string.upper(player.Name)
	chosenBase.ownerNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	chosenBase.model:SetAttribute("OwnerUserId", player.UserId)
	chosenBase.isLocked = false
	chosenBase.lockRemaining = 0
	chosenBase.lockCooldown = 0
	chosenBase.uncollectedCash = 0
	chosenBase.cashAmountLabel.Text = "$0"

	baseIdByUserId[player.UserId] = chosenBase.id

	local pData = PlayerDataService.getData(player)
	if pData then
		pData._assignedBaseId = chosenBase.id
		pData._baseLocked = false
		pData._lockRemaining = 0
		pData._lockCooldown = 0
		pData._uncollectedBaseCash = 0

		-- Restore saved creatures onto base slots
		for _, saved in ipairs(pData.ownedCreatures) do
			local slotIdx = tonumber(saved.slot)
			if slotIdx and slotIdx >= 1 and slotIdx <= GameConfig.BaseDimensions.SlotCount then
				if not chosenBase.slots[slotIdx].occupied then
					BaseService.placeCreatureInSlot(chosenBase.id, slotIdx, saved.id, saved.mutation)
				end
			end
		end
		PlayerDataService.syncToClient(player)
	end

	refreshBaseSecurityVisuals(chosenBase)
	BaseService.applyCharacterCollisionGroup(player, player.Character)
	return chosenBase
end

function BaseService.claimShowcaseBase(baseId: number, npcOwnerTitle: string, statusOverride: string?)
	local base = basesById[baseId]
	if not base or base.ownerUserId ~= nil then
		return nil
	end
	base.isShowcaseNpc = true
	base.ownerUserId = -baseId
	base.ownerName = npcOwnerTitle
	base.ownerNameLabel.Text = "OWNER: " .. string.upper(npcOwnerTitle)
	base.showcaseStatusOverride = statusOverride
	base.model:SetAttribute("OwnerUserId", -baseId)
	refreshBaseSecurityVisuals(base)
	return base
end

function BaseService.releasePlayerBase(player: Player)
	local baseId = baseIdByUserId[player.UserId]
	if not baseId then
		return
	end
	baseIdByUserId[player.UserId] = nil

	local base = basesById[baseId]
	if not base then
		return
	end

	for _, slot in ipairs(base.slots) do
		if slot.creatureUid then
			CreatureService.destroyCreature(slot.creatureUid)
		end
		slot.occupied = false
		slot.reservedForTravel = false
		slot.beingStolen = false
		slot.creatureId = nil
		slot.mutation = "None"
		slot.creatureUid = nil
		slot.accumulatedDisplay = 0
		BaseService.updateSlotVisuals(base, slot.index)
	end

	base.ownerUserId = nil
	base.ownerName = nil
	base.isLocked = false
	base.lockRemaining = 0
	base.lockCooldown = 0
	base.uncollectedCash = 0
	base.ownerNameLabel.Text = "UNCLAIMED BASE"
	base.cashAmountLabel.Text = "$0"
	base.model:SetAttribute("OwnerUserId", nil)
	refreshBaseSecurityVisuals(base)
end

function BaseService.getPlayerBase(player: Player)
	local id = baseIdByUserId[player.UserId]
	return if id then basesById[id] else nil
end

function BaseService.getBaseById(baseId: number)
	return basesById[baseId]
end

function BaseService.getAllBases()
	return basesById
end

function BaseService.isPositionInsideBase(baseId: number, pos: Vector3): boolean
	local base = basesById[baseId]
	if not base then
		return false
	end
	local def = base.def
	local dim = GameConfig.BaseDimensions
	local relDepth = (pos.X - def.frontX) * def.inwardSignX
	local relZ = math.abs(pos.Z - def.centerZ)
	return relDepth >= 1.5 and relDepth <= dim.DepthX and relZ <= (dim.WidthZ * 0.5)
end

function BaseService.setStealAttemptCallback(cb: (Player, number, number) -> ())
	stealAttemptCallback = cb
end

function BaseService.init(remotesFolder: Folder)
	setupCollisionGroups()

	local existing = Workspace:FindFirstChild("PlayerBases")
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "PlayerBases"
	folder.Parent = Workspace

	for _, def in ipairs(GameConfig.Bases) do
		local base = constructSingleBase(folder, def)
		basesById[def.id] = base
		refreshBaseSecurityVisuals(base)

		base.lockPrompt.Triggered:Connect(function(player: Player)
			if base.ownerUserId ~= player.UserId then
				NotificationService.send(player, "error", "Only the base owner can control these lasers!", 1.5)
				return
			end
			BaseService.tryToggleLock(player)
		end)

		for _, slot in ipairs(base.slots) do
			slot.sellPrompt.Triggered:Connect(function(player: Player)
				handleSellCreature(player, base.id, slot.index)
			end)
			slot.stealPrompt.Triggered:Connect(function(player: Player)
				if stealAttemptCallback then
					stealAttemptCallback(player, base.id, slot.index)
				end
			end)
		end
	end

	local lockRemote = remotesFolder:FindFirstChild(GameConfig.Remotes.ToggleLock) :: RemoteEvent?
	if lockRemote then
		lockRemote.OnServerEvent:Connect(function(player: Player)
			local base = BaseService.getPlayerBase(player)
			if not base or not player.Character or not player.Character.PrimaryPart then
				return
			end
			local dist = (player.Character.PrimaryPart.Position - base.lockButtonPart.Position).Magnitude
			if dist <= 20 then
				BaseService.tryToggleLock(player)
			else
				NotificationService.send(player, "warning", "Walk to your base Lock Button to toggle security!", 1.5)
			end
		end)
	end

	local tpRemote = remotesFolder:FindFirstChild(GameConfig.Remotes.TeleportToBase) :: RemoteEvent?
	if tpRemote then
		tpRemote.OnServerEvent:Connect(function(player: Player)
			local pData = PlayerDataService.getData(player)
			if pData and pData._isStealing then
				NotificationService.send(player, "error", "Cannot teleport while carrying a stolen creature!", 1.5)
				return
			end
			local base = BaseService.getPlayerBase(player)
			if base and player.Character and player.Character.PrimaryPart then
				local outsidePos = GameConfig.getBaseWorldPosition(base.def, -7, 0, 3.2)
				local faceIn = CFrame.lookAt(outsidePos, outsidePos + base.inwardDir)
				player.Character:PivotTo(faceIn)
			end
		end)
	end
end

-- Centralized server tick for base lock timers, visual flashing, tutorial check, and intruder ejection
function BaseService.step(dt: number, now: number)
	for _, base in pairs(basesById) do
		if base.isLocked then
			base.lockRemaining -= dt
			if base.flashTimer > 0 then
				base.flashTimer = math.max(0, base.flashTimer - dt)
				local flash = math.sin(now * 24) > 0
				for _, bar in ipairs(base.laserBars) do
					bar.Color = if flash then Color3.fromRGB(255, 255, 255) else GameConfig.Palette.LaserRed
				end
			end

			if base.lockRemaining <= 0 then
				base.isLocked = false
				base.lockRemaining = 0
				base.lockCooldown = EconomyConfig.LockCooldownSeconds
				refreshBaseSecurityVisuals(base)
				if base.ownerUserId and base.ownerUserId > 0 then
					local owner = Players:GetPlayerByUserId(base.ownerUserId)
					if owner then
						NotificationService.send(owner, "warning", "Your base laser lock expired! Watch out for thieves!")
					end
				end
			else
				base.gateStatusLabel.Text = "LOCKED " .. FormatUtil.formatTimer(base.lockRemaining)
				base.lockButtonLabel.Text = "LASERS ON\n" .. FormatUtil.formatTimer(base.lockRemaining)
			end
		elseif base.lockCooldown > 0 then
			base.lockCooldown = math.max(0, base.lockCooldown - dt)
			if base.lockCooldown <= 0 then
				refreshBaseSecurityVisuals(base)
			else
				base.lockButtonLabel.Text = "RECHARGING\n" .. FormatUtil.formatTimer(base.lockCooldown)
			end
		end
	end

	-- Server-side security check: eject non-owners from locked bases & complete "claim_base" tutorial step
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then
			continue
		end

		local myBase = BaseService.getPlayerBase(player)
		if myBase and BaseService.isPositionInsideBase(myBase.id, root.Position) then
			PlayerDataService.advanceTutorial(player, "claim_base")
		end

		for _, base in pairs(basesById) do
			if base.isLocked and base.ownerUserId ~= player.UserId then
				if BaseService.isPositionInsideBase(base.id, root.Position) then
					local ejectPos = GameConfig.getBaseWorldPosition(base.def, -7.5, 0, 3.5)
					char:PivotTo(CFrame.lookAt(ejectPos, ejectPos + base.outwardDir))
					NotificationService.send(player, "error", base.def.name .. " is LOCKED by laser security!", 2.0)
				end
			end
		end
	end
end

return BaseService

-- GameConfig.luau
-- Central world layout, palette, base coordinates, remotes, and tutorial configuration.

local GameConfig = {}

GameConfig.GameTitle = "BRAINROT TRATTORIA"
GameConfig.GameSubtitle = "Collect, Mutate, Defend & Steal!"

-- Bright purple industrial palette tuned for high-contrast readability
GameConfig.Palette = {
	FloorPrimary = Color3.fromRGB(54, 34, 86),
	FloorSecondary = Color3.fromRGB(68, 45, 106),
	FloorWalkway = Color3.fromRGB(80, 54, 124),
	WallPrimary = Color3.fromRGB(64, 40, 102),
	WallDark = Color3.fromRGB(38, 24, 64),
	WallTrim = Color3.fromRGB(168, 85, 255),
	ConveyorSurface = Color3.fromRGB(24, 16, 38),
	ConveyorStripe = Color3.fromRGB(42, 28, 66),
	ConveyorBorderGold = Color3.fromRGB(255, 205, 35),
	ConveyorArrowNeon = Color3.fromRGB(255, 220, 55),
	LaserRed = Color3.fromRGB(255, 42, 68),
	CashPadGreen = Color3.fromRGB(36, 232, 98),
	CashPadBorder = Color3.fromRGB(18, 125, 54),
	ShrineGold = Color3.fromRGB(255, 202, 48),
	ShrineAccent = Color3.fromRGB(255, 242, 150),
	NeonCyan = Color3.fromRGB(55, 230, 255),
	NeonMagenta = Color3.fromRGB(255, 70, 195),
}

-- Symmetrical arena dimensions (~270 x 350 studs)
GameConfig.Arena = {
	HalfWidthX = 135,
	HalfLengthZ = 175,
	WallHeight = 28,
}

-- Central Conveyor configuration
GameConfig.Conveyor = {
	StartZ = -128,
	EndZ = 128,
	BeltWidth = 16,
	BeltTopY = 0.6,
	SpawnInterval = 2.5,
	MaxActiveCreatures = 16,
	DefaultWalkSpeed = 10,
	PurchaseMaxDistance = 20,
}

-- North Spawn & Striped Shop Stalls
GameConfig.SpawnArea = {
	Position = Vector3.new(0, 1.5, -156),
	EquipmentStallPos = Vector3.new(-54, 0, -150),
	IndexStallPos = Vector3.new(54, 0, -150),
}

-- South Golden Rebirth Shrine
GameConfig.Shrine = {
	Position = Vector3.new(0, 0, 154),
	HallWestPos = Vector3.new(-56, 0, 150),
	HallEastPos = Vector3.new(56, 0, 150),
	InteractDistance = 22,
}

-- Base footprint & interior relative offsets
GameConfig.BaseDimensions = {
	WidthZ = 50,
	DepthX = 62,
	WallHeight = 22,
	DoorWidthZ = 14,
	DoorHeightY = 14,
	SlotCount = 10,
	PedestalTopY = 1.2,
	LockButtonDepth = 6.5,
	LockButtonZOffset = -11.5,
	CashPadDepth = 6.5,
	CashPadZOffset = 11.5,
	CashPadSize = Vector3.new(8.5, 0.7, 8.5),
}

-- Build all 8 symmetrical player bases (1-4 on West, 5-8 on East)
-- Priority order assigns central bases first for quick conveyor access
GameConfig.BaseAssignOrder = { 2, 3, 1, 4, 6, 7, 5, 8 }

GameConfig.Bases = {
	{ id = 1, name = "BASE #1", side = "West", frontX = -46, inwardSignX = -1, centerZ = -90, accent = Color3.fromRGB(175, 95, 255) },
	{ id = 2, name = "BASE #2", side = "West", frontX = -46, inwardSignX = -1, centerZ = -30, accent = Color3.fromRGB(70, 210, 255) },
	{ id = 3, name = "BASE #3", side = "West", frontX = -46, inwardSignX = -1, centerZ = 30, accent = Color3.fromRGB(255, 105, 200) },
	{ id = 4, name = "BASE #4", side = "West", frontX = -46, inwardSignX = -1, centerZ = 90, accent = Color3.fromRGB(95, 245, 155) },
	{ id = 5, name = "BASE #5", side = "East", frontX = 46, inwardSignX = 1, centerZ = -90, accent = Color3.fromRGB(255, 185, 55) },
	{ id = 6, name = "BASE #6", side = "East", frontX = 46, inwardSignX = 1, centerZ = -30, accent = Color3.fromRGB(255, 85, 120) },
	{ id = 7, name = "BASE #7", side = "East", frontX = 46, inwardSignX = 1, centerZ = 30, accent = Color3.fromRGB(130, 145, 255) },
	{ id = 8, name = "BASE #8", side = "East", frontX = 46, inwardSignX = 1, centerZ = 90, accent = Color3.fromRGB(65, 245, 220) },
}

local SLOT_DEPTHS = { 17, 26, 35, 44, 53 }

function GameConfig.getBaseWorldPosition(baseDef, depth: number, zOffset: number, y: number): Vector3
	local worldX = baseDef.frontX + baseDef.inwardSignX * depth
	local worldZ = baseDef.centerZ + zOffset
	return Vector3.new(worldX, y, worldZ)
end

function GameConfig.getSlotTransform(baseDef, slotIndex: number): (Vector3, Vector3)
	local isNorthRow = slotIndex <= 5
	local colIndex = if isNorthRow then slotIndex else (slotIndex - 5)
	local depth = SLOT_DEPTHS[colIndex] or 17
	local zOffset = if isNorthRow then -16 else 16
	local faceDir = if isNorthRow then Vector3.new(0, 0, 1) else Vector3.new(0, 0, -1)
	local pos = GameConfig.getBaseWorldPosition(baseDef, depth, zOffset, GameConfig.BaseDimensions.PedestalTopY)
	return pos, faceDir
end

-- RemoteEvent names inside ReplicatedStorage.Remotes
GameConfig.Remotes = {
	FolderName = "Remotes",
	StateSync = "StateSync",
	Notify = "Notify",
	FloatingPopup = "FloatingPopup",
	BuyShopItem = "BuyShopItem",
	UseTool = "UseTool",
	RequestRebirth = "RequestRebirth",
	ToggleLock = "ToggleLock",
	TutorialAction = "TutorialAction",
	TeleportToBase = "TeleportToBase",
	RequestInitialState = "RequestInitialState",
}

-- Guided first-time tutorial steps (one objective at a time)
GameConfig.TutorialSteps = {
	{
		step = 1,
		id = "claim_base",
		title = "1/8 • Claim Your Base",
		instruction = "Walk into your assigned purple base along the main promenade!",
		targetType = "MyBase",
	},
	{
		step = 2,
		id = "buy_first",
		title = "2/8 • Buy First Creature",
		instruction = "Head to the Central Conveyor and press [E] on an affordable creature!",
		targetType = "Conveyor",
	},
	{
		step = 3,
		id = "wait_arrive",
		title = "3/8 • Escort Home",
		instruction = "Watch your creature walk along the path into a display slot in your base!",
		targetType = "MyBase",
	},
	{
		step = 4,
		id = "collect_cash",
		title = "4/8 • Collect Cash",
		instruction = "Step onto your base's glowing GREEN Cash Platform to collect earnings!",
		targetType = "MyCashPad",
	},
	{
		step = 5,
		id = "buy_second",
		title = "5/8 • Expand Your Squad",
		instruction = "Buy another creature from the conveyor to multiply your $/sec!",
		targetType = "Conveyor",
	},
	{
		step = 6,
		id = "visit_shop",
		title = "6/8 • Visit Equipment Shop",
		instruction = "Visit the striped Shop Stalls in the North Plaza or click SHOP on the left!",
		targetType = "Shop",
	},
	{
		step = 7,
		id = "lock_base",
		title = "7/8 • Activate Laser Security",
		instruction = "Press the big LOCK button inside your base gate to turn on Red Lasers (60s)!",
		targetType = "MyLockButton",
	},
	{
		step = 8,
		id = "learn_steal",
		title = "8/8 • Master Stealing",
		instruction = "Sneak into any UNLOCKED rival base and hold [E] on a creature to steal it!",
		targetType = "RivalBase",
	},
}

return GameConfig

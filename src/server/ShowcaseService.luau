-- ShowcaseService.luau
-- Studio-only photo-staging service (strictly inactive in live servers).
-- Uses the real creature, base, conveyor, and theft code paths to stage screenshot-ready scenes,
-- including an elevated Photo Point and Spawn Teleport Pad framing the full arena loop.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local CreatureConfig = require(ReplicatedStorage:WaitForChild("CreatureConfig"))
local EconomyConfig = require(ReplicatedStorage:WaitForChild("EconomyConfig"))
local FormatUtil = require(ReplicatedStorage:WaitForChild("FormatUtil"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local BaseService = require(script.Parent:WaitForChild("BaseService"))
local CreatureService = require(script.Parent:WaitForChild("CreatureService"))
local NotificationService = require(script.Parent:WaitForChild("NotificationService"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local TheftService = require(script.Parent:WaitForChild("TheftService"))

local ShowcaseService = {}

local initialized = false
local PHOTO_POINT_STAND_POS = Vector3.new(0, 24.0, -58)
local PHOTO_POINT_LOOK_TARGET = Vector3.new(0, 12.0, 36)
local lastTeleportByUserId: { [number]: number } = {}

local function makeShowcasePart(
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
	p.CanCollide = if canCollide == nil then false else canCollide
	p.Parent = parent
	return p
end

-- Lowers side walls and makes upper frames/roof trusses nearly transparent on Showcase bases
-- so all 10 interior pedestals and creatures read cleanly from the elevated Photo Point.
local function openUpShowcaseBaseForAerialView(base: any)
	if not base or not base.model then
		return
	end
	local dim = GameConfig.BaseDimensions
	local def = base.def

	for _, part in ipairs(base.model:GetChildren()) do
		if part:IsA("BasePart") then
			if part.Name == "RoofTruss" then
				part.Transparency = 0.88
				part.CanCollide = false
			elseif part.Name == "CeilingLight" then
				part.Transparency = 0.92
			elseif part.Name == "FrontFascia" or part.Name == "GateHeaderWall" then
				part.Material = Enum.Material.Glass
				part.Transparency = 0.88
			elseif part.Name == "FrontWindow" then
				part.Transparency = 0.88
			elseif part.Name == "NorthWall" or part.Name == "SouthWall" then
				local zSign = if part.Name == "NorthWall" then -1 else 1
				local lowHeight = 5.2
				part.Size = Vector3.new(dim.DepthX, lowHeight, 1.8)
				part.CFrame = CFrame.new(
					GameConfig.getBaseWorldPosition(def, dim.DepthX * 0.5, zSign * dim.WidthZ * 0.5, lowHeight * 0.5)
				)
			elseif part.Name == "BackWall" then
				local backHeight = 14.0
				part.Size = Vector3.new(1.8, backHeight, dim.WidthZ + 1.8)
				part.CFrame = CFrame.new(GameConfig.getBaseWorldPosition(def, dim.DepthX, 0, backHeight * 0.5))
			elseif part.Name == "GatePillar" then
				local zOffset = part.Position.Z - def.centerZ
				local pHeight = 15.5
				part.Size = Vector3.new(2.4, pHeight, 2.2)
				part.CFrame = CFrame.new(GameConfig.getBaseWorldPosition(def, 0, zOffset, pHeight * 0.5))
			elseif part.Name == "FrontAccentNeon" then
				part.Transparency = 0.45
				part.CFrame = CFrame.new(GameConfig.getBaseWorldPosition(def, -0.8, 0, 15.6))
			elseif part.Name == "MainOwnerSign" then
				-- Position owner sign cleanly over the back wall angled toward the Photo Point so pedestals never get occluded
				local signPos = GameConfig.getBaseWorldPosition(def, dim.DepthX - 2, 0, 18.5)
				local toPhoto = Vector3.new(PHOTO_POINT_STAND_POS.X - signPos.X, 0, PHOTO_POINT_STAND_POS.Z - signPos.Z)
				if toPhoto.Magnitude > 0.1 then
					part.CFrame = CFrame.lookAt(signPos, signPos + toPhoto.Unit)
				end
			end
		end
	end
end

local function stageDummyMidSteal(showcaseFolder: Folder)
	-- Positioned right outside Showcase Base #7 gate (East Z = +30, reading "UNLOCKED 0:04"), dashing toward the avenue
	local originPos = Vector3.new(33.5, 0, 20.5)
	local dashDir = Vector3.new(-0.76, 0, -0.65).Unit
	local avatarCF = CFrame.lookAt(originPos, originPos + dashDir)

	local thiefDummy = Instance.new("Model")
	thiefDummy.Name = "ShowcaseThiefAvatar"

	local root = makeShowcasePart(thiefDummy, "HumanoidRootPart", Vector3.new(2, 0.2, 2), avatarCF * CFrame.new(0, 0.1, 0), Color3.fromRGB(30, 30, 30), Enum.Material.SmoothPlastic, false, 1)
	thiefDummy.PrimaryPart = root

	local skin = Color3.fromRGB(255, 212, 172)
	local hoodie = Color3.fromRGB(58, 44, 96)
	local jeans = Color3.fromRGB(48, 108, 195)
	local trimRed = Color3.fromRGB(255, 58, 78)

	-- Dynamic mid-sprint legs
	makeShowcasePart(thiefDummy, "LeftLeg", Vector3.new(0.95, 2.0, 0.95), avatarCF * CFrame.new(-0.52, 1.05, -0.45) * CFrame.Angles(math.rad(34), 0, 0), jeans)
	makeShowcasePart(thiefDummy, "RightLeg", Vector3.new(0.95, 2.0, 0.95), avatarCF * CFrame.new(0.52, 1.05, 0.48) * CFrame.Angles(math.rad(-34), 0, 0), jeans)

	-- Forward-leaning torso & bandit scarf
	makeShowcasePart(thiefDummy, "Torso", Vector3.new(2.0, 2.0, 1.05), avatarCF * CFrame.new(0, 2.95, -0.1) * CFrame.Angles(math.rad(-10), 0, 0), hoodie)
	makeShowcasePart(thiefDummy, "Scarf", Vector3.new(2.15, 0.42, 1.2), avatarCF * CFrame.new(0, 3.85, -0.15), trimRed, Enum.Material.Neon)

	-- Both arms raised overhead holding the stolen Epic creature
	makeShowcasePart(thiefDummy, "LeftArm", Vector3.new(0.88, 2.0, 0.88), avatarCF * CFrame.new(-1.38, 4.35, -0.25) * CFrame.Angles(math.rad(168), 0, math.rad(14)), skin)
	makeShowcasePart(thiefDummy, "RightArm", Vector3.new(0.88, 2.0, 0.88), avatarCF * CFrame.new(1.38, 4.35, -0.25) * CFrame.Angles(math.rad(168), 0, math.rad(-14)), skin)

	-- Expressive head & mischievous smirk
	makeShowcasePart(thiefDummy, "Head", Vector3.new(1.5, 1.5, 1.5), avatarCF * CFrame.new(0, 4.7, -0.2), skin, Enum.Material.SmoothPlastic, false, 0, Enum.PartType.Ball)
	makeShowcasePart(thiefDummy, "EyeL", Vector3.new(0.24, 0.28, 0.16), avatarCF * CFrame.new(-0.3, 4.8, -0.9), Color3.fromRGB(20, 18, 28), Enum.Material.SmoothPlastic, false, 0, Enum.PartType.Ball)
	makeShowcasePart(thiefDummy, "EyeR", Vector3.new(0.24, 0.28, 0.16), avatarCF * CFrame.new(0.3, 4.8, -0.9), Color3.fromRGB(20, 18, 28), Enum.Material.SmoothPlastic, false, 0, Enum.PartType.Ball)
	makeShowcasePart(thiefDummy, "Smirk", Vector3.new(0.55, 0.14, 0.15), avatarCF * CFrame.new(0.08, 4.42, -0.9) * CFrame.Angles(0, 0, math.rad(12)), trimRed)

	local hl = Instance.new("Highlight")
	hl.Name = "ThiefAlertHighlight"
	hl.FillColor = Color3.fromRGB(255, 42, 65)
	hl.FillTransparency = 0.72
	hl.OutlineColor = Color3.fromRGB(255, 85, 95)
	hl.OutlineTransparency = 0.05
	hl.Parent = thiefDummy

	thiefDummy.Parent = showcaseFolder

	-- Real glowing Epic creature carried overhead with the real [STEALING!] banner
	local carryPos = originPos + Vector3.new(0, 5.55, -0.2)
	local carriedRec = CreatureService.spawnCreatureInstance(
		"opera_octopus",
		"None",
		carryPos,
		dashDir,
		"showcase",
		1
	)
	if carriedRec and carriedRec.model then
		TheftService.attachStealingBanner(carriedRec.model, "opera_octopus", "None")
	end
end

local function stageConveyorRarityParade()
	local beltY = GameConfig.Conveyor.BeltTopY
	-- Spaced 28 studs apart along the belt with distinct lateral & vertical tag offsets so every tag stands completely alone
	local paradeEntries = {
		{ id = "rigatoni_rex", mutation = "None", pos = Vector3.new(1.8, beltY, -22), tagBonus = 0.0 },
		{ id = "lasagna_mech", mutation = "None", pos = Vector3.new(4.2, beltY, 6), tagBonus = 2.8 },
		{ id = "imperatore_cosmico", mutation = "Golden", pos = Vector3.new(1.4, beltY, 34), tagBonus = 1.4 },
	}

	-- Angled toward the Photo Point so their 3D faces and accessories read clearly
	local lookDir = Vector3.new(-0.18, 0, -0.98).Unit
	for _, item in ipairs(paradeEntries) do
		local rec = CreatureService.spawnCreatureInstance(
			item.id,
			item.mutation,
			item.pos,
			lookDir,
			"conveyor",
			1
		)
		if rec and rec.model then
			rec.model:SetAttribute("TagHeightBonus", item.tagBonus)
			CreatureConfig.createCreatureBillboard(rec.model, item.id, item.mutation, "conveyor", 1)
		end
	end
end

local function stageShowcaseBases()
	-- Symmetrical pair on BOTH sides of the central conveyor at Z = +30:
	-- East Showcase Base #7: Gate sign reads "UNLOCKED 0:04", pre-filled with high-rarity creatures
	-- including a Golden-mutated Secret on front pedestal #1!
	local baseEast = BaseService.claimShowcaseBase(7, "Rival_Lorenzo", "UNLOCKED 0:04")
	if baseEast then
		openUpShowcaseBaseForAerialView(baseEast)
		BaseService.placeCreatureInSlot(7, 1, "imperatore_cosmico", "Golden")
		BaseService.placeCreatureInSlot(7, 2, "pasta_seraph", "Radioactive")
		BaseService.placeCreatureInSlot(7, 3, "vesuvius_drake", "None")
		BaseService.placeCreatureInSlot(7, 6, "omni_nonna_prime", "Void")
		BaseService.placeCreatureInSlot(7, 7, "cyber_cappuccino_shark", "None")
		BaseService.placeCreatureInSlot(7, 8, "lasagna_mech", "Golden")
		baseEast.uncollectedCash = 18450000
		baseEast.cashAmountLabel.Text = FormatUtil.formatCash(baseEast.uncollectedCash)
	end

	-- West Showcase Base #3: Symmetrical opposite base protected by active Red Laser Security Gate!
	local baseWest = BaseService.claimShowcaseBase(3, "Nonna_Viper", nil)
	if baseWest then
		openUpShowcaseBaseForAerialView(baseWest)
		BaseService.placeCreatureInSlot(3, 1, "omni_nonna_prime", "Golden")
		BaseService.placeCreatureInSlot(3, 2, "colosseum_golem", "Radioactive")
		BaseService.placeCreatureInSlot(3, 3, "truffle_boar", "Void")
		BaseService.placeCreatureInSlot(3, 6, "pasta_seraph", "Golden")
		BaseService.placeCreatureInSlot(3, 7, "vesuvius_drake", "Radioactive")
		baseWest.isLocked = true
		baseWest.lockRemaining = 54
		baseWest.gateBarrier.CanCollide = true
		for _, bar in ipairs(baseWest.laserBars) do
			bar.Transparency = 0.04
		end
		baseWest.gateStatusLabel.Text = "LOCKED 0:54"
		baseWest.gateStatusLabel.TextColor3 = Color3.fromRGB(255, 78, 95)
		baseWest.gateBg.BackgroundColor3 = Color3.fromRGB(48, 12, 24)
		baseWest.gateStroke.Color = GameConfig.Palette.LaserRed
		for _, slot in ipairs(baseWest.slots) do
			slot.stealPrompt.Enabled = false
		end
		baseWest.uncollectedCash = 42800000
		baseWest.cashAmountLabel.Text = FormatUtil.formatCash(baseWest.uncollectedCash)
	end
end

local function teleportPlayerToPhotoPoint(player: Player)
	local now = os.clock()
	if lastTeleportByUserId[player.UserId] and (now - lastTeleportByUserId[player.UserId]) < 1.5 then
		return
	end
	lastTeleportByUserId[player.UserId] = now

	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not char or not root then
		return
	end

	local targetPos = PHOTO_POINT_STAND_POS + Vector3.new(0, 3.2, 0)
	local flatLook = Vector3.new(PHOTO_POINT_LOOK_TARGET.X, targetPos.Y, PHOTO_POINT_LOOK_TARGET.Z)
	char:PivotTo(CFrame.lookAt(targetPos, flatLook))
	NotificationService.send(player, "info", "Moved to Showcase Photo Point! Aim slightly down toward the conveyor & Shrine.", 2.5)
end

local function createPhotoTeleportPad(parent: Instance, name: string, padPos: Vector3)
	local outer = makeShowcasePart(
		parent,
		name .. "_Outer",
		Vector3.new(0.45, 7.2, 7.2),
		CFrame.new(padPos) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(255, 208, 45),
		Enum.Material.Metal,
		true,
		0,
		Enum.PartType.Cylinder
	)
	local pad = makeShowcasePart(
		parent,
		name,
		Vector3.new(0.58, 5.8, 5.8),
		CFrame.new(padPos + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(55, 230, 255),
		Enum.Material.Neon,
		true,
		0,
		Enum.PartType.Cylinder
	)

	pad.Touched:Connect(function(hit: BasePart)
		local char = hit and hit.Parent
		local player = char and Players:GetPlayerFromCharacter(char)
		if player then
			teleportPlayerToPhotoPoint(player)
		end
	end)
	outer.CanCollide = true
end

local function stagePhotoPointAndPads(showcaseFolder: Folder)
	-- Invisible elevated platform centered on the central promenade/conveyor axis
	makeShowcasePart(
		showcaseFolder,
		"ShowcasePhotoPlatform",
		Vector3.new(20, 1.0, 20),
		CFrame.new(PHOTO_POINT_STAND_POS - Vector3.new(0, 0.5, 0)),
		Color3.fromRGB(200, 230, 255),
		Enum.Material.SmoothPlastic,
		true,
		1
	)

	-- Small visible marker disc on the platform surface
	makeShowcasePart(
		showcaseFolder,
		"PhotoPointMarkerDisc",
		Vector3.new(0.24, 3.8, 3.8),
		CFrame.new(PHOTO_POINT_STAND_POS + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(55, 232, 255),
		Enum.Material.Neon,
		false,
		0.15,
		Enum.PartType.Cylinder
	)
	makeShowcasePart(
		showcaseFolder,
		"PhotoPointMarkerInner",
		Vector3.new(0.28, 2.2, 2.2),
		CFrame.new(PHOTO_POINT_STAND_POS + Vector3.new(0, 0.14, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(255, 214, 52),
		Enum.Material.Neon,
		false,
		0.1,
		Enum.PartType.Cylinder
	)

	-- Teleport pad at the Main Spawn Plaza + convenience pad beside Base #2's promenade start
	createPhotoTeleportPad(showcaseFolder, "SpawnPhotoTeleportPad", Vector3.new(0, 0.28, -145))
	createPhotoTeleportPad(showcaseFolder, "PromenadePhotoTeleportPad", Vector3.new(-29, 0.28, -40))
end

function ShowcaseService.init()
	if not RunService:IsStudio() or initialized then
		return
	end
	initialized = true

	local showcaseFolder = Instance.new("Folder")
	showcaseFolder.Name = "StudioShowcaseProps"
	showcaseFolder.Parent = Workspace

	stageShowcaseBases()
	stageConveyorRarityParade()
	stageDummyMidSteal(showcaseFolder)
	stagePhotoPointAndPads(showcaseFolder)
end

-- Grants generous showcase cash & starter showcase roster to the Studio player
function ShowcaseService.prepareStudioPlayer(player: Player)
	if not RunService:IsStudio() then
		return
	end
	local pData = PlayerDataService.getData(player)
	if not pData then
		return
	end

	if pData.cash < EconomyConfig.ShowcaseStudioCash then
		pData.cash = EconomyConfig.ShowcaseStudioCash
	end

	-- Seed local player's base with 4 photogenic creatures (leaving 6 free slots for buying & stealing!)
	local myBase = BaseService.getPlayerBase(player)
	if myBase and #pData.ownedCreatures == 0 then
		local starterSet = {
			{ slot = 1, id = "vesuvius_drake", mut = "Golden" },
			{ slot = 2, id = "lasagna_mech", mut = "Radioactive" },
			{ slot = 6, id = "gondola_gator", mut = "None" },
			{ slot = 7, id = "rigatoni_rex", mut = "None" },
		}
		for _, s in ipairs(starterSet) do
			BaseService.placeCreatureInSlot(myBase.id, s.slot, s.id, s.mut)
			PlayerDataService.recordDiscovery(player, s.id, s.mut)
		end
		PlayerDataService.recordDiscovery(player, "espresso_goblin", "None")
		PlayerDataService.recordDiscovery(player, "vespa_pigeon", "Radioactive")
		PlayerDataService.recordDiscovery(player, "opera_octopus", "None")
		PlayerDataService.recordDiscovery(player, "imperatore_cosmico", "Golden")

		myBase.uncollectedCash = 485000
		myBase.cashAmountLabel.Text = FormatUtil.formatCash(myBase.uncollectedCash)
		pData._uncollectedBaseCash = myBase.uncollectedCash
	end

	PlayerDataService.syncToClient(player)
end

function ShowcaseService.step()
	if not RunService:IsStudio() then
		return
	end
	local baseWest = BaseService.getBaseById(3)
	if baseWest and baseWest.isShowcaseNpc and baseWest.lockRemaining < 12 then
		baseWest.isLocked = true
		baseWest.lockRemaining = 58
	end
end

return ShowcaseService

-- ShowcaseService.luau
-- Studio-only photo-staging service (strictly inactive in live servers).
-- Uses the real creature, base, conveyor, and theft code paths to stage screenshot-ready scenes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local EconomyConfig = require(ReplicatedStorage:WaitForChild("EconomyConfig"))
local FormatUtil = require(ReplicatedStorage:WaitForChild("FormatUtil"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local BaseService = require(script.Parent:WaitForChild("BaseService"))
local CreatureService = require(script.Parent:WaitForChild("CreatureService"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local TheftService = require(script.Parent:WaitForChild("TheftService"))

local ShowcaseService = {}

local initialized = false

local function makeAvatarPart(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?,
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
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = true
	p.CanCollide = false
	p.Parent = parent
	return p
end

local function stageDummyMidSteal(showcaseFolder: Folder)
	-- Positioned right outside Showcase Base #6 gate (which reads "UNLOCKED 0:04"), dashing across the avenue
	local originPos = Vector3.new(35.5, 0, -25.5)
	local dashDir = Vector3.new(-0.92, 0, -0.38).Unit
	local avatarCF = CFrame.lookAt(originPos, originPos + dashDir)

	local thiefDummy = Instance.new("Model")
	thiefDummy.Name = "ShowcaseThiefAvatar"

	local root = makeAvatarPart(thiefDummy, "HumanoidRootPart", Vector3.new(2, 0.2, 2), avatarCF * CFrame.new(0, 0.1, 0), Color3.fromRGB(30, 30, 30))
	root.Transparency = 1
	thiefDummy.PrimaryPart = root

	local skin = Color3.fromRGB(255, 212, 172)
	local hoodie = Color3.fromRGB(42, 34, 64)
	local jeans = Color3.fromRGB(38, 86, 155)
	local trimRed = Color3.fromRGB(255, 58, 78)

	-- Dynamic mid-sprint legs
	makeAvatarPart(thiefDummy, "LeftLeg", Vector3.new(0.95, 2.0, 0.95), avatarCF * CFrame.new(-0.52, 1.05, -0.45) * CFrame.Angles(math.rad(34), 0, 0), jeans)
	makeAvatarPart(thiefDummy, "RightLeg", Vector3.new(0.95, 2.0, 0.95), avatarCF * CFrame.new(0.52, 1.05, 0.48) * CFrame.Angles(math.rad(-34), 0, 0), jeans)

	-- Forward-leaning torso & bandit scarf
	makeAvatarPart(thiefDummy, "Torso", Vector3.new(2.0, 2.0, 1.05), avatarCF * CFrame.new(0, 2.95, -0.1) * CFrame.Angles(math.rad(-10), 0, 0), hoodie)
	makeAvatarPart(thiefDummy, "Scarf", Vector3.new(2.15, 0.42, 1.2), avatarCF * CFrame.new(0, 3.85, -0.15), trimRed, Enum.Material.Neon)

	-- Both arms raised overhead holding the stolen Epic creature
	makeAvatarPart(thiefDummy, "LeftArm", Vector3.new(0.88, 2.0, 0.88), avatarCF * CFrame.new(-1.38, 4.35, -0.25) * CFrame.Angles(math.rad(168), 0, math.rad(14)), skin)
	makeAvatarPart(thiefDummy, "RightArm", Vector3.new(0.88, 2.0, 0.88), avatarCF * CFrame.new(1.38, 4.35, -0.25) * CFrame.Angles(math.rad(168), 0, math.rad(-14)), skin)

	-- Expressive head & mischievous smirk
	makeAvatarPart(thiefDummy, "Head", Vector3.new(1.5, 1.5, 1.5), avatarCF * CFrame.new(0, 4.7, -0.2), skin, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	makeAvatarPart(thiefDummy, "EyeL", Vector3.new(0.24, 0.28, 0.16), avatarCF * CFrame.new(-0.3, 4.8, -0.9), Color3.fromRGB(20, 18, 28), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	makeAvatarPart(thiefDummy, "EyeR", Vector3.new(0.24, 0.28, 0.16), avatarCF * CFrame.new(0.3, 4.8, -0.9), Color3.fromRGB(20, 18, 28), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	makeAvatarPart(thiefDummy, "Smirk", Vector3.new(0.55, 0.14, 0.15), avatarCF * CFrame.new(0.08, 4.42, -0.9) * CFrame.Angles(0, 0, math.rad(12)), trimRed)

	-- Red thief Highlight matching live TheftService
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
	-- Common, Epic, and Golden Secret side-by-side along the east lane of the central conveyor
	local paradeEntries = {
		{ id = "rigatoni_rex", mutation = "None", pos = Vector3.new(3.8, beltY, -29) },
		{ id = "lasagna_mech", mutation = "None", pos = Vector3.new(3.8, beltY, -18) },
		{ id = "imperatore_cosmico", mutation = "Golden", pos = Vector3.new(3.8, beltY, -6) },
	}

	local lookDir = Vector3.new(-0.55, 0, 0.83).Unit
	for _, item in ipairs(paradeEntries) do
		CreatureService.spawnCreatureInstance(
			item.id,
			item.mutation,
			item.pos,
			lookDir,
			"conveyor",
			1
		)
	end
end

local function stageShowcaseBases()
	-- Showcase Base #6: Gate sign reads "UNLOCKED 0:04", pre-filled with high-rarity creatures
	-- including a Golden-mutated Secret on front pedestal #1!
	local baseA = BaseService.claimShowcaseBase(6, "Rival_Lorenzo", "UNLOCKED 0:04")
	if baseA then
		BaseService.placeCreatureInSlot(6, 1, "imperatore_cosmico", "Golden")
		BaseService.placeCreatureInSlot(6, 2, "pasta_seraph", "Radioactive")
		BaseService.placeCreatureInSlot(6, 3, "vesuvius_drake", "None")
		BaseService.placeCreatureInSlot(6, 6, "omni_nonna_prime", "Void")
		BaseService.placeCreatureInSlot(6, 7, "cyber_cappuccino_shark", "None")
		BaseService.placeCreatureInSlot(6, 8, "lasagna_mech", "Golden")
		baseA.uncollectedCash = 18450000
		baseA.cashAmountLabel.Text = FormatUtil.formatCash(baseA.uncollectedCash)
	end

	-- Showcase Base #7: High-tier rival base protected by active Red Laser Security Gate!
	local baseB = BaseService.claimShowcaseBase(7, "Nonna_Viper", nil)
	if baseB then
		BaseService.placeCreatureInSlot(7, 1, "omni_nonna_prime", "Golden")
		BaseService.placeCreatureInSlot(7, 2, "colosseum_golem", "Radioactive")
		BaseService.placeCreatureInSlot(7, 3, "truffle_boar", "Void")
		BaseService.placeCreatureInSlot(7, 6, "pasta_seraph", "Golden")
		BaseService.placeCreatureInSlot(7, 7, "vesuvius_drake", "Radioactive")
		baseB.isLocked = true
		baseB.lockRemaining = 54
		baseB.gateBarrier.CanCollide = true
		for _, bar in ipairs(baseB.laserBars) do
			bar.Transparency = 0.04
		end
		baseB.gateStatusLabel.Text = "LOCKED 0:54"
		baseB.gateStatusLabel.TextColor3 = Color3.fromRGB(255, 78, 95)
		baseB.gateBg.BackgroundColor3 = Color3.fromRGB(48, 12, 24)
		baseB.gateStroke.Color = GameConfig.Palette.LaserRed
		for _, slot in ipairs(baseB.slots) do
			slot.stealPrompt.Enabled = false
		end
		baseB.uncollectedCash = 42800000
		baseB.cashAmountLabel.Text = FormatUtil.formatCash(baseB.uncollectedCash)
	end
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
		-- Also record a couple extra discoveries so the Index UI looks rich right away
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
	local baseB = BaseService.getBaseById(7)
	if baseB and baseB.isShowcaseNpc and baseB.lockRemaining < 12 then
		baseB.isLocked = true
		baseB.lockRemaining = 58
	end
end

return ShowcaseService

-- ConveyorService.luau
-- Spawns collectible creatures along the central conveyor, handles server-validated purchases,
-- prevents race conditions, and routes bought creatures physically along waypoints to base slots.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CreatureConfig = require(ReplicatedStorage:WaitForChild("CreatureConfig"))
local FormatUtil = require(ReplicatedStorage:WaitForChild("FormatUtil"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local MutationConfig = require(ReplicatedStorage:WaitForChild("MutationConfig"))

local BaseService = require(script.Parent:WaitForChild("BaseService"))
local CreatureService = require(script.Parent:WaitForChild("CreatureService"))
local NotificationService = require(script.Parent:WaitForChild("NotificationService"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

local ConveyorService = {}

local conveyorUids: { [string]: boolean } = {}
local travelingByUserId: { [number]: { [string]: boolean } } = {}
local spawnAccumulator = 0
local totalSpawnCounter = 0

local function countActiveConveyorCreatures(): number
	local n = 0
	for uid in pairs(conveyorUids) do
		if CreatureService.getRecord(uid) then
			n += 1
		else
			conveyorUids[uid] = nil
		end
	end
	return n
end

local function handlePurchaseAttempt(player: Player, uid: string)
	local rec = CreatureService.getRecord(uid)
	if not rec or rec.mode ~= "conveyor" or rec.reserved then
		return
	end

	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end

	local dist = (root.Position - rec.position).Magnitude
	if dist > GameConfig.Conveyor.PurchaseMaxDistance + 6 then
		NotificationService.send(player, "warning", "Move closer to buy this creature!", 1.2)
		return
	end

	local base = BaseService.getPlayerBase(player)
	if not base then
		NotificationService.send(player, "error", "You do not have an assigned base yet!", 1.5)
		return
	end

	local pData = PlayerDataService.getData(player)
	if not pData then
		return
	end
	if pData._isStealing then
		NotificationService.send(player, "warning", "Finish delivering your stolen creature first!", 1.5)
		return
	end

	local price = rec.def.PurchasePrice
	if pData.cash < price then
		NotificationService.send(
			player,
			"error",
			"Insufficient funds! Need " .. FormatUtil.formatCash(price) .. "!",
			1.2
		)
		return
	end

	local targetSlot = BaseService.reserveFreeSlot(base.id)
	if not targetSlot then
		NotificationService.send(player, "warning", "Your base is full (10/10 slots)! Sell a creature with [R] first!", 2.0)
		return
	end

	-- Atomic spend & lock
	if not PlayerDataService.spendCash(player, price) then
		BaseService.cancelSlotReservation(base.id, targetSlot)
		NotificationService.send(player, "error", "Insufficient funds!", 1.2)
		return
	end

	rec.reserved = true
	rec.mode = "traveling"
	rec.buyerUserId = player.UserId
	rec.reservedBaseId = base.id
	rec.reservedSlot = targetSlot
	conveyorUids[uid] = nil

	if not travelingByUserId[player.UserId] then
		travelingByUserId[player.UserId] = {}
	end
	travelingByUserId[player.UserId][uid] = true

	-- Remove Buy prompt immediately so no second player can purchase
	if rec.model and rec.model.PrimaryPart then
		local prompt = rec.model.PrimaryPart:FindFirstChild("ConveyorBuyPrompt")
		if prompt then
			prompt:Destroy()
		end
	end

	CreatureConfig.createCreatureBillboard(
		rec.model,
		rec.creatureId,
		rec.mutation,
		"traveling",
		pData.incomeMultiplier,
		"BOUGHT BY " .. string.upper(player.Name) .. "!"
	)

	pData.stats.totalPurchases += 1
	if pData.tutorialStep == 2 then
		PlayerDataService.advanceTutorial(player, "buy_first")
	elseif pData.tutorialStep == 5 then
		PlayerDataService.advanceTutorial(player, "buy_second")
	else
		PlayerDataService.syncToClient(player)
	end

	local mutPrefix = if rec.mutation ~= "None" then (rec.mutation .. " ") else ""
	NotificationService.send(
		player,
		"info",
		"Bought " .. mutPrefix .. rec.def.DisplayName .. "! Wait for your creature to reach your base!"
	)

	-- Build physical waypoint path from conveyor -> promenade -> base entrance -> slot pedestal
	local slotPos, _ = GameConfig.getSlotTransform(base.def, targetSlot)
	local promenadeX = if base.def.frontX < 0 then -26 else 26
	local gateEntryPos = GameConfig.getBaseWorldPosition(base.def, 6, 0, 0.3)
	local aisleAlignedPos = Vector3.new(slotPos.X, 0.3, base.def.centerZ)

	local waypoints = {
		Vector3.new(promenadeX, 0.16, rec.position.Z),
		Vector3.new(promenadeX, 0.16, base.def.centerZ),
		gateEntryPos,
		aisleAlignedPos,
		slotPos,
	}

	local travelSpeed = math.max(16, (rec.def.WalkSpeed or 10) * 1.55)
	CreatureService.setWaypoints(uid, waypoints, travelSpeed, function()
		if travelingByUserId[player.UserId] then
			travelingByUserId[player.UserId][uid] = nil
		end

		local liveBuyer = Players:GetPlayerByUserId(player.UserId)
		local currentBase = liveBuyer and BaseService.getPlayerBase(liveBuyer)
		if not liveBuyer or not currentBase or currentBase.id ~= base.id then
			BaseService.cancelSlotReservation(base.id, targetSlot)
			CreatureService.destroyCreature(uid)
			return
		end

		local placed = BaseService.placeCreatureInSlot(base.id, targetSlot, rec.creatureId, rec.mutation, uid)
		if placed then
			PlayerDataService.recordDiscovery(liveBuyer, rec.creatureId, rec.mutation)
			PlayerDataService.advanceTutorial(liveBuyer, "wait_arrive")
			PlayerDataService.syncToClient(liveBuyer)
			NotificationService.send(
				liveBuyer,
				"success",
				mutPrefix .. rec.def.DisplayName .. " arrived at Slot #" .. tostring(targetSlot) .. "!"
			)
		else
			BaseService.cancelSlotReservation(base.id, targetSlot)
			CreatureService.destroyCreature(uid)
		end
	end)
end

function ConveyorService.spawnConveyorCreature(forcedCreatureId: string?, forcedMutation: string?, zOverride: number?)
	totalSpawnCounter += 1

	local minRarityOrder = 1
	if not forcedCreatureId then
		if totalSpawnCounter % 32 == 0 then
			minRarityOrder = 4 -- Periodic Epic+ excitement drop
		elseif totalSpawnCounter % 11 == 0 then
			minRarityOrder = 3 -- Periodic Rare+ drop
		end
	end

	local creatureId = forcedCreatureId or CreatureConfig.rollWeightedCreatureId(minRarityOrder)
	local serverLuck = PlayerDataService.getMaxServerMutationLuck()
	local mutation = forcedMutation or MutationConfig.rollMutation(serverLuck)

	local cfg = GameConfig.Conveyor
	local laneX: number
	if RunService:IsStudio() then
		-- Keep west conveyor edge clear of Showcase Rarity Parade on the east/center lane
		laneX = -5.4
	else
		local laneIndex = (totalSpawnCounter % 3) - 1
		laneX = laneIndex * 2.6
	end

	local startPos = Vector3.new(laneX, cfg.BeltTopY, zOverride or cfg.StartZ)
	local endPos = Vector3.new(laneX, cfg.BeltTopY, cfg.EndZ)

	local rec = CreatureService.spawnCreatureInstance(
		creatureId,
		mutation,
		startPos,
		Vector3.new(0, 0, 1),
		"conveyor",
		1
	)
	if not rec or not rec.model or not rec.model.PrimaryPart then
		return nil
	end

	local uid = rec.uid
	conveyorUids[uid] = true

	local mutInfo = MutationConfig.getMutationInfo(mutation)
	local objPrefix = if mutInfo.id ~= "None" then (mutInfo.displayName .. " ") else ""

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ConveyorBuyPrompt"
	prompt.ActionText = "Buy " .. FormatUtil.formatCash(rec.def.PurchasePrice)
	prompt.ObjectText = objPrefix .. rec.def.DisplayName .. " (" .. rec.def.Rarity .. ")"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.18
	prompt.MaxActivationDistance = 15
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("PromptRole", "ConveyorBuy")
	prompt.Parent = rec.model.PrimaryPart

	prompt.Triggered:Connect(function(player: Player)
		handlePurchaseAttempt(player, uid)
	end)

	CreatureService.setWaypoints(uid, { endPos }, rec.def.WalkSpeed or cfg.DefaultWalkSpeed, function()
		conveyorUids[uid] = nil
		if not rec.reserved and rec.mode == "conveyor" then
			CreatureService.destroyCreature(uid)
		end
	end)

	return rec
end

function ConveyorService.cleanupPlayerTravelers(userId: number)
	local set = travelingByUserId[userId]
	if not set then
		return
	end
	for uid in pairs(set) do
		local rec = CreatureService.getRecord(uid)
		if rec then
			if rec.reservedBaseId and rec.reservedSlot then
				BaseService.cancelSlotReservation(rec.reservedBaseId, rec.reservedSlot)
			end
			CreatureService.destroyCreature(uid)
		end
	end
	travelingByUserId[userId] = nil
end

function ConveyorService.cancelAllPlayerTravelersForRebirth(userId: number)
	ConveyorService.cleanupPlayerTravelers(userId)
end

function ConveyorService.init()
	-- Pre-seed 5 creatures spaced along the conveyor belt at server boot so the belt is immediately lively!
	local initialSeeds = {
		{ id = "rigatoni_rex", mut = "None", z = -98 },
		{ id = "espresso_goblin", mut = "None", z = -66 },
		{ id = "vespa_pigeon", mut = "Radioactive", z = -34 },
		{ id = "garlic_goober", mut = "None", z = 18 },
		{ id = "accordion_crab", mut = "None", z = 54 },
	}
	for _, seed in ipairs(initialSeeds) do
		ConveyorService.spawnConveyorCreature(seed.id, seed.mut, seed.z)
	end
end

function ConveyorService.step(dt: number)
	spawnAccumulator += dt
	if spawnAccumulator >= GameConfig.Conveyor.SpawnInterval then
		spawnAccumulator = 0
		if countActiveConveyorCreatures() < GameConfig.Conveyor.MaxActiveCreatures then
			ConveyorService.spawnConveyorCreature()
		end
	end
end

return ConveyorService

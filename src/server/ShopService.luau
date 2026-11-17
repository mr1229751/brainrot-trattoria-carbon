-- ShopService.luau
-- Server-authoritative equipment purchasing, persistent Backpack provisioning,
-- and real tool mechanics (Slap knockback, Speed/Gravity coils, Laser Shock Traps, Guardian Repulsor).

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local EconomyConfig = require(ReplicatedStorage:WaitForChild("EconomyConfig"))
local FormatUtil = require(ReplicatedStorage:WaitForChild("FormatUtil"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))

local NotificationService = require(script.Parent:WaitForChild("NotificationService"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local TheftService = require(script.Parent:WaitForChild("TheftService"))

local ShopService = {}

local trapsFolder: Folder? = nil
local activeTraps: { any } = {}
local lastToolUse: { [string]: number } = {}
local stunnedUntilByUserId: { [number]: number } = {}

local function getEquippedShopItem(character: Model?)
	if not character then
		return nil
	end
	local tool = character:FindFirstChildOfClass("Tool")
	if not tool then
		return nil
	end
	local itemId = tool:GetAttribute("ShopItemId")
	if type(itemId) == "string" then
		return ShopConfig.getItem(itemId)
	end
	return nil
end

function ShopService.refreshPlayerMovementStats(player: Player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not char or not hum then
		return
	end

	if TheftService.isPlayerStealing(player) then
		hum.WalkSpeed = EconomyConfig.StealCarryWalkSpeed
		hum.JumpPower = 50
		return
	end

	local stunUntil = stunnedUntilByUserId[player.UserId]
	if stunUntil and os.clock() < stunUntil then
		hum.WalkSpeed = 7.5
		hum.JumpPower = 35
		return
	end

	local pData = PlayerDataService.getData(player)
	local rebirths = if pData then pData.rebirths else 0
	local equipped = getEquippedShopItem(char)
	local coilSpeed = if equipped then (equipped.speedMultiplier or 1) else 1
	local jumpPow = if equipped then (equipped.jumpPower or 52) else 52

	hum.UseJumpPower = true
	hum.WalkSpeed = EconomyConfig.getPlayerWalkSpeed(rebirths, coilSpeed)
	hum.JumpPower = jumpPow
end

local function ensureToolInInventory(player: Player, itemId: string, autoEquip: boolean?)
	local backpack = player:FindFirstChildOfClass("Backpack")
	local char = player.Character
	if not backpack then
		return
	end

	for _, existing in ipairs(backpack:GetChildren()) do
		if existing:IsA("Tool") and existing:GetAttribute("ShopItemId") == itemId then
			if autoEquip and char and not TheftService.isPlayerStealing(player) then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then
					hum:EquipTool(existing)
				end
			end
			return
		end
	end
	if char then
		for _, existing in ipairs(char:GetChildren()) do
			if existing:IsA("Tool") and existing:GetAttribute("ShopItemId") == itemId then
				return
			end
		end
	end

	local tool = ShopConfig.buildTool(itemId)
	if not tool then
		return
	end
	tool.Parent = backpack

	if autoEquip and char and not TheftService.isPlayerStealing(player) then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum:EquipTool(tool)
		end
	end
end

function ShopService.provisionOwnedTools(player: Player)
	local pData = PlayerDataService.getData(player)
	if not pData then
		return
	end
	for itemId, owned in pairs(pData.ownedItems) do
		if owned == true then
			ensureToolInInventory(player, itemId, false)
		end
	end
	ShopService.refreshPlayerMovementStats(player)
end

function ShopService.onCharacterAdded(player: Player, character: Model)
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			ShopService.refreshPlayerMovementStats(player)
		end
	end)
	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			ShopService.refreshPlayerMovementStats(player)
		end
	end)
	task.defer(function()
		if player.Parent then
			ShopService.provisionOwnedTools(player)
		end
	end)
end

function ShopService.tryPurchaseItem(player: Player, itemId: string)
	if type(itemId) ~= "string" then
		return
	end
	local item = ShopConfig.getItem(itemId)
	if not item then
		return
	end

	PlayerDataService.advanceTutorial(player, "visit_shop")

	if PlayerDataService.hasShopItem(player, itemId) then
		ensureToolInInventory(player, itemId, true)
		NotificationService.send(player, "info", "Equipped " .. item.name .. "!")
		return
	end

	if not PlayerDataService.spendCash(player, item.price) then
		NotificationService.send(
			player,
			"error",
			"Insufficient funds! Need " .. FormatUtil.formatCash(item.price) .. " for " .. item.name .. "!",
			1.2
		)
		return
	end

	PlayerDataService.grantShopItem(player, itemId)
	ensureToolInInventory(player, itemId, true)
	ShopService.refreshPlayerMovementStats(player)
	NotificationService.send(player, "success", "Purchased & equipped " .. item.name .. "!")
end

local function spawnBurstRing(centerPos: Vector3, color: Color3, endDiameter: number)
	local ring = Instance.new("Part")
	ring.Name = "ShockwaveRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.35, 2, 2)
	ring.CFrame = CFrame.new(centerPos) * CFrame.Angles(0, 0, math.rad(90))
	ring.Color = color
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.15
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Parent = Workspace

	local tween = TweenService:Create(
		ring,
		TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = Vector3.new(0.15, endDiameter, endDiameter),
			Transparency = 1,
		}
	)
	tween:Play()
	Debris:AddItem(ring, 0.42)
end

local function deployShockTrap(owner: Player, footPos: Vector3)
	if not trapsFolder then
		return
	end

	-- Cap at 2 active traps per player
	local ownedIndices = {}
	for idx, trap in ipairs(activeTraps) do
		if trap.ownerUserId == owner.UserId then
			table.insert(ownedIndices, idx)
		end
	end
	if #ownedIndices >= 2 then
		local oldestIdx = ownedIndices[1]
		local oldest = table.remove(activeTraps, oldestIdx)
		if oldest and oldest.model and oldest.model.Parent then
			oldest.model:Destroy()
		end
	end

	local model = Instance.new("Model")
	model.Name = "ArmedShockTrap_" .. owner.Name

	local disc = Instance.new("Part")
	disc.Name = "TrapBase"
	disc.Shape = Enum.PartType.Cylinder
	disc.Size = Vector3.new(0.45, 5.2, 5.2)
	disc.CFrame = CFrame.new(footPos.X, 0.24, footPos.Z) * CFrame.Angles(0, 0, math.rad(90))
	disc.Color = Color3.fromRGB(48, 32, 76)
	disc.Material = Enum.Material.Metal
	disc.Anchored = true
	disc.CanCollide = false
	disc.Parent = model

	local core = Instance.new("Part")
	core.Name = "PlasmaCore"
	core.Shape = Enum.PartType.Cylinder
	core.Size = Vector3.new(0.55, 3.2, 3.2)
	core.CFrame = CFrame.new(footPos.X, 0.28, footPos.Z) * CFrame.Angles(0, 0, math.rad(90))
	core.Color = Color3.fromRGB(255, 215, 45)
	core.Material = Enum.Material.Neon
	core.Anchored = true
	core.CanCollide = false
	core.Parent = model

	model.PrimaryPart = disc
	model.Parent = trapsFolder

	table.insert(activeTraps, {
		ownerUserId = owner.UserId,
		ownerName = owner.Name,
		position = Vector3.new(footPos.X, 0.3, footPos.Z),
		expiresAt = os.clock() + 90,
		model = model,
	})

	NotificationService.send(owner, "info", "Armed Laser Shock Trap placed!", 1.2)
end

local function handleUseTool(player: Player)
	if TheftService.isPlayerStealing(player) then
		return
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not char or not root then
		return
	end

	local item = getEquippedShopItem(char)
	if not item or not PlayerDataService.hasShopItem(player, item.id) then
		return
	end

	local key = tostring(player.UserId) .. ":" .. item.id
	local now = os.clock()
	if lastToolUse[key] and (now - lastToolUse[key]) < (item.cooldown or 1.0) then
		return
	end
	lastToolUse[key] = now

	if item.id == "slap_hand" then
		local hitCenter = root.Position + root.CFrame.LookVector * 3.8
		spawnBurstRing(hitCenter - Vector3.new(0, 1.5, 0), item.accentColor, 11)
		local hitCount = 0

		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= player and other.Character then
				local oRoot = other.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if oRoot and (oRoot.Position - hitCenter).Magnitude <= 8.5 then
					hitCount += 1
					local push = (oRoot.Position - root.Position)
					local horiz = Vector3.new(push.X, 0, push.Z)
					local dir = if horiz.Magnitude > 0.05 then horiz.Unit else root.CFrame.LookVector
					oRoot.AssemblyLinearVelocity = dir * 56 + Vector3.new(0, 28, 0)
					TheftService.foilSteal(other.UserId, player.Name .. " slapped you with Turbo Slap Glove!")
					NotificationService.send(other, "warning", player.Name .. " slapped you!", 1.5)
				end
			end
		end
		if hitCount > 0 then
			NotificationService.send(player, "success", "SMACK! Knocked back " .. tostring(hitCount) .. " rival(s)!", 1.2)
		end

	elseif item.id == "repulsor_baton" then
		spawnBurstRing(root.Position - Vector3.new(0, 2.2, 0), item.accentColor, 26)
		local blasted = 0
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= player and other.Character then
				local oRoot = other.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if oRoot and (oRoot.Position - root.Position).Magnitude <= 14.5 then
					blasted += 1
					local push = oRoot.Position - root.Position
					local horiz = Vector3.new(push.X, 0, push.Z)
					local dir = if horiz.Magnitude > 0.05 then horiz.Unit else Vector3.new(0, 0, 1)
					oRoot.AssemblyLinearVelocity = dir * 64 + Vector3.new(0, 32, 0)
					TheftService.foilSteal(other.UserId, player.Name .. "'s Guardian Repulsor blasted you!")
				end
			end
		end
		NotificationService.send(player, "info", "Guardian Repulsor shockwave unleashed! (" .. tostring(blasted) .. " hit)", 1.5)

	elseif item.id == "shock_trap" then
		deployShockTrap(player, root.Position)
	end
end

function ShopService.init(remotesFolder: Folder, worldHooks: any)
	local existing = Workspace:FindFirstChild("ActiveTraps")
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "ActiveTraps"
	folder.Parent = Workspace
	trapsFolder = folder

	TheftService.setSpeedRefreshCallback(function(player: Player)
		ShopService.refreshPlayerMovementStats(player)
	end)

	local buyRemote = remotesFolder:FindFirstChild(GameConfig.Remotes.BuyShopItem) :: RemoteEvent?
	if buyRemote then
		buyRemote.OnServerEvent:Connect(function(player: Player, itemId: any)
			if type(itemId) == "string" then
				ShopService.tryPurchaseItem(player, itemId)
			end
		end)
	end

	local useRemote = remotesFolder:FindFirstChild(GameConfig.Remotes.UseTool) :: RemoteEvent?
	if useRemote then
		useRemote.OnServerEvent:Connect(function(player: Player)
			handleUseTool(player)
		end)
	end

	if worldHooks and worldHooks.shopDisplayPrompts then
		for _, entry in ipairs(worldHooks.shopDisplayPrompts) do
			entry.prompt.Triggered:Connect(function(player: Player)
				ShopService.tryPurchaseItem(player, entry.itemId)
			end)
		end
	end
end

function ShopService.cleanupPlayer(userId: number)
	stunnedUntilByUserId[userId] = nil
	for i = #activeTraps, 1, -1 do
		local trap = activeTraps[i]
		if trap.ownerUserId == userId then
			if trap.model and trap.model.Parent then
				trap.model:Destroy()
			end
			table.remove(activeTraps, i)
		end
	end
end

function ShopService.step(_dt: number, now: number)
	-- Check trap expirations and rival proximity triggers
	for i = #activeTraps, 1, -1 do
		local trap = activeTraps[i]
		if now >= trap.expiresAt or not trap.model or not trap.model.Parent then
			if trap.model and trap.model.Parent then
				trap.model:Destroy()
			end
			table.remove(activeTraps, i)
			continue
		end

		local triggeredBy: Player? = nil
		for _, player in ipairs(Players:GetPlayers()) do
			if player.UserId ~= trap.ownerUserId and player.Character then
				local pRoot = player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if pRoot and (pRoot.Position - trap.position).Magnitude <= 5.0 then
					triggeredBy = player
					break
				end
			end
		end

		if triggeredBy and triggeredBy.Character then
			local pRoot = triggeredBy.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if pRoot then
				pRoot.AssemblyLinearVelocity = Vector3.new(0, 36, 0)
			end
			spawnBurstRing(trap.position, Color3.fromRGB(255, 220, 55), 14)
			stunnedUntilByUserId[triggeredBy.UserId] = now + 3.2
			TheftService.foilSteal(triggeredBy.UserId, "Stepped on " .. trap.ownerName .. "'s Laser Shock Trap!")
			ShopService.refreshPlayerMovementStats(triggeredBy)

			NotificationService.send(triggeredBy, "error", "ZAPPED! You stepped on " .. trap.ownerName .. "'s Laser Shock Trap!")
			local ownerPlayer = Players:GetPlayerByUserId(trap.ownerUserId)
			if ownerPlayer then
				NotificationService.send(ownerPlayer, "success", triggeredBy.Name .. " triggered your Laser Shock Trap!")
			end

			local victimRef = triggeredBy
			task.delay(3.3, function()
				if victimRef and victimRef.Parent then
					ShopService.refreshPlayerMovementStats(victimRef)
				end
			end)

			trap.model:Destroy()
			table.remove(activeTraps, i)
		end
	end
end

return ShopService

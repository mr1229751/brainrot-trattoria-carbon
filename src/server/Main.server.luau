-- Main.server.luau
-- Server bootstrapper: creates RemoteEvents, builds the 3D arena, initializes all gameplay services,
-- manages player lifecycle & autosaves, and runs one centralized server Heartbeat loop.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local NotificationService = require(script.Parent:WaitForChild("NotificationService"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local CreatureService = require(script.Parent:WaitForChild("CreatureService"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local ConveyorService = require(script.Parent:WaitForChild("ConveyorService"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))
local TheftService = require(script.Parent:WaitForChild("TheftService"))
local ShopService = require(script.Parent:WaitForChild("ShopService"))
local RebirthService = require(script.Parent:WaitForChild("RebirthService"))
local ShowcaseService = require(script.Parent:WaitForChild("ShowcaseService"))

-- 1. Create RemoteEvents folder in ReplicatedStorage before clients connect
local function setupRemotes(): Folder
	local existing = ReplicatedStorage:FindFirstChild(GameConfig.Remotes.FolderName)
	if existing then
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = GameConfig.Remotes.FolderName
	folder.Parent = ReplicatedStorage

	local eventNames = {
		GameConfig.Remotes.StateSync,
		GameConfig.Remotes.Notify,
		GameConfig.Remotes.FloatingPopup,
		GameConfig.Remotes.BuyShopItem,
		GameConfig.Remotes.UseTool,
		GameConfig.Remotes.RequestRebirth,
		GameConfig.Remotes.ToggleLock,
		GameConfig.Remotes.TutorialAction,
		GameConfig.Remotes.TeleportToBase,
		GameConfig.Remotes.RequestInitialState,
	}

	for _, rName in ipairs(eventNames) do
		local ev = Instance.new("RemoteEvent")
		ev.Name = rName
		ev.Parent = folder
	end

	return folder
end

local remotesFolder = setupRemotes()

-- 2. Initialize world & gameplay services in strict dependency order
NotificationService.init(remotesFolder)
PlayerDataService.init(remotesFolder)
CreatureService.init()

local worldHooks = WorldBuilder.buildWorld()

BaseService.init(remotesFolder)
TheftService.init()
ShopService.init(remotesFolder, worldHooks)
RebirthService.init(remotesFolder, worldHooks)
ShowcaseService.init()
ConveyorService.init()
EconomyService.init()

-- 3. Player join / spawn / leave lifecycle
local function positionCharacterAtAssignedBase(player: Player, character: Model)
	local base = BaseService.getPlayerBase(player)
	if not base then
		return
	end
	local root = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	if not root or not player.Parent then
		return
	end

	BaseService.applyCharacterCollisionGroup(player, character)

	-- Place player on the promenade outside their base facing across the central conveyor
	local spawnPos = GameConfig.getBaseWorldPosition(base.def, -9, -6, 3.2)
	local lookTarget = Vector3.new(0, 3.2, base.def.centerZ + 6)
	character:PivotTo(CFrame.lookAt(spawnPos, lookTarget))
end

local function onPlayerAdded(player: Player)
	PlayerDataService.loadPlayer(player)
	local assignedBase = BaseService.assignBaseToPlayer(player)
	ShowcaseService.prepareStudioPlayer(player)

	player.CharacterAdded:Connect(function(character: Model)
		ShopService.onCharacterAdded(player, character)
		task.defer(function()
			positionCharacterAtAssignedBase(player, character)
		end)
	end)

	if player.Character then
		ShopService.onCharacterAdded(player, player.Character)
		task.defer(function()
			positionCharacterAtAssignedBase(player, player.Character)
		end)
	end

	PlayerDataService.syncToClient(player)
	if assignedBase then
		task.delay(1.0, function()
			if player.Parent then
				NotificationService.send(
					player,
					"info",
					"Welcome to Brainrot Trattoria! You own " .. assignedBase.def.name .. "!"
				)
			end
		end)
	end
end

local function onPlayerRemoving(player: Player)
	local uid = player.UserId
	TheftService.cleanupPlayer(player)
	ConveyorService.cleanupPlayerTravelers(uid)
	ShopService.cleanupPlayer(uid)
	PlayerDataService.removePlayer(player)
	BaseService.releasePlayerBase(player)
	NotificationService.cleanupPlayer(uid)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, existingPlayer in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, existingPlayer)
end

game:BindToClose(function()
	PlayerDataService.saveAll()
end)

-- 4. Periodic 60-second autosave loop
task.spawn(function()
	while true do
		task.wait(60)
		PlayerDataService.saveAll()
	end
end)

-- 5. Single centralized Heartbeat loop driving all active systems cleanly
RunService.Heartbeat:Connect(function(dt: number)
	local clampedDt = math.min(dt, 0.1)
	local now = os.clock()

	ConveyorService.step(clampedDt)
	CreatureService.step(clampedDt, now)
	BaseService.step(clampedDt, now)
	EconomyService.step(clampedDt)
	TheftService.step(clampedDt, now)
	ShopService.step(clampedDt, now)
	ShowcaseService.step()
end)

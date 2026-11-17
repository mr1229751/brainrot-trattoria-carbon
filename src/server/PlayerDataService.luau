-- PlayerDataService.luau
-- Server-authoritative player profile management with DataStore retries and Studio-safe memory fallback.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CreatureConfig = require(ReplicatedStorage:WaitForChild("CreatureConfig"))
local EconomyConfig = require(ReplicatedStorage:WaitForChild("EconomyConfig"))
local FormatUtil = require(ReplicatedStorage:WaitForChild("FormatUtil"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local PlayerDataService = {}

local DATASTORE_NAME = "BrainrotTrattoria_Save_v1"
local MAX_RETRIES = 3

local dataStore = nil
local useMemoryFallback = false
local memoryStore: { [string]: any } = {}
local profiles: { [number]: any } = {}
local stateSyncRemote: RemoteEvent? = nil

local function initDataStore()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(DATASTORE_NAME)
	end)
	if ok and result then
		dataStore = result
	else
		useMemoryFallback = true
	end
end

local function createDefaultData()
	return {
		cash = EconomyConfig.StarterCash,
		rebirths = 0,
		incomeMultiplier = 1.0,
		ownedCreatures = {}, -- { [1..10 slot str or array]: { id, mutation, slot } }
		index = {}, -- { [creatureId] = { discovered = true, mutations = { None = true }, obtainedCount = 1 } }
		ownedItems = {}, -- { [itemId] = true }
		tutorialStep = 1,
		stats = {
			totalCashEarned = 0,
			totalPurchases = 0,
			totalSteals = 0,
			totalRebirths = 0,
		},
		-- Runtime transient fields (not persisted directly)
		_assignedBaseId = nil,
		_incomePerSecond = 0,
		_baseLocked = false,
		_lockRemaining = 0,
		_lockCooldown = 0,
		_uncollectedBaseCash = 0,
		_isStealing = false,
	}
end

local function sanitizeLoadedData(raw: any)
	local clean = createDefaultData()
	if type(raw) ~= "table" then
		return clean
	end

	if type(raw.cash) == "number" and raw.cash >= 0 then
		clean.cash = math.floor(raw.cash)
	end
	if type(raw.rebirths) == "number" and raw.rebirths >= 0 then
		clean.rebirths = math.floor(raw.rebirths)
	end
	clean.incomeMultiplier = EconomyConfig.getIncomeMultiplier(clean.rebirths)

	if type(raw.ownedCreatures) == "table" then
		for _, entry in ipairs(raw.ownedCreatures) do
			if type(entry) == "table" and type(entry.id) == "string" and CreatureConfig.getCreature(entry.id) then
				local slotNum = tonumber(entry.slot)
				if slotNum and slotNum >= 1 and slotNum <= GameConfig.BaseDimensions.SlotCount then
					table.insert(clean.ownedCreatures, {
						id = entry.id,
						mutation = type(entry.mutation) == "string" and entry.mutation or "None",
						slot = math.floor(slotNum),
					})
				end
			end
		end
	end

	if type(raw.index) == "table" then
		for cid, info in pairs(raw.index) do
			if type(cid) == "string" and CreatureConfig.getCreature(cid) and type(info) == "table" then
				local muts = {}
				if type(info.mutations) == "table" then
					for mName, mVal in pairs(info.mutations) do
						if mVal == true and type(mName) == "string" then
							muts[mName] = true
						end
					end
				end
				clean.index[cid] = {
					discovered = info.discovered == true,
					mutations = muts,
					obtainedCount = tonumber(info.obtainedCount) or 1,
				}
			end
		end
	end

	if type(raw.ownedItems) == "table" then
		for itemId, owned in pairs(raw.ownedItems) do
			if owned == true and type(itemId) == "string" then
				clean.ownedItems[itemId] = true
			end
		end
	end

	if type(raw.tutorialStep) == "number" then
		clean.tutorialStep = math.clamp(math.floor(raw.tutorialStep), 1, #GameConfig.TutorialSteps + 1)
	end

	if type(raw.stats) == "table" then
		clean.stats.totalCashEarned = tonumber(raw.stats.totalCashEarned) or 0
		clean.stats.totalPurchases = tonumber(raw.stats.totalPurchases) or 0
		clean.stats.totalSteals = tonumber(raw.stats.totalSteals) or 0
		clean.stats.totalRebirths = tonumber(raw.stats.totalRebirths) or clean.rebirths
	end

	return clean
end

local function serializeForSave(data: any)
	return {
		cash = data.cash,
		rebirths = data.rebirths,
		incomeMultiplier = data.incomeMultiplier,
		ownedCreatures = data.ownedCreatures,
		index = data.index,
		ownedItems = data.ownedItems,
		tutorialStep = data.tutorialStep,
		stats = data.stats,
	}
end

local function safeGetAsync(key: string)
	if useMemoryFallback or not dataStore then
		return memoryStore[key]
	end
	for attempt = 1, MAX_RETRIES do
		local ok, res = pcall(function()
			return dataStore:GetAsync(key)
		end)
		if ok then
			return res
		end
		if RunService:IsStudio() then
			useMemoryFallback = true
			return memoryStore[key]
		end
		if attempt < MAX_RETRIES then
			task.wait(0.6 * attempt)
		end
	end
	useMemoryFallback = true
	return memoryStore[key]
end

local function safeSetAsync(key: string, payload: any)
	memoryStore[key] = payload
	if useMemoryFallback or not dataStore then
		return true
	end
	for attempt = 1, MAX_RETRIES do
		local ok = pcall(function()
			dataStore:SetAsync(key, payload)
		end)
		if ok then
			return true
		end
		if RunService:IsStudio() then
			useMemoryFallback = true
			return true
		end
		if attempt < MAX_RETRIES then
			task.wait(0.6 * attempt)
		end
	end
	return false
end

local function updateLeaderstats(player: Player, data: any)
	local ls = player:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		ls.Parent = player

		local cashVal = Instance.new("StringValue")
		cashVal.Name = "Cash"
		cashVal.Parent = ls

		local rebVal = Instance.new("IntValue")
		rebVal.Name = "Rebirths"
		rebVal.Parent = ls
	end

	local cashStat = ls:FindFirstChild("Cash") :: StringValue?
	if cashStat then
		cashStat.Value = FormatUtil.formatCash(data.cash)
	end
	local rebStat = ls:FindFirstChild("Rebirths") :: IntValue?
	if rebStat then
		rebStat.Value = data.rebirths
	end
end

function PlayerDataService.init(remotesFolder: Folder)
	stateSyncRemote = remotesFolder:FindFirstChild(GameConfig.Remotes.StateSync) :: RemoteEvent
	initDataStore()

	local reqRemote = remotesFolder:FindFirstChild(GameConfig.Remotes.RequestInitialState) :: RemoteEvent?
	if reqRemote then
		reqRemote.OnServerEvent:Connect(function(player: Player)
			PlayerDataService.syncToClient(player)
		end)
	end

	local tutRemote = remotesFolder:FindFirstChild(GameConfig.Remotes.TutorialAction) :: RemoteEvent?
	if tutRemote then
		tutRemote.OnServerEvent:Connect(function(player: Player, action: any)
			if action == "skip" then
				local data = profiles[player.UserId]
				if data then
					data.tutorialStep = #GameConfig.TutorialSteps + 1
					PlayerDataService.syncToClient(player)
				end
			elseif action == "visit_shop" then
				PlayerDataService.advanceTutorial(player, "visit_shop")
			elseif action == "complete_steal_guide" then
				PlayerDataService.advanceTutorial(player, "learn_steal")
			end
		end)
	end
end

function PlayerDataService.loadPlayer(player: Player)
	local key = "Player_" .. tostring(player.UserId)
	local raw = safeGetAsync(key)
	local data = sanitizeLoadedData(raw)
	profiles[player.UserId] = data
	updateLeaderstats(player, data)
	return data
end

function PlayerDataService.getData(player: Player)
	return profiles[player.UserId]
end

function PlayerDataService.getDataByUserId(userId: number)
	return profiles[userId]
end

function PlayerDataService.getMaxServerMutationLuck(): number
	local best = 1
	for _, data in pairs(profiles) do
		local luck = EconomyConfig.getMutationLuck(data.rebirths)
		if luck > best then
			best = luck
		end
	end
	return best
end

function PlayerDataService.syncToClient(player: Player)
	if not player or not player.Parent or not stateSyncRemote then
		return
	end
	local data = profiles[player.UserId]
	if not data then
		return
	end
	updateLeaderstats(player, data)

	stateSyncRemote:FireClient(player, {
		cash = data.cash,
		rebirths = data.rebirths,
		incomeMultiplier = data.incomeMultiplier,
		incomePerSecond = data._incomePerSecond,
		assignedBaseId = data._assignedBaseId,
		baseLocked = data._baseLocked,
		lockRemaining = data._lockRemaining,
		lockCooldown = data._lockCooldown,
		uncollectedBaseCash = data._uncollectedBaseCash,
		isStealing = data._isStealing,
		ownedCreatures = data.ownedCreatures,
		index = data.index,
		ownedItems = data.ownedItems,
		tutorialStep = data.tutorialStep,
		stats = data.stats,
	})
end

function PlayerDataService.addCash(player: Player, amount: number, countEarned: boolean?)
	local data = profiles[player.UserId]
	if not data or amount <= 0 then
		return
	end
	local delta = math.floor(amount)
	data.cash += delta
	if countEarned ~= false then
		data.stats.totalCashEarned += delta
	end
	PlayerDataService.syncToClient(player)
end

function PlayerDataService.spendCash(player: Player, cost: number): boolean
	local data = profiles[player.UserId]
	if not data then
		return false
	end
	local c = math.floor(cost)
	if c < 0 or data.cash < c then
		return false
	end
	data.cash -= c
	PlayerDataService.syncToClient(player)
	return true
end

function PlayerDataService.recordDiscovery(player: Player, creatureId: string, mutationName: string?)
	local data = profiles[player.UserId]
	if not data or not CreatureConfig.getCreature(creatureId) then
		return
	end
	local mut = mutationName or "None"
	local entry = data.index[creatureId]
	if not entry then
		entry = {
			discovered = true,
			mutations = {},
			obtainedCount = 0,
		}
		data.index[creatureId] = entry
	end
	entry.discovered = true
	entry.obtainedCount = (entry.obtainedCount or 0) + 1
	entry.mutations[mut] = true
end

function PlayerDataService.syncOwnedSlotsFromBase(userId: number, slotEntries: { any })
	local data = profiles[userId]
	if not data then
		return
	end
	data.ownedCreatures = slotEntries
	local player = Players:GetPlayerByUserId(userId)
	if player then
		PlayerDataService.syncToClient(player)
	end
end

function PlayerDataService.grantShopItem(player: Player, itemId: string)
	local data = profiles[player.UserId]
	if not data then
		return
	end
	data.ownedItems[itemId] = true
	PlayerDataService.syncToClient(player)
end

function PlayerDataService.hasShopItem(player: Player, itemId: string): boolean
	local data = profiles[player.UserId]
	if not data then
		return false
	end
	return data.ownedItems[itemId] == true
end

function PlayerDataService.advanceTutorial(player: Player, stepId: string)
	local data = profiles[player.UserId]
	if not data then
		return
	end
	local currentDef = GameConfig.TutorialSteps[data.tutorialStep]
	if currentDef and currentDef.id == stepId then
		data.tutorialStep += 1
		PlayerDataService.syncToClient(player)
	end
end

function PlayerDataService.savePlayer(player: Player)
	local data = profiles[player.UserId]
	if not data then
		return
	end
	local key = "Player_" .. tostring(player.UserId)
	safeSetAsync(key, serializeForSave(data))
end

function PlayerDataService.removePlayer(player: Player)
	PlayerDataService.savePlayer(player)
	profiles[player.UserId] = nil
end

function PlayerDataService.saveAll()
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerDataService.savePlayer(player)
	end
end

return PlayerDataService

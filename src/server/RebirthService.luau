-- RebirthService.luau
-- Server-authoritative Rebirth validation, progression reset, and permanent multiplier rewards.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local EconomyConfig = require(ReplicatedStorage:WaitForChild("EconomyConfig"))
local FormatUtil = require(ReplicatedStorage:WaitForChild("FormatUtil"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local BaseService = require(script.Parent:WaitForChild("BaseService"))
local ConveyorService = require(script.Parent:WaitForChild("ConveyorService"))
local NotificationService = require(script.Parent:WaitForChild("NotificationService"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local ShopService = require(script.Parent:WaitForChild("ShopService"))
local TheftService = require(script.Parent:WaitForChild("TheftService"))

local RebirthService = {}

local function playGoldenRebirthFX(player: Player)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end

	local beam = Instance.new("Part")
	beam.Name = "RebirthGoldenPillar"
	beam.Shape = Enum.PartType.Cylinder
	beam.Size = Vector3.new(28, 3, 3)
	beam.CFrame = CFrame.new(root.Position + Vector3.new(0, 12, 0)) * CFrame.Angles(0, 0, math.rad(90))
	beam.Color = Color3.fromRGB(255, 215, 55)
	beam.Material = Enum.Material.Neon
	beam.Transparency = 0.15
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.CanTouch = false
	beam.Parent = Workspace

	TweenService:Create(
		beam,
		TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = Vector3.new(32, 16, 16),
			Transparency = 1,
		}
	):Play()
	Debris:AddItem(beam, 0.95)
end

function RebirthService.tryRebirth(player: Player)
	local pData = PlayerDataService.getData(player)
	if not pData then
		return
	end

	if TheftService.isPlayerStealing(player) then
		NotificationService.send(player, "error", "Finish or cancel your active steal before Rebirthing!", 1.5)
		return
	end

	local requiredCash = EconomyConfig.getRebirthCost(pData.rebirths)
	if pData.cash < requiredCash then
		NotificationService.send(
			player,
			"warning",
			"Need " .. FormatUtil.formatCash(requiredCash) .. " to Rebirth! (You have " .. FormatUtil.formatCash(pData.cash) .. ")",
			1.5
		)
		return
	end

	-- Safely clean up steals & traveling creatures tied to this player
	TheftService.foilStealsFromVictim(player.UserId)
	ConveyorService.cancelAllPlayerTravelersForRebirth(player.UserId)

	local base = BaseService.getPlayerBase(player)
	if base then
		BaseService.clearAllBaseSlots(base.id)
	end

	-- Reset cash & creatures, apply permanent rewards
	pData.rebirths += 1
	pData.stats.totalRebirths = (pData.stats.totalRebirths or 0) + 1
	pData.cash = EconomyConfig.StarterCash
	pData.ownedCreatures = {}
	pData.incomeMultiplier = EconomyConfig.getIncomeMultiplier(pData.rebirths)
	pData._incomePerSecond = 0
	pData._uncollectedBaseCash = 0

	ShopService.refreshPlayerMovementStats(player)
	PlayerDataService.syncToClient(player)
	PlayerDataService.savePlayer(player)
	playGoldenRebirthFX(player)

	local lockDur = EconomyConfig.getLockDuration(pData.rebirths)
	NotificationService.send(
		player,
		"rebirth",
		string.format(
			"REBIRTH #%d COMPLETE! %.2fx Income • +%d%% Speed • %ds Base Lock!",
			pData.rebirths,
			pData.incomeMultiplier,
			math.floor(math.min(pData.rebirths * 10, 120)),
			lockDur
		)
	)
	NotificationService.broadcast(
		"rebirth",
		player.Name .. " ascended to REBIRTH #" .. tostring(pData.rebirths) .. " (" .. string.format("%.2fx", pData.incomeMultiplier) .. " Multiplier)!"
	)
end

function RebirthService.init(remotesFolder: Folder, worldHooks: any)
	local rebRemote = remotesFolder:FindFirstChild(GameConfig.Remotes.RequestRebirth) :: RemoteEvent?
	if rebRemote then
		rebRemote.OnServerEvent:Connect(function(player: Player)
			RebirthService.tryRebirth(player)
		end)
	end

	if worldHooks and worldHooks.rebirthShrinePrompt then
		worldHooks.rebirthShrinePrompt.Triggered:Connect(function(player: Player)
			RebirthService.tryRebirth(player)
		end)
	end
end

return RebirthService

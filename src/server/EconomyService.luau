-- EconomyService.luau
-- Server-authoritative 1-second income accrual across base slots and instant Green Platform cash collection.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CreatureConfig = require(ReplicatedStorage:WaitForChild("CreatureConfig"))
local EconomyConfig = require(ReplicatedStorage:WaitForChild("EconomyConfig"))
local FormatUtil = require(ReplicatedStorage:WaitForChild("FormatUtil"))

local BaseService = require(script.Parent:WaitForChild("BaseService"))
local CreatureService = require(script.Parent:WaitForChild("CreatureService"))
local NotificationService = require(script.Parent:WaitForChild("NotificationService"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

local EconomyService = {}

local secondAccumulator = 0
local collectCheckAccumulator = 0

local function tryCollectBaseCash(player: Player, base: any)
	if not base or base.ownerUserId ~= player.UserId or base.isShowcaseNpc then
		return
	end
	local amount = math.floor(base.uncollectedCash)
	if amount <= 0 then
		return
	end

	base.uncollectedCash = 0
	base.cashAmountLabel.Text = "$0"

	for _, slot in ipairs(base.slots) do
		if slot.occupied then
			slot.accumulatedDisplay = 0
			if slot.creatureUid then
				local rec = CreatureService.getRecord(slot.creatureUid)
				local pData = PlayerDataService.getData(player)
				local rebMult = if pData then pData.incomeMultiplier else 1
				if rec and rec.model then
					CreatureConfig.createCreatureBillboard(
						rec.model,
						slot.creatureId,
						slot.mutation,
						"slot",
						rebMult,
						"SLOT #" .. tostring(slot.index) .. " • EARNING"
					)
				end
			end
		end
	end

	local pData = PlayerDataService.getData(player)
	if pData then
		pData._uncollectedBaseCash = 0
	end

	PlayerDataService.addCash(player, amount, true)
	PlayerDataService.advanceTutorial(player, "collect_cash")

	NotificationService.sendFloatingPopup(
		player,
		base.cashPadPart.Position + Vector3.new(0, 3.2, 0),
		"+ " .. FormatUtil.formatCash(amount),
		Color3.fromRGB(78, 255, 132)
	)
	NotificationService.send(player, "cash", "Collected " .. FormatUtil.formatCash(amount) .. "!", 3.2)
end

function EconomyService.init()
	for _, base in pairs(BaseService.getAllBases()) do
		base.cashPadPart.Touched:Connect(function(hit: BasePart)
			local char = hit and hit.Parent
			if not char then
				return
			end
			local player = Players:GetPlayerFromCharacter(char)
			if player and base.ownerUserId == player.UserId then
				tryCollectBaseCash(player, base)
			end
		end)
	end
end

function EconomyService.recomputeBaseIncomePerSecond(base: any): number
	if not base or not base.ownerUserId then
		return 0
	end
	local rebMult = 1
	if not base.isShowcaseNpc then
		local pData = PlayerDataService.getDataByUserId(base.ownerUserId)
		if pData then
			rebMult = pData.incomeMultiplier or 1
		end
	end

	local totalRate = 0
	for _, slot in ipairs(base.slots) do
		if slot.occupied and not slot.beingStolen and slot.creatureId then
			local cDef = CreatureConfig.getCreature(slot.creatureId)
			if cDef then
				totalRate += EconomyConfig.computeSlotIncome(cDef.IncomePerSecond, slot.mutation, rebMult)
			end
		end
	end
	return totalRate
end

local function tickOneSecondIncome()
	for _, base in pairs(BaseService.getAllBases()) do
		if not base.ownerUserId then
			continue
		end

		local rebMult = 1
		local ownerPlayer: Player? = nil
		local pData = nil
		if not base.isShowcaseNpc then
			ownerPlayer = Players:GetPlayerByUserId(base.ownerUserId)
			pData = PlayerDataService.getDataByUserId(base.ownerUserId)
			if pData then
				rebMult = pData.incomeMultiplier or 1
			end
		end

		local totalRate = 0
		for _, slot in ipairs(base.slots) do
			if slot.occupied and not slot.beingStolen and slot.creatureId then
				local cDef = CreatureConfig.getCreature(slot.creatureId)
				if cDef then
					local slotRate = EconomyConfig.computeSlotIncome(cDef.IncomePerSecond, slot.mutation, rebMult)
					totalRate += slotRate
					slot.accumulatedDisplay += slotRate

					if slot.creatureUid then
						local rec = CreatureService.getRecord(slot.creatureUid)
						if rec and rec.model then
							local bb = rec.model:FindFirstChild("CreatureInfoBillboard")
							local card = bb and bb:FindFirstChild("Card")
							local bottomLbl = card and card:FindFirstChild("BottomLabel") :: TextLabel?
							if bottomLbl then
								bottomLbl.Text = "SLOT #" .. tostring(slot.index) .. " • +" .. FormatUtil.formatCash(slot.accumulatedDisplay)
							end
						end
					end
				end
			end
		end

		if totalRate > 0 then
			base.uncollectedCash += totalRate
			base.cashAmountLabel.Text = FormatUtil.formatCash(base.uncollectedCash)
		end

		if pData and ownerPlayer then
			pData._incomePerSecond = totalRate
			pData._uncollectedBaseCash = base.uncollectedCash
			pData._baseLocked = base.isLocked
			pData._lockRemaining = math.ceil(base.lockRemaining)
			pData._lockCooldown = math.ceil(base.lockCooldown)
			PlayerDataService.syncToClient(ownerPlayer)
		end
	end
end

function EconomyService.step(dt: number)
	secondAccumulator += dt
	if secondAccumulator >= 1.0 then
		secondAccumulator -= 1.0
		tickOneSecondIncome()
	end

	-- Fast spatial check so standing still on the green cash platform collects immediately
	collectCheckAccumulator += dt
	if collectCheckAccumulator >= 0.2 then
		collectCheckAccumulator = 0
		for _, player in ipairs(Players:GetPlayers()) do
			local base = BaseService.getPlayerBase(player)
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if base and root and base.uncollectedCash >= 1 then
				local padPos = base.cashPadPart.Position
				local dx = math.abs(root.Position.X - padPos.X)
				local dz = math.abs(root.Position.Z - padPos.Z)
				local dy = root.Position.Y - padPos.Y
				if dx <= 5.2 and dz <= 5.2 and dy >= -2 and dy <= 8 then
					tryCollectBaseCash(player, base)
				end
			end
		end
	end
end

return EconomyService

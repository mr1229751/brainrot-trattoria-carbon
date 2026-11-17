-- EconomyConfig.luau
-- Currency constants, base lock timings, rebirth progression scaling, and income math.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MutationConfig = require(ReplicatedStorage:WaitForChild("MutationConfig"))

local EconomyConfig = {}

EconomyConfig.StarterCash = 120
EconomyConfig.ShowcaseStudioCash = 250000000
EconomyConfig.SellRefundFraction = 0.50

-- Base laser security parameters
EconomyConfig.DefaultLockDuration = 60
EconomyConfig.LockDurationPerRebirth = 10
EconomyConfig.LockCooldownSeconds = 12

-- Stealing speed & tag parameters
EconomyConfig.BaseWalkSpeed = 18
EconomyConfig.StealCarryWalkSpeed = 11.5
EconomyConfig.OwnerTagDistance = 6.2

-- Rebirth ladder configuration (cost scales x8 per rebirth)
EconomyConfig.RebirthBaseCost = 25000
EconomyConfig.RebirthCostMultiplier = 8
EconomyConfig.IncomeBonusPerRebirth = 0.75
EconomyConfig.WalkSpeedBonusPerRebirth = 0.10
EconomyConfig.MaxWalkSpeedBonus = 1.20
EconomyConfig.MutationLuckPerRebirth = 0.15

function EconomyConfig.getRebirthCost(currentRebirths: number): number
	local r = math.max(0, math.floor(currentRebirths))
	return math.floor(EconomyConfig.RebirthBaseCost * (EconomyConfig.RebirthCostMultiplier ^ r))
end

function EconomyConfig.getIncomeMultiplier(rebirths: number): number
	local r = math.max(0, math.floor(rebirths))
	return 1 + (r * EconomyConfig.IncomeBonusPerRebirth)
end

function EconomyConfig.getPlayerWalkSpeed(rebirths: number, coilMultiplier: number?): number
	local r = math.max(0, math.floor(rebirths))
	local rebirthSpeedFactor = 1 + math.min(r * EconomyConfig.WalkSpeedBonusPerRebirth, EconomyConfig.MaxWalkSpeedBonus)
	local equipFactor = coilMultiplier or 1
	return EconomyConfig.BaseWalkSpeed * rebirthSpeedFactor * equipFactor
end

function EconomyConfig.getLockDuration(rebirths: number): number
	local r = math.max(0, math.floor(rebirths))
	return EconomyConfig.DefaultLockDuration + (r * EconomyConfig.LockDurationPerRebirth)
end

function EconomyConfig.getMutationLuck(rebirths: number): number
	local r = math.max(0, math.floor(rebirths))
	return 1 + (r * EconomyConfig.MutationLuckPerRebirth)
end

function EconomyConfig.getRebirthPreview(currentRebirths: number)
	local nextRebirth = math.max(0, math.floor(currentRebirths)) + 1
	return {
		nextRebirth = nextRebirth,
		cost = EconomyConfig.getRebirthCost(currentRebirths),
		currentMultiplier = EconomyConfig.getIncomeMultiplier(currentRebirths),
		nextMultiplier = EconomyConfig.getIncomeMultiplier(nextRebirth),
		currentWalkSpeedPct = math.floor(math.min(currentRebirths * 10, 120)),
		nextWalkSpeedPct = math.floor(math.min(nextRebirth * 10, 120)),
		currentLockSeconds = EconomyConfig.getLockDuration(currentRebirths),
		nextLockSeconds = EconomyConfig.getLockDuration(nextRebirth),
		currentLuckPct = math.floor(currentRebirths * 15),
		nextLuckPct = math.floor(nextRebirth * 15),
	}
end

function EconomyConfig.computeSlotIncome(baseIncome: number, mutationName: string?, rebirthMultiplier: number?): number
	local mutMult = MutationConfig.getMultiplier(mutationName)
	local rebMult = rebirthMultiplier or 1
	return math.max(1, math.floor(baseIncome * mutMult * rebMult + 0.5))
end

return EconomyConfig

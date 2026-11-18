-- TheftService.luau
-- Server-authoritative stealing loop: unlocked base validation, overhead carry with [STEALING!] tag,
-- thief slowdown, owner touch/tool/trap foiling, zero-duplication guarantees, and base delivery.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CreatureConfig = require(ReplicatedStorage:WaitForChild("CreatureConfig"))
local EconomyConfig = require(ReplicatedStorage:WaitForChild("EconomyConfig"))
local FormatUtil = require(ReplicatedStorage:WaitForChild("FormatUtil"))
local MutationConfig = require(ReplicatedStorage:WaitForChild("MutationConfig"))

local BaseService = require(script.Parent:WaitForChild("BaseService"))
local CreatureService = require(script.Parent:WaitForChild("CreatureService"))
local NotificationService = require(script.Parent:WaitForChild("NotificationService"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

local TheftService = {}

local activeStealsByThief: { [number]: any } = {}
local speedRefreshCallback: ((Player) -> ())? = nil

function TheftService.setSpeedRefreshCallback(cb: (Player) -> ())
	speedRefreshCallback = cb
end

-- Shared builder for the big red [STEALING!] overhead BillboardGui (used in live play & Studio Showcase)
function TheftService.attachStealingBanner(model: Model, creatureId: string, mutationName: string?)
	local cDef = CreatureConfig.getCreature(creatureId)
	local root = model and model.PrimaryPart
	if not cDef or not root then
		return
	end

	local existing = model:FindFirstChild("CreatureInfoBillboard")
	if existing then
		existing:Destroy()
	end

	local mutInfo = MutationConfig.getMutationInfo(mutationName)
	local rate = EconomyConfig.computeSlotIncome(cDef.IncomePerSecond, mutationName, 1)

	local bb = Instance.new("BillboardGui")
	bb.Name = "CreatureInfoBillboard"
	bb.Adornee = root
	bb.StudsOffset = Vector3.new(0, (cDef.HeightStuds or 5.0) + 2.2, 0)
	bb.Size = UDim2.new(0, 262, 0, 100)
	bb.MaxDistance = 104
	bb.LightInfluence = 0
	bb.AlwaysOnTop = false
	bb.Parent = model

	local card = Instance.new("Frame")
	card.Name = "Card"
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = Color3.fromRGB(58, 10, 20)
	card.BackgroundTransparency = 0.06
	card.BorderSizePixel = 0
	card.Parent = bb

	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 52, 72)
	stroke.Thickness = 3.0
	stroke.Parent = card

	local badge = Instance.new("TextLabel")
	badge.Size = UDim2.new(0.94, 0, 0.44, 0)
	badge.Position = UDim2.new(0.03, 0, 0.04, 0)
	badge.BackgroundTransparency = 1
	badge.Font = Enum.Font.GothamBlack
	badge.Text = "[STEALING!]"
	badge.TextColor3 = Color3.fromRGB(255, 75, 88)
	badge.TextScaled = true
	badge.Parent = card
	local bStroke = Instance.new("UIStroke")
	bStroke.Color = Color3.fromRGB(10, 4, 14)
	bStroke.Thickness = 2.8
	bStroke.Parent = badge

	local prefix = if mutInfo.id ~= "None" then ("[" .. mutInfo.displayName .. "] ") else ""
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(0.94, 0, 0.28, 0)
	nameLbl.Position = UDim2.new(0.03, 0, 0.46, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Font = Enum.Font.GothamBlack
	nameLbl.Text = prefix .. string.upper(cDef.DisplayName)
	nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLbl.TextScaled = true
	nameLbl.Parent = card
	local nStroke = Instance.new("UIStroke")
	nStroke.Color = Color3.fromRGB(10, 4, 14)
	nStroke.Thickness = 2.4
	nStroke.Parent = nameLbl

	local rateLbl = Instance.new("TextLabel")
	rateLbl.Size = UDim2.new(0.94, 0, 0.22, 0)
	rateLbl.Position = UDim2.new(0.03, 0, 0.74, 0)
	rateLbl.BackgroundTransparency = 1
	rateLbl.Font = Enum.Font.GothamBold
	rateLbl.Text = cDef.Rarity .. " • " .. FormatUtil.formatRate(rate)
	rateLbl.TextColor3 = Color3.fromRGB(255, 224, 92)
	rateLbl.TextScaled = true
	rateLbl.Parent = card
	local rStroke = Instance.new("UIStroke")
	rStroke.Color = Color3.fromRGB(10, 4, 14)
	rStroke.Thickness = 2.2
	rStroke.Parent = rateLbl
end

local function restoreThiefState(thiefPlayer: Player?)
	if not thiefPlayer then
		return
	end
	local pData = PlayerDataService.getData(thiefPlayer)
	if pData then
		pData._isStealing = false
		PlayerDataService.syncToClient(thiefPlayer)
	end

	local char = thiefPlayer.Character
	if char then
		local hl = char:FindFirstChild("ThiefAlertHighlight")
		if hl then
			hl:Destroy()
		end
	end

	if speedRefreshCallback then
		speedRefreshCallback(thiefPlayer)
	elseif char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = EconomyConfig.getPlayerWalkSpeed(if pData then pData.rebirths else 0, 1)
		end
	end
end

local function returnCreatureToOrigin(stealRec: any): boolean
	local originBase = BaseService.getBaseById(stealRec.originBaseId)
	if originBase and originBase.ownerUserId == stealRec.victimUserId then
		local targetSlot = stealRec.originSlotIndex
		if originBase.slots[targetSlot] and originBase.slots[targetSlot].occupied then
			targetSlot = BaseService.findFreeSlotUnreserved(originBase.id)
		end
		if targetSlot then
			local ok = BaseService.placeCreatureInSlot(
				originBase.id,
				targetSlot,
				stealRec.creatureId,
				stealRec.mutation,
				stealRec.creatureUid
			)
			if ok then
				return true
			end
		end
	end
	CreatureService.destroyCreature(stealRec.creatureUid)
	return false
end

function TheftService.isPlayerStealing(player: Player): boolean
	return activeStealsByThief[player.UserId] ~= nil
end

function TheftService.foilSteal(thiefUserId: number, reasonText: string?)
	local stealRec = activeStealsByThief[thiefUserId]
	if not stealRec then
		return false
	end
	activeStealsByThief[thiefUserId] = nil

	local returned = returnCreatureToOrigin(stealRec)
	local thiefPlayer = Players:GetPlayerByUserId(thiefUserId)
	restoreThiefState(thiefPlayer)

	local cDef = CreatureConfig.getCreature(stealRec.creatureId)
	local cName = if cDef then cDef.DisplayName else "creature"
	local why = reasonText or "Stopped by defense!"

	if thiefPlayer then
		NotificationService.send(thiefPlayer, "error", "STEAL FAILED! " .. why .. " (" .. cName .. " returned)")
	end

	if stealRec.victimUserId and stealRec.victimUserId > 0 then
		local victimPlayer = Players:GetPlayerByUserId(stealRec.victimUserId)
		if victimPlayer and returned then
			NotificationService.send(victimPlayer, "success", "DEFENDED! Your " .. cName .. " returned safely to its slot!")
		end
	end
	return true
end

function TheftService.foilStealsFromVictim(victimUserId: number)
	for thiefUserId, rec in pairs(activeStealsByThief) do
		if rec.victimUserId == victimUserId then
			TheftService.foilSteal(thiefUserId, "Owner reset their base!")
		end
	end
end

function TheftService.tryStartSteal(thief: Player, targetBaseId: number, slotIndex: number)
	if activeStealsByThief[thief.UserId] then
		NotificationService.send(thief, "warning", "You are already carrying a stolen creature!", 1.5)
		return
	end

	local char = thief.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not char or not hum or hum.Health <= 0 or not root then
		return
	end

	local thiefBase = BaseService.getPlayerBase(thief)
	if not thiefBase then
		NotificationService.send(thief, "error", "Claim a base first before stealing!", 1.5)
		return
	end
	if thiefBase.id == targetBaseId then
		return
	end
	if not BaseService.findFreeSlotUnreserved(thiefBase.id) then
		NotificationService.send(thief, "warning", "Your base is full (10/10)! Sell a creature before stealing!", 2.0)
		return
	end

	local targetBase = BaseService.getBaseById(targetBaseId)
	if not targetBase or targetBase.ownerUserId == nil or targetBase.ownerUserId == thief.UserId then
		return
	end
	if targetBase.isLocked then
		NotificationService.send(thief, "error", targetBase.def.name .. " is LOCKED by red lasers!", 1.5)
		return
	end

	local slot = targetBase.slots[slotIndex]
	if not slot or not slot.occupied or slot.beingStolen then
		return
	end
	if (root.Position - slot.worldPos).Magnitude > 16.5 then
		NotificationService.send(thief, "warning", "Move closer to steal!", 1.2)
		return
	end

	-- Atomically detach creature from victim slot (guarantees zero duplication)
	local detached = BaseService.detachSlotForSteal(targetBaseId, slotIndex)
	if not detached then
		return
	end

	local rec = CreatureService.getRecord(detached.creatureUid)
	if not rec or not rec.model then
		return
	end

	rec.mode = "stealing"
	rec.waypoints = nil
	TheftService.attachStealingBanner(rec.model, detached.creatureId, detached.mutation)

	-- Disable thief tools, apply slowdown & red alert Highlight
	hum:UnequipTools()
	hum.WalkSpeed = EconomyConfig.StealCarryWalkSpeed

	local thiefHl = Instance.new("Highlight")
	thiefHl.Name = "ThiefAlertHighlight"
	thiefHl.FillColor = Color3.fromRGB(255, 42, 65)
	thiefHl.FillTransparency = 0.72
	thiefHl.OutlineColor = Color3.fromRGB(255, 85, 95)
	thiefHl.OutlineTransparency = 0.05
	thiefHl.Parent = char

	local pData = PlayerDataService.getData(thief)
	if pData then
		pData._isStealing = true
		PlayerDataService.advanceTutorial(thief, "learn_steal")
		PlayerDataService.syncToClient(thief)
	end

	activeStealsByThief[thief.UserId] = {
		thiefUserId = thief.UserId,
		thiefName = thief.Name,
		victimUserId = targetBase.ownerUserId,
		originBaseId = targetBaseId,
		originSlotIndex = slotIndex,
		creatureId = detached.creatureId,
		mutation = detached.mutation,
		creatureUid = detached.creatureUid,
		startedAt = os.clock(),
	}

	-- Block re-equipping tools while stealing
	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and activeStealsByThief[thief.UserId] then
			task.defer(function()
				if hum and hum.Parent then
					hum:UnequipTools()
				end
			end)
		end
	end)

	local cDef = CreatureConfig.getCreature(detached.creatureId)
	local fullName = (if detached.mutation ~= "None" then (detached.mutation .. " ") else "") .. (if cDef then cDef.DisplayName else "Creature")

	NotificationService.send(thief, "alert", "STEALING " .. fullName .. "! Sprint back to " .. thiefBase.def.name .. "!")

	if targetBase.ownerUserId > 0 then
		local victim = Players:GetPlayerByUserId(targetBase.ownerUserId)
		if victim then
			NotificationService.send(victim, "alert", "Someone is stealing your " .. fullName .. "! Tag " .. thief.Name .. "!")
		end
	end
end

local function completeStealDelivery(thief: Player, stealRec: any)
	activeStealsByThief[thief.UserId] = nil
	restoreThiefState(thief)

	local thiefBase = BaseService.getPlayerBase(thief)
	local freeSlot = thiefBase and BaseService.findFreeSlotUnreserved(thiefBase.id)
	if not thiefBase or not freeSlot then
		returnCreatureToOrigin(stealRec)
		NotificationService.send(thief, "error", "No free slot in your base! Creature escaped back!")
		return
	end

	local placed = BaseService.placeCreatureInSlot(
		thiefBase.id,
		freeSlot,
		stealRec.creatureId,
		stealRec.mutation,
		stealRec.creatureUid
	)
	if not placed then
		returnCreatureToOrigin(stealRec)
		return
	end

	local pData = PlayerDataService.getData(thief)
	if pData then
		pData.stats.totalSteals += 1
		PlayerDataService.recordDiscovery(thief, stealRec.creatureId, stealRec.mutation)
		PlayerDataService.syncToClient(thief)
	end

	local cDef = CreatureConfig.getCreature(stealRec.creatureId)
	local fullName = (if stealRec.mutation ~= "None" then (stealRec.mutation .. " ") else "") .. (if cDef then cDef.DisplayName else "Creature")

	NotificationService.send(thief, "success", "HEIST COMPLETE! " .. fullName .. " is now earning in Slot #" .. tostring(freeSlot) .. "!")

	if stealRec.victimUserId and stealRec.victimUserId > 0 then
		local victim = Players:GetPlayerByUserId(stealRec.victimUserId)
		if victim then
			NotificationService.send(victim, "error", thief.Name .. " stole your " .. fullName .. "! Remember to LOCK your base!")
		end
	end
end

function TheftService.init()
	BaseService.setStealAttemptCallback(function(player: Player, baseId: number, slotIndex: number)
		TheftService.tryStartSteal(player, baseId, slotIndex)
	end)
end

function TheftService.cleanupPlayer(player: Player)
	if activeStealsByThief[player.UserId] then
		TheftService.foilSteal(player.UserId, player.Name .. " disconnected!")
	end
	-- If leaving player was a victim of an active steal, clear origin reference cleanly
	for _, rec in pairs(activeStealsByThief) do
		if rec.victimUserId == player.UserId then
			rec.victimUserId = -999
		end
	end
end

function TheftService.step(_dt: number, now: number)
	for thiefUserId, stealRec in pairs(activeStealsByThief) do
		local thief = Players:GetPlayerByUserId(thiefUserId)
		local char = thief and thief.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?

		if not thief or not char or not hum or hum.Health <= 0 or not root then
			TheftService.foilSteal(thiefUserId, "Thief was knocked out!")
			continue
		end

		-- Enforce carry slowdown continuously
		if hum.WalkSpeed > EconomyConfig.StealCarryWalkSpeed + 0.5 then
			hum.WalkSpeed = EconomyConfig.StealCarryWalkSpeed
		end

		-- Position stolen creature overhead
		local cRec = CreatureService.getRecord(stealRec.creatureUid)
		if cRec and cRec.model then
			local bob = math.sin(now * 6) * 0.25
			local carryPos = root.Position + Vector3.new(0, 3.8 + bob, 0)
			local look = root.CFrame.LookVector
			local flatLook = Vector3.new(look.X, 0, look.Z)
			if flatLook.Magnitude < 0.01 then
				flatLook = Vector3.new(0, 0, 1)
			end
			cRec.position = carryPos
			cRec.model:PivotTo(CFrame.lookAt(carryPos, carryPos + flatLook))
		else
			TheftService.foilSteal(thiefUserId, "Creature slipped away!")
			continue
		end

		-- Check if base owner touched/tagged the thief
		if stealRec.victimUserId and stealRec.victimUserId > 0 then
			local victim = Players:GetPlayerByUserId(stealRec.victimUserId)
			local vChar = victim and victim.Character
			local vHum = vChar and vChar:FindFirstChildOfClass("Humanoid")
			local vRoot = vChar and vChar:FindFirstChild("HumanoidRootPart") :: BasePart?
			if victim and vHum and vHum.Health > 0 and vRoot then
				local dist = (vRoot.Position - root.Position).Magnitude
				if dist <= EconomyConfig.OwnerTagDistance then
					-- Apply light knockback impulse on thief
					local pushDir = (root.Position - vRoot.Position)
					local horiz = Vector3.new(pushDir.X, 0, pushDir.Z)
					if horiz.Magnitude > 0.05 then
						root.AssemblyLinearVelocity = horiz.Unit * 38 + Vector3.new(0, 22, 0)
					end
					TheftService.foilSteal(thiefUserId, victim.Name .. " tagged you!")
					continue
				end
			end
		end

		-- Check if thief reached inside their own base
		local thiefBase = BaseService.getPlayerBase(thief)
		if thiefBase and BaseService.isPositionInsideBase(thiefBase.id, root.Position) then
			completeStealDelivery(thief, stealRec)
		end
	end
end

return TheftService

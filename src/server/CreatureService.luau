-- CreatureService.luau
-- Centralized 3D creature lifecycle, movement stepping, idle/walk animation, and mutation FX updater.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CreatureConfig = require(ReplicatedStorage:WaitForChild("CreatureConfig"))

local CreatureService = {}

local creaturesFolder: Folder? = nil
local activeRecords: { [string]: any } = {}
local nextUid = 0

function CreatureService.init()
	local existing = Workspace:FindFirstChild("Creatures")
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Creatures"
	folder.Parent = Workspace
	creaturesFolder = folder
end

function CreatureService.getFolder(): Folder
	if not creaturesFolder then
		CreatureService.init()
	end
	return creaturesFolder :: Folder
end

local function updateMutationAttachments(model: Model, rootCF: CFrame, now: number, phase: number)
	local orbitFolder = model:FindFirstChild("OrbitStars")
	if orbitFolder then
		for _, star in ipairs(orbitFolder:GetChildren()) do
			if star:IsA("Model") and star.PrimaryPart then
				local idx = star:GetAttribute("OrbitIndex") or 1
				local ang = (idx - 1) * ((math.pi * 2) / 3) + now * 2.4 + phase
				local radius = 2.85
				local yWave = 2.45 + math.sin(now * 3.2 + idx) * 0.35
				local offset = Vector3.new(math.cos(ang) * radius, yWave, math.sin(ang) * radius)
				local targetCF = CFrame.new(rootCF.Position + offset) * CFrame.Angles(0, ang, math.rad(25))
				star:PivotTo(targetCF)
			end
		end
	end

	local voidCore = model:FindFirstChild("VoidNeonCore")
	if voidCore and voidCore:IsA("BasePart") then
		local pulse = 2.0 + math.sin(now * 4.5 + phase) * 0.25
		voidCore.Size = Vector3.new(pulse, pulse, pulse)
		voidCore.CFrame = rootCF * CFrame.new(0, 2.35, 0)
	end
end

function CreatureService.spawnCreatureInstance(
	creatureId: string,
	mutationName: string?,
	worldPos: Vector3,
	lookDir: Vector3,
	mode: string,
	incomeMultiplier: number?,
	customBottomText: string?
)
	local def = CreatureConfig.getCreature(creatureId)
	if not def then
		return nil
	end

	local model = CreatureConfig.buildCreatureModel(creatureId, mutationName or "None")
	if not model then
		return nil
	end

	nextUid += 1
	local uid = "cr_" .. tostring(nextUid)
	model.Name = def.CreatureID .. "_" .. tostring(nextUid)
	model:SetAttribute("UID", uid)

	local flatLook = Vector3.new(lookDir.X, 0, lookDir.Z)
	if flatLook.Magnitude < 0.001 then
		flatLook = Vector3.new(0, 0, 1)
	else
		flatLook = flatLook.Unit
	end

	local baseCF = CFrame.lookAt(worldPos, worldPos + flatLook)
	model:PivotTo(baseCF)
	model.Parent = CreatureService.getFolder()

	CreatureConfig.createCreatureBillboard(
		model,
		creatureId,
		mutationName or "None",
		mode,
		incomeMultiplier or 1,
		customBottomText
	)

	local record = {
		uid = uid,
		creatureId = creatureId,
		mutation = mutationName or "None",
		def = def,
		model = model,
		mode = mode, -- "conveyor" | "traveling" | "slot" | "stealing" | "showcase"
		position = worldPos,
		lookDir = flatLook,
		walkSpeed = def.WalkSpeed or 10,
		waypoints = nil,
		waypointIndex = 1,
		onArrive = nil,
		phase = math.random() * math.pi * 2,
		reserved = false,
		buyerUserId = nil,
		reservedBaseId = nil,
		reservedSlot = nil,
	}

	activeRecords[uid] = record
	return record
end

function CreatureService.getRecord(uid: string)
	return activeRecords[uid]
end

function CreatureService.destroyCreature(uid: string)
	local rec = activeRecords[uid]
	if not rec then
		return
	end
	activeRecords[uid] = nil
	if rec.model and rec.model.Parent then
		rec.model:Destroy()
	end
end

function CreatureService.setWaypoints(uid: string, waypoints: { Vector3 }, speed: number?, onArrive: (() -> ())?)
	local rec = activeRecords[uid]
	if not rec then
		return
	end
	rec.waypoints = waypoints
	rec.waypointIndex = 1
	if speed then
		rec.walkSpeed = speed
	end
	rec.onArrive = onArrive
end

-- Single centralized server animation & locomotion tick
function CreatureService.step(dt: number, now: number)
	local completedCallbacks = {}

	for uid, rec in pairs(activeRecords) do
		local model: Model = rec.model
		if not model or not model.Parent or not model.PrimaryPart then
			activeRecords[uid] = nil
			continue
		end

		local anim = rec.def.AnimationSettings or { bobAmplitude = 0.2, bobFrequency = 3.0, spinSpeed = 0, tiltAmount = 4 }

		if rec.mode == "stealing" then
			-- Overhead position is driven by TheftService; still update Golden/Void mutation FX
			updateMutationAttachments(model, model.PrimaryPart.CFrame, now, rec.phase)
			continue
		end

		if rec.waypoints and rec.waypointIndex <= #rec.waypoints then
			local target: Vector3 = rec.waypoints[rec.waypointIndex]
			local toTarget = target - rec.position
			local horiz = Vector3.new(toTarget.X, 0, toTarget.Z)
			local dist = toTarget.Magnitude
			local stepDist = rec.walkSpeed * dt

			if horiz.Magnitude > 0.05 then
				rec.lookDir = horiz.Unit
			end

			if dist <= stepDist or dist < 0.15 then
				rec.position = target
				rec.waypointIndex += 1
				if rec.waypointIndex > #rec.waypoints then
					rec.waypoints = nil
					if rec.onArrive then
						local cb = rec.onArrive
						rec.onArrive = nil
						table.insert(completedCallbacks, cb)
					end
				end
			else
				rec.position = rec.position + toTarget.Unit * stepDist
			end

			-- Lively waddle & bounce while walking
			local stride = now * 8.5 + rec.phase
			local bounceY = math.abs(math.sin(stride)) * 0.34
			local waddleRoll = math.rad(math.sin(stride) * (anim.tiltAmount or 4))
			local pitch = math.rad(-3)
			local renderPos = rec.position + Vector3.new(0, bounceY, 0)
			local renderCF = CFrame.lookAt(renderPos, renderPos + rec.lookDir) * CFrame.Angles(pitch, 0, waddleRoll)
			model:PivotTo(renderCF)
			updateMutationAttachments(model, renderCF, now, rec.phase)
		else
			-- Idle animation in base slot or showcase parade
			local t = now * (anim.bobFrequency or 2.8) + rec.phase
			local bobY = (math.sin(t) + 1) * 0.5 * (anim.bobAmplitude or 0.2)
			local spinAngle = if (anim.spinSpeed or 0) > 0
				then math.sin(now * (anim.spinSpeed or 0.5) + rec.phase) * math.rad(22)
				else 0
			local swayRoll = math.rad(math.sin(t * 0.7) * ((anim.tiltAmount or 3) * 0.45))

			local renderPos = rec.position + Vector3.new(0, bobY, 0)
			local renderCF = CFrame.lookAt(renderPos, renderPos + rec.lookDir) * CFrame.Angles(0, spinAngle, swayRoll)
			model:PivotTo(renderCF)
			updateMutationAttachments(model, renderCF, now, rec.phase)
		end
	end

	for _, cb in ipairs(completedCallbacks) do
		cb()
	end
end

return CreatureService

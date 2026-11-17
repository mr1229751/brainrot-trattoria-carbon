-- TutorialUI.luau
-- Guided 8-step first-time objective card with subtle 3D golden directional guide beam.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local TutorialUI = {}

local function resolveTargetWorldPosition(targetType: string, assignedBaseId: number?): Vector3?
	if targetType == "Conveyor" then
		if assignedBaseId and GameConfig.Bases[assignedBaseId] then
			return Vector3.new(0, 1.5, GameConfig.Bases[assignedBaseId].centerZ)
		end
		return Vector3.new(0, 1.5, -20)
	elseif targetType == "Shop" then
		return GameConfig.SpawnArea.EquipmentStallPos + Vector3.new(0, 2, 8)
	elseif assignedBaseId and GameConfig.Bases[assignedBaseId] then
		local bDef = GameConfig.Bases[assignedBaseId]
		if targetType == "MyBase" then
			return GameConfig.getBaseWorldPosition(bDef, 10, 0, 2)
		elseif targetType == "MyCashPad" then
			return GameConfig.getBaseWorldPosition(
				bDef,
				GameConfig.BaseDimensions.CashPadDepth,
				GameConfig.BaseDimensions.CashPadZOffset,
				1.8
			)
		elseif targetType == "MyLockButton" then
			return GameConfig.getBaseWorldPosition(
				bDef,
				GameConfig.BaseDimensions.LockButtonDepth,
				GameConfig.BaseDimensions.LockButtonZOffset,
				2.4
			)
		end
	end
	return nil
end

function TutorialUI.mount(playerGui: PlayerGui, callbacks: any)
	local localPlayer = Players.LocalPlayer

	local sg = Instance.new("ScreenGui")
	sg.Name = "TutorialGui"
	sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.DisplayOrder = 6
	sg.Parent = playerGui

	local uiScale = Instance.new("UIScale")
	uiScale.Parent = sg

	local card = Instance.new("Frame")
	card.Name = "TutorialCard"
	card.AnchorPoint = Vector2.new(1, 0)
	card.Position = UDim2.new(1, -16, 0, 10)
	card.Size = UDim2.new(0, 285, 0, 102)
	card.BackgroundColor3 = Color3.fromRGB(24, 14, 44)
	card.BackgroundTransparency = 0.08
	card.BorderSizePixel = 0
	card.Parent = sg

	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 208, 55)
	stroke.Thickness = 2
	stroke.Parent = card

	local stepHeader = Instance.new("TextLabel")
	stepHeader.Position = UDim2.new(0.05, 0, 0, 8)
	stepHeader.Size = UDim2.new(0.68, 0, 0, 22)
	stepHeader.BackgroundTransparency = 1
	stepHeader.Font = Enum.Font.GothamBlack
	stepHeader.TextXAlignment = Enum.TextXAlignment.Left
	stepHeader.Text = "1/8 • Claim Your Base"
	stepHeader.TextColor3 = Color3.fromRGB(255, 215, 65)
	stepHeader.TextScaled = true
	stepHeader.Parent = card

	local skipBtn = Instance.new("TextButton")
	skipBtn.AnchorPoint = Vector2.new(1, 0)
	skipBtn.Position = UDim2.new(1, -10, 0, 7)
	skipBtn.Size = UDim2.new(0, 56, 0, 22)
	skipBtn.BackgroundColor3 = Color3.fromRGB(58, 38, 92)
	skipBtn.Font = Enum.Font.GothamBold
	skipBtn.Text = "SKIP"
	skipBtn.TextColor3 = Color3.fromRGB(215, 202, 242)
	skipBtn.TextScaled = true
	skipBtn.Parent = card
	Instance.new("UICorner", skipBtn).CornerRadius = UDim.new(0, 6)

	local bodyText = Instance.new("TextLabel")
	bodyText.Position = UDim2.new(0.05, 0, 0, 34)
	bodyText.Size = UDim2.new(0.9, 0, 0, 40)
	bodyText.BackgroundTransparency = 1
	bodyText.Font = Enum.Font.GothamMedium
	bodyText.TextXAlignment = Enum.TextXAlignment.Left
	bodyText.TextWrapped = true
	bodyText.Text = "Walk into your assigned purple base!"
	bodyText.TextColor3 = Color3.fromRGB(245, 240, 255)
	bodyText.TextSize = 13
	bodyText.Parent = card

	local progBg = Instance.new("Frame")
	progBg.Position = UDim2.new(0.05, 0, 1, -16)
	progBg.Size = UDim2.new(0.9, 0, 0, 7)
	progBg.BackgroundColor3 = Color3.fromRGB(12, 8, 22)
	progBg.BorderSizePixel = 0
	progBg.Parent = card
	Instance.new("UICorner", progBg).CornerRadius = UDim.new(1, 0)

	local progFill = Instance.new("Frame")
	progFill.Size = UDim2.new(0.125, 0, 1, 0)
	progFill.BackgroundColor3 = Color3.fromRGB(85, 245, 138)
	progFill.BorderSizePixel = 0
	progFill.Parent = progBg
	Instance.new("UICorner", progFill).CornerRadius = UDim.new(1, 0)

	-- 3D Target Marker & Guide Beam
	local markerPart = Instance.new("Part")
	markerPart.Name = "TutorialGuideTarget"
	markerPart.Shape = Enum.PartType.Cylinder
	markerPart.Size = Vector3.new(0.3, 4.5, 4.5)
	markerPart.Material = Enum.Material.Neon
	markerPart.Color = Color3.fromRGB(255, 215, 58)
	markerPart.Transparency = 0.35
	markerPart.Anchored = true
	markerPart.CanCollide = false
	markerPart.CanQuery = false
	markerPart.CanTouch = false
	markerPart.Parent = Workspace

	local targetAtt = Instance.new("Attachment")
	targetAtt.Parent = markerPart

	local playerAtt: Attachment? = nil
	local beam = Instance.new("Beam")
	beam.Attachment1 = targetAtt
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 218, 65), Color3.fromRGB(95, 245, 255))
	beam.Transparency = NumberSequence.new(0.28)
	beam.Width0 = 0.45
	beam.Width1 = 0.75
	beam.LightEmission = 1
	beam.FaceCamera = true
	beam.Enabled = false
	beam.Parent = markerPart

	local userHidden = false
	local currentStepNum = 1
	local currentAssignedBaseId: number? = nil

	skipBtn.Activated:Connect(function()
		local stepDef = GameConfig.TutorialSteps[currentStepNum]
		if stepDef and stepDef.id == "learn_steal" then
			if callbacks.onCompleteStealGuide then
				callbacks.onCompleteStealGuide()
			end
		else
			if callbacks.onSkipTutorial then
				callbacks.onSkipTutorial()
			end
		end
	end)

	local function refreshVisibility()
		local stepDef = GameConfig.TutorialSteps[currentStepNum]
		local active = (stepDef ~= nil) and (not userHidden)
		card.Visible = active
		if not active then
			beam.Enabled = false
			markerPart.Transparency = 1
		end
	end

	RunService.RenderStepped:Connect(function()
		local stepDef = GameConfig.TutorialSteps[currentStepNum]
		if not stepDef or userHidden then
			beam.Enabled = false
			markerPart.Transparency = 1
			return
		end

		local targetPos = resolveTargetWorldPosition(stepDef.targetType, currentAssignedBaseId)
		local char = localPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not targetPos or not root then
			beam.Enabled = false
			markerPart.Transparency = 1
			return
		end

		if not playerAtt or playerAtt.Parent ~= root then
			if playerAtt then
				playerAtt:Destroy()
			end
			local att = Instance.new("Attachment")
			att.Name = "TutorialOriginAtt"
			att.Parent = root
			playerAtt = att
			beam.Attachment0 = att
		end

		markerPart.CFrame = CFrame.new(targetPos) * CFrame.Angles(0, 0, math.rad(90))
		markerPart.Transparency = 0.35
		beam.Enabled = true
	end)

	local api = {}

	function api.setScale(scale: number)
		uiScale.Scale = scale
	end

	function api.setUserVisible(visible: boolean)
		userHidden = not visible
		refreshVisibility()
	end

	function api.updateState(state: any)
		currentStepNum = state.tutorialStep or 1
		currentAssignedBaseId = state.assignedBaseId
		local stepDef = GameConfig.TutorialSteps[currentStepNum]
		if stepDef then
			stepHeader.Text = stepDef.title
			bodyText.Text = stepDef.instruction
			progFill.Size = UDim2.new((currentStepNum - 0.1) / #GameConfig.TutorialSteps, 0, 1, 0)
			skipBtn.Text = if stepDef.id == "learn_steal" then "DONE" else "SKIP"
		end
		refreshVisibility()
	end

	return api
end

return TutorialUI

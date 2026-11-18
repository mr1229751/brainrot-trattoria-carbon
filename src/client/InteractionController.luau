-- InteractionController.luau
-- Client-side tool activation bindings, contextual ProximityPrompt filtering,
-- animated conveyor chevron wave, Secret rainbow cycling, and client visual settings.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local FormatUtil = require(ReplicatedStorage:WaitForChild("FormatUtil"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local InteractionController = {}

local myAssignedBaseId: number? = nil
local currentTutorialStep = 1
local particlesEnabled = true
local farTagsEnabled = true
local boundTools: { [Tool]: boolean } = {}

local function bindToolActivation(tool: Tool, useToolRemote: RemoteEvent)
	if boundTools[tool] then
		return
	end
	if not tool:GetAttribute("ShopItemId") then
		return
	end
	boundTools[tool] = true

	tool.Activated:Connect(function()
		useToolRemote:FireServer()
		-- Snappy grip swing feedback
		local origGrip = tool.Grip
		tool.Grip = origGrip * CFrame.Angles(math.rad(-42), 0, 0)
		task.delay(0.16, function()
			if tool and tool.Parent then
				tool.Grip = origGrip
			end
		end)
	end)
end

local function applyParticlesSetting()
	for _, inst in ipairs(Workspace:GetDescendants()) do
		if inst:IsA("ParticleEmitter") then
			inst.Enabled = particlesEnabled
		end
	end
end

local function applyTagDistanceSetting()
	local dist = if farTagsEnabled then 320 else 130
	local creaturesFolder = Workspace:FindFirstChild("Creatures")
	if not creaturesFolder then
		return
	end
	for _, inst in ipairs(creaturesFolder:GetDescendants()) do
		if inst:IsA("BillboardGui") and inst.Name == "CreatureInfoBillboard" then
			inst.MaxDistance = dist
		end
	end
end

local function filterBasePromptsForLocalPlayer()
	if not myAssignedBaseId then
		return
	end
	local basesFolder = Workspace:FindFirstChild("PlayerBases")
	if not basesFolder then
		return
	end

	for _, inst in ipairs(basesFolder:GetDescendants()) do
		if inst:IsA("ProximityPrompt") then
			local role = inst:GetAttribute("PromptRole")
			local bId = inst:GetAttribute("BaseId")
			if role == "RivalSteal" and bId == myAssignedBaseId then
				inst.Enabled = false
			elseif role == "OwnerSell" and bId ~= myAssignedBaseId then
				inst.Enabled = false
			end
		end
	end
end

function InteractionController.applySetting(key: string, value: boolean)
	if key == "particles" then
		particlesEnabled = value
		applyParticlesSetting()
	elseif key == "farTags" then
		farTagsEnabled = value
		applyTagDistanceSetting()
	end
end

function InteractionController.onStateUpdated(state: any)
	myAssignedBaseId = state.assignedBaseId
	currentTutorialStep = state.tutorialStep or 1
	filterBasePromptsForLocalPlayer()
end

function InteractionController.init(remotesFolder: Folder)
	local localPlayer = Players.LocalPlayer
	local useToolRemote = remotesFolder:WaitForChild(GameConfig.Remotes.UseTool) :: RemoteEvent
	local tutActionRemote = remotesFolder:WaitForChild(GameConfig.Remotes.TutorialAction) :: RemoteEvent

	local function watchCharacter(character: Model)
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				bindToolActivation(child, useToolRemote)
			end
		end)
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") then
				bindToolActivation(child, useToolRemote)
			end
		end
	end

	localPlayer.CharacterAdded:Connect(watchCharacter)
	if localPlayer.Character then
		watchCharacter(localPlayer.Character)
	end

	Workspace.DescendantAdded:Connect(function(inst)
		if inst:IsA("ParticleEmitter") and not particlesEnabled then
			inst.Enabled = false
		elseif inst:IsA("BillboardGui") and inst.Name == "CreatureInfoBillboard" and not farTagsEnabled then
			inst.MaxDistance = 130
		end
	end)

	local promptFilterAcc = 0
	local shopProximitySent = false

	RunService.RenderStepped:Connect(function(dt: number)
		local now = os.clock()
		local rainbow = FormatUtil.getRainbowColor(now, 0)
		local rainbowAlt = FormatUtil.getRainbowColor(now, 0.33)

		-- 1. Secret rarity neon rainbow cycling
		for _, lbl in ipairs(CollectionService:GetTagged("RainbowText")) do
			if lbl:IsA("TextLabel") then
				lbl.TextColor3 = rainbow
			end
		end
		for _, st in ipairs(CollectionService:GetTagged("RainbowStroke")) do
			if st:IsA("UIStroke") then
				st.Color = rainbow
			end
		end
		for _, hl in ipairs(CollectionService:GetTagged("RainbowHighlight")) do
			if hl:IsA("Highlight") then
				hl.FillColor = rainbow
				hl.OutlineColor = rainbowAlt
			end
		end
		for _, part in ipairs(CollectionService:GetTagged("RainbowPart")) do
			if part:IsA("BasePart") then
				part.Color = rainbow
			end
		end

		-- 2. Animated directional conveyor chevron wave flowing South (+Z)
		local waveIndex = (now * 7.5)
		for _, arrow in ipairs(CollectionService:GetTagged("ConveyorArrow")) do
			if arrow:IsA("BasePart") then
				local order = arrow:GetAttribute("ArrowOrder") or 1
				local phase = math.sin(waveIndex - order * 0.75)
				local alpha = (phase + 1) * 0.5
				arrow.Color = FormatUtil.lerpColor(
					Color3.fromRGB(168, 122, 22),
					Color3.fromRGB(255, 244, 110),
					alpha
				)
			end
		end

		-- 3. Periodic lightweight prompt filter & physical Shop visit detection
		promptFilterAcc += dt
		if promptFilterAcc >= 0.4 then
			promptFilterAcc = 0
			filterBasePromptsForLocalPlayer()

			if currentTutorialStep == 6 and not shopProximitySent then
				local char = localPlayer.Character
				local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
				if root then
					local d = (root.Position - GameConfig.SpawnArea.EquipmentStallPos).Magnitude
					if d <= 24 then
						shopProximitySent = true
						tutActionRemote:FireServer("visit_shop")
					end
				end
			elseif currentTutorialStep ~= 6 then
				shopProximitySent = false
			end
		end
	end)
end

return InteractionController

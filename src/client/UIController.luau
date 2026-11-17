-- UIController.luau
-- Coordinates all StarterGui panels, responsive scaling, RemoteEvent state updates, and shortcuts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local UIController = {}

local latestState: any = {
	cash = 120,
	rebirths = 0,
	incomeMultiplier = 1,
	incomePerSecond = 0,
	assignedBaseId = nil,
	baseLocked = false,
	lockRemaining = 0,
	index = {},
	ownedItems = {},
	tutorialStep = 1,
}

local stateListeners: { (any) -> () } = {}
local settingCallback: ((string, boolean) -> ())? = nil

local function requireGuiModule(playerGui: PlayerGui, moduleName: string)
	local mod = StarterGui:FindFirstChild(moduleName) or playerGui:WaitForChild(moduleName, 10)
	if not mod then
		mod = StarterGui:WaitForChild(moduleName, 10)
	end
	return require(mod)
end

function UIController.onStateUpdated(fn: (any) -> ())
	table.insert(stateListeners, fn)
	fn(latestState)
end

function UIController.setSettingHandler(fn: (string, boolean) -> ())
	settingCallback = fn
end

function UIController.getState()
	return latestState
end

function UIController.init(remotesFolder: Folder)
	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

	local MainHUD = requireGuiModule(playerGui, "MainHUD")
	local ShopUI = requireGuiModule(playerGui, "ShopUI")
	local RebirthUI = requireGuiModule(playerGui, "RebirthUI")
	local IndexUI = requireGuiModule(playerGui, "IndexUI")
	local NotificationUI = requireGuiModule(playerGui, "NotificationUI")
	local TutorialUI = requireGuiModule(playerGui, "TutorialUI")

	local buyShopRemote = remotesFolder:WaitForChild(GameConfig.Remotes.BuyShopItem) :: RemoteEvent
	local reqRebirthRemote = remotesFolder:WaitForChild(GameConfig.Remotes.RequestRebirth) :: RemoteEvent
	local tutActionRemote = remotesFolder:WaitForChild(GameConfig.Remotes.TutorialAction) :: RemoteEvent
	local tpBaseRemote = remotesFolder:WaitForChild(GameConfig.Remotes.TeleportToBase) :: RemoteEvent
	local stateSyncRemote = remotesFolder:WaitForChild(GameConfig.Remotes.StateSync) :: RemoteEvent
	local notifyRemote = remotesFolder:WaitForChild(GameConfig.Remotes.Notify) :: RemoteEvent
	local popupRemote = remotesFolder:WaitForChild(GameConfig.Remotes.FloatingPopup) :: RemoteEvent

	local hudApi
	local shopApi
	local rebirthApi
	local indexApi
	local notifyApi = NotificationUI.mount(playerGui)
	local tutorialApi

	local function toggleExclusivePanel(panelId: string)
		local nextShop = (panelId == "shop") and (not shopApi.isVisible())
		local nextRebirth = (panelId == "rebirth") and (not rebirthApi.isVisible())
		local nextIndex = (panelId == "index") and (not indexApi.isVisible())
		local nextSettings = (panelId == "settings") and (not hudApi.isSettingsVisible())

		shopApi.setVisible(nextShop)
		rebirthApi.setVisible(nextRebirth)
		indexApi.setVisible(nextIndex)
		hudApi.setSettingsVisible(nextSettings)
	end

	hudApi = MainHUD.mount(playerGui, {
		onTogglePanel = toggleExclusivePanel,
		onTeleportHome = function()
			tpBaseRemote:FireServer()
		end,
		onSettingChanged = function(key: string, val: boolean)
			if key == "popups" then
				notifyApi.setPopupsEnabled(val)
			elseif key == "showTutorial" then
				tutorialApi.setUserVisible(val)
			end
			if settingCallback then
				settingCallback(key, val)
			end
		end,
	})

	shopApi = ShopUI.mount(playerGui, {
		onBuyItem = function(itemId: string)
			buyShopRemote:FireServer(itemId)
		end,
		onOpened = function()
			tutActionRemote:FireServer("visit_shop")
		end,
	})

	rebirthApi = RebirthUI.mount(playerGui, {
		onRequestRebirth = function()
			reqRebirthRemote:FireServer()
		end,
	})

	indexApi = IndexUI.mount(playerGui)

	tutorialApi = TutorialUI.mount(playerGui, {
		onSkipTutorial = function()
			tutActionRemote:FireServer("skip")
		end,
		onCompleteStealGuide = function()
			tutActionRemote:FireServer("complete_steal_guide")
		end,
	})

	-- Responsive viewport scaling across PC, tablet, and mobile
	local function updateResponsiveScale()
		local cam = Workspace.CurrentCamera
		if not cam then
			return
		end
		local vp = cam.ViewportSize
		if vp.X <= 0 or vp.Y <= 0 then
			return
		end
		local scale = math.clamp(math.min(vp.X / 1280, vp.Y / 720), 0.62, 1.12)
		hudApi.setScale(scale)
		shopApi.setScale(scale)
		rebirthApi.setScale(scale)
		indexApi.setScale(scale)
		notifyApi.setScale(scale)
		tutorialApi.setScale(scale)
	end

	local function bindCamera()
		local cam = Workspace.CurrentCamera
		if cam then
			cam:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveScale)
			updateResponsiveScale()
		end
	end
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
	bindCamera()

	-- Apply incoming server state
	stateSyncRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" then
			return
		end
		latestState = payload
		hudApi.updateState(payload)
		shopApi.updateState(payload)
		rebirthApi.updateState(payload)
		indexApi.updateState(payload)
		tutorialApi.updateState(payload)
		for _, fn in ipairs(stateListeners) do
			fn(payload)
		end
	end)

	notifyRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) == "table" and type(payload.message) == "string" then
			notifyApi.pushToast(payload.kind or "info", payload.message)
		end
	end)

	popupRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) == "table" and typeof(payload.position) == "Vector3" then
			notifyApi.spawnFloatingPopup(payload.position, tostring(payload.text or ""), payload.color)
		end
	end)

	-- Optional PC hotkeys (B = Shop, G = Rebirth, C = Index)
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then
			return
		end
		if input.KeyCode == Enum.KeyCode.B then
			toggleExclusivePanel("shop")
		elseif input.KeyCode == Enum.KeyCode.G then
			toggleExclusivePanel("rebirth")
		elseif input.KeyCode == Enum.KeyCode.C then
			toggleExclusivePanel("index")
		end
	end)
end

return UIController

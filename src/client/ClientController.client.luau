-- ClientController.client.luau
-- Client entry point initializing UIController, InteractionController, and initial state sync.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local UIController = require(script.Parent:WaitForChild("UIController"))
local InteractionController = require(script.Parent:WaitForChild("InteractionController"))

local remotesFolder = ReplicatedStorage:WaitForChild(GameConfig.Remotes.FolderName) :: Folder

UIController.setSettingHandler(function(key: string, val: boolean)
	InteractionController.applySetting(key, val)
end)

UIController.init(remotesFolder)
InteractionController.init(remotesFolder)

UIController.onStateUpdated(function(state: any)
	InteractionController.onStateUpdated(state)
end)

local reqInitRemote = remotesFolder:WaitForChild(GameConfig.Remotes.RequestInitialState) :: RemoteEvent
reqInitRemote:FireServer()

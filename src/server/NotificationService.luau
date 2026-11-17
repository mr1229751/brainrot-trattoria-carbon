-- NotificationService.luau
-- Dispatches clean toast notifications and 3D floating world popups to clients.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local NotificationService = {}

local notifyRemote: RemoteEvent? = nil
local popupRemote: RemoteEvent? = nil
local lastNotifyByKey: { [string]: number } = {}

function NotificationService.init(remotesFolder: Folder)
	notifyRemote = remotesFolder:FindFirstChild(GameConfig.Remotes.Notify) :: RemoteEvent
	popupRemote = remotesFolder:FindFirstChild(GameConfig.Remotes.FloatingPopup) :: RemoteEvent
end

-- kind: "success" | "cash" | "warning" | "error" | "alert" | "rebirth" | "info"
function NotificationService.send(player: Player, kind: string, message: string, throttleSeconds: number?)
	if not notifyRemote or not player or not player.Parent then
		return
	end
	if throttleSeconds and throttleSeconds > 0 then
		local key = tostring(player.UserId) .. ":" .. kind .. ":" .. message
		local now = os.clock()
		if lastNotifyByKey[key] and (now - lastNotifyByKey[key]) < throttleSeconds then
			return
		end
		lastNotifyByKey[key] = now
	end
	notifyRemote:FireClient(player, {
		kind = kind,
		message = message,
		timestamp = os.clock(),
	})
end

function NotificationService.broadcast(kind: string, message: string)
	if not notifyRemote then
		return
	end
	for _, player in ipairs(Players:GetPlayers()) do
		notifyRemote:FireClient(player, {
			kind = kind,
			message = message,
			timestamp = os.clock(),
		})
	end
end

function NotificationService.sendFloatingPopup(player: Player, worldPos: Vector3, textStr: string, color: Color3?)
	if not popupRemote or not player or not player.Parent then
		return
	end
	popupRemote:FireClient(player, {
		position = worldPos,
		text = textStr,
		color = color or Color3.fromRGB(85, 255, 130),
	})
end

function NotificationService.cleanupPlayer(userId: number)
	local prefix = tostring(userId) .. ":"
	for k in pairs(lastNotifyByKey) do
		if string.sub(k, 1, #prefix) == prefix then
			lastNotifyByKey[k] = nil
		end
	end
end

return NotificationService

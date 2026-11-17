-- NotificationUI.luau
-- Non-cluttered toast notification stack and rising 3D floating "+ $Cash" world popups.

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local NotificationUI = {}

local KIND_STYLES = {
	success = { border = Color3.fromRGB(72, 245, 128), bg = Color3.fromRGB(16, 44, 28) },
	cash = { border = Color3.fromRGB(95, 255, 145), bg = Color3.fromRGB(18, 48, 30) },
	warning = { border = Color3.fromRGB(255, 198, 52), bg = Color3.fromRGB(52, 36, 14) },
	error = { border = Color3.fromRGB(255, 68, 88), bg = Color3.fromRGB(56, 14, 24) },
	alert = { border = Color3.fromRGB(255, 52, 72), bg = Color3.fromRGB(72, 12, 22) },
	rebirth = { border = Color3.fromRGB(255, 218, 58), bg = Color3.fromRGB(58, 42, 12) },
	info = { border = Color3.fromRGB(85, 222, 255), bg = Color3.fromRGB(20, 32, 58) },
}

function NotificationUI.mount(playerGui: PlayerGui)
	local sg = Instance.new("ScreenGui")
	sg.Name = "NotificationGui"
	sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.DisplayOrder = 20
	sg.Parent = playerGui

	local uiScale = Instance.new("UIScale")
	uiScale.Parent = sg

	local stack = Instance.new("Frame")
	stack.Name = "ToastStack"
	stack.AnchorPoint = Vector2.new(0.5, 1)
	stack.Position = UDim2.new(0.5, 0, 1, -84)
	stack.Size = UDim2.new(0, 480, 0, 200)
	stack.BackgroundTransparency = 1
	stack.Parent = sg

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = stack

	local activeToasts: { Frame } = {}
	local toastOrder = 0
	local popupsEnabled = true

	local api = {}

	function api.setScale(scale: number)
		uiScale.Scale = scale
	end

	function api.setPopupsEnabled(enabled: boolean)
		popupsEnabled = enabled
	end

	function api.pushToast(kind: string, message: string)
		toastOrder += 1
		local style = KIND_STYLES[kind] or KIND_STYLES.info

		while #activeToasts >= 4 do
			local oldest = table.remove(activeToasts, 1)
			if oldest and oldest.Parent then
				oldest:Destroy()
			end
		end

		local card = Instance.new("Frame")
		card.Name = "Toast_" .. tostring(toastOrder)
		card.LayoutOrder = toastOrder
		card.Size = UDim2.new(0.96, 0, 0, 40)
		card.BackgroundColor3 = style.bg
		card.BackgroundTransparency = 0.08
		card.BorderSizePixel = 0
		card.Parent = stack

		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
		local st = Instance.new("UIStroke")
		st.Color = style.border
		st.Thickness = 2.2
		st.Parent = card

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(0.94, 0, 0.8, 0)
		lbl.Position = UDim2.new(0.03, 0, 0.1, 0)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBlack
		lbl.Text = message
		lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		lbl.TextScaled = true
		lbl.Parent = card

		local ts = Instance.new("UIStroke")
		ts.Color = Color3.fromRGB(8, 4, 16)
		ts.Thickness = 1.5
		ts.Parent = lbl

		table.insert(activeToasts, card)

		task.delay(3.4, function()
			if not card or not card.Parent then
				return
			end
			TweenService:Create(card, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(lbl, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
			TweenService:Create(st, TweenInfo.new(0.35), { Transparency = 1 }):Play()
			task.delay(0.38, function()
				local idx = table.find(activeToasts, card)
				if idx then
					table.remove(activeToasts, idx)
				end
				if card and card.Parent then
					card:Destroy()
				end
			end)
		end)
	end

	function api.spawnFloatingPopup(worldPos: Vector3, textStr: string, color: Color3?)
		if not popupsEnabled then
			return
		end

		local anchor = Instance.new("Part")
		anchor.Name = "FloatingCashAnchor"
		anchor.Size = Vector3.new(0.2, 0.2, 0.2)
		anchor.Transparency = 1
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanQuery = false
		anchor.CanTouch = false
		anchor.Position = worldPos
		anchor.Parent = Workspace

		local bb = Instance.new("BillboardGui")
		bb.Adornee = anchor
		bb.Size = UDim2.new(0, 210, 0, 52)
		bb.AlwaysOnTop = true
		bb.LightInfluence = 0
		bb.Parent = anchor

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBlack
		lbl.Text = textStr
		lbl.TextColor3 = color or Color3.fromRGB(85, 255, 132)
		lbl.TextScaled = true
		lbl.Parent = bb

		local st = Instance.new("UIStroke")
		st.Color = Color3.fromRGB(10, 24, 14)
		st.Thickness = 2.4
		st.Parent = lbl

		TweenService:Create(
			anchor,
			TweenInfo.new(1.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Position = worldPos + Vector3.new(0, 4.8, 0) }
		):Play()

		task.delay(0.65, function()
			if lbl and lbl.Parent then
				TweenService:Create(lbl, TweenInfo.new(0.45), { TextTransparency = 1 }):Play()
				TweenService:Create(st, TweenInfo.new(0.45), { Transparency = 1 }):Play()
			end
		end)

		Debris:AddItem(anchor, 1.25)
	end

	return api
end

return NotificationUI

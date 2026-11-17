-- ShopUI.luau
-- Equipment & Tools Shop modal supporting server-validated purchases and instant equipping.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FormatUtil = require(ReplicatedStorage:WaitForChild("FormatUtil"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))

local ShopUI = {}

function ShopUI.mount(playerGui: PlayerGui, callbacks: any)
	local sg = Instance.new("ScreenGui")
	sg.Name = "ShopGui"
	sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.DisplayOrder = 10
	sg.Parent = playerGui

	local uiScale = Instance.new("UIScale")
	uiScale.Parent = sg

	local modal = Instance.new("Frame")
	modal.Name = "ShopModal"
	modal.AnchorPoint = Vector2.new(0.5, 0.5)
	modal.Position = UDim2.fromScale(0.5, 0.52)
	modal.Size = UDim2.new(0, 630, 0, 430)
	modal.BackgroundColor3 = Color3.fromRGB(22, 12, 42)
	modal.BorderSizePixel = 0
	modal.Visible = false
	modal.Parent = sg

	Instance.new("UICorner", modal).CornerRadius = UDim.new(0, 16)
	local mStroke = Instance.new("UIStroke")
	mStroke.Color = Color3.fromRGB(255, 78, 175)
	mStroke.Thickness = 3
	mStroke.Parent = modal

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.76, 0, 0, 42)
	title.Position = UDim2.new(0.04, 0, 0, 12)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "EQUIPMENT & DEFENSE SHOP"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Parent = modal

	local closeBtn = Instance.new("TextButton")
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.Position = UDim2.new(1, -14, 0, 12)
	closeBtn.Size = UDim2.new(0, 40, 0, 40)
	closeBtn.BackgroundColor3 = Color3.fromRGB(225, 52, 78)
	closeBtn.Font = Enum.Font.GothamBlack
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextScaled = true
	closeBtn.Parent = modal
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
	closeBtn.Activated:Connect(function()
		modal.Visible = false
	end)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Position = UDim2.new(0.04, 0, 0, 66)
	scroll.Size = UDim2.new(0.92, 0, 0, 344)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 115, 205)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.Parent = modal

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 10)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = scroll

	local itemButtons: { [string]: TextButton } = {}

	for idx, item in ipairs(ShopConfig.Items) do
		local card = Instance.new("Frame")
		card.Name = "Card_" .. item.id
		card.LayoutOrder = idx
		card.Size = UDim2.new(1, -10, 0, 84)
		card.BackgroundColor3 = Color3.fromRGB(38, 22, 68)
		card.BorderSizePixel = 0
		card.Parent = scroll
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)

		local cStroke = Instance.new("UIStroke")
		cStroke.Color = item.accentColor
		cStroke.Thickness = 1.8
		cStroke.Parent = card

		-- Geometric emblem badge (built purely from native GUI frames)
		local badge = Instance.new("Frame")
		badge.Position = UDim2.new(0, 12, 0.5, -28)
		badge.Size = UDim2.new(0, 56, 0, 56)
		badge.BackgroundColor3 = Color3.fromRGB(24, 14, 44)
		badge.BorderSizePixel = 0
		badge.Parent = card
		Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 10)

		local diamond = Instance.new("Frame")
		diamond.AnchorPoint = Vector2.new(0.5, 0.5)
		diamond.Position = UDim2.fromScale(0.5, 0.5)
		diamond.Size = UDim2.new(0, 26, 0, 26)
		diamond.Rotation = 45
		diamond.BackgroundColor3 = item.accentColor
		diamond.BorderSizePixel = 0
		diamond.Parent = badge
		Instance.new("UICorner", diamond).CornerRadius = UDim.new(0, 5)

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Position = UDim2.new(0, 80, 0, 8)
		nameLbl.Size = UDim2.new(0.56, 0, 0, 26)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font = Enum.Font.GothamBlack
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.Text = item.name .. "  [" .. string.upper(item.category) .. "]"
		nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLbl.TextScaled = true
		nameLbl.Parent = card

		local descLbl = Instance.new("TextLabel")
		descLbl.Position = UDim2.new(0, 80, 0, 36)
		descLbl.Size = UDim2.new(0.58, 0, 0, 40)
		descLbl.BackgroundTransparency = 1
		descLbl.Font = Enum.Font.GothamMedium
		descLbl.TextXAlignment = Enum.TextXAlignment.Left
		descLbl.TextWrapped = true
		descLbl.Text = item.description
		descLbl.TextColor3 = Color3.fromRGB(208, 192, 238)
		descLbl.TextSize = 13
		descLbl.Parent = card

		local actionBtn = Instance.new("TextButton")
		actionBtn.Name = "ActionButton"
		actionBtn.AnchorPoint = Vector2.new(1, 0.5)
		actionBtn.Position = UDim2.new(1, -14, 0.5, 0)
		actionBtn.Size = UDim2.new(0, 132, 0, 48)
		actionBtn.BackgroundColor3 = Color3.fromRGB(48, 205, 102)
		actionBtn.Font = Enum.Font.GothamBlack
		actionBtn.Text = "BUY " .. FormatUtil.formatCash(item.price)
		actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		actionBtn.TextScaled = true
		actionBtn.Parent = card
		Instance.new("UICorner", actionBtn).CornerRadius = UDim.new(0, 10)

		actionBtn.Activated:Connect(function()
			if callbacks.onBuyItem then
				callbacks.onBuyItem(item.id)
			end
		end)

		itemButtons[item.id] = actionBtn
	end

	local api = {}

	function api.setScale(scale: number)
		uiScale.Scale = scale
	end

	function api.setVisible(visible: boolean)
		modal.Visible = visible
		if visible and callbacks.onOpened then
			callbacks.onOpened()
		end
	end

	function api.isVisible(): boolean
		return modal.Visible
	end

	function api.updateState(state: any)
		local cash = state.cash or 0
		local ownedItems = state.ownedItems or {}

		for _, item in ipairs(ShopConfig.Items) do
			local btn = itemButtons[item.id]
			if btn then
				if ownedItems[item.id] == true then
					btn.Text = "EQUIP"
					btn.BackgroundColor3 = Color3.fromRGB(52, 178, 255)
				elseif cash >= item.price then
					btn.Text = "BUY " .. FormatUtil.formatCash(item.price)
					btn.BackgroundColor3 = Color3.fromRGB(48, 208, 104)
				else
					btn.Text = FormatUtil.formatCash(item.price)
					btn.BackgroundColor3 = Color3.fromRGB(88, 68, 118)
				end
			end
		end
	end

	return api
end

return ShopUI

-- RebirthUI.luau
-- Golden Rebirth Shrine UI showing cash requirements, progress bar, and permanent reward previews.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage:WaitForChild("EconomyConfig"))
local FormatUtil = require(ReplicatedStorage:WaitForChild("FormatUtil"))

local RebirthUI = {}

function RebirthUI.mount(playerGui: PlayerGui, callbacks: any)
	local sg = Instance.new("ScreenGui")
	sg.Name = "RebirthGui"
	sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.DisplayOrder = 10
	sg.Parent = playerGui

	local uiScale = Instance.new("UIScale")
	uiScale.Parent = sg

	local modal = Instance.new("Frame")
	modal.Name = "RebirthModal"
	modal.AnchorPoint = Vector2.new(0.5, 0.5)
	modal.Position = UDim2.fromScale(0.5, 0.52)
	modal.Size = UDim2.new(0, 560, 0, 410)
	modal.BackgroundColor3 = Color3.fromRGB(28, 18, 44)
	modal.BorderSizePixel = 0
	modal.Visible = false
	modal.Parent = sg

	Instance.new("UICorner", modal).CornerRadius = UDim.new(0, 16)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 208, 48)
	stroke.Thickness = 3
	stroke.Parent = modal

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.8, 0, 0, 40)
	title.Position = UDim2.new(0.05, 0, 0, 12)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "GOLDEN REBIRTH SHRINE"
	title.TextColor3 = Color3.fromRGB(255, 218, 72)
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

	local tierLabel = Instance.new("TextLabel")
	tierLabel.Position = UDim2.new(0.05, 0, 0, 58)
	tierLabel.Size = UDim2.new(0.9, 0, 0, 30)
	tierLabel.BackgroundTransparency = 1
	tierLabel.Font = Enum.Font.GothamBlack
	tierLabel.Text = "REBIRTH #0  →  REBIRTH #1"
	tierLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	tierLabel.TextScaled = true
	tierLabel.Parent = modal

	-- Cash Requirement Progress Bar
	local barBg = Instance.new("Frame")
	barBg.Position = UDim2.new(0.05, 0, 0, 96)
	barBg.Size = UDim2.new(0.9, 0, 0, 34)
	barBg.BackgroundColor3 = Color3.fromRGB(16, 10, 28)
	barBg.BorderSizePixel = 0
	barBg.Parent = modal
	Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 10)

	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.new(0, 0, 1, 0)
	barFill.BackgroundColor3 = Color3.fromRGB(255, 198, 42)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
	Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 10)

	local barText = Instance.new("TextLabel")
	barText.Size = UDim2.fromScale(1, 1)
	barText.BackgroundTransparency = 1
	barText.Font = Enum.Font.GothamBlack
	barText.Text = "$0 / $25K"
	barText.TextColor3 = Color3.fromRGB(255, 255, 255)
	barText.TextSize = 16
	barText.Parent = barBg
	local bStroke = Instance.new("UIStroke")
	bStroke.Color = Color3.fromRGB(10, 5, 20)
	bStroke.Thickness = 1.6
	bStroke.Parent = barText

	-- 2x2 Reward Preview Grid
	local gridFrame = Instance.new("Frame")
	gridFrame.Position = UDim2.new(0.05, 0, 0, 144)
	gridFrame.Size = UDim2.new(0.9, 0, 0, 152)
	gridFrame.BackgroundTransparency = 1
	gridFrame.Parent = modal

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.485, 0, 0, 68)
	grid.CellPadding = UDim2.new(0.03, 0, 0, 12)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = gridFrame

	local function makeRewardTile(order: number, titleStr: string, accent: Color3): TextLabel
		local tile = Instance.new("Frame")
		tile.LayoutOrder = order
		tile.BackgroundColor3 = Color3.fromRGB(40, 24, 68)
		tile.BorderSizePixel = 0
		tile.Parent = gridFrame
		Instance.new("UICorner", tile).CornerRadius = UDim.new(0, 10)
		local ts = Instance.new("UIStroke")
		ts.Color = accent
		ts.Thickness = 1.6
		ts.Parent = tile

		local h = Instance.new("TextLabel")
		h.Position = UDim2.new(0.06, 0, 0.08, 0)
		h.Size = UDim2.new(0.88, 0, 0.36, 0)
		h.BackgroundTransparency = 1
		h.Font = Enum.Font.GothamBold
		h.Text = titleStr
		h.TextColor3 = Color3.fromRGB(205, 190, 238)
		h.TextScaled = true
		h.Parent = tile

		local v = Instance.new("TextLabel")
		v.Position = UDim2.new(0.06, 0, 0.48, 0)
		v.Size = UDim2.new(0.88, 0, 0.44, 0)
		v.BackgroundTransparency = 1
		v.Font = Enum.Font.GothamBlack
		v.Text = "--"
		v.TextColor3 = accent
		v.TextScaled = true
		v.Parent = tile
		return v
	end

	local multPreview = makeRewardTile(1, "PERMANENT INCOME", Color3.fromRGB(85, 255, 138))
	local speedPreview = makeRewardTile(2, "WALKSPEED BONUS", Color3.fromRGB(68, 228, 255))
	local lockPreview = makeRewardTile(3, "LASER LOCK DURATION", Color3.fromRGB(255, 98, 128))
	local luckPreview = makeRewardTile(4, "MUTATION LUCK", Color3.fromRGB(255, 212, 58))

	local note = Instance.new("TextLabel")
	note.Position = UDim2.new(0.05, 0, 0, 304)
	note.Size = UDim2.new(0.9, 0, 0, 24)
	note.BackgroundTransparency = 1
	note.Font = Enum.Font.GothamMedium
	note.Text = "Resets Cash & Base Slots • Keeps Collection Index & Shop Equipment!"
	note.TextColor3 = Color3.fromRGB(215, 198, 245)
	note.TextScaled = true
	note.Parent = modal

	local rebirthBtn = Instance.new("TextButton")
	rebirthBtn.AnchorPoint = Vector2.new(0.5, 1)
	rebirthBtn.Position = UDim2.new(0.5, 0, 1, -16)
	rebirthBtn.Size = UDim2.new(0.76, 0, 0, 52)
	rebirthBtn.BackgroundColor3 = Color3.fromRGB(255, 195, 38)
	rebirthBtn.Font = Enum.Font.GothamBlack
	rebirthBtn.Text = "REBIRTH NOW"
	rebirthBtn.TextColor3 = Color3.fromRGB(28, 16, 42)
	rebirthBtn.TextScaled = true
	rebirthBtn.Parent = modal
	Instance.new("UICorner", rebirthBtn).CornerRadius = UDim.new(0, 12)

	rebirthBtn.Activated:Connect(function()
		if callbacks.onRequestRebirth then
			callbacks.onRequestRebirth()
		end
	end)

	local api = {}

	function api.setScale(scale: number)
		uiScale.Scale = scale
	end

	function api.setVisible(visible: boolean)
		modal.Visible = visible
	end

	function api.isVisible(): boolean
		return modal.Visible
	end

	function api.updateState(state: any)
		local reb = state.rebirths or 0
		local cash = state.cash or 0
		local preview = EconomyConfig.getRebirthPreview(reb)

		tierLabel.Text = string.format("REBIRTH #%d   →   REBIRTH #%d", reb, preview.nextRebirth)

		local ratio = math.clamp(cash / math.max(1, preview.cost), 0, 1)
		barFill.Size = UDim2.new(ratio, 0, 1, 0)
		barText.Text = FormatUtil.formatCash(cash) .. " / " .. FormatUtil.formatCash(preview.cost)

		multPreview.Text = string.format("%.2fx  →  %.2fx", preview.currentMultiplier, preview.nextMultiplier)
		speedPreview.Text = string.format("+%d%%  →  +%d%%", preview.currentWalkSpeedPct, preview.nextWalkSpeedPct)
		lockPreview.Text = string.format("%ds  →  %ds", preview.currentLockSeconds, preview.nextLockSeconds)
		luckPreview.Text = string.format("+%d%%  →  +%d%%", preview.currentLuckPct, preview.nextLuckPct)

		if cash >= preview.cost then
			rebirthBtn.BackgroundColor3 = Color3.fromRGB(255, 205, 42)
			rebirthBtn.TextColor3 = Color3.fromRGB(24, 14, 38)
			rebirthBtn.Text = "ASCEND TO REBIRTH #" .. tostring(preview.nextRebirth) .. "!"
		else
			rebirthBtn.BackgroundColor3 = Color3.fromRGB(84, 68, 110)
			rebirthBtn.TextColor3 = Color3.fromRGB(215, 205, 235)
			rebirthBtn.Text = "NEED " .. FormatUtil.formatCash(preview.cost)
		end
	end

	return api
end

return RebirthUI

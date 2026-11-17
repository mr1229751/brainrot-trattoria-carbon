-- MainHUD.luau
-- Top-center currency/base HUD, left-side navigation column (safely below top-left Roblox controls),
-- stealing alert banner, and functional Settings modal.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FormatUtil = require(ReplicatedStorage:WaitForChild("FormatUtil"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local MainHUD = {}

local function styleFrame(frame: Frame, bg: Color3, strokeColor: Color3, radius: number, thickness: number?)
	frame.BackgroundColor3 = bg
	frame.BorderSizePixel = 0
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = frame
	local s = Instance.new("UIStroke")
	s.Color = strokeColor
	s.Thickness = thickness or 2
	s.Parent = frame
	return s
end

local function makeStatBox(parent: Instance, order: number, titleText: string, initVal: string, accent: Color3, widthScale: number)
	local box = Instance.new("Frame")
	box.Name = titleText .. "Box"
	box.LayoutOrder = order
	box.Size = UDim2.new(widthScale, -8, 1, -10)
	styleFrame(box, Color3.fromRGB(32, 18, 56), accent, 10, 2)
	box.Parent = parent

	local hdr = Instance.new("TextLabel")
	hdr.Size = UDim2.new(0.9, 0, 0.34, 0)
	hdr.Position = UDim2.new(0.05, 0, 0.06, 0)
	hdr.BackgroundTransparency = 1
	hdr.Font = Enum.Font.GothamBold
	hdr.Text = titleText
	hdr.TextColor3 = Color3.fromRGB(198, 178, 235)
	hdr.TextScaled = true
	hdr.Parent = box

	local val = Instance.new("TextLabel")
	val.Name = "ValueLabel"
	val.Size = UDim2.new(0.92, 0, 0.52, 0)
	val.Position = UDim2.new(0.04, 0, 0.42, 0)
	val.BackgroundTransparency = 1
	val.Font = Enum.Font.GothamBlack
	val.Text = initVal
	val.TextColor3 = accent
	val.TextScaled = true
	val.Parent = box

	local ts = Instance.new("UIStroke")
	ts.Color = Color3.fromRGB(10, 4, 20)
	ts.Thickness = 1.6
	ts.Parent = val

	return box, val
end

function MainHUD.mount(playerGui: PlayerGui, callbacks: any)
	local sg = Instance.new("ScreenGui")
	sg.Name = "MainHUDGui"
	sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.DisplayOrder = 5
	sg.Parent = playerGui

	local uiScale = Instance.new("UIScale")
	uiScale.Name = "ResponsiveScale"
	uiScale.Parent = sg

	-- 1. Top-Center Main Currency & Base Bar (leaves top-left completely clear)
	local topBar = Instance.new("Frame")
	topBar.Name = "TopCenterBar"
	topBar.AnchorPoint = Vector2.new(0.5, 0)
	topBar.Position = UDim2.new(0.5, 0, 0, 8)
	topBar.Size = UDim2.new(0, 650, 0, 64)
	styleFrame(topBar, Color3.fromRGB(20, 11, 38), GameConfig.Palette.ConveyorBorderGold, 14, 2.5)
	topBar.Parent = sg

	local topLayout = Instance.new("UIListLayout")
	topLayout.FillDirection = Enum.FillDirection.Horizontal
	topLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	topLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	topLayout.Padding = UDim.new(0, 8)
	topLayout.SortOrder = Enum.SortOrder.LayoutOrder
	topLayout.Parent = topBar

	local _, cashLabel = makeStatBox(topBar, 1, "CASH", "$120", Color3.fromRGB(78, 255, 130), 0.24)
	local _, incomeLabel = makeStatBox(topBar, 2, "INCOME", "$0/s", Color3.fromRGB(255, 215, 58), 0.23)
	local _, multLabel = makeStatBox(topBar, 3, "MULTIPLIER", "1.00x", Color3.fromRGB(205, 115, 255), 0.19)
	local baseBox, baseLabel = makeStatBox(topBar, 4, "MY BASE", "ASSIGNING...", Color3.fromRGB(85, 232, 255), 0.32)

	-- Quick Teleport-to-Base button inside Base Box
	baseLabel.Size = UDim2.new(0.68, 0, 0.52, 0)
	local homeBtn = Instance.new("TextButton")
	homeBtn.Name = "HomeTeleportButton"
	homeBtn.AnchorPoint = Vector2.new(1, 0.5)
	homeBtn.Position = UDim2.new(0.96, 0, 0.54, 0)
	homeBtn.Size = UDim2.new(0.26, 0, 0.68, 0)
	homeBtn.BackgroundColor3 = Color3.fromRGB(65, 165, 255)
	homeBtn.Font = Enum.Font.GothamBlack
	homeBtn.Text = "GO"
	homeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	homeBtn.TextScaled = true
	homeBtn.AutoButtonColor = true
	homeBtn.Parent = baseBox
	Instance.new("UICorner", homeBtn).CornerRadius = UDim.new(0, 6)

	homeBtn.Activated:Connect(function()
		if callbacks.onTeleportHome then
			callbacks.onTeleportHome()
		end
	end)

	-- 2. Stealing Active Warning Banner
	local stealBanner = Instance.new("Frame")
	stealBanner.Name = "StealActiveBanner"
	stealBanner.AnchorPoint = Vector2.new(0.5, 0)
	stealBanner.Position = UDim2.new(0.5, 0, 0, 78)
	stealBanner.Size = UDim2.new(0, 480, 0, 38)
	stealBanner.Visible = false
	styleFrame(stealBanner, Color3.fromRGB(88, 12, 24), Color3.fromRGB(255, 65, 85), 10, 2.5)
	stealBanner.Parent = sg

	local stealText = Instance.new("TextLabel")
	stealText.Size = UDim2.fromScale(0.96, 0.84)
	stealText.Position = UDim2.fromScale(0.02, 0.08)
	stealText.BackgroundTransparency = 1
	stealText.Font = Enum.Font.GothamBlack
	stealText.Text = "[STEALING!] SPRINT BACK INSIDE YOUR BASE!"
	stealText.TextColor3 = Color3.fromRGB(255, 238, 95)
	stealText.TextScaled = true
	stealText.Parent = stealBanner

	-- 3. Left-Side Vertical Navigation Column (positioned at Y = 54% to stay far clear of top-left Roblox controls)
	local navCol = Instance.new("Frame")
	navCol.Name = "LeftNavColumn"
	navCol.AnchorPoint = Vector2.new(0, 0.5)
	navCol.Position = UDim2.new(0, 16, 0.55, 0)
	navCol.Size = UDim2.new(0, 142, 0, 252)
	navCol.BackgroundTransparency = 1
	navCol.Parent = sg

	local navLayout = Instance.new("UIListLayout")
	navLayout.FillDirection = Enum.FillDirection.Vertical
	navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	navLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	navLayout.Padding = UDim.new(0, 10)
	navLayout.SortOrder = Enum.SortOrder.LayoutOrder
	navLayout.Parent = navCol

	local navButtons = {}
	local navDefs = {
		{ id = "shop", label = "SHOP", tag = "TOOLS", color = Color3.fromRGB(255, 72, 168), bg = Color3.fromRGB(58, 18, 48) },
		{ id = "rebirth", label = "REBIRTH", tag = "xMULTI", color = Color3.fromRGB(255, 208, 48), bg = Color3.fromRGB(64, 44, 14) },
		{ id = "index", label = "INDEX", tag = "0/18", color = Color3.fromRGB(65, 222, 255), bg = Color3.fromRGB(16, 46, 68) },
		{ id = "settings", label = "SETTINGS", tag = "OPTIONS", color = Color3.fromRGB(185, 125, 255), bg = Color3.fromRGB(38, 24, 68) },
	}

	for idx, def in ipairs(navDefs) do
		local btn = Instance.new("TextButton")
		btn.Name = def.id .. "NavButton"
		btn.LayoutOrder = idx
		btn.Size = UDim2.new(1, 0, 0, 54)
		btn.BackgroundColor3 = def.bg
		btn.AutoButtonColor = true
		btn.Text = ""
		btn.Parent = navCol

		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)
		local st = Instance.new("UIStroke")
		st.Color = def.color
		st.Thickness = 2.4
		st.Parent = btn

		local barAccent = Instance.new("Frame")
		barAccent.Size = UDim2.new(0, 6, 0.68, 0)
		barAccent.Position = UDim2.new(0, 7, 0.16, 0)
		barAccent.BackgroundColor3 = def.color
		barAccent.BorderSizePixel = 0
		barAccent.Parent = btn
		Instance.new("UICorner", barAccent).CornerRadius = UDim.new(1, 0)

		local titleLbl = Instance.new("TextLabel")
		titleLbl.Size = UDim2.new(0.82, 0, 0.5, 0)
		titleLbl.Position = UDim2.new(0, 20, 0.08, 0)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Font = Enum.Font.GothamBlack
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.Text = def.label
		titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		titleLbl.TextScaled = true
		titleLbl.Parent = btn

		local subLbl = Instance.new("TextLabel")
		subLbl.Name = "SubBadge"
		subLbl.Size = UDim2.new(0.82, 0, 0.34, 0)
		subLbl.Position = UDim2.new(0, 20, 0.58, 0)
		subLbl.BackgroundTransparency = 1
		subLbl.Font = Enum.Font.GothamBold
		subLbl.TextXAlignment = Enum.TextXAlignment.Left
		subLbl.Text = def.tag
		subLbl.TextColor3 = def.color
		subLbl.TextScaled = true
		subLbl.Parent = btn

		btn.Activated:Connect(function()
			if callbacks.onTogglePanel then
				callbacks.onTogglePanel(def.id)
			end
		end)

		navButtons[def.id] = { button = btn, subLabel = subLbl }
	end

	-- 4. Functional Settings Panel Modal
	local settingsModal = Instance.new("Frame")
	settingsModal.Name = "SettingsModal"
	settingsModal.AnchorPoint = Vector2.new(0.5, 0.5)
	settingsModal.Position = UDim2.fromScale(0.5, 0.52)
	settingsModal.Size = UDim2.new(0, 460, 0, 340)
	settingsModal.Visible = false
	styleFrame(settingsModal, Color3.fromRGB(24, 14, 44), Color3.fromRGB(185, 120, 255), 16, 3)
	settingsModal.Parent = sg

	local sHeader = Instance.new("TextLabel")
	sHeader.Size = UDim2.new(0.8, 0, 0, 40)
	sHeader.Position = UDim2.new(0.05, 0, 0, 12)
	sHeader.BackgroundTransparency = 1
	sHeader.Font = Enum.Font.GothamBlack
	sHeader.TextXAlignment = Enum.TextXAlignment.Left
	sHeader.Text = "GAME SETTINGS"
	sHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
	sHeader.TextScaled = true
	sHeader.Parent = settingsModal

	local closeSettings = Instance.new("TextButton")
	closeSettings.AnchorPoint = Vector2.new(1, 0)
	closeSettings.Position = UDim2.new(1, -14, 0, 12)
	closeSettings.Size = UDim2.new(0, 38, 0, 38)
	closeSettings.BackgroundColor3 = Color3.fromRGB(220, 52, 78)
	closeSettings.Font = Enum.Font.GothamBlack
	closeSettings.Text = "X"
	closeSettings.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeSettings.TextScaled = true
	closeSettings.Parent = settingsModal
	Instance.new("UICorner", closeSettings).CornerRadius = UDim.new(0, 8)
	closeSettings.Activated:Connect(function()
		settingsModal.Visible = false
	end)

	local sList = Instance.new("Frame")
	sList.Position = UDim2.new(0.05, 0, 0, 64)
	sList.Size = UDim2.new(0.9, 0, 0, 256)
	sList.BackgroundTransparency = 1
	sList.Parent = settingsModal

	local sLayout = Instance.new("UIListLayout")
	sLayout.Padding = UDim.new(0, 10)
	sLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sLayout.Parent = sList

	local settingsState = {
		particles = true,
		popups = true,
		farTags = true,
		showTutorial = true,
	}

	local function addToggleRow(order: number, key: string, labelText: string)
		local row = Instance.new("Frame")
		row.LayoutOrder = order
		row.Size = UDim2.new(1, 0, 0, 50)
		styleFrame(row, Color3.fromRGB(38, 22, 68), Color3.fromRGB(115, 78, 175), 10, 1.5)
		row.Parent = sList

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(0.65, 0, 0.7, 0)
		lbl.Position = UDim2.new(0.04, 0, 0.15, 0)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBold
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Text = labelText
		lbl.TextColor3 = Color3.fromRGB(240, 235, 255)
		lbl.TextScaled = true
		lbl.Parent = row

		local tBtn = Instance.new("TextButton")
		tBtn.AnchorPoint = Vector2.new(1, 0.5)
		tBtn.Position = UDim2.new(0.96, 0, 0.5, 0)
		tBtn.Size = UDim2.new(0.25, 0, 0.72, 0)
		tBtn.Font = Enum.Font.GothamBlack
		tBtn.TextScaled = true
		tBtn.Parent = row
		Instance.new("UICorner", tBtn).CornerRadius = UDim.new(0, 8)

		local function refreshBtn()
			local on = settingsState[key]
			tBtn.Text = if on then "ON" else "OFF"
			tBtn.BackgroundColor3 = if on then Color3.fromRGB(52, 210, 105) else Color3.fromRGB(95, 72, 125)
			tBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
		refreshBtn()

		tBtn.Activated:Connect(function()
			settingsState[key] = not settingsState[key]
			refreshBtn()
			if callbacks.onSettingChanged then
				callbacks.onSettingChanged(key, settingsState[key])
			end
		end)
	end

	addToggleRow(1, "particles", "World Aura Particles")
	addToggleRow(2, "popups", "Floating +$Cash Popups")
	addToggleRow(3, "farTags", "Extended Creature Tag Range")
	addToggleRow(4, "showTutorial", "Show Objective Guide")

	local api = {}

	function api.setScale(scale: number)
		uiScale.Scale = scale
	end

	function api.setSettingsVisible(visible: boolean)
		settingsModal.Visible = visible
	end

	function api.isSettingsVisible(): boolean
		return settingsModal.Visible
	end

	function api.updateState(state: any)
		cashLabel.Text = FormatUtil.formatCash(state.cash or 0)
		incomeLabel.Text = FormatUtil.formatRate(state.incomePerSecond or 0)
		multLabel.Text = string.format("%.2fx", state.incomeMultiplier or 1)

		if state.assignedBaseId then
			local bText = "BASE #" .. tostring(state.assignedBaseId)
			if state.baseLocked then
				baseLabel.Text = bText .. " • LOCK " .. FormatUtil.formatTimer(state.lockRemaining or 0)
				baseLabel.TextColor3 = Color3.fromRGB(255, 92, 110)
			else
				baseLabel.Text = bText .. " • OPEN"
				baseLabel.TextColor3 = Color3.fromRGB(85, 238, 255)
			end
		else
			baseLabel.Text = "NO BASE"
		end

		stealBanner.Visible = state.isStealing == true

		-- Update Index discovered count badge
		local discCount = 0
		if type(state.index) == "table" then
			for _, entry in pairs(state.index) do
				if type(entry) == "table" and entry.discovered then
					discCount += 1
				end
			end
		end
		if navButtons.index then
			navButtons.index.subLabel.Text = tostring(discCount) .. "/18"
		end
	end

	return api
end

return MainHUD

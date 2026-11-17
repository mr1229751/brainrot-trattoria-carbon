-- IndexUI.luau
-- Persistent Collection Index panel displaying all 18 creatures, discovery progress,
-- rarity filter pills, mutation badges, and locked silhouettes for undiscovered entries.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CreatureConfig = require(ReplicatedStorage:WaitForChild("CreatureConfig"))
local FormatUtil = require(ReplicatedStorage:WaitForChild("FormatUtil"))
local MutationConfig = require(ReplicatedStorage:WaitForChild("MutationConfig"))

local IndexUI = {}

function IndexUI.mount(playerGui: PlayerGui)
	local sg = Instance.new("ScreenGui")
	sg.Name = "IndexGui"
	sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.DisplayOrder = 10
	sg.Parent = playerGui

	local uiScale = Instance.new("UIScale")
	uiScale.Parent = sg

	local modal = Instance.new("Frame")
	modal.Name = "IndexModal"
	modal.AnchorPoint = Vector2.new(0.5, 0.5)
	modal.Position = UDim2.fromScale(0.5, 0.52)
	modal.Size = UDim2.new(0, 690, 0, 460)
	modal.BackgroundColor3 = Color3.fromRGB(20, 12, 38)
	modal.BorderSizePixel = 0
	modal.Visible = false
	modal.Parent = sg

	Instance.new("UICorner", modal).CornerRadius = UDim.new(0, 16)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(65, 224, 255)
	stroke.Thickness = 3
	stroke.Parent = modal

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.55, 0, 0, 38)
	title.Position = UDim2.new(0.04, 0, 0, 12)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "BRAINROT COLLECTION INDEX"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Parent = modal

	local progressText = Instance.new("TextLabel")
	progressText.Position = UDim2.new(0.60, 0, 0, 16)
	progressText.Size = UDim2.new(0.28, 0, 0, 30)
	progressText.BackgroundTransparency = 1
	progressText.Font = Enum.Font.GothamBlack
	progressText.TextXAlignment = Enum.TextXAlignment.Right
	progressText.Text = "0 / 18 (0%)"
	progressText.TextColor3 = Color3.fromRGB(85, 245, 255)
	progressText.TextScaled = true
	progressText.Parent = modal

	local closeBtn = Instance.new("TextButton")
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.Position = UDim2.new(1, -14, 0, 12)
	closeBtn.Size = UDim2.new(0, 38, 0, 38)
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

	-- Progress Bar
	local pBarBg = Instance.new("Frame")
	pBarBg.Position = UDim2.new(0.04, 0, 0, 56)
	pBarBg.Size = UDim2.new(0.92, 0, 0, 14)
	pBarBg.BackgroundColor3 = Color3.fromRGB(12, 8, 24)
	pBarBg.BorderSizePixel = 0
	pBarBg.Parent = modal
	Instance.new("UICorner", pBarBg).CornerRadius = UDim.new(1, 0)

	local pBarFill = Instance.new("Frame")
	pBarFill.Size = UDim2.new(0, 0, 1, 0)
	pBarFill.BackgroundColor3 = Color3.fromRGB(65, 224, 255)
	pBarFill.BorderSizePixel = 0
	pBarFill.Parent = pBarBg
	Instance.new("UICorner", pBarFill).CornerRadius = UDim.new(1, 0)

	-- Rarity Filter Bar
	local filterRow = Instance.new("Frame")
	filterRow.Position = UDim2.new(0.04, 0, 0, 78)
	filterRow.Size = UDim2.new(0.92, 0, 0, 32)
	filterRow.BackgroundTransparency = 1
	filterRow.Parent = modal

	local fLayout = Instance.new("UIListLayout")
	fLayout.FillDirection = Enum.FillDirection.Horizontal
	fLayout.Padding = UDim.new(0, 8)
	fLayout.SortOrder = Enum.SortOrder.LayoutOrder
	fLayout.Parent = filterRow

	local activeFilter = "ALL"
	local filterButtons = {}
	local cardsById = {}

	local function applyFilter()
		for cid, rec in pairs(cardsById) do
			local cDef = CreatureConfig.getCreature(cid)
			local rOrder = CreatureConfig.getRarityInfo(cDef.Rarity).order
			local show = true
			if activeFilter == "COMMON" then
				show = rOrder <= 3
			elseif activeFilter == "EPIC" then
				show = rOrder >= 4 and rOrder <= 6
			elseif activeFilter == "SECRET" then
				show = rOrder == 7
			end
			rec.card.Visible = show
		end
		for fId, btn in pairs(filterButtons) do
			btn.BackgroundColor3 = if fId == activeFilter
				then Color3.fromRGB(72, 185, 255)
				else Color3.fromRGB(38, 24, 68)
		end
	end

	local filters = {
		{ id = "ALL", text = "ALL (18)" },
		{ id = "COMMON", text = "COMMON - RARE" },
		{ id = "EPIC", text = "EPIC - MYTHIC" },
		{ id = "SECRET", text = "SECRETS" },
	}
	for idx, f in ipairs(filters) do
		local b = Instance.new("TextButton")
		b.LayoutOrder = idx
		b.Size = UDim2.new(0.235, 0, 1, 0)
		b.Font = Enum.Font.GothamBlack
		b.Text = f.text
		b.TextColor3 = Color3.fromRGB(255, 255, 255)
		b.TextScaled = true
		b.Parent = filterRow
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
		filterButtons[f.id] = b
		b.Activated:Connect(function()
			activeFilter = f.id
			applyFilter()
		end)
	end

	-- Scrollable 3-column Creature Grid
	local gridScroll = Instance.new("ScrollingFrame")
	gridScroll.Position = UDim2.new(0.04, 0, 0, 118)
	gridScroll.Size = UDim2.new(0.92, 0, 0, 324)
	gridScroll.BackgroundTransparency = 1
	gridScroll.BorderSizePixel = 0
	gridScroll.ScrollBarThickness = 6
	gridScroll.ScrollBarImageColor3 = Color3.fromRGB(65, 224, 255)
	gridScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	gridScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	gridScroll.Parent = modal

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.315, 0, 0, 146)
	grid.CellPadding = UDim2.new(0.02, 0, 0, 10)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = gridScroll

	for orderIdx, cDef in ipairs(CreatureConfig.Roster) do
		local rInfo = CreatureConfig.getRarityInfo(cDef.Rarity)

		local card = Instance.new("Frame")
		card.Name = "IndexCard_" .. cDef.CreatureID
		card.LayoutOrder = orderIdx
		card.BackgroundColor3 = Color3.fromRGB(34, 20, 60)
		card.BorderSizePixel = 0
		card.Parent = gridScroll
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)

		local cStroke = Instance.new("UIStroke")
		cStroke.Color = rInfo.color
		cStroke.Thickness = 2
		cStroke.Parent = card

		-- Silhouette / Avatar Portrait Box
		local portrait = Instance.new("Frame")
		portrait.Position = UDim2.new(0.06, 0, 0, 8)
		portrait.Size = UDim2.new(0, 44, 0, 44)
		portrait.BackgroundColor3 = Color3.fromRGB(16, 10, 28)
		portrait.BorderSizePixel = 0
		portrait.Parent = card
		Instance.new("UICorner", portrait).CornerRadius = UDim.new(0, 8)

		local silHead = Instance.new("Frame")
		silHead.AnchorPoint = Vector2.new(0.5, 0.5)
		silHead.Position = UDim2.fromScale(0.5, 0.36)
		silHead.Size = UDim2.new(0, 16, 0, 16)
		silHead.BackgroundColor3 = Color3.fromRGB(8, 5, 14)
		silHead.BorderSizePixel = 0
		silHead.Parent = portrait
		Instance.new("UICorner", silHead).CornerRadius = UDim.new(1, 0)

		local silBody = Instance.new("Frame")
		silBody.AnchorPoint = Vector2.new(0.5, 1)
		silBody.Position = UDim2.fromScale(0.5, 0.88)
		silBody.Size = UDim2.new(0, 26, 0, 16)
		silBody.BackgroundColor3 = Color3.fromRGB(8, 5, 14)
		silBody.BorderSizePixel = 0
		silBody.Parent = portrait
		Instance.new("UICorner", silBody).CornerRadius = UDim.new(0, 6)

		local rarityLbl = Instance.new("TextLabel")
		rarityLbl.Position = UDim2.new(0, 58, 0, 8)
		rarityLbl.Size = UDim2.new(1, -66, 0, 18)
		rarityLbl.BackgroundTransparency = 1
		rarityLbl.Font = Enum.Font.GothamBlack
		rarityLbl.TextXAlignment = Enum.TextXAlignment.Left
		rarityLbl.Text = string.upper(rInfo.name)
		rarityLbl.TextColor3 = rInfo.color
		rarityLbl.TextScaled = true
		rarityLbl.Parent = card

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Position = UDim2.new(0, 58, 0, 26)
		nameLbl.Size = UDim2.new(1, -66, 0, 24)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font = Enum.Font.GothamBlack
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.Text = "???"
		nameLbl.TextColor3 = Color3.fromRGB(160, 145, 190)
		nameLbl.TextScaled = true
		nameLbl.Parent = card

		local statsLbl = Instance.new("TextLabel")
		statsLbl.Position = UDim2.new(0.06, 0, 0, 56)
		statsLbl.Size = UDim2.new(0.88, 0, 0, 22)
		statsLbl.BackgroundTransparency = 1
		statsLbl.Font = Enum.Font.GothamBold
		statsLbl.TextXAlignment = Enum.TextXAlignment.Left
		statsLbl.Text = "LOCKED SILHOUETTE"
		statsLbl.TextColor3 = Color3.fromRGB(128, 112, 162)
		statsLbl.TextScaled = true
		statsLbl.Parent = card

		local descLbl = Instance.new("TextLabel")
		descLbl.Position = UDim2.new(0.06, 0, 0, 80)
		descLbl.Size = UDim2.new(0.88, 0, 0, 32)
		descLbl.BackgroundTransparency = 1
		descLbl.Font = Enum.Font.GothamMedium
		descLbl.TextXAlignment = Enum.TextXAlignment.Left
		descLbl.TextWrapped = true
		descLbl.Text = "Obtain from Conveyor or Steal to unlock!"
		descLbl.TextColor3 = Color3.fromRGB(150, 138, 182)
		descLbl.TextSize = 11
		descLbl.Parent = card

		-- Mutation badges row (RAD / GOLD / VOID)
		local mutRow = Instance.new("Frame")
		mutRow.Position = UDim2.new(0.06, 0, 1, -26)
		mutRow.Size = UDim2.new(0.88, 0, 0, 20)
		mutRow.BackgroundTransparency = 1
		mutRow.Parent = card

		local mList = Instance.new("UIListLayout")
		mList.FillDirection = Enum.FillDirection.Horizontal
		mList.Padding = UDim.new(0, 6)
		mList.Parent = mutRow

		local mutPills = {}
		for _, mName in ipairs(MutationConfig.OrderedNames) do
			local mInfo = MutationConfig.getMutationInfo(mName)
			local pill = Instance.new("TextLabel")
			pill.Size = UDim2.new(0.30, 0, 1, 0)
			pill.BackgroundColor3 = Color3.fromRGB(20, 12, 34)
			pill.Font = Enum.Font.GothamBlack
			pill.Text = mInfo.shortBadge
			pill.TextColor3 = Color3.fromRGB(82, 72, 108)
			pill.TextScaled = true
			pill.Parent = mutRow
			Instance.new("UICorner", pill).CornerRadius = UDim.new(0, 5)
			mutPills[mName] = pill
		end

		cardsById[cDef.CreatureID] = {
			card = card,
			cStroke = cStroke,
			silHead = silHead,
			silBody = silBody,
			nameLbl = nameLbl,
			statsLbl = statsLbl,
			descLbl = descLbl,
			mutPills = mutPills,
			def = cDef,
			rInfo = rInfo,
		}
	end

	applyFilter()

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
		local indexMap = state.index or {}
		local discoveredTotal = 0
		local totalCount = #CreatureConfig.Roster

		for cid, uiRec in pairs(cardsById) do
			local entry = indexMap[cid]
			local isDiscovered = type(entry) == "table" and entry.discovered == true
			if isDiscovered then
				discoveredTotal += 1
				uiRec.card.BackgroundColor3 = Color3.fromRGB(42, 26, 74)
				uiRec.cStroke.Color = uiRec.rInfo.color
				uiRec.silHead.BackgroundColor3 = uiRec.rInfo.color
				uiRec.silBody.BackgroundColor3 = uiRec.rInfo.color
				uiRec.nameLbl.Text = uiRec.def.DisplayName
				uiRec.nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
				uiRec.statsLbl.Text = FormatUtil.formatRate(uiRec.def.IncomePerSecond) .. " • " .. FormatUtil.formatCash(uiRec.def.PurchasePrice)
				uiRec.statsLbl.TextColor3 = Color3.fromRGB(85, 255, 138)
				uiRec.descLbl.Text = uiRec.def.Description

				local muts = entry.mutations or {}
				for mName, pill in pairs(uiRec.mutPills) do
					local mInfo = MutationConfig.getMutationInfo(mName)
					if muts[mName] == true then
						pill.BackgroundColor3 = mInfo.color
						pill.TextColor3 = Color3.fromRGB(18, 10, 28)
					else
						pill.BackgroundColor3 = Color3.fromRGB(22, 14, 38)
						pill.TextColor3 = Color3.fromRGB(88, 78, 116)
					end
				end
			else
				uiRec.card.BackgroundColor3 = Color3.fromRGB(24, 15, 42)
				uiRec.cStroke.Color = Color3.fromRGB(68, 52, 98)
				uiRec.silHead.BackgroundColor3 = Color3.fromRGB(8, 5, 14)
				uiRec.silBody.BackgroundColor3 = Color3.fromRGB(8, 5, 14)
				uiRec.nameLbl.Text = "???"
				uiRec.nameLbl.TextColor3 = Color3.fromRGB(132, 118, 165)
				uiRec.statsLbl.Text = "LOCKED SILHOUETTE"
				uiRec.statsLbl.TextColor3 = Color3.fromRGB(115, 100, 148)
				uiRec.descLbl.Text = "Obtain this " .. uiRec.def.Rarity .. " brainrot to unlock!"
				for _, pill in pairs(uiRec.mutPills) do
					pill.BackgroundColor3 = Color3.fromRGB(18, 11, 32)
					pill.TextColor3 = Color3.fromRGB(68, 58, 92)
				end
			end
		end

		local pct = math.floor((discoveredTotal / math.max(1, totalCount)) * 100 + 0.5)
		progressText.Text = string.format("%d / %d (%d%%)", discoveredTotal, totalCount, pct)
		pBarFill.Size = UDim2.new(discoveredTotal / math.max(1, totalCount), 0, 1, 0)
	end

	return api
end

return IndexUI

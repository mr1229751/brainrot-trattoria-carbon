-- ShopConfig.luau
-- Equipment shop items, stats, and 3D primitive builders for held Tools and Stall displays.

local ShopConfig = {}

ShopConfig.Items = {
	{
		id = "slap_hand",
		name = "Turbo Slap Glove",
		category = "Offense / Defense",
		price = 250,
		cooldown = 1.1,
		description = "Giant neon foam glove! Click to slap rivals flying and instantly stop thieves!",
		accentColor = Color3.fromRGB(255, 75, 195),
		speedMultiplier = 1.0,
		jumpPower = 52,
	},
	{
		id = "speed_coil",
		name = "Neon Speed Coil",
		category = "Mobility",
		price = 1200,
		cooldown = 0.5,
		description = "Hold to boost your WalkSpeed by +45%! Chase down thieves or sprint the conveyor!",
		accentColor = Color3.fromRGB(55, 230, 255),
		speedMultiplier = 1.45,
		jumpPower = 52,
	},
	{
		id = "shock_trap",
		name = "Laser Shock Trap",
		category = "Base Trap",
		price = 3500,
		cooldown = 3.0,
		description = "Click to place an armed plasma trap (max 2). Zaps intruders and drops stolen brainrots!",
		accentColor = Color3.fromRGB(255, 210, 45),
		speedMultiplier = 1.0,
		jumpPower = 52,
	},
	{
		id = "repulsor_baton",
		name = "Guardian Repulsor",
		category = "Base Defense",
		price = 12000,
		cooldown = 4.0,
		description = "Defensive shockwave baton! Click to blast all nearby rivals back 14 studs and foil steals!",
		accentColor = Color3.fromRGB(95, 255, 145),
		speedMultiplier = 1.10,
		jumpPower = 52,
	},
	{
		id = "gravity_coil",
		name = "Cosmic Gravity Coil",
		category = "Mobility",
		price = 30000,
		cooldown = 0.5,
		description = "Anti-gravity coil granting +30% WalkSpeed and super high jumps across the arena!",
		accentColor = Color3.fromRGB(185, 95, 255),
		speedMultiplier = 1.30,
		jumpPower = 78,
	},
}

ShopConfig.ById = {}
for _, item in ipairs(ShopConfig.Items) do
	ShopConfig.ById[item.id] = item
end

function ShopConfig.getItem(itemId: string)
	return ShopConfig.ById[itemId]
end

local function addToolPart(
	parent: Instance,
	handle: BasePart,
	name: string,
	shape: Enum.PartType,
	size: Vector3,
	offsetCF: CFrame,
	color: Color3,
	material: Enum.Material,
	anchored: boolean
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape
	p.Size = size
	p.Color = color
	p.Material = material
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.Anchored = anchored
	p.CFrame = handle.CFrame * offsetCF
	p.Parent = parent

	if not anchored then
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = p
		weld.Parent = p
	end
	return p
end

local function populateGeometry(container: Instance, handle: BasePart, itemId: string, anchored: boolean)
	if itemId == "slap_hand" then
		-- Grip shaft + giant foam palm + 4 fingers + thumb
		addToolPart(container, handle, "Palm", Enum.PartType.Block, Vector3.new(0.45, 1.8, 1.5), CFrame.new(0, 1.35, 0), Color3.fromRGB(255, 65, 185), Enum.Material.SmoothPlastic, anchored)
		addToolPart(container, handle, "PalmGlow", Enum.PartType.Cylinder, Vector3.new(0.5, 0.9, 0.9), CFrame.new(0, 1.3, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 225, 75), Enum.Material.Neon, anchored)
		for i = -1.5, 1.5, 1 do
			addToolPart(container, handle, "Finger", Enum.PartType.Block, Vector3.new(0.38, 0.95, 0.3), CFrame.new(0, 2.55, i * 0.36), Color3.fromRGB(255, 85, 200), Enum.Material.SmoothPlastic, anchored)
		end
		addToolPart(container, handle, "Thumb", Enum.PartType.Block, Vector3.new(0.38, 0.75, 0.32), CFrame.new(0, 1.25, -0.95) * CFrame.Angles(math.rad(-35), 0, 0), Color3.fromRGB(255, 85, 200), Enum.Material.SmoothPlastic, anchored)

	elseif itemId == "speed_coil" then
		for i = -2, 2 do
			addToolPart(container, handle, "CoilRing", Enum.PartType.Cylinder, Vector3.new(0.22, 1.35, 1.35), CFrame.new(0, i * 0.34, 0) * CFrame.Angles(math.rad(15), 0, math.rad(90)), Color3.fromRGB(55, 235, 255), Enum.Material.Neon, anchored)
		end
		addToolPart(container, handle, "CoreBar", Enum.PartType.Cylinder, Vector3.new(1.8, 0.35, 0.35), CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 210, 55), Enum.Material.Metal, anchored)

	elseif itemId == "shock_trap" then
		addToolPart(container, handle, "TrapDisc", Enum.PartType.Cylinder, Vector3.new(0.38, 1.9, 1.9), CFrame.new(0, 0.4, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(48, 36, 72), Enum.Material.Metal, anchored)
		addToolPart(container, handle, "TrapCore", Enum.PartType.Cylinder, Vector3.new(0.46, 0.95, 0.95), CFrame.new(0, 0.45, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 215, 45), Enum.Material.Neon, anchored)
		for a = 0, 3 do
			local ang = math.rad(a * 90 + 45)
			addToolPart(container, handle, "Prong", Enum.PartType.Block, Vector3.new(0.24, 0.55, 0.24), CFrame.new(math.cos(ang) * 0.68, 0.72, math.sin(ang) * 0.68), Color3.fromRGB(255, 65, 95), Enum.Material.Neon, anchored)
		end

	elseif itemId == "repulsor_baton" then
		addToolPart(container, handle, "Guard", Enum.PartType.Block, Vector3.new(0.55, 0.25, 1.1), CFrame.new(0, 0.55, 0), Color3.fromRGB(255, 205, 55), Enum.Material.Metal, anchored)
		addToolPart(container, handle, "Shaft", Enum.PartType.Cylinder, Vector3.new(2.1, 0.38, 0.38), CFrame.new(0, 1.65, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(45, 55, 85), Enum.Material.Metal, anchored)
		addToolPart(container, handle, "EmitterTip", Enum.PartType.Ball, Vector3.new(0.85, 0.85, 0.85), CFrame.new(0, 2.75, 0), Color3.fromRGB(85, 255, 155), Enum.Material.Neon, anchored)
		addToolPart(container, handle, "EnergyFin1", Enum.PartType.Block, Vector3.new(0.15, 1.5, 0.75), CFrame.new(0, 1.75, 0), Color3.fromRGB(85, 255, 155), Enum.Material.Neon, anchored)

	elseif itemId == "gravity_coil" then
		for i = -2, 2 do
			addToolPart(container, handle, "GravRing", Enum.PartType.Cylinder, Vector3.new(0.22, 1.45, 1.45), CFrame.new(0, i * 0.36, 0) * CFrame.Angles(math.rad(-18), 0, math.rad(90)), Color3.fromRGB(190, 85, 255), Enum.Material.Neon, anchored)
		end
		addToolPart(container, handle, "GravOrb", Enum.PartType.Ball, Vector3.new(0.65, 0.65, 0.65), CFrame.new(0, 0.95, 0), Color3.fromRGB(255, 120, 255), Enum.Material.Neon, anchored)
	end
end

function ShopConfig.buildTool(itemId: string): Tool?
	local info = ShopConfig.getItem(itemId)
	if not info then
		return nil
	end

	local tool = Instance.new("Tool")
	tool.Name = info.name
	tool.ToolTip = info.description
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool:SetAttribute("ShopItemId", info.id)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.42, 1.15, 0.42)
	handle.Color = Color3.fromRGB(42, 30, 62)
	handle.Material = Enum.Material.SmoothPlastic
	handle.CanCollide = false
	handle.Massless = true
	handle.CFrame = CFrame.new(0, 0, 0)
	handle.Parent = tool

	populateGeometry(tool, handle, itemId, false)
	return tool
end

function ShopConfig.buildDisplayModel(itemId: string, worldCF: CFrame): Model?
	local info = ShopConfig.getItem(itemId)
	if not info then
		return nil
	end

	local model = Instance.new("Model")
	model.Name = "Display_" .. itemId

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.42, 1.15, 0.42)
	handle.Color = Color3.fromRGB(42, 30, 62)
	handle.Material = Enum.Material.SmoothPlastic
	handle.Anchored = true
	handle.CanCollide = false
	handle.CFrame = worldCF
	handle.Parent = model
	model.PrimaryPart = handle

	populateGeometry(model, handle, itemId, true)
	return model
end

return ShopConfig

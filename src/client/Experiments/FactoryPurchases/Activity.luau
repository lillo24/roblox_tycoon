--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local Rules = require(ReplicatedStorage.TycoonShared.Experiments.FactoryPurchases.Rules)
local Catalogue = require(ReplicatedStorage.TycoonShared.UpgradeCatalogue)
local Config = require(ReplicatedStorage.TycoonShared.Config)
local Preferences = require(script.Parent.Parent.Parent.UiPreferences)
local Activity = {}
type Item = {
	model: Model,
	plot: Model,
	label: TextLabel,
	benefit: string,
	rotor: Part,
	products: { Part },
	output: CFrame,
	rotorFrame: CFrame,
	light: BasePart,
	parts: { { part: BasePart, frame: CFrame, transparency: number, tween: Tween? } },
	added: number,
}

function Activity.start(root: Instance): () -> ()
	local items: { [Model]: Item } = {}
	local connections: { RBXScriptConnection } = {}
	local alive = true
	local initializing = true
	local function reduced(): boolean
		return Preferences.motionReduced(Preferences.read(), GuiService.ReducedMotionEnabled)
	end
	local function decor(parent: Instance, name: string, size: Vector3, frame: CFrame, color: Color3): Part
		local part = Instance.new("Part")
		part.Name, part.Size, part.CFrame, part.Color = name, size, frame, color
		part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
		part.Material, part.Parent = Enum.Material.Metal, parent
		return part
	end
	local function attach(model: Model)
		if items[model] or (model.Name ~= "Generator" and not Catalogue.ById[model.Name]) then
			return
		end
		local housing, output, light =
			model:FindFirstChild("Housing"), model:FindFirstChild("Output"), model:FindFirstChild("StatusLight")
		if
			not housing
			or not housing:IsA("BasePart")
			or not output
			or not output:IsA("BasePart")
			or not light
			or not light:IsA("BasePart")
		then
			return
		end
		local label = housing:FindFirstChildWhichIsA("SurfaceGui")
		local text = label and label:FindFirstChildWhichIsA("TextLabel")
		if not text then
			return
		end -- Replication may deliver the label after parts.
		-- Keep benefit text above the front output block, which hides the lower face.
		text.Size, text.TextSize, text.TextYAlignment = UDim2.fromScale(1, 0.42), 24, Enum.TextYAlignment.Top
		local plot = if model.Parent and model.Parent.Name == "Upgrades" then model.Parent.Parent else model.Parent
		assert(plot and plot:IsA("Model"), "Factory activity machine has no owning plot")
		local definition = Catalogue.ById[model.Name]
		local benefit = if definition
			then `{definition.DisplayName}\n+{definition.IncomeDelta} / sec`
			else "STARTER UNIT\n+1 / sec"
		local folder = Instance.new("Folder")
		folder.Name, folder.Parent = "LocalFactoryActivity", model
		local rotorFrame = housing.CFrame * CFrame.new(-2.6, 0, 0)
		local rotor = decor(folder, "Rotor", Vector3.new(0.25, 2, 0.4), rotorFrame, Color3.fromRGB(112, 214, 191))
		local item: Item = {
			model = model,
			plot = plot,
			label = text,
			benefit = benefit,
			rotor = rotor,
			rotorFrame = rotorFrame,
			output = output.CFrame,
			light = light,
			products = {},
			parts = {},
			added = os.clock(),
		}
		for i = 1, 2 do
			table.insert(
				item.products,
				decor(
					folder,
					`SimulatedOutput{i}`,
					Vector3.new(0.45, 0.45, 0.45),
					output.CFrame,
					Color3.fromRGB(213, 172, 81)
				)
			)
		end
		-- Existing starter/late-join equipment is immediately settled. New upgrades
		-- animate presentation only; anchored colliders never move or change size.
		local construct = model.Name ~= "Generator" and not initializing
		for _, part in model:GetChildren() do
			if part:IsA("BasePart") then
				local entry =
					{ part = part, frame = part.CFrame, transparency = part.Transparency, tween = nil :: Tween? }
				table.insert(item.parts, entry)
				if construct and not reduced() then
					part.Transparency = 0.85
					if not part.CanCollide then
						part.CFrame += Vector3.new(0, 2, 0)
					end
					local tween = TweenService:Create(
						part,
						TweenInfo.new(Rules.AnimationDuration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
						{ CFrame = entry.frame, Transparency = entry.transparency }
					)
					entry.tween = tween
					tween:Play()
				end
			end
		end
		items[model] = item
	end
	local function scan()
		if not alive then
			return
		end
		for _, instance in root:GetDescendants() do
			if instance:IsA("Model") then
				attach(instance)
			end
		end
	end
	-- Models replicate incrementally; a debounced rescan after any child addition
	-- waits until required components are present without blocking client startup.
	local pending = false
	table.insert(
		connections,
		root.DescendantAdded:Connect(function(instance)
			if instance.Name == "LocalFactoryActivity" or pending then
				return
			end
			pending = true
			task.defer(function()
				pending = false
				scan()
			end)
		end)
	)
	scan()
	initializing = false
	local elapsed = 0
	table.insert(
		connections,
		RunService.RenderStepped:Connect(function(delta)
			elapsed += delta
			if elapsed < Rules.ActivityInterval then
				return
			end
			elapsed = 0
			local player = Players.LocalPlayer
			local character = player and player.Character
			local rootPart = character and character:FindFirstChild("HumanoidRootPart")
			local origin = if rootPart and rootPart:IsA("BasePart") then rootPart.Position else nil
			local now, reducedMotion = os.clock(), reduced()
			for model, item in items do
				if not model:IsDescendantOf(root) then
					items[model] = nil
					continue
				end
				local active = item.plot:GetAttribute(Config.Attributes.OwnerUserId) ~= nil
				local quiet = reducedMotion or not active
				item.label.Text = item.benefit .. (if active then " · ACTIVE" else " · awaiting owner")
				for _, product in item.products do
					product.Transparency = if active then 0 else 1
				end
				if quiet then
					for _, entry in item.parts do
						if entry.tween then
							entry.tween:Cancel()
							entry.tween = nil
						end
						entry.part.CFrame, entry.part.Transparency = entry.frame, entry.transparency
					end
				end
				if not origin or (origin - item.output.Position).Magnitude > Rules.ActivityDistance then
					continue
				end
				item.rotor.CFrame = item.rotorFrame * CFrame.Angles(if quiet then 0 else now * 1.8, 0, 0)
				for i, product in item.products do
					local progress = if quiet then (i - 1) * 0.8 else (now * 0.6 + i * 0.5) % 1
					product.CFrame = item.output * CFrame.new(0, -progress * 1.6, -progress * 1.2)
				end
				item.light.Color = if not active
					then Color3.fromRGB(86, 96, 105)
					elseif quiet then Color3.fromRGB(145, 217, 187)
					else Color3.fromRGB(145, 200 + math.sin(now * 2) * 17, 187)
			end
		end)
	)
	return function()
		alive = false
		for _, connection in connections do
			connection:Disconnect()
		end
		for model, item in items do
			for _, entry in item.parts do
				if entry.tween then
					entry.tween:Cancel()
				end
				if entry.part.Parent then
					entry.part.CFrame, entry.part.Transparency = entry.frame, entry.transparency
				end
			end
			local folder = model:FindFirstChild("LocalFactoryActivity")
			if folder then
				folder:Destroy()
			end
		end
		table.clear(items)
	end
end

return Activity

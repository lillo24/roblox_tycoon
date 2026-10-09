--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.TycoonShared.Config)
local Theme = require(script.Parent.UiTheme)

local Labels = {}
type Override = { apply: (boolean, number) -> (), restore: () -> () }

-- Restrict discovery to the known runtime/plot trees, including both PlotWorld layouts.
function Labels.kind(instance: Instance, root: Instance): string?
	local parent = instance.Parent
	if not parent or not instance:IsDescendantOf(root) then
		return nil
	end
	local ancestor: Instance? = parent
	local plot: Instance? = nil
	while ancestor and ancestor ~= root do
		if
			ancestor.Parent == root
			and ancestor:IsA("Model")
			and typeof(ancestor:GetAttribute(Config.Attributes.PlotId)) == "number"
		then
			plot = ancestor
		end
		ancestor = ancestor.Parent
	end
	if not plot then
		return nil
	end
	if
		instance:IsA("BillboardGui")
		and instance.Name == "Ownership"
		and parent.Parent == plot
		and (parent.Name == "Generator" or parent.Name == "OwnerPanel")
	then
		return "ownership"
	end
	if instance:IsA("TextLabel") then
		if parent:IsA("BillboardGui") and parent.Name == "Ownership" then
			return if Labels.kind(parent, root) == "ownership" then "ownerText" else nil
		end
		if parent:IsA("SurfaceGui") and (parent.Name == "UpgradeLabel" or parent.Name == "Label") then
			local part = parent.Parent
			local upgrades = plot:FindFirstChild("Upgrades")
			local generator = plot:FindFirstChild("Generator")
			if
				part
				and (
					string.sub(part.Name, 1, 4) == "Pad_" and part.Parent == plot
					or part.Name == "Generator" and part.Parent == plot
					or generator and generator:IsA("Model") and part.Parent == generator and part.Name == "Housing"
					or upgrades and part:IsDescendantOf(upgrades)
				)
			then
				return "surfaceText"
			end
		end
	end
	return nil
end

function Labels.start(): { refresh: (boolean, number) -> (), destroy: () -> () }
	local records: { [Instance]: Override } = {}
	local connections: { RBXScriptConnection } = {}
	local rootConnections: { RBXScriptConnection } = {}
	local root: Instance? = nil
	local shown, transparency = true, 1
	local function clearRoot()
		for _, connection in rootConnections do
			connection:Disconnect()
		end
		table.clear(rootConnections)
		for _, record in records do
			record.restore()
		end
		table.clear(records)
		root = nil
	end
	local function discover(instance: Instance)
		local current = root
		if not current or records[instance] then
			return
		end
		local kind = Labels.kind(instance, current)
		local record: Override?
		if kind == "ownership" and instance:IsA("BillboardGui") then
			local enabled, onTop, distance, size =
				instance.Enabled, instance.AlwaysOnTop, instance.MaxDistance, instance.Size
			record = {
				apply = function(visible: boolean, _alpha: number)
					instance.Enabled = enabled and visible
					instance.AlwaysOnTop = false
					instance.MaxDistance = math.min(distance, 65)
					instance.Size = UDim2.fromOffset(180, 72)
				end,
				restore = function()
					instance.Enabled, instance.AlwaysOnTop, instance.MaxDistance, instance.Size =
						enabled, onTop, distance, size
				end,
			}
		elseif (kind == "ownerText" or kind == "surfaceText") and instance:IsA("TextLabel") then
			local font, size, color = instance.Font, instance.TextSize, instance.TextColor3
			local background, alpha = instance.BackgroundColor3, instance.BackgroundTransparency
			record = {
				apply = function(_visible: boolean, preferred: number)
					instance.Font = Theme.StrongFont
					instance.TextSize = if kind == "ownerText" then 14 else size
					instance.TextColor3 = Theme.Text
					instance.BackgroundColor3 = Theme.Background
					instance.BackgroundTransparency = Theme.Transparency * preferred
				end,
				restore = function()
					instance.Font, instance.TextSize, instance.TextColor3 = font, size, color
					instance.BackgroundColor3, instance.BackgroundTransparency = background, alpha
				end,
			}
		end
		if record then
			records[instance] = record
			record.apply(shown, transparency)
		end
	end
	local function attach(instance: Instance)
		if instance.Name ~= Config.RuntimeName or not instance:IsA("Folder") then
			return
		end
		clearRoot()
		root = instance
		table.insert(rootConnections, instance.DescendantAdded:Connect(discover))
		table.insert(
			rootConnections,
			instance.DescendantRemoving:Connect(function(descendant: Instance)
				local record = records[descendant]
				if record then
					record.restore()
					records[descendant] = nil
				end
			end)
		)
		for _, descendant in instance:GetDescendants() do
			discover(descendant)
		end
	end
	table.insert(connections, workspace.ChildAdded:Connect(attach))
	table.insert(
		connections,
		workspace.ChildRemoved:Connect(function(instance: Instance)
			if instance == root then
				clearRoot()
			end
		end)
	)
	local existing = workspace:FindFirstChild(Config.RuntimeName)
	if existing then
		attach(existing)
	end
	return {
		refresh = function(visible: boolean, preferred: number)
			shown, transparency = visible, preferred
			for _, record in records do
				record.apply(shown, transparency)
			end
		end,
		destroy = function()
			for _, connection in connections do
				connection:Disconnect()
			end
			clearRoot()
		end,
	}
end

return Labels

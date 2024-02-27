local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")
local CoreGui = game:GetService("CoreGui")

do
	if not RunService:IsEdit() then
		return
	end

	local Anchors = require(script.Anchors)

	local Toolbar = plugin:CreateToolbar("Anchor Buddy")

	local ToggleGuiButton = Toolbar:CreateButton("Anchor Buddy", "Toggle anchor buddy", "rbxassetid://16118589305")
	ToggleGuiButton.ClickableWhenViewportHidden = false

	do
		local existingGui = CoreGui:FindFirstChild("AnchorBuddy")
		if existingGui then
			existingGui:Destroy()
		end
	end

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "AnchorBuddy"
	ScreenGui.DisplayOrder = 999999999

	local Pointer = Instance.new("Frame")
	Pointer.Name = "Pointer"
	Pointer.AnchorPoint = Vector2.new(0.5, 0.5)
	Pointer.Position = UDim2.fromScale(0.5, 0.5)
	Pointer.Size = UDim2.fromOffset(6, 6)
	Pointer.BackgroundColor3 = Color3.new(1, 1, 1)
	Pointer.BorderSizePixel = 2
	Pointer.Visible = false

	local Current = Instance.new("Frame")
	Current.Name = "Current"
	Current.AnchorPoint = Vector2.new(0.5, 0.5)
	Current.Position = UDim2.fromScale(0.5, 0.5)
	Current.Size = UDim2.fromOffset(6, 6)
	Current.BackgroundColor3 = Color3.new(1, 1, 1)
	Current.BorderSizePixel = 2
	Current.Visible = false

	Current.Parent = ScreenGui
	Pointer.Parent = ScreenGui
	ScreenGui.Parent = CoreGui

	local enabled = true
	local connections = {}

	local function addConnection(connection)
		table.insert(connections, connection)
	end

	local function vec2ToOffset(vec2: Vector2)
		return UDim2.fromOffset(vec2.X, vec2.Y)
	end

	local function stopAnchorBuddy()
		for _, connection in connections do
			connection:Disconnect()
		end

		table.clear(connections)

		Pointer.Visible = false
		Current.Visible = false
	end

	local function runAnchorBuddy()
		if not enabled then
			return
		end

		stopAnchorBuddy()

		for _, instance in Selection:Get() do
			if not instance:IsA("GuiObject") then
				continue
			end

			Current.Visible = true

			local anchorPositions = {}

			local function updateCurrent()
				for key, anchor in Anchors do
					if anchor == instance.AnchorPoint then
						Current.Position = vec2ToOffset(anchorPositions[key])
					end
				end
			end

			local function updateAnchorPositions()
				local absPosition = instance.AbsolutePosition
				local absSize = instance.AbsoluteSize

				for key, anchor in Anchors do
					anchorPositions[key] = absPosition + absSize * anchor
				end

				updateCurrent()
			end

			updateAnchorPositions()
			addConnection(instance:GetPropertyChangedSignal("AbsolutePosition"):Connect(updateAnchorPositions))
			addConnection(instance:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateAnchorPositions))

			local editing = false
			local currentKey = nil

			local function updatePointer()
				local mousePosition = UserInputService:GetMouseLocation()

				local closestDistance = math.huge
				local closestKey = nil

				for key, position in anchorPositions do
					local distance = (position - mousePosition).Magnitude
					if distance > closestDistance then
						continue
					end

					closestDistance = distance
					closestKey = key
				end

				if closestKey then
					currentKey = closestKey
					Pointer.Position = vec2ToOffset(anchorPositions[closestKey])
				end
			end

			addConnection(UserInputService.InputBegan:Connect(function(input)
				if input.KeyCode == Enum.KeyCode.LeftAlt then
					editing = true
					Pointer.Visible = true

					updatePointer()
				end
			end))

			addConnection(UserInputService.InputEnded:Connect(function(input)
				if not editing then
					return
				end

				if input.KeyCode == Enum.KeyCode.LeftAlt then
					editing = false
					Pointer.Visible = false

					if currentKey then
						instance.AnchorPoint = Anchors[currentKey]
						updateCurrent()
					end
				end
			end))

			addConnection(UserInputService.InputChanged:Connect(function(input)
				if not editing then
					return
				end

				if input.UserInputType == Enum.UserInputType.MouseMovement then
					updatePointer()
				end
			end))

			break
		end
	end

	ToggleGuiButton.Click:Connect(function()
		enabled = not enabled

		if not enabled then
			stopAnchorBuddy()
		else
			runAnchorBuddy()
		end

		warn("Anchor Buddy:", enabled and "Enabled" or "Disabled")
	end)

	Selection.SelectionChanged:Connect(runAnchorBuddy)
end

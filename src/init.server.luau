local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")

local Camera = workspace.CurrentCamera

local Toolbar = plugin:CreateToolbar("Selection To Camera")

local ToggleGuiButton =
	Toolbar:CreateButton("Selection To Camera", "Move selection to camera", "rbxassetid://16542667621")
ToggleGuiButton.ClickableWhenViewportHidden = false

ToggleGuiButton.Click:Connect(function()
	for _, selected in Selection:Get() do
		if selected:IsA("Model") then
			selected:PivotTo(CFrame.new())
			selected:PivotTo(Camera.CFrame)
		elseif selected:IsA("BasePart") then
			selected.CFrame = Camera.CFrame
		end
	end

	ChangeHistoryService:SetWaypoint("Selection To Camera")
end)

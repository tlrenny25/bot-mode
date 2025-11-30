-- Noclip Mode GUI Script
-- Client-sided script for random movement noclip

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- GUI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NoclipModeGUI"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = screenGui
mainFrame.Size = UDim2.new(0, 200, 0, 100)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.BorderSizePixel = 0

-- Corner rounding
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Title Label
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Parent = mainFrame
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Position = UDim2.new(0, 0, 0, 5)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Noclip Mode"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.SourceSansBold

-- Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleNoclip"
toggleButton.Parent = mainFrame
toggleButton.Size = UDim2.new(0, 180, 0, 40)
toggleButton.Position = UDim2.new(0, 10, 0, 45)
toggleButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
toggleButton.BorderSizePixel = 0
toggleButton.Text = "Toggle Noclip"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextScaled = true
toggleButton.Font = Enum.Font.SourceSans

-- Button corner
local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 6)
buttonCorner.Parent = toggleButton

-- Variables
local noclipEnabled = false
local connection = nil
local moveInterval = 0.5 -- seconds between random movements
local moveDistance = 10 -- studs per movement
local originalWalkSpeed = 16
local originalJumpPower = 50
local originalPosition = nil -- Store original position

-- Function to get camera direction
local function getCameraDirection()
	local camera = workspace.CurrentCamera
	if not camera then return Vector3.new(0, 0, -1) end
	
	-- Get the forward direction of the camera (ignoring vertical component for horizontal movement)
	local cameraCFrame = camera.CFrame
	local lookVector = cameraCFrame.LookVector
	
	-- Normalize and return the direction
	return lookVector.Unit
end

-- Tween info for smooth easing
local tweenInfo = TweenInfo.new(
	0.3, -- Time (seconds)
	Enum.EasingStyle.Quad, -- Easing style
	Enum.EasingDirection.InOut, -- Easing direction
	0, -- Repeat count
	false, -- Reverse
	0 -- Delay time
)

-- Function to enable noclip
local function enableNoclip()
	if noclipEnabled then return end

	noclipEnabled = true

	-- Store original values and position
	originalWalkSpeed = humanoid.WalkSpeed
	originalJumpPower = humanoid.JumpPower
	originalPosition = humanoidRootPart.Position -- Store current position

	-- Disable humanoid movement
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	-- Automatically rotate character 90 degrees down
	local currentCFrame = humanoidRootPart.CFrame
	local rotationCFrame = CFrame.Angles(math.rad(90), 0, 0)
	local newCFrame = currentCFrame * rotationCFrame
	humanoidRootPart.CFrame = newCFrame

	-- Update button appearance
	toggleButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
	toggleButton.Text = "Disable Noclip"

	-- Start random character movement
	local lastMove = tick()
	local currentLerpStart = nil
	local currentLerpEnd = nil
	local lerpStartTime = nil

	connection = RunService.Heartbeat:Connect(function()
		if not noclipEnabled or not character or not humanoidRootPart then return end

		-- Anchor and disable collisions for all parts except HumanoidRootPart
		for _, part in character:GetDescendants() do
			if part:IsA("BasePart") and part ~= humanoidRootPart then
				part.Anchored = true
				part.CanCollide = false
			end
		end

		-- Keep HumanoidRootPart unanchored so it can move
		humanoidRootPart.Anchored = false
		humanoidRootPart.CanCollide = false

		-- Handle lerping for smooth movement
		if currentLerpStart and currentLerpEnd and lerpStartTime then
			local elapsed = tick() - lerpStartTime
			local alpha = math.min(elapsed / 0.3, 1) -- 0.3 second lerp

			-- Smooth easing function
			alpha = alpha * alpha * (3.0 - 2.0 * alpha)

			-- Interpolate position
			local lerpedPosition = currentLerpStart:lerp(currentLerpEnd, alpha)
			local targetCFrame = CFrame.new(lerpedPosition) * CFrame.Angles(math.rad(90), 0, 0)

			-- Move the entire character
			character:SetPrimaryPartCFrame(targetCFrame)

			if alpha >= 1 then
				currentLerpStart = nil
				currentLerpEnd = nil
				lerpStartTime = nil
			end
		end

		if tick() - lastMove >= moveInterval then
			-- Get camera direction
			local cameraDirection = getCameraDirection()
			local currentPosition = humanoidRootPart.Position
			local newPosition = currentPosition + (cameraDirection * moveDistance)

			-- Start new lerp
			currentLerpStart = currentPosition
			currentLerpEnd = newPosition
			lerpStartTime = tick()

			lastMove = tick()
		end
	end)
end

-- Function to disable noclip
local function disableNoclip()
	if not noclipEnabled then return end

	noclipEnabled = false

	-- Stop random movement
	if connection then
		connection:Disconnect()
		connection = nil
	end

	-- Teleport player back to original position
	if originalPosition then
		character:SetPrimaryPartCFrame(CFrame.new(originalPosition))
	end

	-- Simply unanchor all character parts and re-enable collisions
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = true
		end
	end

	-- Restore humanoid movement
	humanoid.WalkSpeed = originalWalkSpeed
	humanoid.JumpPower = originalJumpPower
	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)

	-- Update button appearance
	toggleButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	toggleButton.Text = "Toggle Noclip"
end

-- Toggle button click handler
toggleButton.MouseButton1Click:Connect(function()
	if noclipEnabled then
		disableNoclip()
	else
		enableNoclip()
	end
end)

-- Handle character respawn
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	humanoid = character:WaitForChild("Humanoid")

	-- Reset noclip state on respawn
	if noclipEnabled then
		disableNoclip()
	end
end)

-- Ensure character has PrimaryPart set
if not character.PrimaryPart then
	character.PrimaryPart = humanoidRootPart
end

-- Make GUI draggable
local dragging = false
local dragStart = nil
local startPos = nil

mainFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

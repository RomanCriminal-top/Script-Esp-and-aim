local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Settings = {
    ESP_Enabled = false, Aimbot_Enabled = false, Fly_Enabled = false,
    Crosshair_Enabled = false, Wallhack_Enabled = false, HealthBar_Enabled = false,
    SpeedHack_Enabled = false, NoClip_Enabled = false, AntiAFK_Enabled = false,
    NameESP_Enabled = false, DistanceESP_Enabled = false,
    Aimbot_FOV = 150, Crosshair_Size = 10, SpeedMultiplier = 2,
    JumpMultiplier = 2, Smoothness = 0.3, AimPart = "Head",
}

local ESP_Cache = {}
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(0, 255, 255)
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 60
FOVCircle.Filled = false
FOVCircle.Visible = false

local Crosshair_Horizontal = Drawing.new("Line")
Crosshair_Horizontal.Color = Color3.fromRGB(255, 0, 0)
Crosshair_Horizontal.Thickness = 2
Crosshair_Horizontal.Visible = false

local Crosshair_Vertical = Drawing.new("Line")
Crosshair_Vertical.Color = Color3.fromRGB(255, 0, 0)
Crosshair_Vertical.Thickness = 2
Crosshair_Vertical.Visible = false

local function IsVisible(player)
    if not player or not player.Character or not player.Character:FindFirstChild("Head") then return false end
    local origin = Camera.CFrame.Position
    local direction = (player.Character.Head.Position - origin).Unit * 1000
    local ray = Ray.new(origin, direction)
    local part = workspace:FindPartOnRay(ray, LocalPlayer.Character)
    return part and part:IsDescendantOf(player.Character)
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    local Box = Drawing.new("Square")
    Box.Visible = false
    Box.Color = Color3.fromRGB(255, 0, 0)
    Box.Thickness = 1.5
    Box.Filled = false
    local Line = Drawing.new("Line")
    Line.Visible = false
    Line.Color = Color3.fromRGB(255, 255, 255)
    Line.Thickness = 1
    local HealthBar = Drawing.new("Line")
    HealthBar.Visible = false
    HealthBar.Color = Color3.fromRGB(0, 255, 0)
    HealthBar.Thickness = 3
    local HeadDot = Drawing.new("Circle")
    HeadDot.Visible = false
    HeadDot.Radius = 3
    HeadDot.Filled = true
    HeadDot.Color = Color3.fromRGB(255, 0, 0)
    local NameTag = Drawing.new("Text")
    NameTag.Visible = false
    NameTag.Color = Color3.fromRGB(255, 255, 255)
    NameTag.Size = 14
    NameTag.Center = true
    local DistanceTag = Drawing.new("Text")
    DistanceTag.Visible = false
    DistanceTag.Color = Color3.fromRGB(200, 200, 200)
    DistanceTag.Size = 12
    DistanceTag.Center = true
    ESP_Cache[player] = {Box = Box, Line = Line, HealthBar = HealthBar, HeadDot = HeadDot, NameTag = NameTag, DistanceTag = DistanceTag}
end

local function RemoveESP(player)
    if ESP_Cache[player] then
        for _, obj in pairs(ESP_Cache[player]) do
            if obj and obj.Remove then obj:Remove() end
        end
        ESP_Cache[player] = nil
    end
end

for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

local function GetClosestPlayerToCenter()
    local closestPlayer = nil
    local shortestDistance = Settings.Aimbot_FOV
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(Settings.AimPart) and player.Character:FindFirstChildOfClass("Humanoid") and player.Character.Humanoid.Health > 0 then
            if player.Team == LocalPlayer.Team then continue end
            local pos, onScreen = Camera:WorldToViewportPoint(player.Character[Settings.AimPart].Position)
            if onScreen then
                local distance = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                if distance < shortestDistance then
                    closestPlayer = player
                    shortestDistance = distance
                end
            end
        end
    end
    return closestPlayer
end

UserInputService.JumpRequest:Connect(function()
    if Settings.Fly_Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)

RunService.Heartbeat:Connect(function()
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    if Settings.Aimbot_Enabled then
        FOVCircle.Radius = Settings.Aimbot_FOV
        FOVCircle.Position = screenCenter
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end
    
    if Settings.Crosshair_Enabled then
        local lSize = Settings.Crosshair_Size
        local gap = 3
        Crosshair_Horizontal.From = Vector2.new(screenCenter.X - lSize - gap, screenCenter.Y)
        Crosshair_Horizontal.To = Vector2.new(screenCenter.X + lSize + gap, screenCenter.Y)
        Crosshair_Vertical.From = Vector2.new(screenCenter.X, screenCenter.Y - lSize - gap)
        Crosshair_Vertical.To = Vector2.new(screenCenter.X, screenCenter.Y + lSize + gap)
        Crosshair_Horizontal.Visible = true
        Crosshair_Vertical.Visible = true
    else
        Crosshair_Horizontal.Visible = false
        Crosshair_Vertical.Visible = false
    end
    
    for player, objs in pairs(ESP_Cache) do
        if Settings.ESP_Enabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid") and player.Character.Humanoid.Health > 0 then
            local hrp = player.Character.HumanoidRootPart
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
                local sizeX = 2300 / distance
                local sizeY = 3300 / distance
                objs.Box.Size = Vector2.new(sizeX, sizeY)
                objs.Box.Position = Vector2.new(pos.X - sizeX / 2, pos.Y - sizeY / 2)
                objs.Box.Visible = true
                if Settings.Wallhack_Enabled then
                    objs.Box.Color = IsVisible(player) and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 0)
                else
                    objs.Box.Color = Color3.fromRGB(255, 0, 0)
                end
                objs.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                objs.Line.To = Vector2.new(pos.X, pos.Y + (sizeY / 2))
                objs.Line.Visible = true
                if Settings.HealthBar_Enabled then
                    local health = player.Character.Humanoid.Health
                    local maxHealth = player.Character.Humanoid.MaxHealth
                    local healthPercent = health / maxHealth
                    objs.HealthBar.From = Vector2.new(pos.X - sizeX/2, pos.Y - sizeY/2 - 10)
                    objs.HealthBar.To = Vector2.new(pos.X - sizeX/2 + (sizeX * healthPercent), pos.Y - sizeY/2 - 10)
                    objs.HealthBar.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
                    objs.HealthBar.Visible = true
                else
                    objs.HealthBar.Visible = false
                end
                objs.HeadDot.Position = Vector2.new(pos.X, pos.Y - sizeY/2)
                objs.HeadDot.Visible = true
                if Settings.NameESP_Enabled then
                    objs.NameTag.Text = player.Name
                    objs.NameTag.Position = Vector2.new(pos.X, pos.Y - sizeY/2 - 30)
                    objs.NameTag.Visible = true
                else
                    objs.NameTag.Visible = false
                end
                if Settings.DistanceESP_Enabled then
                    objs.DistanceTag.Text = math.floor(distance) .. "m"
                    objs.DistanceTag.Position = Vector2.new(pos.X, pos.Y - sizeY/2 - 45)
                    objs.DistanceTag.Visible = true
                else
                    objs.DistanceTag.Visible = false
                end
            else
                objs.Box.Visible = false
                objs.Line.Visible = false
                objs.HealthBar.Visible = false
                objs.HeadDot.Visible = false
                objs.NameTag.Visible = false
                objs.DistanceTag.Visible = false
            end
        else
            objs.Box.Visible = false
            objs.Line.Visible = false
            objs.HealthBar.Visible = false
            objs.HeadDot.Visible = false
            objs.NameTag.Visible = false
            objs.DistanceTag.Visible = false
        end
    end
    
    if Settings.Aimbot_Enabled then
        local target = GetClosestPlayerToCenter()
        if target and target.Character and target.Character:FindFirstChild(Settings.AimPart) then
            local targetPart = target.Character[Settings.AimPart]
            local isMovingCamera = UserInputService:GetMouseDelta().Magnitude > 2
            if isMovingCamera then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, targetPart.Position), Settings.Smoothness)
            else
                Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetPart.Position)
            end
        end
    end
    
    if Settings.SpeedHack_Enabled and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 16 * Settings.SpeedMultiplier
            humanoid.JumpPower = 50 * Settings.JumpMultiplier
        end
    end
    
    if Settings.NoClip_Enabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
    
    if Settings.AntiAFK_Enabled then
        LocalPlayer:SendMessage("Anti-AFK")
    end
end)if CoreGui:FindFirstChild("DeltaESP_Gui") then CoreGui.DeltaESP_Gui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaESP_Gui"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 400, 0, 500)
MainFrame.Position = UDim2.new(0.5, -200, 0.4, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
Title.Text = "@RomanCriminal Script v2.0"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

local Tabs = {}
local CurrentTab = "ESP"

local function CreateTab(name, position)
    local tab = Instance.new("TextButton")
    tab.Size = UDim2.new(0, 80, 0, 30)
    tab.Position = UDim2.new(position, 0, 0, 45)
    tab.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    tab.Text = name
    tab.TextColor3 = Color3.fromRGB(255, 255, 255)
    tab.Font = Enum.Font.GothamBold
    tab.TextSize = 12
    tab.Parent = MainFrame
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = tab
    Tabs[name] = tab
    return tab
end

local function CreateTabContent(name)
    local content = Instance.new("Frame")
    content.Name = name .. "Content"
    content.Size = UDim2.new(1, 0, 1, -80)
    content.Position = UDim2.new(0, 0, 0, 80)
    content.BackgroundTransparency = 1
    content.Visible = false
    content.Parent = MainFrame
    return content
end

CreateTab("ESP", 0.05)
CreateTab("AIM", 0.3)
CreateTab("MOVE", 0.55)
CreateTab("SET", 0.8)

local espContent = CreateTabContent("ESP")
local aimContent = CreateTabContent("AIM")
local moveContent = CreateTabContent("MOVE")
local setContent = CreateTabContent("SET")
espContent.Visible = true

local function CreateToggleButton(parent, yPos, text, setting, xPos)
    xPos = xPos or 20
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 160, 0, 35)
    button.Position = UDim2.new(0, xPos, 0, yPos)
    button.BackgroundColor3 = Settings[setting] and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    button.Text = text .. ": " .. (Settings[setting] and "ON" or "OFF")
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 12
    button.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    button.MouseButton1Click:Connect(function()
        Settings[setting] = not Settings[setting]
        button.Text = text .. ": " .. (Settings[setting] and "ON" or "OFF")
        button.BackgroundColor3 = Settings[setting] and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    end)
    return button
end

CreateToggleButton(espContent, 10, "ESP", "ESP_Enabled")
CreateToggleButton(espContent, 55, "Wallhack", "Wallhack_Enabled", 190)
CreateToggleButton(espContent, 100, "Health Bar", "HealthBar_Enabled")
CreateToggleButton(espContent, 145, "Name ESP", "NameESP_Enabled", 190)
CreateToggleButton(espContent, 190, "Distance ESP", "DistanceESP_Enabled")

CreateToggleButton(aimContent, 10, "Aimbot", "Aimbot_Enabled")
CreateToggleButton(aimContent, 55, "Crosshair", "Crosshair_Enabled", 190)

local aimPartLabel = Instance.new("TextLabel")
aimPartLabel.Size = UDim2.new(0, 160, 0, 30)
aimPartLabel.Position = UDim2.new(0, 20, 0, 100)
aimPartLabel.BackgroundTransparency = 1
aimPartLabel.Text = "Aim Part: " .. Settings.AimPart
aimPartLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
aimPartLabel.Font = Enum.Font.GothamBold
aimPartLabel.TextSize = 12
aimPartLabel.Parent = aimContent

local aimPartButton = Instance.new("TextButton")
aimPartButton.Size = UDim2.new(0, 160, 0, 30)
aimPartButton.Position = UDim2.new(0, 190, 0, 100)
aimPartButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
aimPartButton.Text = "Change"
aimPartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
aimPartButton.Font = Enum.Font.GothamBold
aimPartButton.TextSize = 12
aimPartButton.Parent = aimContent

local aimParts = {"Head", "Torso", "HumanoidRootPart"}
local aimPartIndex = 1
aimPartButton.MouseButton1Click:Connect(function()
    aimPartIndex = aimPartIndex % #aimParts + 1
    Settings.AimPart = aimParts[aimPartIndex]
    aimPartLabel.Text = "Aim Part: " .. Settings.AimPart
end)

CreateToggleButton(moveContent, 10, "Infinite Jump", "Fly_Enabled")
CreateToggleButton(moveContent, 55, "Speed Hack", "SpeedHack_Enabled", 190)
CreateToggleButton(moveContent, 100, "No Clip", "NoClip_Enabled")
CreateToggleButton(moveContent, 145, "Anti-AFK", "AntiAFK_Enabled", 190)

local function CreateSlider(parent, yPos, text, setting, minVal, maxVal, step)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 360, 0, 20)
    label.Position = UDim2.new(0, 20, 0, yPos)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. tostring(Settings[setting])
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.Parent = parent
    
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(0, 360, 0, 8)
    sliderFrame.Position = UDim2.new(0, 20, 0, yPos + 25)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    sliderFrame.BorderSizePixel = 0
    sliderFrame.Parent = parent
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 4)
    sliderCorner.Parent = sliderFrame
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((Settings[setting] - minVal) / (maxVal - minVal), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderFrame
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = sliderFill
    
    local sliderButton = Instance.new("TextButton")
    sliderButton.Size = UDim2.new(0, 14, 0, 14)
    sliderButton.Position = UDim2.new((Settings[setting] - minVal) / (maxVal - minVal), -7, 0.5, -7)
    sliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderButton.Text = ""
    sliderButton.Parent = sliderFrame
    local roundCorner = Instance.new("UICorner")
    roundCorner.CornerRadius = UDim.new(1, 0)
    roundCorner.Parent = sliderButton
    
    local dragging = false
    local function updateSlider(input)
        local minX = sliderFrame.AbsolutePosition.X
        local maxX = minX + sliderFrame.AbsoluteSize.X
        local inputX = math.clamp(input.Position.X, minX, maxX)
        local percentage = (inputX - minX) / sliderFrame.AbsoluteSize.X
        local value = math.floor((minVal + (percentage * (maxVal - minVal))) / step) * step
        Settings[setting] = math.clamp(value, minVal, maxVal)
        label.Text = text .. ": " .. tostring(Settings[setting])
        sliderButton.Position = UDim2.new(percentage, -7, 0.5, -7)
        sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
    end
    
    sliderButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                updateSlider(input)
            end
        end
    end)
end

CreateSlider(aimContent, 150, "FOV Radius", "Aimbot_FOV", 10, 500, 5)
CreateSlider(aimContent, 205, "Smoothness", "Smoothness", 1, 10, 1)
CreateSlider(moveContent, 190, "Speed Multiplier", "SpeedMultiplier", 1, 10, 0.5)
CreateSlider(moveContent, 245, "Jump Multiplier", "JumpMultiplier", 1, 5, 0.5)

local function SwitchTab(tabName)
    for name, tab in pairs(Tabs) do
        tab.BackgroundColor3 = name == tabName and Color3.fromRGB(70, 70, 80) or Color3.fromRGB(45, 45, 50)
        local content = MainFrame:FindFirstChild(name .. "Content")
        if content then
            content.Visible = name == tabName
        end
    end
    CurrentTab = tabName
end

for name, tab in pairs(Tabs) do
    tab.MouseButton1Click:Connect(function()
        SwitchTab(name)
    end)
end

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -35, 0, 2)
CloseButton.BackgroundTransparency = 1
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 18
CloseButton.Parent = MainFrame

local OpenButton = Instance.new("TextButton")
OpenButton.Name = "OpenButton"
OpenButton.Size = UDim2.new(0, 50, 0, 50)
OpenButton.Position = UDim2.new(0, 10, 0.3, 0)
OpenButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
OpenButton.Text = "MENU"
OpenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenButton.Font = Enum.Font.GothamBold
OpenButton.TextSize = 12
OpenButton.Visible = false
OpenButton.Active = true
OpenButton.Draggable = true
OpenButton.Parent = ScreenGui

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(1, 0)
OpenCorner.Parent = OpenButton

CloseButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    OpenButton.Visible = true
end)

local dragStartPos = nil
OpenButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragStartPos = OpenButton.Position
    end
end)

OpenButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if dragStartPos then
            local startX = dragStartPos.X.Offset
            local startY = dragStartPos.Y.Offset
            local currentX = OpenButton.Position.X.Offset
            local currentY = OpenButton.Position.Y.Offset
            local distanceMoved = math.sqrt((currentX - startX)^2 + (currentY - startY)^2)
            if distanceMoved < 5 then
                MainFrame.Visible = true
                OpenButton.Visible = false
            end
        end
    end
end)

print("✅ Script loaded! @RomanCriminal")

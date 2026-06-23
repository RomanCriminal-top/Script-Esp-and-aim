local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- НАСТРОЙКИ
local Settings = {
    ESP_Enabled = false,
    Aimbot_Enabled = false,
    Fly_Enabled = false,
    Crosshair_Enabled = false,
    Wallhack_Enabled = false,
    HealthBar_Enabled = false,
    SpeedHack_Enabled = false,
    NoClip_Enabled = false,
    AntiAFK_Enabled = false,
    NameESP_Enabled = false,
    DistanceESP_Enabled = false,
    Aimbot_FOV = 150,
    Crosshair_Size = 10,
    SpeedMultiplier = 2,
    JumpMultiplier = 2,
    Smoothness = 0.3,
    AimPart = "Head",
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
Crosshair_Vertical.Visible = falselocal function IsVisible(player)
    if not player or not player.Character or not player.Character:FindFirstChild("Head") then 
        return false 
    end
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
    
    ESP_Cache[player] = {
        Box = Box, 
        Line = Line, 
        HealthBar = HealthBar,
        HeadDot = HeadDot,
        NameTag = NameTag,
        DistanceTag = DistanceTag
    }
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
Players.PlayerRemoving:Connect(RemoveESP)local function GetClosestPlayerToCenter()
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

-- Бесконечный прыжок
UserInputService.JumpRequest:Connect(function()
    if Settings.Fly_Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)RunService.Heartbeat:Connect(function()
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    -- FOV Круг
    if Settings.Aimbot_Enabled then
        FOVCircle.Radius = Settings.Aimbot_FOV
        FOVCircle.Position = screenCenter
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end
    
    -- Кроссхеир
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
    
    -- ESP Отрисовка
    for player, objs in pairs(ESP_Cache) do
        if Settings.ESP_Enabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid") and player.Character.Humanoid.Health > 0 then
            local hrp = player.Character.HumanoidRootPart
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            
            if onScreen then
                local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
                local sizeX = 2300 / distance
                local sizeY = 3300 / distance
                
                -- Бокс
                objs.Box.Size = Vector2.new(sizeX, sizeY)
                objs.Box.Position = Vector2.new(pos.X - sizeX / 2, pos.Y - sizeY / 2)
                objs.Box.Visible = true
                
                if Settings.Wallhack_Enabled then
                    objs.Box.Color = IsVisible(player) and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 0)
                else
                    objs.Box.Color = Color3.fromRGB(255, 0, 0)
                end
                
                -- Линия
                objs.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                objs.Line.To = Vector2.new(pos.X, pos.Y + (sizeY / 2))
                objs.Line.Visible = true
                
                -- Health Bar
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
                
                -- Head Dot
                objs.HeadDot.Position = Vector2.new(pos.X, pos.Y - sizeY/2)
                objs.HeadDot.Visible = true
                
                -- Name ESP
                if Settings.NameESP_Enabled then
                    objs.NameTag.Text = player.Name
                    objs.NameTag.Position = Vector2.new(pos.X, pos.Y - sizeY/2 - 30)
                    objs.NameTag.Visible = true
                else
                    objs.NameTag.Visible = false
                end
                
                -- Distance ESP
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
    
    -- Аимбот
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
    
    -- Speed Hack + Jump
    if Settings.SpeedHack_Enabled and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 16 * Settings.SpeedMultiplier
            humanoid.JumpPower = 50 * Settings.JumpMultiplier
        end
    end
    
    -- No Clip
    if Settings.NoClip_Enabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
    
    -- Anti-AFK
    if Settings.AntiAFK_Enabled then
        LocalPlayer:SendMessage("Anti-AFK")
    end
end)if CoreGui:FindFirstChild("DeltaESP_Gui") then
    CoreGui.DeltaESP_Gui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaESP_Gui"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 220, 0, 400)
MainFrame.Position = UDim2.new(0.5, -110, 0.4, -200)
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
TitleCorner.Parent = Titlelocal function CreateButton(parent, yPos, text, setting)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 180, 0, 35)
    button.Position = UDim2.new(0.5, -90, 0, yPos)
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
end

-- СОЗДАЁМ КНОПКИ
CreateButton(MainFrame, 50, "ESP", "ESP_Enabled")
CreateButton(MainFrame, 95, "Wallhack", "Wallhack_Enabled")
CreateButton(MainFrame, 140, "Health Bar", "HealthBar_Enabled")
CreateButton(MainFrame, 185, "Name ESP", "NameESP_Enabled")
CreateButton(MainFrame, 230, "Aimbot", "Aimbot_Enabled")
CreateButton(MainFrame, 275, "Infinite Jump", "Fly_Enabled")
CreateButton(MainFrame, 320, "Speed Hack", "SpeedHack_Enabled")
CreateButton(MainFrame, 365, "No Clip", "NoClip_Enabled")local CloseButton = Instance.new("TextButton")
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

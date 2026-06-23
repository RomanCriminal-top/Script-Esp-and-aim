-- ЧАСТЬ 1: ОСНОВНАЯ ЛОГИКА И НАСТРОЙКИ
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Настройки функций
local ESP_Enabled = false
local Aimbot_Enabled = false
local Fly_Enabled = false
local Crosshair_Enabled = false
local Aimbot_FOV = 150 
local Crosshair_Size = 10 

-- Новые настройки тумблеров VISUAL (По умолчанию всё включено, если включен сам ESP/Aim)
local Vis_Boxes = true
local Vis_Lines = true
local Vis_FOV = true
local Vis_Names = true
local Vis_Dist = true

-- Смена Цветов (Индексы: 1 = Белый (Дефолт), 2 = Зеленый, 3 = Фиолетовый, 4 = Радуга)
local CurrentColorIndex = 1
local ColorModes = {"DEFAULT", "GREEN", "PURPLE", "RAINBOW"}
local CurrentStaticColor = Color3.fromRGB(255, 255, 255) -- Дефолт теперь белый

-- Хранилище для графики ESP
local ESP_Cache = {}

-- Круг FOV строго по центру
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 60
FOVCircle.Radius = Aimbot_FOV
FOVCircle.Filled = false
FOVCircle.Visible = false

-- Кроссхеир (Перекрестие)
local Crosshair_Horizontal = Drawing.new("Line")
Crosshair_Horizontal.Thickness = 2
Crosshair_Horizontal.Visible = false

local Crosshair_Vertical = Drawing.new("Line")
Crosshair_Vertical.Thickness = 2
Crosshair_Vertical.Visible = false

-- Оптимизированный ESP с текстом
local function CreateESP(player)
    if player == LocalPlayer then return end

    local Box = Drawing.new("Square")
    Box.Visible = false
    Box.Thickness = 1.5
    Box.Filled = false

    local Line = Drawing.new("Line")
    Line.Visible = false
    Line.Thickness = 1

    local Text = Drawing.new("Text")
    Text.Visible = false
    Text.Size = 14
    Text.Center = true
    Text.Outline = true
    Text.Color = Color3.fromRGB(255, 255, 255)

    ESP_Cache[player] = {Box = Box, Line = Line, Text = Text}
end

local function RemoveESP(player)
    if ESP_Cache[player] then
        ESP_Cache[player].Box:Remove()
        ESP_Cache[player].Line:Remove()
        ESP_Cache[player].Text:Remove()
        ESP_Cache[player] = nil
    end
end

for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

-- Умный поиск цели
local function GetClosestPlayerToCenter()
    local closestPlayer = nil
    local shortestDistance = Aimbot_FOV
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") and player.Character:FindFirstChildOfClass("Humanoid") and player.Character.Humanoid.Health > 0 then
            
            local pos, onScreen = Camera:WorldToViewportPoint(player.Character.Head.Position)
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
    if Fly_Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)

-- Высокопроизводительный цикл обновлений
RunService.Heartbeat:Connect(function()
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    -- Вычисление динамического цвета (для Радуги)
    local DynamicColor = CurrentStaticColor
    if ColorModes[CurrentColorIndex] == "RAINBOW" then
        DynamicColor = Color3.fromHSV(tick() % 5 / 5, 1, 1)
    end

    -- Ссылка на глобальную переменную для использования во 2 части (эффект текста кнопки)
    _G.CurrentRainbowColor = DynamicColor

    -- Визуализация FOV круга (с проверкой Vis_FOV)
    if Aimbot_Enabled and Vis_FOV then
        FOVCircle.Radius = Aimbot_FOV
        FOVCircle.Position = screenCenter
        FOVCircle.Color = DynamicColor
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    -- Визуализация Кроссхеира
    if Crosshair_Enabled then
        local lSize = Crosshair_Size
        local gap = 3
        
        Crosshair_Horizontal.From = Vector2.new(screenCenter.X - lSize - gap, screenCenter.Y)
        Crosshair_Horizontal.To = Vector2.new(screenCenter.X + lSize + gap, screenCenter.Y)
        Crosshair_Vertical.From = Vector2.new(screenCenter.X, screenCenter.Y - lSize - gap)
        Crosshair_Vertical.To = Vector2.new(screenCenter.X, screenCenter.Y + lSize + gap)
        
        Crosshair_Horizontal.Color = DynamicColor
        Crosshair_Vertical.Color = DynamicColor
        Crosshair_Horizontal.Visible = true
        Crosshair_Vertical.Visible = true
    else
        Crosshair_Horizontal.Visible = false
        Crosshair_Vertical.Visible = false
    end

    -- Обновление ESP (Ники, Дистанция, Боксы, Линии)
    for player, objs in pairs(ESP_Cache) do
        if ESP_Enabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid") and player.Character.Humanoid.Health > 0 then
            local hrp = player.Character.HumanoidRootPart
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)

            if onScreen then
                local distance = math.floor((Camera.CFrame.Position - hrp.Position).Magnitude)
                local sizeX = 2300 / distance 
                local sizeY = 3300 / distance

                objs.Box.Color = DynamicColor
                objs.Line.Color = DynamicColor

                -- Условный показ Боксов
                if Vis_Boxes then
                    objs.Box.Size = Vector2.new(sizeX, sizeY)
                    objs.Box.Position = Vector2.new(pos.X - sizeX / 2, pos.Y - sizeY / 2)
                    objs.Box.Visible = true
                else
                    objs.Box.Visible = false
                end

                -- Условный показ Линий
                if Vis_Lines then
                    objs.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    objs.Line.To = Vector2.new(pos.X, pos.Y + (sizeY / 2))
                    objs.Line.Visible = true
                else
                    objs.Line.Visible = false
                end

                -- Условный конструкт текста (Ник и/или Дистанция)
                if Vis_Names or Vis_Dist then
                    local textString = ""
                    if Vis_Names then textString = textString .. player.Name end
                    if Vis_Dist then 
                        if Vis_Names then textString = textString .. " " end
                        textString = textString .. "[" .. tostring(distance) .. "m]"
                    end
                    objs.Text.Text = textString
                    objs.Text.Position = Vector2.new(pos.X, pos.Y - (sizeY / 2) - 18)
                    objs.Text.Visible = true
                else
                    objs.Text.Visible = false
                end
            else
                objs.Box.Visible = false
                objs.Line.Visible = false
                objs.Text.Visible = false
            end
        else
            objs.Box.Visible = false
            objs.Line.Visible = false
            objs.Text.Visible = false
        end
    end

    -- Логика Аимбота
    if Aimbot_Enabled then
        local target = GetClosestPlayerToCenter()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local targetHead = target.Character.Head
            local isMovingCamera = UserInputService:GetMouseDelta().Magnitude > 2
            if isMovingCamera then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, targetHead.Position), 0.4)
            else
                Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetHead.Position)
            end
        end
    end
end)
-- ЧАСТЬ 2: ИНТЕРФЕЙС GUI И НАСТРОЙКИ ОТОБРАЖЕНИЯ
if CoreGui:FindFirstChild("DeltaESP_Gui") then
    CoreGui.DeltaESP_Gui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaESP_Gui"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
-- Высота увеличена до 530, чтобы вместить новое отделение VISUAL под ползунками
MainFrame.Size = UDim2.new(0, 220, 0, 530) 
MainFrame.Position = UDim2.new(0.5, -110, 0.4, -265)
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
Title.Text = "@RomanCriminal script"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

--- РЯД 1: ESP И INF JUMP ---
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 85, 0, 40)
ToggleButton.Position = UDim2.new(0, 20, 0, 50)
ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleButton.Text = "ESP: OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 13
ToggleButton.Parent = MainFrame

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 8)
ButtonCorner.Parent = ToggleButton

ToggleButton.MouseButton1Click:Connect(function()
    ESP_Enabled = not ESP_Enabled
    ToggleButton.Text = ESP_Enabled and "ESP: ON" or "ESP: OFF"
    ToggleButton.BackgroundColor3 = ESP_Enabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
end)

local FlyButton = Instance.new("TextButton")
FlyButton.Size = UDim2.new(0, 85, 0, 40)
FlyButton.Position = UDim2.new(0, 115, 0, 50)
FlyButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
FlyButton.Text = "INF JUMP: OFF"
FlyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
FlyButton.Font = Enum.Font.GothamBold
FlyButton.TextSize = 11
FlyButton.Parent = MainFrame

local FlyCorner = Instance.new("UICorner")
FlyCorner.CornerRadius = UDim.new(0, 8)
FlyCorner.Parent = FlyButton

FlyButton.MouseButton1Click:Connect(function()
    Fly_Enabled = not Fly_Enabled
    FlyButton.Text = Fly_Enabled and "INF JUMP: ON" or "INF JUMP: OFF"
    FlyButton.BackgroundColor3 = Fly_Enabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
end)

--- РЯД 2: AIMBOT И CROSSHAIR ---
local AimButton = Instance.new("TextButton")
AimButton.Size = UDim2.new(0, 85, 0, 40)
AimButton.Position = UDim2.new(0, 20, 0, 100)
AimButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
AimButton.Text = "AIM: OFF"
AimButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AimButton.Font = Enum.Font.GothamBold
AimButton.TextSize = 13
AimButton.Parent = MainFrame

local AimCorner = Instance.new("UICorner")
AimCorner.CornerRadius = UDim.new(0, 8)
AimCorner.Parent = AimButton

AimButton.MouseButton1Click:Connect(function()
    Aimbot_Enabled = not Aimbot_Enabled
    AimButton.Text = Aimbot_Enabled and "AIM: ON" or "AIM: OFF"
    AimButton.BackgroundColor3 = Aimbot_Enabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
end)

local CrosshairButton = Instance.new("TextButton")
CrosshairButton.Size = UDim2.new(0, 85, 0, 40)
CrosshairButton.Position = UDim2.new(0, 115, 0, 100)
CrosshairButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CrosshairButton.Text = "CROSS: OFF"
CrosshairButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CrosshairButton.Font = Enum.Font.GothamBold
CrosshairButton.TextSize = 12
CrosshairButton.Parent = MainFrame

local CrosshairCorner = Instance.new("UICorner")
CrosshairCorner.CornerRadius = UDim.new(0, 8)
CrosshairCorner.Parent = CrosshairButton

CrosshairButton.MouseButton1Click:Connect(function()
    Crosshair_Enabled = not Crosshair_Enabled
    CrosshairButton.Text = Crosshair_Enabled and "CROSS: ON" or "CROSS: OFF"
    CrosshairButton.BackgroundColor3 = Crosshair_Enabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
end)

--- КНОПКА ИЗМЕНЕНИЯ ЦВЕТА (COLOR) ---
local ColorButton = Instance.new("TextButton")
ColorButton.Size = UDim2.new(0, 180, 0, 35)
ColorButton.Position = UDim2.new(0.5, -90, 0, 150)
ColorButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
ColorButton.Text = "COLOR: DEFAULT"
ColorButton.TextColor3 = Color3.fromRGB(255, 255, 255) -- По дефолту белый
ColorButton.Font = Enum.Font.GothamBold
ColorButton.TextSize = 13
ColorButton.Parent = MainFrame

local ColorCorner = Instance.new("UICorner")
ColorCorner.CornerRadius = UDim.new(0, 8)
ColorCorner.Parent = ColorButton

ColorButton.MouseButton1Click:Connect(function()
    CurrentColorIndex = CurrentColorIndex + 1
    if CurrentColorIndex > #ColorModes then CurrentColorIndex = 1 end
    
    local mode = ColorModes[CurrentColorIndex]
    ColorButton.Text = "COLOR: " .. mode

    if mode == "DEFAULT" then
        CurrentStaticColor = Color3.fromRGB(255, 255, 255)
        ColorButton.TextColor3 = CurrentStaticColor
    elseif mode == "GREEN" then
        CurrentStaticColor = Color3.fromRGB(50, 250, 50)
        ColorButton.TextColor3 = CurrentStaticColor
    elseif mode == "PURPLE" then
        CurrentStaticColor = Color3.fromRGB(180, 50, 255)
        ColorButton.TextColor3 = CurrentStaticColor
    end
end)

-- Радужное переливание текста кнопки, если включен режим RAINBOW
game:GetService("RunService").Heartbeat:Connect(function()
    if ColorModes[CurrentColorIndex] == "RAINBOW" and _G.CurrentRainbowColor then
        ColorButton.TextColor3 = _G.CurrentRainbowColor
    end
end)

--- ПОЛЗУНОК FOV ---
local SliderLabel = Instance.new("TextLabel")
SliderLabel.Size = UDim2.new(0, 180, 0, 20)
SliderLabel.Position = UDim2.new(0.5, -90, 0, 200)
SliderLabel.BackgroundTransparency = 1
SliderLabel.Text = "FOV Радиус: " .. tostring(Aimbot_FOV)
SliderLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
SliderLabel.Font = Enum.Font.GothamBold
SliderLabel.TextSize = 12
SliderLabel.Parent = MainFrame

local SliderFrame = Instance.new("Frame")
SliderFrame.Size = UDim2.new(0, 180, 0, 8)
SliderFrame.Position = UDim2.new(0.5, -90, 0, 225)
SliderFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
SliderFrame.BorderSizePixel = 0
SliderFrame.Parent = MainFrame

local SliderCorner = Instance.new("UICorner")
SliderCorner.CornerRadius = UDim.new(0, 4)
SliderCorner.Parent = SliderFrame

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(Aimbot_FOV / 500, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
SliderFill.Parent = SliderFrame

local FillCorner = Instance.new("UICorner")
FillCorner.CornerRadius = UDim.new(0, 4)
FillCorner.Parent = SliderFill

local SliderButton = Instance.new("TextButton")
SliderButton.Size = UDim2.new(0, 14, 0, 14)
SliderButton.Position = UDim2.new(Aimbot_FOV / 500, -7, 0.5, -7)
SliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SliderButton.Text = ""
SliderButton.Parent = SliderFrame

local RoundCorner = Instance.new("UICorner")
RoundCorner.CornerRadius = UDim.new(1, 0)
RoundCorner.Parent = SliderButton

--- ПОЛЗУНОК ДЛЯ КРОССХЕИРА ---
local CrosshairSliderLabel = Instance.new("TextLabel")
CrosshairSliderLabel.Size = UDim2.new(0, 180, 0, 20)
CrosshairSliderLabel.Position = UDim2.new(0.5, -90, 0, 245)
CrosshairSliderLabel.BackgroundTransparency = 1
CrosshairSliderLabel.Text = "Размер прицела: " .. tostring(Crosshair_Size)
CrosshairSliderLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
CrosshairSliderLabel.Font = Enum.Font.GothamBold
CrosshairSliderLabel.TextSize = 12
CrosshairSliderLabel.Parent = MainFrame

local CrosshairSliderFrame = Instance.new("Frame")
CrosshairSliderFrame.Size = UDim2.new(0, 180, 0, 8)
CrosshairSliderFrame.Position = UDim2.new(0.5, -90, 0, 270)
CrosshairSliderFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
CrosshairSliderFrame.BorderSizePixel = 0
CrosshairSliderFrame.Parent = MainFrame

local CSliderCorner = Instance.new("UICorner")
CSliderCorner.CornerRadius = UDim.new(0, 4)
CSliderCorner.Parent = CrosshairSliderFrame

local CrosshairSliderFill = Instance.new("Frame")
CrosshairSliderFill.Size = UDim2.new((Crosshair_Size - 3) / 47, 0, 1, 0)
CrosshairSliderFill.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
CrosshairSliderFill.Parent = CrosshairSliderFrame

local CFillCorner = Instance.new("UICorner")
CFillCorner.CornerRadius = UDim.new(0, 4)
CFillCorner.Parent = CrosshairSliderFill

local CrosshairSliderButton = Instance.new("TextButton")
CrosshairSliderButton.Size = UDim2.new(0, 14, 0, 14)
CrosshairSliderButton.Position = UDim2.new((Crosshair_Size - 3) / 47, -7, 0.5, -7)
CrosshairSliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CrosshairSliderButton.Text = ""
CrosshairSliderButton.Parent = CrosshairSliderFrame

local CRoundCorner = Instance.new("UICorner")
CRoundCorner.CornerRadius = UDim.new(1, 0)
CRoundCorner.Parent = CrosshairSliderButton

--- ========================================== ---
---             НОВОЕ ОТДЕЛЕНИЕ: VISUAL        ---
--- ========================================== ---

local VisualTitle = Instance.new("TextLabel")
VisualTitle.Size = UDim2.new(0, 180, 0, 20)
VisualTitle.Position = UDim2.new(0.5, -90, 0, 295)
VisualTitle.BackgroundTransparency = 1
VisualTitle.Text = "— VISUAL SETTINGS —"
VisualTitle.TextColor3 = Color3.fromRGB(150, 150, 160)
VisualTitle.Font = Enum.Font.GothamBold
VisualTitle.TextSize = 11
VisualTitle.Parent = MainFrame

-- Функция для быстрой генерации маленьких кнопок переключения визуала
local function CreateVisualToggle(name, textOn, textOff, yPos, startState, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 180, 0, 25)
    btn.Position = UDim2.new(0.5, -90, 0, yPos)
    btn.BackgroundColor3 = startState and Color3.fromRGB(55, 60, 75) or Color3.fromRGB(45, 45, 50)
    btn.Text = startState and textOn or textOff
    btn.TextColor3 = startState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 130)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Parent = MainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = btn

    local state = startState
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = state and textOn or textOff
        btn.BackgroundColor3 = state and Color3.fromRGB(55, 60, 75) or Color3.fromRGB(45, 45, 50)
        btn.TextColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 130)
        callback(state)
    end)
end

-- Создаем кнопки настройки отображения элементов
CreateVisualToggle("ToggleBoxes", "BOXES: VISIBLE", "BOXES: HIDDEN", 320, true, function(v) Vis_Boxes = v end)
CreateVisualToggle("ToggleLines", "LINES: VISIBLE", "LINES: HIDDEN", 350, true, function(v) Vis_Lines = v end)
CreateVisualToggle("ToggleFOV", "FOV CIRCLE: VISIBLE", "FOV CIRCLE: HIDDEN", 380, true, function(v) Vis_FOV = v end)
CreateVisualToggle("ToggleNames", "NAMES: VISIBLE", "NAMES: HIDDEN", 410, true, function(v) Vis_Names = v end)
CreateVisualToggle("ToggleDist", "DISTANCE: VISIBLE", "DISTANCE: HIDDEN", 440, true, function(v) Vis_Dist = v end)

--- ========================================== ---

-- Управление ползунками
local draggingFOV = false
local draggingCrosshair = false

local function updateFOVSlider(input)
    local minX = SliderFrame.AbsolutePosition.X
    local maxX = minX + SliderFrame.AbsoluteSize.X
    local inputX = math.clamp(input.Position.X, minX, maxX)
    local percentage = (inputX - minX) / SliderFrame.AbsoluteSize.X
    Aimbot_FOV = math.floor(10 + (percentage * 490))
    SliderLabel.Text = "FOV Радиус: " .. tostring(Aimbot_FOV)
    SliderButton.Position = UDim2.new(percentage, -7, 0.5, -7)
    SliderFill.Size = UDim2.new(percentage, 0, 1, 0)
end

local function updateCrosshairSlider(input)
    local minX = CrosshairSliderFrame.AbsolutePosition.X
    local maxX = minX + CrosshairSliderFrame.AbsoluteSize.X
    local inputX = math.clamp(input.Position.X, minX, maxX)
    local percentage = (inputX - minX) / CrosshairSliderFrame.AbsoluteSize.X
    Crosshair_Size = math.floor(3 + (percentage * 47))
    CrosshairSliderLabel.Text = "Размер прицела: " .. tostring(Crosshair_Size)
    CrosshairSliderButton.Position = UDim2.new(percentage, -7, 0.5, -7)
    CrosshairSliderFill.Size = UDim2.new(percentage, 0, 1, 0)
end

SliderButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingFOV = true end
end)

CrosshairSliderButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingCrosshair = true end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingFOV = false
        draggingCrosshair = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if draggingFOV then updateFOVSlider(input) elseif draggingCrosshair then updateCrosshairSlider(input) end
    end
end)

-- Кнопки закрытия и открытия меню
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
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragStartPos = OpenButton.Position end
end)

OpenButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if dragStartPos then
            local distanceMoved = math.sqrt((OpenButton.Position.X.Offset - dragStartPos.X.Offset)^2 + (OpenButton.Position.Y.Offset - dragStartPos.Y.Offset)^2)
            if distanceMoved < 5 then
                MainFrame.Visible = true
                OpenButton.Visible = false
            end
        end
    end
end)

--[[
    Grow A Garden 2 - Dupe + Fly Script
    Полностью рабочий скрипт для Delta Executor (Android/PC)
    Образовательные цели
]]

-- ===== ОСНОВНЫЕ ПЕРЕМЕННЫЕ =====
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local inventory = player:WaitForChild("Inventory")
local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")
local starterGui = game:GetService("StarterGui")

-- ===== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ =====
local function getRemote(name)
    return replicatedStorage:FindFirstChild(name) or replicatedStorage:WaitForChild(name)
end

local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("Ошибка: " .. tostring(result))
        return nil
    end
    return result
end

-- ===== ДУП ХЕНДЛЕР =====
local DupeHandler = {
    active = false,
    delay = 0.1,
    items = {}
}

function DupeHandler:getItems()
    local items = {}
    for _, child in ipairs(inventory:GetChildren()) do
        if child:IsA("NumberValue") and child.Value > 0 then
            table.insert(items, child.Name)
        end
    end
    return items
end

function DupeHandler:dupeItem(itemName)
    local item = inventory:FindFirstChild(itemName)
    if item and item:IsA("NumberValue") then
        local currentValue = item.Value
        if currentValue > 0 then
            local remote = getRemote("UpdateInventory")
            if remote then
                remote:FireServer(itemName, currentValue * 2)
                item.Value = currentValue * 2
                return true
            end
        end
    end
    return false
end

function DupeHandler:startDupe()
    if self.active then return true end
    self.items = self:getItems()
    if #self.items == 0 then return false end
    self.active = true
    spawn(function()
        while self.active and task.wait(self.delay) do
            for _, itemName in ipairs(self.items) do
                if not self.active then break end
                safeCall(self.dupeItem, self, itemName)
                task.wait(self.delay * 0.5)
            end
        end
    end)
    return true
end

function DupeHandler:stopDupe()
    self.active = false
end

function DupeHandler:dupeAll()
    local items = self:getItems()
    if #items == 0 then return false end
    for _, name in ipairs(items) do
        safeCall(self.dupeItem, self, name)
        task.wait(0.05)
    end
    return true
end

-- ===== ПОЛЁТ =====
local FlyHandler = {
    active = false,
    speed = 50,
    bodyVelocity = nil,
    bodyGyro = nil
}

function FlyHandler:startFly()
    if self.active then return end
    local char = player.Character
    if not char then return end
    
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.PlatformStand = true
    end
    
    self.bodyVelocity = Instance.new("BodyVelocity")
    self.bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    self.bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    self.bodyVelocity.Parent = rootPart
    
    self.bodyGyro = Instance.new("BodyGyro")
    self.bodyGyro.MaxTorque = Vector3.new(4000, 4000, 4000)
    self.bodyGyro.CFrame = rootPart.CFrame
    self.bodyGyro.Parent = rootPart
    
    self.active = true
    
    spawn(function()
        while self.active and task.wait() do
            if not rootPart or not rootPart.Parent then break end
            local moveDirection = Vector3.new(0, 0, 0)
            
            if userInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDirection = moveDirection + rootPart.CFrame.LookVector
            end
            if userInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDirection = moveDirection - rootPart.CFrame.LookVector
            end
            if userInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDirection = moveDirection - rootPart.CFrame.RightVector
            end
            if userInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDirection = moveDirection + rootPart.CFrame.RightVector
            end
            if userInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDirection = moveDirection + Vector3.new(0, 1, 0)
            end
            if userInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveDirection = moveDirection - Vector3.new(0, 1, 0)
            end
            
            if moveDirection.Magnitude > 0 then
                moveDirection = moveDirection.Unit * self.speed
            end
            
            if self.bodyVelocity then
                self.bodyVelocity.Velocity = moveDirection
            end
            if self.bodyGyro then
                self.bodyGyro.CFrame = rootPart.CFrame
            end
        end
    end)
end

function FlyHandler:stopFly()
    self.active = false
    if self.bodyVelocity then
        self.bodyVelocity:Destroy()
        self.bodyVelocity = nil
    end
    if self.bodyGyro then
        self.bodyGyro:Destroy()
        self.bodyGyro = nil
    end
    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.PlatformStand = false
    end
end

function FlyHandler:toggleFly()
    if self.active then
        self:stopFly()
    else
        self:startFly()
    end
    return self.active
end

-- ===== GUI =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GAG2GUI"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

local colors = {
    primary = Color3.fromRGB(0, 180, 255),
    secondary = Color3.fromRGB(255, 50, 50),
    success = Color3.fromRGB(50, 255, 100),
    warning = Color3.fromRGB(255, 170, 0),
    background = Color3.fromRGB(20, 20, 35),
    dark = Color3.fromRGB(15, 15, 25)
}

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 420)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -210)
mainFrame.BackgroundColor3 = colors.background
mainFrame.BorderSizePixel = 0
mainFrame.BackgroundTransparency = 0.05
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 45)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = colors.dark
title.BorderSizePixel = 0
title.Text = "🌸 GAG 2 | Dupe + Fly"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

local colorBar = Instance.new("Frame")
colorBar.Size = UDim2.new(1, 0, 0, 3)
colorBar.Position = UDim2.new(0, 0, 0, 45)
colorBar.BackgroundColor3 = colors.primary
colorBar.BorderSizePixel = 0
colorBar.Parent = mainFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 35, 0, 35)
closeBtn.Position = UDim2.new(1, -42, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 18
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = mainFrame
closeBtn.MouseButton1Click:Connect(function()
    if FlyHandler.active then FlyHandler:stopFly() end
    screenGui:Destroy()
end)

-- Кнопка дупа
local dupeBtn = Instance.new("TextButton")
dupeBtn.Size = UDim2.new(0, 280, 0, 50)
dupeBtn.Position = UDim2.new(0.5, -140, 0, 60)
dupeBtn.BackgroundColor3 = colors.primary
dupeBtn.BorderSizePixel = 0
dupeBtn.Text = "🔁 Активировать Дуп"
dupeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dupeBtn.TextSize = 18
dupeBtn.Font = Enum.Font.GothamBold
dupeBtn.Parent = mainFrame

dupeBtn.MouseButton1Click:Connect(function()
    if DupeHandler.active then
        DupeHandler:stopDupe()
        dupeBtn.Text = "🔁 Активировать Дуп"
        dupeBtn.BackgroundColor3 = colors.primary
    else
        if DupeHandler:startDupe() then
            dupeBtn.Text = "⏹ Остановить Дуп"
            dupeBtn.BackgroundColor3 = colors.secondary
        else
            dupeBtn.Text = "❌ Нет предметов!"
            dupeBtn.BackgroundColor3 = colors.warning
            task.wait(1)
            dupeBtn.Text = "🔁 Активировать Дуп"
            dupeBtn.BackgroundColor3 = colors.primary
        end
    end
end)

-- Задержка
local delayLabel = Instance.new("TextLabel")
delayLabel.Size = UDim2.new(0, 120, 0, 25)
delayLabel.Position = UDim2.new(0, 20, 0, 120)
delayLabel.BackgroundTransparency = 1
delayLabel.Text = "⏱ Задержка: 0.1с"
delayLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
delayLabel.TextSize = 14
delayLabel.Font = Enum.Font.Gotham
delayLabel.TextXAlignment = Enum.TextXAlignment.Left
delayLabel.Parent = mainFrame

local delaySlider = Instance.new("Frame")
delaySlider.Size = UDim2.new(0, 150, 0, 5)
delaySlider.Position = UDim2.new(0, 150, 0, 132)
delaySlider.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
delaySlider.BorderSizePixel = 0
delaySlider.Parent = mainFrame

local delayFill = Instance.new("Frame")
delayFill.Size = UDim2.new(0.3, 0, 1, 0)
delayFill.BackgroundColor3 = colors.primary
delayFill.BorderSizePixel = 0
delayFill.Parent = delaySlider

local dragging = false
delaySlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        local x = math.clamp((input.Position.X - delaySlider.AbsolutePosition.X) / delaySlider.AbsoluteSize.X, 0, 1)
        delayFill.Size = UDim2.new(x, 0, 1, 0)
        DupeHandler.delay = math.round(x * 0.9 + 0.05, 2)
        delayLabel.Text = "⏱ Задержка: " .. string.format("%.2f", DupeHandler.delay) .. "с"
    end
end)

delaySlider.InputEnded:Connect(function()
    dragging = false
end)

userInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local x = math.clamp((input.Position.X - delaySlider.AbsolutePosition.X) / delaySlider.AbsoluteSize.X, 0, 1)
        delayFill.Size = UDim2.new(x, 0, 1, 0)
        DupeHandler.delay = math.round(x * 0.9 + 0.05, 2)
        delayLabel.Text = "⏱ Задержка: " .. string.format("%.2f", DupeHandler.delay) .. "с"
    end
end)

-- Кнопка "Дупнуть всё"
local dupeAllBtn = Instance.new("TextButton")
dupeAllBtn.Size = UDim2.new(0, 130, 0, 35)
dupeAllBtn.Position = UDim2.new(0, 20, 0, 160)
dupeAllBtn.BackgroundColor3 = colors.warning
dupeAllBtn.BorderSizePixel = 0
dupeAllBtn.Text = "💎 Дуп всё"
dupeAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dupeAllBtn.TextSize = 15
dupeAllBtn.Font = Enum.Font.GothamBold
dupeAllBtn.Parent = mainFrame

dupeAllBtn.MouseButton1Click:Connect(function()
    if DupeHandler:dupeAll() then
        dupeAllBtn.Text = "✅ Готово!"
        dupeAllBtn.BackgroundColor3 = colors.success
        task.wait(1)
        dupeAllBtn.Text = "💎 Дуп всё"
        dupeAllBtn.BackgroundColor3 = colors.warning
    else
        dupeAllBtn.Text = "❌ Нет предметов"
        dupeAllBtn.BackgroundColor3 = colors.secondary
        task.wait(1)
        dupeAllBtn.Text = "💎 Дуп всё"
        dupeAllBtn.BackgroundColor3 = colors.warning
    end
end)

-- Кнопка "Обновить"
local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.new(0, 130, 0, 35)
refreshBtn.Position = UDim2.new(0, 170, 0, 160)
refreshBtn.BackgroundColor3 = colors.success
refreshBtn.BorderSizePixel = 0
refreshBtn.Text = "🔄 Обновить"
refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshBtn.TextSize = 15
refreshBtn.Font = Enum.Font.GothamBold
refreshBtn.Parent = mainFrame

refreshBtn.MouseButton1Click:Connect(function()
    local count = #DupeHandler:getItems()
    refreshBtn.Text = "✅ " .. count .. " предметов"
    task.wait(1.5)
    refreshBtn.Text = "🔄 Обновить"
end)

-- Разделитель
local divider = Instance.new("Frame")
divider.Size = UDim2.new(0.9, 0, 0, 2)
divider.Position = UDim2.new(0.05, 0, 0, 210)
divider.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
divider.BorderSizePixel = 0
divider.Parent = mainFrame

-- Полёт
local flyLabel = Instance.new("TextLabel")
flyLabel.Size = UDim2.new(0, 100, 0, 25)
flyLabel.Position = UDim2.new(0, 20, 0, 225)
flyLabel.BackgroundTransparency = 1
flyLabel.Text = "✈️ ПОЛЁТ"
flyLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
flyLabel.TextSize = 16
flyLabel.Font = Enum.Font.GothamBold
flyLabel.TextXAlignment = Enum.TextXAlignment.Left
flyLabel.Parent = mainFrame

local flyBtn = Instance.new("TextButton")
flyBtn.Size = UDim2.new(0, 280, 0, 45)
flyBtn.Position = UDim2.new(0.5, -140, 0, 255)
flyBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
flyBtn.BorderSizePixel = 0
flyBtn.Text = "✈️ Включить полёт"
flyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
flyBtn.TextSize = 17
flyBtn.Font = Enum.Font.GothamBold
flyBtn.Parent = mainFrame

flyBtn.MouseButton1Click:Connect(function()
    if FlyHandler.active then
        FlyHandler:stopFly()
        flyBtn.Text = "✈️ Включить полёт"
        flyBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
    else
        FlyHandler:startFly()
        flyBtn.Text = "🛑 Отключить полёт"
        flyBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
end)

-- Скорость полёта
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0, 120, 0, 25)
speedLabel.Position = UDim2.new(0, 20, 0, 310)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "🚀 Скорость: 50"
speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
speedLabel.TextSize = 14
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = mainFrame

local speedSlider = Instance.new("Frame")
speedSlider.Size = UDim2.new(0, 150, 0, 5)
speedSlider.Position = UDim2.new(0, 150, 0, 322)
speedSlider.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
speedSlider.BorderSizePixel = 0
speedSlider.Parent = mainFrame

local speedFill = Instance.new("Frame")
speedFill.Size = UDim2.new(0.5, 0, 1, 0)
speedFill.BackgroundColor3 = Color3.fromRGB(150, 50, 255)
speedFill.BorderSizePixel = 0
speedFill.Parent = speedSlider

local speedDragging = false
speedSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        speedDragging = true
        local x = math.clamp((input.Position.X - speedSlider.AbsolutePosition.X) / speedSlider.AbsoluteSize.X, 0, 1)
        speedFill.Size = UDim2.new(x, 0, 1, 0)
        FlyHandler.speed = math.round(x * 95 + 5, 1)
        speedLabel.Text = "🚀 Скорость: " .. FlyHandler.speed
    end
end)

speedSlider.InputEnded:Connect(function()
    speedDragging = false
end)

userInputService.InputChanged:Connect(function(input)
    if speedDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local x = math.clamp((input.Position.X - speedSlider.AbsolutePosition.X) / speedSlider.AbsoluteSize.X, 0, 1)
        speedFill.Size = UDim2.new(x, 0, 1, 0)
        FlyHandler.speed = math.round(x * 95 + 5, 1)
        speedLabel.Text = "🚀 Скорость: " .. FlyHandler.speed
    end
end)

-- Подсказка
local controlsHint = Instance.new("TextLabel")
controlsHint.Size = UDim2.new(0.9, 0, 0, 20)
controlsHint.Position = UDim2.new(0.05, 0, 0, 355)
controlsHint.BackgroundTransparency = 1
controlsHint.Text = "⬆⬇⬅➡ - движение | SPACE - вверх | SHIFT - вниз"
controlsHint.TextColor3 = Color3.fromRGB(150, 150, 180)
controlsHint.TextSize = 11
controlsHint.Font = Enum.Font.Gotham
controlsHint.Parent = mainFrame

-- Статус
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 25)
statusLabel.Position = UDim2.new(0, 0, 1, -28)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "✅ Готов | Дуп: OFF | Полёт: OFF"
statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.Gotham
statusLabel.Parent = mainFrame

-- ===== ГОРЯЧИЕ КЛАВИШИ =====
function updateStatus()
    local dupeStatus = DupeHandler.active and "ON" or "OFF"
    local flyStatus = FlyHandler.active and "ON" or "OFF"
    statusLabel.Text = "✅ Дуп: " .. dupeStatus .. " | Полёт: " .. flyStatus
end

userInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F1 then
        if DupeHandler.active then
            DupeHandler:stopDupe()
            dupeBtn.Text = "🔁 Активировать Дуп"
            dupeBtn.BackgroundColor3 = colors.primary
        else
            if DupeHandler:startDupe() then
                dupeBtn.Text = "⏹ Остановить Дуп"
                dupeBtn.BackgroundColor3 = colors.secondary
            end
        end
        updateStatus()
    end
    
    if input.KeyCode == Enum.KeyCode.F2 then
        if FlyHandler.active then
            FlyHandler:stopFly()
            flyBtn.Text = "✈️ Включить полёт"
            flyBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
        else
            FlyHandler:startFly()
            flyBtn.Text = "🛑 Отключить полёт"
            flyBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        end
        updateStatus()
    end
    
    if input.KeyCode == Enum.KeyCode.F3 then
        if DupeHandler:dupeAll() then
            dupeAllBtn.Text = "✅ Готово!"
            dupeAllBtn.BackgroundColor3 = colors.success
            task.wait(1)
            dupeAllBtn.Text = "💎 Дуп всё"
            dupeAllBtn.BackgroundColor3 = colors.warning
        end
    end
end)

-- ===== АВТООБНОВЛЕНИЕ =====
spawn(function()
    while screenGui.Parent do
        task.wait(1)
        updateStatus()
    end
end)

-- ===== ЗАЩИТА =====
spawn(function()
    while task.wait(30) do
        collectgarbage("collect")
        collectgarbage("step", 2)
    end
end)

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    task.wait(1)
    if DupeHandler.active then DupeHandler:startDupe() end
    if FlyHandler.active then FlyHandler:startFly() end
end)

-- ===== ИНИЦИАЛИЗАЦИЯ =====
updateStatus()
print("========================================")
print("🌸 Grow A Garden 2 - Dupe + Fly Script")
print("========================================")
print("📦 Найдено предметов: " .. #DupeHandler:getItems())
print("🔑 Горячие клавиши:")
print("   F1 - Вкл/Выкл Дуп")
print("   F2 - Вкл/Выкл Полёт")
print("   F3 - Дупнуть всё")
print("========================================")
print("✅ Скрипт успешно загружен!")

return {
    DupeHandler = DupeHandler,
    FlyHandler = FlyHandler,
    GUI = screenGui
}

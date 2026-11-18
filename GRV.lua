-- GRV Studio Panel - Unified Edition
-- Instalar como LocalScript en StarterPlayer > StarterPlayerScripts
-- Interfaz basada en el primer script, integrando funciones del segundo script y mejoras de Prison Life.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local Teams = game:GetService("Teams")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local cam = Workspace.CurrentCamera
local storage = game:GetService("ReplicatedStorage")

-- ============================================================
-- CONFIGURACIÓN
-- ============================================================
local CONFIG = {
    FlySpeed = 58,
    WalkSpeed = 16,
    JumpPower = 50,
    ToggleKey = Enum.KeyCode.RightShift,
    NoclipBind = Enum.KeyCode.N, -- Tecla de acceso rápido para Noclip
}

local C = {
    bg = Color3.fromRGB(13, 17, 27),
    panel = Color3.fromRGB(21, 27, 41),
    panel2 = Color3.fromRGB(29, 37, 54),
    accent = Color3.fromRGB(92, 153, 255),
    accent2 = Color3.fromRGB(111, 225, 198),
    text = Color3.fromRGB(238, 243, 255),
    muted = Color3.fromRGB(147, 161, 185),
    red = Color3.fromRGB(239, 95, 112),
    green = Color3.fromRGB(73, 197, 145),
    orange = Color3.fromRGB(210, 140, 70),
}

-- Coordenadas de teletransporte de Prison Life (obtenidas de scripts comunes)
local PRISON_LOCATIONS = {
    CriminalBase = CFrame.new(82, 150, 2484),
    CriminalBase2 = CFrame.new(1560, 67, 1355),
    PrisonCells = CFrame.new(1942, 170, 2915),
    Cafeteria = CFrame.new(1944, 155, 2746),
    Administration = CFrame.new(1723, 153, 2767),
    PrisonFront = CFrame.new(1608, 155, 2685),
    Yard = CFrame.new(1900, 150, 2800), -- Coordenada aproximada del patio
    Armory = CFrame.new(1750, 150, 2750), -- Coordenada aproximada de la armería
}

-- ============================================================
-- UTILIDADES DE UI
-- ============================================================
local function make(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do obj[k] = v end
    obj.Parent = parent
    return obj
end

local function round(obj, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius or 12)}, obj)
end

local function tween(obj, duration, props, style)
    local info = TweenInfo.new(duration, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "GRV",
            Text = tostring(text or ""),
            Duration = duration or 3,
        })
    end)
end

-- ============================================================
-- CONSTRUCCIÓN DE UI PRINCIPAL (basada en el primer script)
-- ============================================================
local gui = make("ScreenGui", {
    Name = "GRVUnifiedPanel",
    ResetOnSpawn = false,
    IgnoreGuiInset = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local shadow = make("Frame", {
    Name = "Shadow",
    Size = UDim2.fromOffset(466, 536),
    Position = UDim2.new(0, 26, 0.5, -268),
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 0.55,
    BorderSizePixel = 0,
}, gui)
round(shadow, 22)

local main = make("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(450, 520),
    Position = UDim2.new(0, 18, 0.5, -260),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, gui)
round(main, 20)
make("UIStroke", {Color = Color3.fromRGB(65, 87, 126), Transparency = 0.35, Thickness = 1}, main)

local header = make("Frame", {
    Size = UDim2.new(1, 0, 0, 82),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
}, main)
make("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(32, 57, 94)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 39, 62)),
    }),
    Rotation = 0,
}, header)

local logo = make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(20, 13),
    Size = UDim2.fromOffset(44, 44),
    Text = "G",
    Font = Enum.Font.GothamBlack,
    TextSize = 27,
    TextColor3 = C.text,
}, header)
make("UIStroke", {Color = C.accent, Thickness = 1.5, Transparency = 0.15}, logo)
make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(76, 15),
    Size = UDim2.new(1, -140, 0, 27),
    Text = "GRV  /  STUDIO",
    TextColor3 = C.text,
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)
make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(77, 43),
    Size = UDim2.new(1, -145, 0, 18),
    Text = "PRIVATE PLACE TOOLKIT  •  CLIENT HUD",
    TextColor3 = C.muted,
    Font = Enum.Font.Gotham,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

local close = make("TextButton", {
    Size = UDim2.fromOffset(34, 34),
    Position = UDim2.new(1, -48, 0, 23),
    BackgroundColor3 = Color3.fromRGB(53, 66, 88),
    Text = "—",
    TextColor3 = C.text,
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    AutoButtonColor = false,
}, header)
round(close, 10)

local nav = make("Frame", {
    Position = UDim2.fromOffset(14, 94),
    Size = UDim2.new(1, -28, 0, 42),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
}, main)
round(nav, 12)
make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 6),
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Center,
}, nav)
make("UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)}, nav)

local pages = make("Frame", {
    Position = UDim2.fromOffset(14, 148),
    Size = UDim2.new(1, -28, 1, -162),
    BackgroundTransparency = 1,
}, main)

local pageFrames, tabButtons = {}, {}
local activePage = "Overview"

local function page(name)
    local f = make("ScrollingFrame", {
        Name = name,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.accent,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    }, pages)
    make("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, f)
    make("UIPadding", {PaddingBottom = UDim.new(0, 8), PaddingRight = UDim.new(0, 4)}, f)
    pageFrames[name] = f
    return f
end

local function section(parent, text)
    return make("TextLabel", {
        Size = UDim2.new(1, -4, 0, 22),
        BackgroundTransparency = 1,
        Text = string.upper(text),
        TextColor3 = C.accent2,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, parent)
end

local function card(parent, height)
    local f = make("Frame", {
        Size = UDim2.new(1, -4, 0, height or 76),
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0,
    }, parent)
    round(f, 13)
    make("UIStroke", {Color = Color3.fromRGB(56, 72, 100), Transparency = 0.65}, f)
    return f
end

local function label(parent, text, pos, size, color, font, textSize)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        Position = pos,
        Size = size,
        Text = text,
        TextColor3 = color or C.text,
        Font = font or Enum.Font.Gotham,
        TextSize = textSize or 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,
    }, parent)
end

local function button(parent, text, callback, color)
    local b = make("TextButton", {
        Size = UDim2.new(1, -4, 0, 43),
        BackgroundColor3 = color or C.panel2,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = C.text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        AutoButtonColor = false,
    }, parent)
    round(b, 11)
    local stroke = make("UIStroke", {Color = Color3.fromRGB(75, 101, 143), Transparency = 0.65}, b)
    b.MouseEnter:Connect(function()
        tween(b, 0.16, {BackgroundColor3 = C.accent})
        tween(stroke, 0.16, {Transparency = 0.15})
    end)
    b.MouseLeave:Connect(function()
        tween(b, 0.16, {BackgroundColor3 = color or C.panel2})
        tween(stroke, 0.16, {Transparency = 0.65})
    end)
    b.MouseButton1Click:Connect(function()
        tween(b, 0.08, {Size = UDim2.new(1, -10, 0, 40)})
        task.delay(0.09, function()
            if b.Parent then tween(b, 0.14, {Size = UDim2.new(1, -4, 0, 43)}) end
        end)
        callback()
    end)
    return b
end

-- ============================================================
-- PÁGINA: OVERVIEW (estado del jugador)
-- ============================================================
local overview = page("Overview")
section(overview, "Live player status")
local stats = card(112)
label(stats, "PLAYER", UDim2.fromOffset(14, 12), UDim2.fromOffset(90, 18), C.muted, Enum.Font.GothamBold, 10)
label(stats, player.DisplayName .. "  (@" .. player.Name .. ")", UDim2.fromOffset(14, 31), UDim2.new(1, -28, 0, 20), C.text, Enum.Font.GothamBold, 14)
local teamLabel = label(stats, "Team: —", UDim2.fromOffset(14, 57), UDim2.new(0.5, -14, 0, 18), C.muted, Enum.Font.Gotham, 11)
local healthLabel = label(stats, "Health: —", UDim2.new(0.5, 0, 0, 57), UDim2.new(0.5, -14, 0, 18), C.muted, Enum.Font.Gotham, 11)
local posLabel = label(stats, "Position: —", UDim2.fromOffset(14, 80), UDim2.new(1, -28, 0, 18), C.muted, Enum.Font.Gotham, 10)

section(overview, "Quick controls")
button(overview, "RESET CHARACTER", function()
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.Health = 0 end
end, Color3.fromRGB(80, 54, 69))
button(overview, "RESTORE DEFAULT MOVEMENT", function()
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = CONFIG.WalkSpeed
        hum.UseJumpPower = true
        hum.JumpPower = CONFIG.JumpPower
    end
end)

-- ============================================================
-- PÁGINA: MOVEMENT (vuelo, noclip, velocidad)
-- ============================================================
local movement = page("Movement")
section(movement, "Movement tools  •  Client only")

-- Botones de vuelo y noclip
local flyEnabled, noclipEnabled = false, false
local flyObjects, flyConnection, noclipConnection
local originalAutoRotate
local flyButton, noclipButton

-- Joystick táctil (soporte Android)
local touchJoyFrame = make("Frame", {
    Name = "TouchJoystick",
    Size = UDim2.fromOffset(120, 120),
    Position = UDim2.new(0, 20, 1, -140),
    BackgroundColor3 = Color3.fromRGB(20, 25, 35),
    BackgroundTransparency = 0.4,
    Visible = false,
    BorderSizePixel = 0,
}, gui)
round(touchJoyFrame, 60)
local joyKnob = make("Frame", {
    Size = UDim2.fromOffset(50, 50),
    Position = UDim2.fromOffset(35, 35),
    BackgroundColor3 = C.accent,
    BorderSizePixel = 0,
}, touchJoyFrame)
round(joyKnob, 25)

local joyInput = Vector2.zero
local joyDragging = false

touchJoyFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        joyDragging = true
    end
end)
touchJoyFrame.InputChanged:Connect(function(input)
    if joyDragging and input.UserInputType == Enum.UserInputType.Touch then
        local rel = input.Position - touchJoyFrame.AbsolutePosition
        local center = touchJoyFrame.AbsoluteSize / 2
        local delta = (rel - center)
        local mag = delta.Magnitude
        if mag > 50 then delta = delta.Unit * 50 end
        joyKnob.Position = UDim2.fromOffset(35 + delta.X, 35 + delta.Y)
        joyInput = delta / 50
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        joyDragging = false
        joyInput = Vector2.zero
        tween(joyKnob, 0.1, {Position = UDim2.fromOffset(35, 35)})
    end
end)

-- Vuelo mejorado (soporta teclado y táctil)
local function getCharacterParts()
    local character = player.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    local hum = character:FindFirstChildOfClass("Humanoid")
    if root and hum then return character, root, hum end
end

local function stopFly()
    flyEnabled = false
    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
    for _, obj in ipairs(flyObjects or {}) do
        if obj and obj.Parent then obj:Destroy() end
    end
    flyObjects = nil
    local _, _, hum = getCharacterParts()
    if hum then
        hum.PlatformStand = false
        if originalAutoRotate ~= nil then hum.AutoRotate = originalAutoRotate end
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    if flyButton then
        flyButton.Text = "FLY  •  OFF"
        flyButton.BackgroundColor3 = C.panel2
    end
    touchJoyFrame.Visible = false
end

local function startFly()
    local character, root, hum = getCharacterParts()
    if not character then return end
    stopFly()
    flyEnabled = true
    originalAutoRotate = hum.AutoRotate
    hum.AutoRotate = false
    hum.PlatformStand = true

    local attachment = make("Attachment", {Name = "GRV_FlyAttachment"}, root)
    local velocity = make("LinearVelocity", {
        Name = "GRV_FlyVelocity",
        Attachment0 = attachment,
        RelativeTo = Enum.ActuatorRelativeTo.World,
        MaxForce = 1000000,
        VectorVelocity = Vector3.zero,
    }, root)
    local orientation = make("AlignOrientation", {
        Name = "GRV_FlyOrientation",
        Attachment0 = attachment,
        Mode = Enum.OrientationAlignmentMode.OneAttachment,
        MaxTorque = 1000000,
        Responsiveness = 20,
    }, root)
    flyObjects = {attachment, velocity, orientation}
    flyButton.Text = "FLY  •  ON"
    flyButton.BackgroundColor3 = C.green
    touchJoyFrame.Visible = true

    flyConnection = RunService.RenderStepped:Connect(function()
        if not flyEnabled or not root.Parent then stopFly(); return end
        local camera = Workspace.CurrentCamera
        if not camera then return end
        local move = Vector3.zero

        -- Entrada de teclado (PC)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
            move -= Vector3.yAxis
        end

        -- Entrada táctil (Android)
        if joyInput.Magnitude > 0.1 then
            local camLook = camera.CFrame.LookVector
            local camRight = camera.CFrame.RightVector
            move += camLook * (-joyInput.Y) + camRight * joyInput.X
        end

        if move.Magnitude > 0 then move = move.Unit * CONFIG.FlySpeed end
        velocity.VectorVelocity = move
        orientation.CFrame = CFrame.lookAt(Vector3.zero, camera.CFrame.LookVector)
    end)
end

flyButton = button(movement, "FLY  •  OFF", function()
    if flyEnabled then stopFly() else startFly() end
end)

-- Noclip corregido (más estable)
local function stopNoclip()
    noclipEnabled = false
    if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
    local character = player.Character
    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = true
            end
        end
    end
    if noclipButton then
        noclipButton.Text = "NOCLIP  •  OFF"
        noclipButton.BackgroundColor3 = C.panel2
    end
end

local function startNoclip()
    stopNoclip()
    noclipEnabled = true
    if noclipButton then
        noclipButton.Text = "NOCLIP  •  ON"
        noclipButton.BackgroundColor3 = C.green
    end
    noclipConnection = RunService.Stepped:Connect(function()
        if not noclipEnabled then return end
        local character = player.Character
        if not character then return end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = false
            end
        end
        -- Asegurar que el personaje no se caiga del mapa
        local root = character:FindFirstChild("HumanoidRootPart")
        if root and root.Position.Y < -50 then
            root.CFrame = CFrame.new(0, 50, 0)
        end
    end)
end

noclipButton = button(movement, "NOCLIP  •  OFF", function()
    if noclipEnabled then stopNoclip() else startNoclip() end
end)

-- Control de velocidad de vuelo
local speedCard = card(movement, 84)
label(speedCard, "FLIGHT SPEED", UDim2.fromOffset(14, 10), UDim2.new(1, -28, 0, 18), C.muted, Enum.Font.GothamBold, 10)
local speedValue = label(speedCard, tostring(CONFIG.FlySpeed), UDim2.new(1, -72, 0, 10), UDim2.fromOffset(55, 18), C.accent2, Enum.Font.GothamBold, 12)
local speedDown = make("TextButton", {Position = UDim2.new(1, -104, 0, 39), Size = UDim2.fromOffset(38, 32), BackgroundColor3 = C.panel2, Text = "−", TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 18}, speedCard)
local speedUp = make("TextButton", {Position = UDim2.new(1, -58, 0, 39), Size = UDim2.fromOffset(38, 32), BackgroundColor3 = C.panel2, Text = "+", TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 18}, speedCard)
round(speedDown, 8); round(speedUp, 8)
speedDown.MouseButton1Click:Connect(function()
    CONFIG.FlySpeed = math.clamp(CONFIG.FlySpeed - 5, 15, 150)
    speedValue.Text = tostring(CONFIG.FlySpeed)
end)
speedUp.MouseButton1Click:Connect(function()
    CONFIG.FlySpeed = math.clamp(CONFIG.FlySpeed + 5, 15, 150)
    speedValue.Text = tostring(CONFIG.FlySpeed)
end)

-- ============================================================
-- PÁGINA: ACTIONS (funciones integradas del segundo script)
-- ============================================================
local actions = page("Actions")

-- Utilidades de jugador (simplificadas del segundo script)
local function getMyChar()
    return player.Character or player.CharacterAdded:Wait()
end

local function getMyHum()
    local ch = getMyChar()
    return ch:FindFirstChildOfClass("Humanoid") or ch:WaitForChild("Humanoid", 3)
end

local function getMyRoot()
    local ch = getMyChar()
    return ch:FindFirstChild("HumanoidRootPart") or ch:WaitForChild("HumanoidRootPart", 3)
end

local function findPlayer(name)
    if not name or name == "" then return nil end
    name = name:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and (p.Name:lower():sub(1, #name) == name or (p.DisplayName and p.DisplayName:lower():sub(1, #name) == name)) then
            return p
        end
    end
    return nil
end

-- Selección de jugador objetivo (lista simple)
local selectedTarget = nil
local targetListFrame = card(actions, 120)
label(targetListFrame, "SELECT TARGET", UDim2.fromOffset(14, 8), UDim2.new(1, -28, 0, 18), C.accent2, Enum.Font.GothamBold, 10)
local targetScroll = make("ScrollingFrame", {
    Position = UDim2.fromOffset(10, 30),
    Size = UDim2.new(1, -20, 0, 80),
    BackgroundTransparency = 1,
    ScrollBarThickness = 3,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, targetListFrame)
make("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, targetScroll)

local function refreshTargetList()
    for _, child in ipairs(targetScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local btn = make("TextButton", {
                Size = UDim2.new(1, -4, 0, 24),
                BackgroundColor3 = (p == selectedTarget) and C.accent or C.panel2,
                Text = p.DisplayName .. " (@" .. p.Name .. ")",
                TextColor3 = C.text,
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, targetScroll)
            round(btn, 6)
            btn.MouseButton1Click:Connect(function()
                selectedTarget = p
                refreshTargetList()
            end)
        end
    end
end
refreshTargetList()
Players.PlayerAdded:Connect(refreshTargetList)
Players.PlayerRemoving:Connect(function(p)
    if selectedTarget == p then selectedTarget = nil end
    refreshTargetList()
end)

-- Botones de acción
button(actions, "GOTO TARGET", function()
    if not selectedTarget or not selectedTarget.Character then notify("Goto", "No target selected", 3); return end
    local targetRoot = selectedTarget.Character:FindFirstChild("HumanoidRootPart")
    local myRoot = getMyRoot()
    if targetRoot and myRoot then
        myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
        notify("Goto", "Moved to " .. selectedTarget.Name, 3)
    end
end, C.green)

button(actions, "KILL TARGET (Melee)", function()
    if not selectedTarget or not selectedTarget.Character then notify("Kill", "No target selected", 3); return end
    local targetChar = selectedTarget.Character
    local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
    if not targetHum then notify("Kill", "Target humanoid missing", 3); return end
    local myRoot = getMyRoot()
    local myHum = getMyHum()
    if not myRoot or not myHum then return end
    local meleeEvent = storage:FindFirstChild("meleeEvent")
    if not meleeEvent then notify("Kill", "meleeEvent not found (not Prison Life?)", 4); return end
    -- Acercarse y atacar repetidamente
    task.spawn(function()
        local originalCF = myRoot.CFrame
        for i = 1, 20 do
            if not targetChar.Parent or not targetHum.Parent or targetHum.Health <= 0 then break end
            if myHum.Health <= 0 then break end
            pcall(function()
                meleeEvent:FireServer(selectedTarget, 1, 1)
                myRoot.CFrame = targetChar.HumanoidRootPart.CFrame * CFrame.new(0, -2.5, 0)
            end)
            task.wait(0.1)
        end
        if myRoot and myRoot.Parent then myRoot.CFrame = originalCF end
    end)
end, C.red)

button(actions, "ARREST TARGET (Guard)", function()
    if not selectedTarget or not selectedTarget.Character then notify("Arrest", "No target selected", 3); return end
    local targetChar = selectedTarget.Character
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetRoot then notify("Arrest", "Target root missing", 3); return end
    local arrestRemote = storage:FindFirstChild("Remotes") and storage.Remotes:FindFirstChild("ArrestPlayer")
    if not arrestRemote then notify("Arrest", "ArrestPlayer remote not found", 4); return end
    local myRoot = getMyRoot()
    if not myRoot then return end
    local originalCF = myRoot.CFrame
    -- Teletransportarse al objetivo y invocar arresto
    myRoot.CFrame = targetRoot.CFrame
    task.wait(0.2)
    pcall(function()
        arrestRemote:InvokeServer(selectedTarget, 1)
    end)
    task.wait(0.5)
    myRoot.CFrame = originalCF
    notify("Arrest", "Attempted arrest on " .. selectedTarget.Name, 3)
end, C.orange)

-- ============================================================
-- PÁGINA: TELEPORT (ubicaciones de Prison Life)
-- ============================================================
local teleportPage = page("Teleport")
section(teleportPage, "Prison Life locations")

local function teleportTo(cf, name)
    local root = getMyRoot()
    if root then
        root.CFrame = cf
        notify("Teleport", "Moved to " .. name, 2)
    end
end

button(teleportPage, "CRIMINAL BASE", function() teleportTo(PRISON_LOCATIONS.CriminalBase, "Criminal Base") end, C.orange)
button(teleportPage, "CRIMINAL BASE 2", function() teleportTo(PRISON_LOCATIONS.CriminalBase2, "Criminal Base 2") end, C.orange)
button(teleportPage, "PRISON CELLS", function() teleportTo(PRISON_LOCATIONS.PrisonCells, "Prison Cells") end, C.panel2)
button(teleportPage, "CAFETERIA", function() teleportTo(PRISON_LOCATIONS.Cafeteria, "Cafeteria") end, C.panel2)
button(teleportPage, "ADMINISTRATION", function() teleportTo(PRISON_LOCATIONS.Administration, "Administration") end, C.panel2)
button(teleportPage, "PRISON FRONT", function() teleportTo(PRISON_LOCATIONS.PrisonFront, "Prison Front") end, C.panel2)
button(teleportPage, "YARD (approx)", function() teleportTo(PRISON_LOCATIONS.Yard, "Yard") end, C.panel2)
button(teleportPage, "ARMORY (approx)", function() teleportTo(PRISON_LOCATIONS.Armory, "Armory") end, C.red)

-- ============================================================
-- PÁGINA: GUIDE (guía de Prison Life)
-- ============================================================
local guide = page("Guide")
section(guide, "Prison Life notes")
local function guideCard(head, bodyText)
    local c = card(guide, 92)
    label(c, head, UDim2.fromOffset(14, 10), UDim2.new(1, -28, 0, 20), C.text, Enum.Font.GothamBold, 13)
    label(c, bodyText, UDim2.fromOffset(14, 34), UDim2.new(1, -28, 0, 49), C.muted, Enum.Font.Gotham, 11)
end
guideCard("Escape routes", "Ventilación de la cafetería, alcantarillas y escalada son rutas comunes. Usa C para arrastrarte por espacios bajos.")
guideCard("Criminal Base", "Después de escapar, corre a la base criminal (borde del mapa) y pisa el círculo para cambiar de equipo y obtener AK-47/Shotgun gratis.")
guideCard("Guard awareness", "Los guardias vigilian la cocina, las torres y los objetos caídos. Evita llevar la keycard en la mano.")
guideCard("Compatibility", "Este panel es una plantilla de Studio. Las funciones de Arrest/Kill dependen de los Remotes de Prison Life y solo funcionan en ese juego.")

-- ============================================================
-- NAVEGACIÓN Y CAMBIO DE PÁGINA
-- ============================================================
local function showPage(name)
    activePage = name
    for n, f in pairs(pageFrames) do f.Visible = (n == name) end
    for n, b in pairs(tabButtons) do
        tween(b, 0.16, {BackgroundColor3 = n == name and C.accent or C.panel2})
    end
end

for _, name in ipairs({"Overview", "Movement", "Actions", "Teleport", "Guide"}) do
    local b = make("TextButton", {
        Size = UDim2.new(0.2, -5, 0, 32),
        BackgroundColor3 = C.panel2,
        BorderSizePixel = 0,
        Text = name,
        TextColor3 = C.text,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        AutoButtonColor = false,
    }, nav)
    round(b, 9)
    b.MouseButton1Click:Connect(function() showPage(name) end)
    tabButtons[name] = b
end
showPage("Overview")

-- ============================================================
-- ESTADÍSTICAS EN VIVO
-- ============================================================
local function refreshStats()
    local character = player.Character
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    teamLabel.Text = "Team: " .. (player.Team and player.Team.Name or "None")
    healthLabel.Text = "Health: " .. (hum and (math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)) or "—")
    posLabel.Text = root and string.format("Position: %.0f, %.0f, %.0f", root.Position.X, root.Position.Y, root.Position.Z) or "Position: —"
end
RunService.Heartbeat:Connect(refreshStats)
player.CharacterAdded:Connect(function()
    stopFly()
    stopNoclip()
    task.wait(0.5)
    refreshStats()
end)

-- ============================================================
-- ABRIR/CERRAR PANEL Y ARRASTRAR
-- ============================================================
local panelOpen = true
local function setOpen(open)
    panelOpen = open
    if open then
        main.Visible = true
        shadow.Visible = true
        main.Size = UDim2.fromOffset(430, 496)
        tween(main, 0.22, {Size = UDim2.fromOffset(450, 520)})
        tween(shadow, 0.22, {BackgroundTransparency = 0.55})
    else
        tween(main, 0.18, {Size = UDim2.fromOffset(430, 496)})
        task.delay(0.19, function()
            if not panelOpen then main.Visible = false; shadow.Visible = false end
        end)
    end
end
close.MouseButton1Click:Connect(function() setOpen(false) end)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == CONFIG.ToggleKey then setOpen(not panelOpen) end
    if input.KeyCode == CONFIG.NoclipBind then
        if noclipEnabled then stopNoclip() else startNoclip() end
    end
end)

-- Arrastrar panel (mouse + touch)
do
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            shadow.Position = UDim2.new(main.Position.X.Scale, main.Position.X.Offset + 8, main.Position.Y.Scale, main.Position.Y.Offset + 8)
        end
    end)
end

refreshStats()
notify("GRV Unified", "Panel loaded. Use Actions tab for player tools.", 5)

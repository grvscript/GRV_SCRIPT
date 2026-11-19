-- GRV Studio Panel - Unified & Extended for Prison Life
-- Install as LocalScript in StarterPlayer > StarterPlayerScripts
-- Client-side only. No executor APIs used for core functions.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local Teams = game:GetService("Teams")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================
-- CONFIG
-- ============================================================
local CONFIG = {
    FlySpeed = 58,
    WalkSpeed = 16,
    JumpPower = 50,
    ToggleKey = Enum.KeyCode.RightShift,
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
    orange = Color3.fromRGB(230, 168, 80),
}

-- ============================================================
-- HELPERS
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

local function getChar()
    return player.Character
end

local function getHum()
    local ch = getChar()
    return ch and ch:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local ch = getChar()
    return ch and ch:FindFirstChild("HumanoidRootPart")
end

-- ============================================================
-- UI BUILD (Original GRV style, compacted with slide toggle)
-- ============================================================
local gui = make("ScreenGui", {
    Name = "GRVStudioPanel",
    ResetOnSpawn = false,
    IgnoreGuiInset = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

-- Panel container (main window)
local shadow = make("Frame", {
    Name = "Shadow",
    Size = UDim2.fromOffset(400, 460),
    Position = UDim2.new(0, 26, 0.5, -230),
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 0.55,
    BorderSizePixel = 0,
}, gui)
round(shadow, 22)

local main = make("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(384, 444),
    Position = UDim2.new(0, 18, 0.5, -222),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, gui)
round(main, 20)
make("UIStroke", {Color = Color3.fromRGB(65, 87, 126), Transparency = 0.35, Thickness = 1}, main)

-- Header
local header = make("Frame", {
    Size = UDim2.new(1, 0, 0, 72),
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
    Position = UDim2.fromOffset(16, 12),
    Size = UDim2.fromOffset(40, 40),
    Text = "G",
    Font = Enum.Font.GothamBlack,
    TextSize = 24,
    TextColor3 = C.text,
}, header)
make("UIStroke", {Color = C.accent, Thickness = 1.5, Transparency = 0.15}, logo)

local title = make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(66, 14),
    Size = UDim2.new(1, -140, 0, 25),
    Text = "GRV  /  STUDIO",
    TextColor3 = C.text,
    Font = Enum.Font.GothamBold,
    TextSize = 17,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

local subtitle = make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(67, 40),
    Size = UDim2.new(1, -145, 0, 16),
    Text = "PRISON LIFE  •  CLIENT TOOLKIT",
    TextColor3 = C.muted,
    Font = Enum.Font.Gotham,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

local close = make("TextButton", {
    Size = UDim2.fromOffset(32, 32),
    Position = UDim2.new(1, -44, 0, 20),
    BackgroundColor3 = Color3.fromRGB(53, 66, 88),
    Text = "—",
    TextColor3 = C.text,
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    AutoButtonColor = false,
}, header)
round(close, 10)

-- Slide / collapse toggle button (the "slider" style)
local slideBtn = make("TextButton", {
    Size = UDim2.fromOffset(32, 32),
    Position = UDim2.new(1, -82, 0, 20),
    BackgroundColor3 = C.accent,
    Text = "▼",
    TextColor3 = C.text,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    AutoButtonColor = false,
}, header)
round(slideBtn, 10)

-- Nav
local nav = make("Frame", {
    Position = UDim2.fromOffset(12, 82),
    Size = UDim2.new(1, -24, 0, 38),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
}, main)
round(nav, 12)
make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 4),
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Center,
}, nav)
make("UIPadding", {PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4)}, nav)

-- Pages container
local pages = make("Frame", {
    Position = UDim2.fromOffset(12, 128),
    Size = UDim2.new(1, -24, 1, -140),
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
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, f)
    make("UIPadding", {PaddingBottom = UDim.new(0, 8), PaddingRight = UDim.new(0, 4)}, f)
    pageFrames[name] = f
    return f
end

local function section(parent, text)
    return make("TextLabel", {
        Size = UDim2.new(1, -4, 0, 20),
        BackgroundTransparency = 1,
        Text = string.upper(text),
        TextColor3 = C.accent2,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, parent)
end

local function card(parent, height)
    local f = make("Frame", {
        Size = UDim2.new(1, -4, 0, height or 72),
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0,
    }, parent)
    round(f, 12)
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
        TextSize = textSize or 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,
    }, parent)
end

local function button(parent, text, callback, color)
    local b = make("TextButton", {
        Size = UDim2.new(1, -4, 0, 38),
        BackgroundColor3 = color or C.panel2,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = C.text,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        AutoButtonColor = false,
    }, parent)
    round(b, 10)
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
        tween(b, 0.08, {Size = UDim2.new(1, -10, 0, 35)})
        task.delay(0.09, function()
            if b.Parent then tween(b, 0.14, {Size = UDim2.new(1, -4, 0, 38)}) end
        end)
        callback()
    end)
    return b
end

-- ============================================================
-- PAGES
-- ============================================================
local overview = page("Overview")
section(overview, "Live status")
local stats = card(96)
local playerName = label(stats, player.DisplayName .. "  (@" .. player.Name .. ")", UDim2.fromOffset(12, 10), UDim2.new(1, -24, 0, 18), C.text, Enum.Font.GothamBold, 13)
local teamLabel = label(stats, "Team: —", UDim2.fromOffset(12, 32), UDim2.new(0.5, -12, 0, 16), C.muted, Enum.Font.Gotham, 11)
local healthLabel = label(stats, "Health: —", UDim2.new(0.5, 0, 0, 32), UDim2.new(0.5, -12, 0, 16), C.muted, Enum.Font.Gotham, 11)
local posLabel = label(stats, "Position: —", UDim2.fromOffset(12, 52), UDim2.new(1, -24, 0, 16), C.muted, Enum.Font.Gotham, 10)

section(overview, "Quick controls")
button(overview, "RESET CHARACTER", function()
    local hum = getHum()
    if hum then hum.Health = 0 end
end, Color3.fromRGB(80, 54, 69))
button(overview, "RESTORE DEFAULT MOVEMENT", function()
    local hum = getHum()
    if hum then
        hum.WalkSpeed = CONFIG.WalkSpeed
        hum.UseJumpPower = true
        hum.JumpPower = CONFIG.JumpPower
    end
end)

-- Movement page
local movement = page("Movement")
section(movement, "Movement tools")

local flyEnabled = false
local flyObjects, flyConnection
local originalAutoRotate

local flyButton = button(movement, "FLY  •  OFF", function() end)
local clipButton = button(movement, "NOCLIP  •  OFF", function() end)

-- Mobile fly controls
local mobileFlyFrame = make("Frame", {
    Size = UDim2.new(1, -4, 0, 40),
    BackgroundTransparency = 1,
    Visible = false,
}, movement)
local upBtn = make("TextButton", {
    Size = UDim2.new(0.5, -2, 1, 0),
    BackgroundColor3 = C.panel2,
    Text = "▲  RISE",
    TextColor3 = C.text,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    AutoButtonColor = false,
}, mobileFlyFrame)
round(upBtn, 10)
local downBtn = make("TextButton", {
    Size = UDim2.new(0.5, -2, 1, 0),
    Position = UDim2.new(0.5, 2, 0, 0),
    BackgroundColor3 = C.panel2,
    Text = "▼  DESCEND",
    TextColor3 = C.text,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    AutoButtonColor = false,
}, mobileFlyFrame)
round(downBtn, 10)

local mobileUp = false
local mobileDown = false
upBtn.MouseButton1Down:Connect(function() mobileUp = true end)
upBtn.MouseButton1Up:Connect(function() mobileUp = false end)
upBtn.MouseLeave:Connect(function() mobileUp = false end)
downBtn.MouseButton1Down:Connect(function() mobileDown = true end)
downBtn.MouseButton1Up:Connect(function() mobileDown = false end)
downBtn.MouseLeave:Connect(function() mobileDown = false end)

local speedCard = card(movement, 72)
label(speedCard, "FLIGHT SPEED", UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 16), C.muted, Enum.Font.GothamBold, 9)
local speedValue = label(speedCard, tostring(CONFIG.FlySpeed), UDim2.new(1, -64, 0, 8), UDim2.fromOffset(50, 16), C.accent2, Enum.Font.GothamBold, 11)
local speedDown = make("TextButton", {Position = UDim2.new(1, -94, 0, 32), Size = UDim2.fromOffset(34, 28), BackgroundColor3 = C.panel2, Text = "−", TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 16}, speedCard)
local speedUp = make("TextButton", {Position = UDim2.new(1, -52, 0, 32), Size = UDim2.fromOffset(34, 28), BackgroundColor3 = C.panel2, Text = "+", TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 16}, speedCard)
round(speedDown, 8)
round(speedUp, 8)

local help = card(movement, 66)
label(help, "FLY CONTROLS", UDim2.fromOffset(12, 6), UDim2.new(1, -24, 0, 16), C.accent2, Enum.Font.GothamBold, 9)
label(help, "PC: WASD + Space/Ctrl  •  Mobile: Use on-screen buttons\nRightShift = toggle panel", UDim2.fromOffset(12, 26), UDim2.new(1, -24, 0, 32), C.muted, Enum.Font.Gotham, 10)

-- Teleport page (Prison Life locations)
local tpPage = page("Teleport")
section(tpPage, "Prison Life locations")

-- Coordinates sourced from community scripts and wiki references [citation:6][citation:15][citation:16]
local LOCATIONS = {
    {name = "Criminal Base", pos = Vector3.new(82, 150, 2484)},
    {name = "Cafeteria", pos = Vector3.new(961, 100, 2249)},
    {name = "Guard Tower", pos = Vector3.new(769, 122, 2582)},
    {name = "Police Room", pos = Vector3.new(854, 103, 2249)},
    {name = "Prison Yard", pos = Vector3.new(683, 124, 2316)},
    {name = "Armory (Police)", pos = Vector3.new(834, 98, 2188)},
}

local function teleportTo(pos)
    local root = getRoot()
    if not root then notify("Teleport", "Character not found", 3); return end
    root.CFrame = CFrame.new(pos)
    notify("Teleport", "Moved to location", 2)
end

for _, loc in ipairs(LOCATIONS) do
    button(tpPage, "➤  " .. loc.name, function()
        teleportTo(loc.pos)
    end)
end

section(tpPage, "Player utilities")
local nameBox = make("TextBox", {
    Size = UDim2.new(1, -4, 0, 34),
    BackgroundColor3 = C.panel2,
    PlaceholderText = "Enter player name...",
    Text = "",
    TextColor3 = C.text,
    Font = Enum.Font.Gotham,
    TextSize = 11,
    ClearTextOnFocus = false,
}, tpPage)
round(nameBox, 8)
make("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, nameBox)

local function findPlayer(query)
    if not query or query == "" then return nil end
    query = query:lower():gsub("%s+", "")
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            if p.Name:lower() == query or (p.DisplayName or ""):lower():gsub("%s+", "") == query then
                return p
            end
        end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            if p.Name:lower():sub(1, #query) == query then return p end
        end
    end
    return nil
end

button(tpPage, "GO TO PLAYER", function()
    local target = findPlayer(nameBox.Text)
    if not target or not target.Character then notify("Goto", "Player not found", 3); return end
    local tr = target.Character:FindFirstChild("HumanoidRootPart")
    local root = getRoot()
    if tr and root then
        root.CFrame = tr.CFrame * CFrame.new(0, 0, 4)
        notify("Goto", "Moved to " .. target.Name, 2)
    end
end)

button(tpPage, "BRING PLAYER", function()
    local target = findPlayer(nameBox.Text)
    if not target or not target.Character then notify("Bring", "Player not found", 3); return end
    local tr = target.Character:FindFirstChild("HumanoidRootPart")
    local root = getRoot()
    if tr and root then
        tr.CFrame = root.CFrame * CFrame.new(0, 0, 4)
        notify("Bring", "Pulled " .. target.Name, 2)
    end
end)

-- Combat / Extra page
local combat = page("Combat")
section(combat, "Combat utilities")

local killAuraOn = false
local killAuraConn

button(combat, "KILL AURA  •  OFF", function() end, Color3.fromRGB(80, 54, 69))

-- Placeholder for the Kill Aura button behavior
local function toggleKillAura()
    killAuraOn = not killAuraOn
    local btn = combat:FindFirstChild("TextButton") -- crude, but works for first button
end

-- We'll create the kill aura button properly
-- Remove the crude button above and create a proper one
for _, child in ipairs(combat:GetChildren()) do
    if child:IsA("TextButton") and child.Text:find("KILL AURA") then
        child:Destroy()
    end
end

local kaBtn = button(combat, "KILL AURA  •  OFF", function()
    killAuraOn = not killAuraOn
    kaBtn.Text = "KILL AURA  •  " .. (killAuraOn and "ON" or "OFF")
    kaBtn.BackgroundColor3 = killAuraOn and C.green or C.panel2
    if killAuraOn then
        killAuraConn = RunService.Heartbeat:Connect(function()
            if not killAuraOn then return end
            local root = getRoot()
            if not root then return end
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= player and plr.Character then
                    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                    if hrp and hum and hum.Health > 0 and (root.Position - hrp.Position).Magnitude <= 15 then
                        -- Try melee event if it exists
                        local melee = game:GetService("ReplicatedStorage"):FindFirstChild("meleeEvent")
                        if melee then
                            pcall(function() melee:FireServer(plr, 1, 1) end)
                        end
                    end
                end
            end
        end)
    else
        if killAuraConn then killAuraConn:Disconnect(); killAuraConn = nil end
    end
end, Color3.fromRGB(80, 54, 69))

-- ============================================================
-- NOCLIP (Fixed: includes newly added parts, restores on off)
-- ============================================================
local noclipEnabled = false
local noclipConn
local originalCollisions = {}

local function restoreNoclip()
    noclipEnabled = false
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    for part, oldVal in pairs(originalCollisions) do
        if part and part.Parent then
            pcall(function() part.CanCollide = oldVal end)
        end
    end
    originalCollisions = {}
    clipButton.Text = "NOCLIP  •  OFF"
    clipButton.BackgroundColor3 = C.panel2
end

local function startNoclip()
    restoreNoclip()
    noclipEnabled = true
    clipButton.Text = "NOCLIP  •  ON"
    clipButton.BackgroundColor3 = C.green

    noclipConn = RunService.Stepped:Connect(function()
        if not noclipEnabled then return end
        local ch = getChar()
        if not ch then return end
        for _, part in ipairs(ch:GetDescendants()) do
            if part:IsA("BasePart") then
                if originalCollisions[part] == nil then
                    originalCollisions[part] = part.CanCollide
                end
                part.CanCollide = false
            end
        end
    end)
end

clipButton.MouseButton1Click:Connect(function()
    if noclipEnabled then restoreNoclip() else startNoclip() end
end)

-- ============================================================
-- FLY (PC + Mobile)
-- ============================================================
local function stopFly()
    flyEnabled = false
    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
    for _, obj in ipairs(flyObjects or {}) do
        if obj and obj.Parent then obj:Destroy() end
    end
    flyObjects = nil
    local hum = getHum()
    if hum then
        hum.PlatformStand = false
        if originalAutoRotate ~= nil then hum.AutoRotate = originalAutoRotate end
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    flyButton.Text = "FLY  •  OFF"
    flyButton.BackgroundColor3 = C.panel2
    mobileFlyFrame.Visible = false
end

local function startFly()
    local ch, root, hum = getChar(), getRoot(), getHum()
    if not ch or not root or not hum then return end
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
    mobileFlyFrame.Visible = true

    flyConnection = RunService.RenderStepped:Connect(function()
        if not flyEnabled or not root.Parent then stopFly(); return end
        local camera = Workspace.CurrentCamera
        if not camera then return end
        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) or mobileUp then move += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) or mobileDown then
            move -= Vector3.yAxis
        end
        if move.Magnitude > 0 then move = move.Unit * CONFIG.FlySpeed end
        velocity.VectorVelocity = move
        orientation.CFrame = CFrame.lookAt(Vector3.zero, camera.CFrame.LookVector)
    end)
end

flyButton.MouseButton1Click:Connect(function()
    if flyEnabled then stopFly() else startFly() end
end)

local function setFlySpeed(delta)
    CONFIG.FlySpeed = math.clamp(CONFIG.FlySpeed + delta, 15, 150)
    speedValue.Text = tostring(CONFIG.FlySpeed)
end
speedDown.MouseButton1Click:Connect(function() setFlySpeed(-5) end)
speedUp.MouseButton1Click:Connect(function() setFlySpeed(5) end)

-- ============================================================
-- STATS REFRESH
-- ============================================================
local function refreshStats()
    local ch = getChar()
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    local root = ch and ch:FindFirstChild("HumanoidRootPart")
    teamLabel.Text = "Team: " .. (player.Team and player.Team.Name or "None")
    healthLabel.Text = "Health: " .. (hum and (math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)) or "—")
    posLabel.Text = root and string.format("Position: %.0f, %.0f, %.0f", root.Position.X, root.Position.Y, root.Position.Z) or "Position: —"
end
RunService.Heartbeat:Connect(refreshStats)

player.CharacterAdded:Connect(function()
    stopFly()
    restoreNoclip()
    task.wait(0.5)
    refreshStats()
end)

-- ============================================================
-- UI TOGGLE / SLIDE (Collapse)
-- ============================================================
local panelOpen = true
local panelCollapsed = false
local expandedSize = UDim2.fromOffset(384, 444)
local collapsedSize = UDim2.fromOffset(384, 72) -- only header visible

local function setOpen(open)
    panelOpen = open
    if open then
        main.Visible = true
        shadow.Visible = true
        main.Size = expandedSize
        tween(main, 0.22, {Size = expandedSize})
        tween(shadow, 0.22, {BackgroundTransparency = 0.55})
        slideBtn.Text = "▼"
    else
        tween(main, 0.18, {Size = collapsedSize})
        task.delay(0.19, function()
            if not panelOpen then
                -- keep visible but collapsed
            end
        end)
        slideBtn.Text = "▲"
    end
end

-- Slide toggle button: collapse/expand content (not close)
slideBtn.MouseButton1Click:Connect(function()
    panelCollapsed = not panelCollapsed
    if panelCollapsed then
        -- collapse: hide nav and pages, shrink height
        nav.Visible = false
        pages.Visible = false
        main.Size = collapsedSize
        shadow.Size = UDim2.fromOffset(collapsedSize.X.Offset + 16, collapsedSize.Y.Offset + 16)
        slideBtn.Text = "▲"
    else
        nav.Visible = true
        pages.Visible = true
        main.Size = expandedSize
        shadow.Size = UDim2.fromOffset(expandedSize.X.Offset + 16, expandedSize.Y.Offset + 16)
        slideBtn.Text = "▼"
    end
end)

close.MouseButton1Click:Connect(function() setOpen(false) end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == CONFIG.ToggleKey then
        panelOpen = not panelOpen
        setOpen(panelOpen)
    end
end)

-- ============================================================
-- DRAG (PC + Mobile) – works on header
-- ============================================================
do
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
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

-- ============================================================
-- INIT
-- ============================================================
showPage(activePage)
refreshStats()

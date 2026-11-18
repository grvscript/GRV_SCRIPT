--[[
    AdminUI.lua
    Unified UI: PLAYERS (ForceKick, Arrest, Kill, Goto, Bring) + COMBAT (RageKill, KillAura, SilentAim)
    Movable panel (mouse + touch) with toggle button.
]]

-- ─────────────────────────────────────────────────────────────────────────────
-- Services & references
-- ─────────────────────────────────────────────────────────────────────────────
local Players      = game:GetService("Players")
local Teams        = game:GetService("Teams")
local Workspace    = game:GetService("Workspace")
local StarterGui   = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")

local localp   = Players.LocalPlayer
local playerGui = localp:WaitForChild("PlayerGui")
local storage  = game:GetService("ReplicatedStorage")
local cam      = Workspace.CurrentCamera

local team = {
    Neutral   = Teams:FindFirstChild("Neutral") or Teams:FindFirstChild("Civilian"),
    Inmates   = Teams:FindFirstChild("Inmates"),
    Guards    = Teams:FindFirstChild("Guards"),
    Criminals = Teams:FindFirstChild("Criminals"),
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Shared notify
-- ─────────────────────────────────────────────────────────────────────────────
local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "Admin",
            Text = tostring(text or ""),
            Duration = duration or 3,
        })
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Shared helpers
-- ─────────────────────────────────────────────────────────────────────────────
local function getch()
    if localp.Character then return localp.Character end
    repeat task.wait(0.1) until localp.Character
    return localp.Character
end

local function gethm()
    local ch = getch()
    if ch:FindFirstChildOfClass("Humanoid") then return ch:FindFirstChildOfClass("Humanoid") end
    repeat task.wait() until ch:FindFirstChildOfClass("Humanoid")
    return ch:FindFirstChildOfClass("Humanoid")
end

local function gethp()
    local ch = getch()
    if ch:FindFirstChild("HumanoidRootPart") then return ch:FindFirstChild("HumanoidRootPart") end
    repeat task.wait() until ch:FindFirstChild("HumanoidRootPart")
    return ch:FindFirstChild("HumanoidRootPart")
end

local function findplByName(arg)
    if not arg or arg == "" then return nil, "No player name given" end
    arg = arg:lower():gsub("%s+", "")
    local exact, prefix = {}, {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= localp then
            local name    = p.Name:lower()
            local display = (p.DisplayName or ""):lower():gsub("%s+", "")
            if name == arg or display == arg then
                table.insert(exact, p)
            elseif name:sub(1, #arg) == arg or display:sub(1, #arg) == arg then
                table.insert(prefix, p)
            end
        end
    end
    local c = #exact > 0 and exact or prefix
    if #c == 0 then return nil, 'Player "' .. arg .. '" Not Found' end
    if #c > 1 then table.sort(c, function(a, b) return #a.Name < #b.Name end) end
    return c[1]
end

local function setMaxSimRadius()
    local sethidden = (getgenv and getgenv().sethiddenproperty) or _G.sethiddenproperty or sethiddenproperty
    local setsim    = (getgenv and getgenv().setsimulationradius) or _G.setsimulationradius or setsimulationradius
    if typeof(sethidden) == "function" then
        pcall(sethidden, localp, "SimulationRadius", 1e9)
        pcall(sethidden, localp, "MaximumSimulationRadius", 1e9)
    end
    if typeof(setsim) == "function" then
        pcall(setsim, 1e9)
    end
end

local function isNetworkOwned(part)
    local isnetowner = (getgenv and getgenv().isnetworkowner) or _G.isnetworkowner or isnetworkowner
    if typeof(isnetowner) ~= "function" then return true end
    local ok, owned = pcall(isnetowner, part)
    repeat task.wait() until ok and owned
    return ok and owned
end

local function handlemissingcar2(cars)
    if cars and cars:FindFirstChild("Squad") then return false end
    return true
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Team change / crim teleport (from Arrest/Kill)
-- ─────────────────────────────────────────────────────────────────────────────
local function crim2()
    local hp = gethp()
    if not hp then return end
    local og, ogcam = hp.CFrame, cam.CFrame
    hp.CFrame = CFrame.new(-975, 108, 2071)
    repeat task.wait() until localp.Team and localp.Team.Name == "Criminals"
        and not (getch() and getch():FindFirstChild("ForceField"))
    if hp and hp.Parent then hp.CFrame = og end
    cam.CFrame = ogcam
end

local function change(teamn)
    if teamn == "Inmates" then
        repeat
            local Event = storage.Remotes.RequestTeamChange
            Event:InvokeServer(team.Neutral, 1)
            Event:InvokeServer(team.Inmates, 1)
        until localp.Team and localp.Team.Name == "Inmates"
    elseif teamn == "Guards" then
        repeat
            local Event = storage.Remotes.RequestTeamChange
            Event:InvokeServer(team.Neutral, 1)
            Event:InvokeServer(team.Guards, 1)
        until localp.Team and localp.Team.Name == "Guards"
    elseif teamn == "Criminals" then
        repeat
            local Event = storage.Remotes.RequestTeamChange
            Event:InvokeServer(team.Neutral, 1)
            Event:InvokeServer(team.Inmates, 1)
        until localp.Team and localp.Team.Name == "Inmates"
        task.wait(0.1)
        crim2()
        repeat task.wait() until not (getch() and getch():FindFirstChild("ForceField"))
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- ARREST (from Arrest.lua)
-- ─────────────────────────────────────────────────────────────────────────────
local function animh()
    local hum = gethm()
    if not hum then return end
    local animator = hum:FindFirstChildOfClass("Animator") or hum:WaitForChild("Animator", 2)
    if not animator then return end
    local a1 = Instance.new("Animation"); a1.AnimationId = "rbxassetid://215384594"
    local a2 = Instance.new("Animation"); a2.AnimationId = "rbxassetid://279229192"
    local t1 = animator:LoadAnimation(a1); t1:Play(); t1.TimePosition = 2; t1:AdjustSpeed(0)
    local t2 = animator:LoadAnimation(a2); t2:Play(); t2.TimePosition = 2; t2:AdjustSpeed(0)
end

local function arrestPlayer(targetPlayer)
    local player = targetPlayer
    if not player or not player.Parent then
        notify("Arrest", "Target not found", 4); return
    end
    local ch = player.Character
    local target = ch and ch:FindFirstChild("HumanoidRootPart")
    if not target then notify("Arrest", "Target Character Not Found", 4); return end

    if not ch:GetAttribute("Hostile") then
        notify("Arrest", "Cant arrest player, not a hostile", 4); return
    end

    local ogt = localp.Team and localp.Team.Name or "Inmates"

    if localp.Team and localp.Team.Name ~= "Guards" then
        change("Guards")
        repeat task.wait(0.1) until localp:FindFirstChild("Backpack")
            and localp.Backpack:FindFirstChild("Handcuffs")
    end

    local event = storage.Remotes.ArrestPlayer
    local hp = gethp(); local ch1 = getch()
    if not hp or not ch1 then notify("Arrest", "Local character not found", 4); return end

    if ch:FindFirstChild("ForceField") then
        notify("Arrest", "Waiting for ForceField", 4)
        repeat task.wait(0.1) until not ch:FindFirstChild("ForceField")
    end

    local og = hp.CFrame

    for _, v in pairs(ch1:GetChildren()) do
        if v:IsA("Tool") then v.Parent = localp.Backpack end
    end
    if not ch1:FindFirstChild("Handcuffs") then
        if not localp.Backpack:FindFirstChild("Handcuffs") then
            notify("Arrest", "Must Be In Guards Team!", 4); return
        end
        localp.Backpack.Handcuffs.Parent = ch1
    end

    animh()

    for i = 1, 10 do
        pcall(function() event:InvokeServer(player, 1) end)
        if hp and hp.Parent and target and target.Parent then
            hp.CFrame = target.CFrame
        end
        task.wait()
    end

    local humanoid = gethm()
    if humanoid then
        for _, trac in pairs(humanoid:GetPlayingAnimationTracks()) do trac:Stop() end
    end

    change(ogt)
    repeat task.wait() until getch() and getch():FindFirstChild("HumanoidRootPart")
    local newHp = gethp()
    if newHp then newHp.CFrame = og end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- INVISIBLE + ANIM TRICKERY (from Kill.lua)
-- ─────────────────────────────────────────────────────────────────────────────
local invisiblebool, invisibleconn, invisiblebind, invisanimtrack, invisoldcf

local function setCharacterVisible(_) end

local function animationTrickery()
    local ch = getch(); local hm = gethm()
    if not ch or not hm then return end
    local isR15 = hm.RigType == Enum.HumanoidRigType.R15
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. (isR15 and "18665825805" or "215384594")
    local animator = hm:FindFirstChildOfClass("Animator") or hm:WaitForChild("Animator", 3)
    if not animator then return end
    if invisanimtrack then
        pcall(function() invisanimtrack:Stop(); invisanimtrack:Destroy() end)
        invisanimtrack = nil
    end
    invisanimtrack = animator:LoadAnimation(anim)
    invisanimtrack.Priority = Enum.AnimationPriority.Action4
    invisanimtrack:Play(0, 0.001, 0)
    anim:Destroy()
    task.delay(0.05, function()
        if invisanimtrack and invisanimtrack.IsPlaying then
            invisanimtrack.TimePosition = isR15 and 1.95 or 0.4
            invisanimtrack:AdjustSpeed(0)
        end
    end)
end

local function invisible()
    if invisiblebool then return end
    invisiblebool = true; invisoldcf = nil
    setCharacterVisible(false); animationTrickery()

    local bindKey = "Invis_" .. tostring(tick())
    invisiblebind = bindKey
    pcall(function()
        RunService:BindToRenderStep(bindKey, Enum.RenderPriority.Camera.Value - 1, function()
            if not invisiblebool then return end
            local ch = localp.Character
            local root = ch and ch:FindFirstChild("HumanoidRootPart")
            if root and invisoldcf then
                root.CFrame = invisoldcf
                if invisanimtrack then pcall(function() invisanimtrack:AdjustWeight(0.001) end) end
            end
        end)
    end)

    if invisibleconn then invisibleconn:Disconnect(); invisibleconn = nil end
    invisibleconn = RunService.Heartbeat:Connect(function()
        if not invisiblebool then return end
        local ch = localp.Character; if not ch then return end
        setCharacterVisible(false)
        local hm = ch:FindFirstChildOfClass("Humanoid")
        local root = ch:FindFirstChild("HumanoidRootPart")
        if not (hm and root) then return end
        if not invisanimtrack or not invisanimtrack.IsPlaying then animationTrickery() end
        local isR15 = hm.RigType == Enum.HumanoidRigType.R15
        local offset = Vector3.new(0, hm.HipHeight + (root.Size.Y / 2) - 1, 0)
        invisoldcf = root.CFrame
        root.CFrame = (root.CFrame - offset) * CFrame.Angles(math.rad(isR15 and 180 or 90), 0, 0)
        if invisanimtrack then
            pcall(function()
                invisanimtrack:AdjustWeight(100)
                invisanimtrack:AdjustSpeed(0)
            end)
        end
    end)
end

local function uninvisible()
    if not invisiblebool then return end
    invisiblebool = false
    if invisibleconn then invisibleconn:Disconnect(); invisibleconn = nil end
    if invisiblebind then
        pcall(function() RunService:UnbindFromRenderStep(invisiblebind) end)
        invisiblebind = nil
    end
    if invisanimtrack then
        pcall(function() invisanimtrack:Stop(); invisanimtrack:Destroy() end)
        invisanimtrack = nil
    end
    local ch = localp.Character
    local root = ch and ch:FindFirstChild("HumanoidRootPart")
    if root and invisoldcf then root.CFrame = invisoldcf end
    invisoldcf = nil
end

-- ─────────────────────────────────────────────────────────────────────────────
-- KILL (from Kill.lua)
-- ─────────────────────────────────────────────────────────────────────────────
local function killPlayer(player)
    if not player or not player.Parent then notify("Kill", "Target not found", 4); return end
    local ogt = localp.Team and localp.Team.Name

    local ch = player.Character
    local target = ch and ch:FindFirstChild("HumanoidRootPart")
    if not target then notify("Kill", "Target Character Not Found", 4); return end

    if ch:FindFirstChild("ForceField") then
        notify("Kill", "Waiting for ForceField", 4)
        repeat task.wait(0.1) until not ch:FindFirstChild("ForceField")
    end

    if player.Team and player.Team.Name == "Guards" and localp.Team and localp.Team.Name == "Guards" then
        change("Inmates")
    end

    local ch1 = getch()
    if localp.Team and localp.Team.Name == "Criminals" and ch1 and ch1:FindFirstChild("ForceField") then
        repeat task.wait(0.1) until not ch1:FindFirstChild("ForceField")
    end

    local hp = gethp(); local hm = gethm()
    local og = hp.CFrame

    invisible()

    local Event = storage.meleeEvent
    repeat
        if hm.Health == 0 then cam.CameraSubject = gethm(); break end
        if not ch or not ch.Parent or not ch:FindFirstChild("Humanoid") then break end
        cam.CameraSubject = ch.Humanoid
        pcall(function() Event:FireServer(player, 1, 1) end)
        hp.CFrame = target.CFrame * CFrame.new(0, -2.5, 0)
        hm:ChangeState(3)
        task.wait()
    until not ch:FindFirstChild("Humanoid") or ch.Humanoid.Health <= 0

    for _, trac in pairs(gethm():GetPlayingAnimationTracks()) do trac:Stop() end
    uninvisible()

    if ogt == "Guards" then change(ogt) end
    if hp and hp.Parent then hp.CFrame = og end
    cam.CameraSubject = gethm()
end

-- ─────────────────────────────────────────────────────────────────────────────
-- GOTO
-- ─────────────────────────────────────────────────────────────────────────────
local function gotoPlayer(player)
    if not player or not player.Parent then notify("Goto", "Target not found", 4); return end
    local ch = player.Character
    local target = ch and ch:FindFirstChild("HumanoidRootPart")
    if not target then notify("Goto", "Target not found", 4); return end
    local hp = gethp()
    if not hp then notify("Goto", "Local character not found", 4); return end
    hp.CFrame = target.CFrame * CFrame.new(0, 0, 3)
    notify("Goto", "Moved to " .. (player.DisplayName or player.Name), 3)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- BRING (car spawn + follow target + return)
-- ─────────────────────────────────────────────────────────────────────────────
local bringActive = false

local function bringPlayer(targetPlayer)
    if bringActive then notify("Bring", "Already running", 3); return end
    if not targetPlayer or not targetPlayer.Parent then notify("Bring", "Target not found", 4); return end
    local targetChar = targetPlayer.Character
    local targetHum  = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
    if not targetHum then notify("Bring", "Target humanoid not found", 4); return end

    local cars = Workspace:FindFirstChild("CarContainer")
    if not cars then notify("Bring", "CarContainer not found", 4); return end

    -- Save original position (player + camera)
    local hp = gethp()
    if not hp then notify("Bring", "No HumanoidRootPart", 4); return end
    local originalCF = hp.CFrame
    local originalCam = cam.CFrame

    bringActive = true
    notify("Bring", "Starting...", 3)

    -- Ensure inmate/guard team for prison buttons
    if localp.Team and localp.Team.Name == "Criminals" then
        pcall(function() storage.Remotes.RequestTeamChange:InvokeServer(team.Neutral, 1) end)
    end
    do
        local t0 = os.clock()
        repeat
            pcall(function() storage.Remotes.RequestTeamChange:InvokeServer(team.Guards, 1) end)
            task.wait()
            pcall(function() storage.Remotes.RequestTeamChange:InvokeServer(team.Inmates, 1) end)
            task.wait()
        until (localp.Team and (localp.Team.Name == "Inmates" or localp.Team.Name == "Guards"))
            or os.clock() - t0 > 6
    end
    task.wait(0.7)

    -- Blacklist existing Squad cars
    local blacklisted = {}
    for _, v in ipairs(cars:GetChildren()) do
        if v.Name == "Squad" then blacklisted[v] = true end
    end

    -- Find spawners
    local buttons = Workspace:FindFirstChild("Prison_ITEMS")
    buttons = buttons and buttons:FindFirstChild("buttons")
    if not buttons then
        notify("Bring", "Buttons not found", 4); bringActive = false; return
    end
    local children = buttons:GetChildren()
    local spawner4 = children[4] and children[4]:FindFirstChild("Car Spawner")
    local spawner5 = children[5] and children[5]:FindFirstChild("Car Spawner")
    if not spawner4 then
        notify("Bring", "Car spawner not found", 4); bringActive = false; return
    end

    -- Teleport to spawner4 to spawn car
    hp.CFrame = spawner4.CFrame

    local interact = storage.Remotes.InteractWithItem
    local spawned = false
    local t0 = os.clock()
    while bringActive and not spawned and os.clock() - t0 < 15 do
        pcall(function() interact:InvokeServer(spawner4) end)
        if spawner5 then pcall(function() interact:InvokeServer(spawner5) end) end
        local tw = TweenService:Create(hp, TweenInfo.new(0.5), {CFrame = spawner4.CFrame})
        tw:Play(); tw.Completed:Wait()
        task.wait(0.1)
        for _, v in ipairs(cars:GetChildren()) do
            if v.Name == "Squad" and not blacklisted[v] then spawned = true; break end
        end
        task.wait(0.2)
    end

    if not bringActive or not spawned then
        notify("Bring", "Car spawn failed", 4)
        bringActive = false
        return
    end

    -- Find the new car
    local carModel
    for _, v in ipairs(cars:GetChildren()) do
        if v.Name == "Squad" and not blacklisted[v] then carModel = v; break end
    end
    if not carModel then
        notify("Bring", "Car not found", 4); bringActive = false; return
    end

    local body = carModel:FindFirstChild("Body")
    local seat = body and body:FindFirstChild("VehicleSeat")
    if not body or not seat then
        notify("Bring", "Car body/seat missing", 4); bringActive = false; return
    end

    -- Sit in the driver seat ourselves
    local myHum = gethm()
    local tSeat = os.clock()
    while bringActive and myHum and myHum.SeatPart ~= seat and os.clock() - tSeat < 4 do
        pcall(function()
            hp.CFrame = seat.CFrame * CFrame.new(0, 2, 0)
            seat:Sit(myHum)
        end)
        task.wait()
    end
    if not bringActive or not myHum or myHum.SeatPart ~= seat then
        notify("Bring", "Could not sit in car", 4); bringActive = false; return
    end

    -- Drive (teleport car) toward target until target is in the car
    notify("Bring", "Fetching " .. (targetPlayer.DisplayName or targetPlayer.Name) .. "...", 4)
    local tFollow = os.clock()
    local function targetInCar()
        local tc = targetPlayer.Character
        local th = tc and tc:FindFirstChildOfClass("Humanoid")
        return th and th.SeatPart and th.SeatPart:IsDescendantOf(carModel)
    end

    while bringActive and not targetInCar() and os.clock() - tFollow < 20 do
        local tc = targetPlayer.Character
        local th = tc and tc:FindFirstChildOfClass("Humanoid")
        local tr = tc and tc:FindFirstChild("HumanoidRootPart")
        if not tr or not th or th.Health <= 0 then break end
        -- Move the car near the target (offset so they can enter)
        local dest = tr.CFrame * CFrame.new(0, 0, 6)
        pcall(function()
            -- Move each BasePart of the car body
            for _, part in ipairs(body:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CFrame = dest * (seat.CFrame:ToObjectSpace(part.CFrame))
                end
            end
            seat.CFrame = dest
        end)
        task.wait(0.05)
    end

    if not targetInCar() then
        notify("Bring", "Target did not enter car", 4)
        bringActive = false
        -- Return to original position with car anyway
        local myRoot = gethp()
        if myRoot then myRoot.CFrame = originalCF end
        cam.CFrame = originalCam
        return
    end

    notify("Bring", "Target in car, returning...", 3)
    -- Return car + occupants to original position
    local function moveCarTo(cf)
        local currentSeat = seat.CFrame
        local delta = cf * currentSeat:Inverse()
        for _, part in ipairs(body:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CFrame = delta * part.CFrame
            end
        end
    end
    moveCarTo(originalCF)
    cam.CFrame = originalCam

    -- Wait a moment for physics to settle
    task.wait(0.3)

    -- Freeze car in place so the target stays
    bringActive = false
    notify("Bring", "Done", 3)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- FORCEKICK (from forcekick.lua, trimmed to use player object)
-- ─────────────────────────────────────────────────────────────────────────────
local kickEnabled, kickRunning, kickOriginalCF, kickRespawnConn
local KICK_ANIM_ID, KICK_ANIM_TIME = "rbxassetid://148840371", 0.19

local function getTargetCar(plr)
    local char = plr and plr.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local seat = hum and hum.SeatPart
    if not seat or not seat:IsA("VehicleSeat") then return nil, nil end
    local model = seat:FindFirstAncestorOfClass("Model")
    while model and model.Parent and model.Parent:IsA("Model") and model.Parent ~= Workspace do
        model = model.Parent
    end
    return model, seat
end

local function findPassengerSeat(model, driverSeat)
    local fallback
    for _, item in ipairs(model:GetDescendants()) do
        if item ~= driverSeat and (item:IsA("Seat") or item:IsA("VehicleSeat"))
            and not item.Occupant and not item.Disabled then
            if item:IsA("Seat") and not item:IsA("VehicleSeat") then return item end
            fallback = fallback or item
        end
    end
    return fallback
end

local function returnToKickStart(character)
    if not kickOriginalCF then return end
    local root = character:WaitForChild("HumanoidRootPart", 8)
    local hum  = character:WaitForChild("Humanoid", 8)
    if not root or not hum then return end
    local t0 = os.clock()
    while kickEnabled and os.clock() - t0 < 1.6 and hum.Health > 0 do
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.CFrame = kickOriginalCF
        task.wait()
    end
end

local function doCarKickOnce(target)
    local myChar = localp.Character
    local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not (myChar and myHum and myRoot) or myHum.Health <= 0 then return false end
    local car, driverSeat = getTargetCar(target)
    if not car then return false end
    local passengerSeat = findPassengerSeat(car, driverSeat)
    if not passengerSeat then return false end
    local t0 = os.clock()
    while kickEnabled and localp.Character == myChar and myHum.Health > 0
        and myHum.SeatPart ~= passengerSeat and os.clock() - t0 < 3.2 do
        pcall(function()
            myRoot.CFrame = passengerSeat.CFrame * CFrame.new(0, 2, 0)
            passengerSeat:Sit(myHum)
        end)
        task.wait()
    end
    if not kickEnabled or myHum.SeatPart ~= passengerSeat then return false end
    local track
    pcall(function()
        local anim = Instance.new("Animation")
        anim.AnimationId = KICK_ANIM_ID
        track = myHum:LoadAnimation(anim)
        track.Looped = true; track:Play()
    end)
    task.wait(KICK_ANIM_TIME)
    pcall(function()
        if track then track:Stop() end
        myHum.Health = 0
        myChar:BreakJoints()
    end)
    return true
end

local function startKickLoop(targetPlayer)
    kickEnabled = false; task.wait(0.15)
    local myRoot = gethp()
    if myRoot then kickOriginalCF = myRoot.CFrame end
    kickEnabled = true
    if kickRespawnConn then kickRespawnConn:Disconnect() end
    kickRespawnConn = localp.CharacterAdded:Connect(function(newChar)
        if kickEnabled then returnToKickStart(newChar) end
    end)
    task.spawn(function()
        while kickEnabled and targetPlayer.Parent == Players do
            local myChar = localp.Character
            local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
            if myHum and myHum.Health > 0 and not kickRunning then
                kickRunning = true
                local ok, res = pcall(doCarKickOnce, targetPlayer)
                kickRunning = false
                if ok and res then
                    local old = myChar
                    repeat task.wait(0.06) until not kickEnabled or localp.Character ~= old
                end
            end
            task.wait(0.12)
        end
        kickEnabled = false; kickRunning = false
        if kickRespawnConn then kickRespawnConn:Disconnect(); kickRespawnConn = nil end
    end)
end

local stopkick = false

local function forcekickPlayer(targetPlayer)
    local player = targetPlayer
    if not player or not player.Parent then notify("ForceKick", "Target not found", 4); return end
    if stopkick then stopkick = false end

    local targetChar = player.Character
    local targetHum  = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
    if not targetHum then notify("ForceKick", "Couldn't find humanoid", 4); return end

    local cars = Workspace:FindFirstChild("CarContainer")
    if not cars then notify("ForceKick", "CarContainer not found", 4); return end

    if localp.Team and localp.Team.Name == "Criminals" then
        pcall(function() storage.Remotes.RequestTeamChange:InvokeServer(team.Neutral, 1) end)
    end
    repeat
        pcall(function() storage.Remotes.RequestTeamChange:InvokeServer(team.Guards, 1) end)
        task.wait()
        pcall(function() storage.Remotes.RequestTeamChange:InvokeServer(team.Inmates, 1) end)
        task.wait()
    until (localp.Team and (localp.Team.Name == "Inmates" or localp.Team.Name == "Guards")) or stopkick
    if stopkick then return end
    task.wait(0.7)

    local blacklisted = {}
    for _, v in ipairs(cars:GetChildren()) do
        if v.Name == "Squad" then blacklisted[v] = true end
    end

    local hp = gethp()
    if not hp then notify("ForceKick", "No HumanoidRootPart", 4); return end

    local buttons = Workspace:FindFirstChild("Prison_ITEMS")
    buttons = buttons and buttons:FindFirstChild("buttons")
    if not buttons then notify("ForceKick", "Buttons not found", 4); return end
    local children = buttons:GetChildren()
    local spawner4 = children[4] and children[4]:FindFirstChild("Car Spawner")
    local spawner5 = children[5] and children[5]:FindFirstChild("Car Spawner")
    if not spawner4 then notify("ForceKick", "Car spawner not found", 4); return end

    hp.CFrame = spawner4.CFrame

    local ok = pcall(function()
        repeat
            if stopkick then return end
            pcall(function() storage.Remotes.InteractWithItem:InvokeServer(spawner4) end)
            if spawner5 then pcall(function() storage.Remotes.InteractWithItem:InvokeServer(spawner5) end) end
            local tw = TweenService:Create(hp, TweenInfo.new(0.7), {CFrame = spawner4.CFrame})
            tw:Play(); tw.Completed:Wait()
            task.wait(0.1)
            local tw2 = TweenService:Create(hp, TweenInfo.new(0.7), {CFrame = CFrame.new(589, 98, 2494)})
            tw2:Play(); tw2.Completed:Wait()
        until (function()
            for _, v in ipairs(cars:GetChildren()) do
                if v.Name == "Squad" and not blacklisted[v] then return true end
            end
            return false
        end)() or stopkick
    end)

    if not ok then notify("ForceKick", "Car spawn failed", 4); return end
    if stopkick then return end

    local carModel
    for _, v in ipairs(cars:GetChildren()) do
        if v.Name == "Squad" and not blacklisted[v] then carModel = v; break end
    end
    if not carModel or handlemissingcar2(cars) then
        notify("ForceKick", "Car disappeared", 4); return
    end

    local body = carModel:FindFirstChild("Body")
    local seat = body and body:FindFirstChild("VehicleSeat")
    if not body or not seat then notify("ForceKick", "Car body/seat missing", 4); return end

    local parts = {}
    for _, v in ipairs(body:GetDescendants()) do
        if v:IsA("BasePart") then table.insert(parts, v) end
    end
    if #parts == 0 then return end

    local sethidden = (getgenv and getgenv().sethiddenproperty) or _G.sethiddenproperty or sethiddenproperty
    local hasInstanceHandle = typeof(InstanceHandle) == "table" or typeof(InstanceHandle) == "function"

    startKickLoop(player)

    for _, v in ipairs(parts) do
        if stopkick or handlemissingcar2(cars) then return end
        if v and v.Parent then
            local success = pcall(function()
                if isNetworkOwned(seat) then
                    if handlemissingcar2(cars) or stopkick then return end
                    local freshChar = player.Character
                    local freshHum  = freshChar and freshChar:FindFirstChildOfClass("Humanoid")
                    local freshHead = freshChar and freshChar:FindFirstChild("Head")
                    local freshRoot = freshHum and (freshHum.RootPart or freshChar:FindFirstChild("HumanoidRootPart"))
                    if not freshHead or not freshRoot then return end
                    setMaxSimRadius()
                    if typeof(sethidden) == "function" then
                        pcall(sethidden, seat, "PhysicsRepRootPart", freshRoot)
                        if hasInstanceHandle then
                            pcall(sethidden, seat, "PhysicsRepRootRef", InstanceHandle.new(freshRoot))
                        end
                    end
                    seat.CFrame = freshHead.CFrame * CFrame.new(0, -1.5, 0.5)
                    v.Velocity = Vector3.new(10000, 10000, 10000)
                end
            end)
            if not success and handlemissingcar2(cars) then return end
        end
    end
end

local function stopForceKick()
    stopkick = true
    kickEnabled = false
    kickRunning = false
    if kickRespawnConn then kickRespawnConn:Disconnect(); kickRespawnConn = nil end
    notify("ForceKick", "Stopped", 3)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- COMBAT: RageKill
-- ─────────────────────────────────────────────────────────────────────────────
local rageConn = nil

local function parseKillfeed(text)
    local killerPart, rest = text:match("^(.-)%s+killed%s+(.+)$")
    if not killerPart or not rest then return nil, nil end
    local victimPart = rest:match("^(.-)%s+with") or rest
    local killerName = killerPart:match("^(.-)%s*%(@") or killerPart
    killerName = killerName:match("^%s*(.-)%s*$")
    local victimName = victimPart:match("^%s*(.-)%s*$")
    return killerName, victimName
end

local function enableRageKill()
    if rageConn then notify("RageKill", "Already enabled", 3); return end
    local killfeed = storage:FindFirstChild("Killfeed")
    if not killfeed then notify("RageKill", "Killfeed not found", 4); return end
    rageConn = killfeed.ChildAdded:Connect(function(child)
        local text = child.Name
        if not text or text == "" then return end
        local killer, victim = parseKillfeed(text)
        if not killer or not victim then return end
        local me = localp.Name:lower()
        local meDisplay = (localp.DisplayName or ""):lower()
        if victim:lower():find(me, 1, true) or victim:lower():find(meDisplay, 1, true) then
            task.spawn(function()
                local hm = gethm()
                if hm and hm.Health == 0 then
                    task.wait(Players.RespawnTime + 0.5)
                end
                local hp = gethp()
                local oldCF = hp and hp.CFrame
                local target = findplByName(killer)
                if target then killPlayer(target) end
                if oldCF then local n = gethp(); if n then n.CFrame = oldCF end end
            end)
        end
    end)
    notify("RageKill", "Enabled", 3)
end

local function disableRageKill()
    if rageConn then rageConn:Disconnect(); rageConn = nil; notify("RageKill", "Disabled", 3) end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- COMBAT: KillAura
-- ─────────────────────────────────────────────────────────────────────────────
local kaurabool = false

local function enableKillAura()
    if kaurabool then return end
    kaurabool = true
    task.spawn(function()
        while kaurabool do
            local myRoot = gethp()
            if not myRoot then task.wait(0.1); continue end
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= localp and plr.Character then
                    local root = plr.Character:FindFirstChild("HumanoidRootPart")
                    local hum  = plr.Character:FindFirstChildOfClass("Humanoid")
                    if root and hum and hum.Health > 0
                        and (myRoot.Position - root.Position).Magnitude <= 15 then
                        pcall(function() storage.meleeEvent:FireServer(plr, 1, 1) end)
                    end
                end
            end
            task.wait(0.05)
        end
    end)
    notify("KillAura", "Enabled", 3)
end

local function disableKillAura()
    if not kaurabool then return end
    kaurabool = false
    notify("KillAura", "Disabled", 3)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- COMBAT: SilentAim
-- ─────────────────────────────────────────────────────────────────────────────
local silentAimEnabled = false
local AIM_PART, WALL_CHECK, FOV, TEAM_CHECK = "Head", true, 360, true

local function canDamage(plr)
    local char = plr.Character; if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if char:FindFirstChild("ForceField") then return false end
    if TEAM_CHECK and localp.Team and plr.Team and localp.Team == plr.Team then return false end
    return true
end

local function isVisible(char, origin)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = localp.Character and { localp.Character } or {}
    for _, part in ipairs({
        char:FindFirstChild(AIM_PART),
        char:FindFirstChild("Head"),
        char:FindFirstChild("HumanoidRootPart")
    }) do
        if not part then continue end
        local dir = part.Position - origin
        if dir.Magnitude <= 0 then continue end
        local result = Workspace:Raycast(origin, dir, params)
        if not result or result.Instance:FindFirstAncestorOfClass("Model") == char then return part end
    end
    return nil
end

local function getTarget(origin)
    local camera = Workspace.CurrentCamera; if not camera then return nil end
    local vps = camera.ViewportSize
    local center = Vector2.new(vps.X / 2, vps.Y / 2)
    local bestDist, bestPart = FOV, nil
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= localp and canDamage(plr) then
            local char = plr.Character
            if char then
                local part = char:FindFirstChild(AIM_PART) or char:FindFirstChild("Head")
                if part then
                    local pos, onScreen = camera:WorldToViewportPoint(part.Position)
                    if onScreen and (part.Position - camera.CFrame.Position):Dot(camera.CFrame.LookVector) > 0 then
                        local sDist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        if sDist < bestDist then
                            local vis = not WALL_CHECK and part or isVisible(char, origin)
                            if vis then bestPart = vis; bestDist = sDist end
                        end
                    end
                end
            end
        end
    end
    return bestPart
end

local function getAttr(tool, attr)
    if typeof(tool) == "Instance" then
        local ok, val = pcall(function() return tool:GetAttribute(attr) end)
        if ok then return val end
    end
    return nil
end

local function normalCast(p1, p2, p3)
    local origin, aim, tool
    if typeof(p1) == "Vector3" then
        origin = p1
        if typeof(p2) == "Vector3" then aim = p2 elseif typeof(p3) == "Vector3" then aim = p3 end
        if typeof(p2) == "Instance" then tool = p2 elseif typeof(p3) == "Instance" then tool = p3 end
    else
        tool = p1
        if typeof(p2) == "Vector3" then origin = p2 end
        if typeof(p3) == "Vector3" then aim = p3 elseif typeof(p2) == "Vector3" then aim = p2 end
    end
    if not origin or not aim then return nil, Vector3.new() end
    local dir = aim - origin
    if dir.Magnitude <= 0 then dir = Vector3.new(0, 0, -1) end
    local range = getAttr(tool, "Range") or 200
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = localp.Character and { localp.Character } or {}
    params.CollisionGroup = "ClientBullet"
    local result = Workspace:Raycast(origin, dir.Unit * range, params)
    if result then return result.Instance, result.Position end
    return nil, origin + dir.Unit * range
end

local function hookCast(p1, p2, p3)
    local origin
    if typeof(p1) == "Vector3" then origin = p1
    elseif typeof(p2) == "Vector3" then origin = p2
    elseif typeof(p3) == "Vector3" then origin = p3 end
    if not silentAimEnabled then return normalCast(p1, p2, p3) end
    if origin then
        local char = localp.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root and (origin - root.Position).Magnitude <= 75 then
            local target = getTarget(origin)
            if target and target.Parent then return target, target.Position end
        end
    end
    return normalCast(p1, p2, p3)
end

local function ensureSilentHook()
    if _G.silentAimHooked then return end
    _G.silentAimHooked = true
    task.spawn(function()
        local hooked = 0
        for _, func in next, getgc(true) do
            if type(func) == "function" then
                local info = debug.getinfo(func, "nS")
                if info and info.name == "castRay" then
                    pcall(hookfunction, func, hookCast)
                    hooked = hooked + 1
                end
            end
            if hooked >= 5 then break end
        end
    end)
end

local function enableSilentAim()
    if silentAimEnabled then return end
    silentAimEnabled = true
    ensureSilentHook()
    notify("SilentAim", "Enabled", 3)
end

local function disableSilentAim()
    if not silentAimEnabled then return end
    silentAimEnabled = false
    notify("SilentAim", "Disabled", 3)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- UI: build panel
-- ─────────────────────────────────────────────────────────────────────────────
local COL_BG       = Color3.fromRGB(22, 22, 26)
local COL_PANEL    = Color3.fromRGB(32, 32, 38)
local COL_ROW      = Color3.fromRGB(45, 45, 52)
local COL_ROW_SEL  = Color3.fromRGB(70, 130, 70)
local COL_BTN      = Color3.fromRGB(60, 60, 68)
local COL_BTN_RED  = Color3.fromRGB(170, 50, 50)
local COL_BTN_GRN  = Color3.fromRGB(50, 140, 70)
local COL_BTN_ORG  = Color3.fromRGB(180, 120, 40)
local COL_TEXT     = Color3.fromRGB(235, 235, 235)
local COL_SUBTEXT  = Color3.fromRGB(160, 160, 165)

local gui = Instance.new("ScreenGui")
gui.Name = "AdminUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.Parent = playerGui

-- Main panel
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 320, 0, 460)
panel.Position = UDim2.new(0, 20, 0, 20)
panel.BackgroundColor3 = COL_BG
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)

-- Title bar (drag handle)
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 32)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
titleBar.BorderSizePixel = 0
titleBar.Active = true
titleBar.Parent = panel
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -70, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "ADMIN"
titleLabel.TextColor3 = COL_TEXT
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 16
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Toggle button (hides panel)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 26, 0, 22)
toggleBtn.Position = UDim2.new(1, -32, 0, 5)
toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "–"
toggleBtn.TextColor3 = COL_TEXT
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 16
toggleBtn.Parent = titleBar
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 4)

-- Body container
local body = Instance.new("ScrollingFrame")
body.Name = "Body"
body.Size = UDim2.new(1, -16, 1, -42)
body.Position = UDim2.new(0, 8, 0, 36)
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.ScrollBarThickness = 5
body.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 100)
body.CanvasSize = UDim2.new(0, 0, 0, 0)
body.AutomaticCanvasSize = Enum.AutomaticSize.Y
body.Parent = panel

local bodyLayout = Instance.new("UIListLayout")
bodyLayout.FillDirection = Enum.FillDirection.Vertical
bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
bodyLayout.Padding = UDim.new(0, 6)
bodyLayout.Parent = body

-- Helpers for building UI
local function makeSection(parent, text, order)
    local sec = Instance.new("TextLabel")
    sec.Size = UDim2.new(1, 0, 0, 20)
    sec.BackgroundTransparency = 1
    sec.Text = text
    sec.TextColor3 = COL_SUBTEXT
    sec.Font = Enum.Font.GothamBold
    sec.TextSize = 12
    sec.TextXAlignment = Enum.TextXAlignment.Left
    sec.LayoutOrder = order
    sec.Parent = parent
    return sec
end

local function makeButton(parent, text, color, order, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 28)
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = COL_TEXT
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.LayoutOrder = order
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    b.MouseButton1Click:Connect(callback)
    return b
end

-- ── PLAYERS section ──────────────────────────────────────────────────────────
makeSection(body, "PLAYERS", 1)

-- Placeholder list (scrolling)
local playerList = Instance.new("ScrollingFrame")
playerList.Name = "PlayerList"
playerList.Size = UDim2.new(1, 0, 0, 160)
playerList.BackgroundColor3 = COL_PANEL
playerList.BorderSizePixel = 0
playerList.ScrollBarThickness = 5
playerList.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 100)
playerList.CanvasSize = UDim2.new(0, 0, 0, 0)
playerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerList.LayoutOrder = 2
playerList.Parent = body
Instance.new("UICorner", playerList).CornerRadius = UDim.new(0, 4)

local plLayout = Instance.new("UIListLayout")
plLayout.FillDirection = Enum.FillDirection.Vertical
plLayout.SortOrder = Enum.SortOrder.LayoutOrder
plLayout.Padding = UDim.new(0, 3)
plLayout.Parent = playerList
Instance.new("UIPadding", playerList).PaddingTop = UDim.new(0, 4)
-- (also apply left/right/bottom padding via a proper UIPadding instance)
local plPad = playerList:FindFirstChildOfClass("UIPadding")
plPad.PaddingLeft = UDim.new(0, 4)
plPad.PaddingRight = UDim.new(0, 4)
plPad.PaddingBottom = UDim.new(0, 4)

local selectedPlayer = nil
local rowButtons = {}

local function updateSelectedLabel()
    -- reflected via row styling only; no extra label needed
end

local function applyRowStyle(btn, player)
    if player == selectedPlayer then
        btn.BackgroundColor3 = COL_ROW_SEL
    else
        btn.BackgroundColor3 = COL_ROW
    end
end

local function selectPlayer(player)
    selectedPlayer = (selectedPlayer == player) and nil or player
    for p, b in pairs(rowButtons) do
        if b and b.Parent then applyRowStyle(b, p) end
    end
    updateSelectedLabel()
end

local function rebuildPlayerList()
    for _, b in pairs(rowButtons) do if b and b.Parent then b:Destroy() end end
    rowButtons = {}
    if selectedPlayer and selectedPlayer.Parent ~= Players then selectedPlayer = nil end
    local all = Players:GetPlayers()
    table.sort(all, function(a, b)
        return (a.DisplayName or a.Name):lower() < (b.DisplayName or b.Name):lower()
    end)
    local idx = 0
    for _, p in ipairs(all) do
        if p ~= localp then
            idx = idx + 1
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, 0, 0, 26)
            b.BackgroundColor3 = COL_ROW
            b.BorderSizePixel = 0
            b.Text = "  " .. (p.DisplayName or p.Name) .. "  (@" .. p.Name .. ")"
            b.TextColor3 = COL_TEXT
            b.Font = Enum.Font.Gotham
            b.TextSize = 13
            b.TextXAlignment = Enum.TextXAlignment.Left
            b.LayoutOrder = idx
            b.Parent = playerList
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 3)
            b.MouseButton1Click:Connect(function()
                if p.Parent then selectPlayer(p) end
            end)
            rowButtons[p] = b
            applyRowStyle(b, p)
        end
    end
end

rebuildPlayerList()
Players.PlayerAdded:Connect(rebuildPlayerList)
Players.PlayerRemoving:Connect(function(p)
    if selectedPlayer == p then selectedPlayer = nil end
    task.defer(rebuildPlayerList)
end)

local function requireSelection(cbName)
    if not selectedPlayer or not selectedPlayer.Parent then
        notify(cbName, "Select a player first", 3)
        return nil
    end
    return selectedPlayer
end

makeButton(body, "ForceKick", COL_BTN_RED, 3, function()
    local p = requireSelection("ForceKick"); if not p then return end
    stopkick = false
    task.spawn(forcekickPlayer, p)
end)

makeButton(body, "Stop ForceKick", COL_BTN, 4, function()
    stopForceKick()
end)

makeButton(body, "Arrest", COL_BTN_ORG, 5, function()
    local p = requireSelection("Arrest"); if not p then return end
    task.spawn(arrestPlayer, p)
end)

makeButton(body, "Kill", COL_BTN_RED, 6, function()
    local p = requireSelection("Kill"); if not p then return end
    task.spawn(killPlayer, p)
end)

makeButton(body, "Goto", COL_BTN_GRN, 7, function()
    local p = requireSelection("Goto"); if not p then return end
    gotoPlayer(p)
end)

makeButton(body, "Bring", COL_BTN_GRN, 8, function()
    local p = requireSelection("Bring"); if not p then return end
    task.spawn(bringPlayer, p)
end)

-- ── COMBAT section ───────────────────────────────────────────────────────────
makeSection(body, "COMBAT", 20)

makeButton(body, "RageKill: OFF", COL_BTN, 21, function(btn)
    if rageConn then disableRageKill() else enableRageKill() end
    btn.Text = rageConn and "RageKill: ON" or "RageKill: OFF"
    btn.BackgroundColor3 = rageConn and COL_BTN_GRN or COL_BTN
end)

makeButton(body, "KillAura: OFF", COL_BTN, 22, function(btn)
    if kaurabool then disableKillAura() else enableKillAura() end
    btn.Text = kaurabool and "KillAura: ON" or "KillAura: OFF"
    btn.BackgroundColor3 = kaurabool and COL_BTN_GRN or COL_BTN
end)

makeButton(body, "SilentAim: OFF", COL_BTN, 23, function(btn)
    if silentAimEnabled then disableSilentAim() else enableSilentAim() end
    btn.Text = silentAimEnabled and "SilentAim: ON" or "SilentAim: OFF"
    btn.BackgroundColor3 = silentAimEnabled and COL_BTN_GRN or COL_BTN
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Drag: title bar (mouse + touch)
-- ─────────────────────────────────────────────────────────────────────────────
local function makeDraggable(frame, handle)
    local dragging = false
    local dragStart, startPos

    local function begin(input)
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        if input.UserInputType == Enum.UserInputType.Touch then
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            begin(input)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

makeDraggable(panel, titleBar)

-- ─────────────────────────────────────────────────────────────────────────────
-- Toggle UI (hide panel → show floating button)
-- ─────────────────────────────────────────────────────────────────────────────
local toggleFrame = Instance.new("Frame")
toggleFrame.Name = "ToggleButton"
toggleFrame.Size = UDim2.new(0, 50, 0, 50)
toggleFrame.Position = UDim2.new(0, 20, 0, 20)
toggleFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
toggleFrame.BorderSizePixel = 0
toggleFrame.Visible = false
toggleFrame.Active = true
toggleFrame.Parent = gui
Instance.new("UICorner", toggleFrame).CornerRadius = UDim.new(1, 0) -- circular

local toggleText = Instance.new("TextButton")
toggleText.Size = UDim2.new(1, 0, 1, 0)
toggleText.BackgroundTransparency = 1
toggleText.Text = "≡"
toggleText.TextColor3 = COL_TEXT
toggleText.Font = Enum.Font.GothamBold
toggleText.TextSize = 24
toggleText.Parent = toggleFrame

local function setPanelVisible(v)
    panel.Visible = v
    toggleFrame.Visible = not v
end

toggleBtn.MouseButton1Click:Connect(function()
    setPanelVisible(false)
end)

toggleText.MouseButton1Click:Connect(function()
    setPanelVisible(true)
end)

-- Draggable toggle button
makeDraggable(toggleFrame, toggleFrame)

-- ─────────────────────────────────────────────────────────────────────────────
-- Done
-- ─────────────────────────────────────────────────────────────────────────────
notify("AdminUI", "Loaded", 4)
print("[AdminUI] Loaded")
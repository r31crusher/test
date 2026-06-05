-- Wild West (PlaceId 2317712696)
-- Custom framework: all remotes routed through ReplicatedStorage.Communication via named events.
-- Characters live in workspace.WORKSPACE_Entities.Players (custom RepChar system).
-- GetMouseHit in Global.Utils is the single source-of-truth target position for all projectiles.

return function(section)
    local elements = getgenv()._astroElements
    local rs       = game:GetService("ReplicatedStorage")
    local uis      = game:GetService("UserInputService")
    local lp       = game:GetService("Players").LocalPlayer

    local Global = require(rs.SharedModules.Global)
    local Utils  = Global.Utils
    local RCH    = Global.RepCharHandler

    local playersFolder = workspace:WaitForChild("WORKSPACE_Entities"):WaitForChild("Players")

    local loops = {}
    local conns = {}
    local function cancelLoop(n)
        if loops[n] then task.cancel(loops[n]); loops[n] = nil end
    end
    local function addConn(n, c)
        if conns[n] then conns[n]:Disconnect() end
        conns[n] = c
    end

    -- ── Silent Aim ────────────────────────────────────────────────────────────
    -- GunItemType.Fire() calls Utils.GetMouseHit(2000, ...) to get the world-space
    -- target position, then builds the projectile direction from it.
    -- Replacing it redirects every shot toward the nearest player.
    local origGetMouseHit = Utils.GetMouseHit
    local silentAimOn = false

    Utils.GetMouseHit = function(dist, atPos, ...)
        if not silentAimOn then return origGetMouseHit(dist, atPos, ...) end
        local myRC  = RCH and RCH:GetRepChar(lp)
        local myMdl = myRC and myRC.Model
        local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            or (myRC and myRC.RootPart)
        if not myHRP then return origGetMouseHit(dist, atPos, ...) end

        local nearest, nearDist = nil, math.huge
        for _, model in playersFolder:GetChildren() do
            if model ~= myMdl then
                local hrp = model:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local d = (hrp.Position - myHRP.Position).Magnitude
                    if d < nearDist then nearest = hrp; nearDist = d end
                end
            end
        end
        return nearest and nearest.Position or origGetMouseHit(dist, atPos, ...)
    end

    elements:Toggle("Silent Aim", section, function(state)
        silentAimOn = state
    end)

    -- ── ESP ───────────────────────────────────────────────────────────────────
    local espObjs = {}
    local espOn   = false

    local function removeEsp(model)
        if not espObjs[model] then return end
        for _, v in espObjs[model] do pcall(v.Destroy, v) end
        espObjs[model] = nil
    end

    local function addEsp(model)
        if espObjs[model] then return end
        local hrp = model:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local objs = {}

        local box = Instance.new("SelectionBox")
        box.Color3              = Color3.fromRGB(255, 60, 60)
        box.LineThickness       = 0.05
        box.SurfaceTransparency = 0.85
        box.SurfaceColor3       = Color3.fromRGB(255, 60, 60)
        box.Adornee             = model
        box.Parent              = workspace.CurrentCamera
        table.insert(objs, box)

        local bb  = Instance.new("BillboardGui")
        bb.Size         = UDim2.new(0, 160, 0, 28)
        bb.AlwaysOnTop  = true
        bb.StudsOffset  = Vector3.new(0, 3.5, 0)
        bb.Adornee      = hrp
        bb.Parent       = workspace.CurrentCamera
        local lbl = Instance.new("TextLabel", bb)
        lbl.Size                  = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3            = Color3.fromRGB(255, 255, 255)
        lbl.TextStrokeTransparency = 0
        lbl.Font                  = Enum.Font.GothamBold
        lbl.TextSize              = 14
        local rc = RCH and RCH:GetRepChar(model)
        lbl.Text = (rc and rc.Player and (rc.Player.DisplayName or rc.Player.Name)) or model.Name
        table.insert(objs, bb)

        espObjs[model] = objs
    end

    local function rebuildEsp()
        for model in pairs(espObjs) do removeEsp(model) end
        if not espOn then return end
        local myRC = RCH and RCH:GetRepChar(lp)
        local myMdl = myRC and myRC.Model
        for _, model in playersFolder:GetChildren() do
            if model ~= myMdl then addEsp(model) end
        end
    end

    elements:Toggle("ESP", section, function(state)
        espOn = state
        rebuildEsp()
        addConn("espAdd", nil)
        addConn("espRem", nil)
        if not state then return end
        addConn("espAdd", playersFolder.ChildAdded:Connect(function(m)
            if not espOn then return end
            local myRC = RCH and RCH:GetRepChar(lp)
            if m ~= (myRC and myRC.Model) then task.wait(0.3); addEsp(m) end
        end))
        addConn("espRem", playersFolder.ChildRemoved:Connect(removeEsp))
    end)

    -- ── Infinite Ammo ────────────────────────────────────────────────────────
    -- item.Ammo and ChamberData.bullets are both client-side only.
    -- Server only receives InitProjectiles events and never validates ammo counts.
    -- For revolvers (HasChamber), FireGun() checks the slot state — reset to "unused"
    -- so it never dry-fires regardless of how many shots have been taken.
    elements:Toggle("Infinite Ammo", section, function(state)
        cancelLoop("ammo")
        if not state then return end
        loops.ammo = task.spawn(function()
            while task.wait() do
                local item = Global.PlayerCharacter and Global.PlayerCharacter:GetEquippedItem()
                if item and item.IsGunItem then
                    item.Ammo = item.MaxAmmo
                    if item.HasChamber and item.State and item.State.ChamberData then
                        local cd = item.State.ChamberData
                        for i = 1, cd.count do
                            cd.bullets[i] = "unused"
                        end
                    end
                end
            end
        end)
    end)

    -- ── Speed Hack ────────────────────────────────────────────────────────────
    -- PlayerCharacter module sets WalkSpeed each frame from Params.Character.MoveSpeed.
    -- We win the race by setting it in Heartbeat after it runs (~4x per render step).
    local speedMult  = 2
    local speedLabel = Instance.new("TextLabel")
    speedLabel.Name                   = "LabelElement"
    speedLabel.Size                   = UDim2.new(1, 0, 0, 24)
    speedLabel.BackgroundTransparency = 1
    speedLabel.Font                   = Enum.Font.Gotham
    speedLabel.TextSize               = 13
    speedLabel.TextColor3             = Color3.fromRGB(200, 190, 255)
    speedLabel.TextXAlignment         = Enum.TextXAlignment.Left
    speedLabel.Text                   = "Speed mult:  2x"
    speedLabel.Parent                 = section

    local function setSpeedLabel(n)
        speedMult = n
        speedLabel.Text = "Speed mult:  " .. n .. "x"
    end

    elements:Button("1x", section, function() setSpeedLabel(1) end)
    elements:Button("2x", section, function() setSpeedLabel(2) end)
    elements:Button("3x", section, function() setSpeedLabel(3) end)
    elements:Button("5x", section, function() setSpeedLabel(5) end)

    local function resetSpeed()
        local char = lp.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end

    elements:Toggle("Speed Hack", section, function(state)
        cancelLoop("speed")
        if not state then resetSpeed(); return end
        loops.speed = task.spawn(function()
            while task.wait() do
                local char = lp.Character
                local hum  = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = 16 * speedMult end
            end
        end)
    end)

    -- ── Fly ───────────────────────────────────────────────────────────────────
    local flySpeed = 80
    local flyBV, flyBG

    local function stopFly()
        cancelLoop("fly")
        if flyBV then flyBV:Destroy(); flyBV = nil end
        if flyBG then flyBG:Destroy(); flyBG = nil end
        local char = lp.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then pcall(hum.ChangeState, hum, Enum.HumanoidStateType.GettingUp) end
    end

    elements:Toggle("Fly", section, function(state)
        stopFly()
        if not state then return end
        local char = lp.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end

        pcall(hum.ChangeState, hum, Enum.HumanoidStateType.Physics)

        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        flyBV.Velocity = Vector3.new(0, 0, 0)
        flyBV.Parent   = hrp

        flyBG = Instance.new("BodyGyro")
        flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        flyBG.D         = 100
        flyBG.CFrame    = hrp.CFrame
        flyBG.Parent    = hrp

        loops.fly = task.spawn(function()
            while flyBV and flyBV.Parent do
                task.wait()
                local cam = workspace.CurrentCamera
                local dir = Vector3.new(0, 0, 0)
                if uis:IsKeyDown(Enum.KeyCode.W)           then dir = dir + cam.CFrame.LookVector  end
                if uis:IsKeyDown(Enum.KeyCode.S)           then dir = dir - cam.CFrame.LookVector  end
                if uis:IsKeyDown(Enum.KeyCode.A)           then dir = dir - cam.CFrame.RightVector end
                if uis:IsKeyDown(Enum.KeyCode.D)           then dir = dir + cam.CFrame.RightVector end
                if uis:IsKeyDown(Enum.KeyCode.Space)       then dir = dir + Vector3.new(0, 1, 0)  end
                if uis:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0)  end
                flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * flySpeed or Vector3.new(0, 0, 0)
                flyBG.CFrame   = cam.CFrame
            end
        end)
    end)

    -- ── Unload ────────────────────────────────────────────────────────────────
    section.AncestorRemoving:Connect(function()
        Utils.GetMouseHit = origGetMouseHit
        for model in pairs(espObjs) do removeEsp(model) end
        for _, c in conns do if c then c:Disconnect() end end
        for name in loops do cancelLoop(name) end
        stopFly()
        resetSpeed()
        if speedLabel and speedLabel.Parent then speedLabel:Destroy() end
    end)
end

-- Murder Mystery 2 (PlaceId 142823291)

return function(section)
    local elements = getgenv()._astroElements
    local Players  = game:GetService("Players")
    local RS       = game:GetService("ReplicatedStorage")
    local RunSvc   = game:GetService("RunService")
    local player   = Players.LocalPlayer

    local Remotes       = RS:WaitForChild("Remotes")
    local GameplayR     = Remotes:WaitForChild("Gameplay")
    local GiveWeapon    = GameplayR:WaitForChild("GiveWeapon")
    local ShowTeammates = GameplayR:WaitForChild("ShowTeammates")

    -- WeaponService module (provides GetMouseTargetCFrame used by gun tools)
    local WeaponService = require(RS:WaitForChild("ClientServices"):WaitForChild("WeaponService"))


    -- ── Role detection ────────────────────────────────────────────────────────
    -- GiveWeapon only fires to the local player for their own role, so we cannot
    -- use remote events to learn other players' roles. Instead we read the
    -- CollectionService tags that the game applies to weapon tools — "Weapon_Knife"
    -- = murderer, "Weapon_Gun" = sheriff. These tags replicate to all clients, so
    -- checking any player's character (or backpack) is reliable.
    local function getRole(p)
        for _, container in { p.Character, p.Backpack } do
            if container then
                for _, obj in container:GetChildren() do
                    if obj:IsA("Tool") then
                        if obj:HasTag("Weapon_Knife") then return "Murderer" end
                        if obj:HasTag("Weapon_Gun")   then return "Sheriff"  end
                    end
                end
            end
        end
        return "Innocent"
    end

    local _roleConns = {}

    -- Still listen to ShowTeammates for modes where multiple murderers exist and
    -- one may not have their knife visible yet. Store as a supplement.
    local _knownMurderers = {}
    table.insert(_roleConns, ShowTeammates.OnClientEvent:Connect(function(names)
        for _, name in ipairs(names) do
            _knownMurderers[name] = true
        end
    end))
    table.insert(_roleConns, GameplayR:WaitForChild("RoundStart").OnClientEvent:Connect(function()
        _knownMurderers = {}
    end))

    -- Wrap getRole so ShowTeammates data acts as a fallback
    local function getPlayerRole(p)
        local r = getRole(p)
        if r ~= "Innocent" then return r end
        if _knownMurderers[p.Name] then return "Murderer" end
        return "Innocent"
    end

    -- ── Silent Aim + FOV + Target Indicator + Through Walls ──────────────────
    getgenv()._mm2_silentaim   = false
    getgenv()._mm2_sheriffonly = false
    getgenv()._mm2_wallcheck   = false

    local origGetTarget = WeaponService.GetMouseTargetCFrame
    local camera        = workspace.CurrentCamera
    local _lockedTarget = nil
    local _fovRadius    = 150  -- screen-space pixels; updated by FOV slider

    -- ── GUI setup ─────────────────────────────────────────────────────────────
    local targetGui = Instance.new("ScreenGui")
    targetGui.Name = "_mm2targetui"
    targetGui.ResetOnSpawn = false
    targetGui.IgnoreGuiInset = true
    targetGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    targetGui.Parent = game.CoreGui

    -- FOV circle — fixed at screen center, shows aim selection radius
    local fovCircle = Instance.new("Frame")
    fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
    fovCircle.Position    = UDim2.new(0.5, 0, 0.5, 0)
    fovCircle.Size        = UDim2.new(0, _fovRadius * 2, 0, _fovRadius * 2)
    fovCircle.BackgroundTransparency = 1
    fovCircle.BorderSizePixel = 0
    fovCircle.Visible = false
    fovCircle.Parent = targetGui
    Instance.new("UICorner", fovCircle).CornerRadius = UDim.new(1, 0)
    local fovStroke = Instance.new("UIStroke", fovCircle)
    fovStroke.Color       = Color3.fromRGB(255, 255, 255)
    fovStroke.Thickness   = 1
    fovStroke.Transparency = 0.4

    -- Target ring — follows the locked enemy, purely visual
    local targetRing = Instance.new("Frame")
    targetRing.AnchorPoint = Vector2.new(0.5, 0.5)
    targetRing.Size        = UDim2.new(0, 36, 0, 36)
    targetRing.BackgroundTransparency = 1
    targetRing.BorderSizePixel = 0
    targetRing.Visible = false
    targetRing.Parent = targetGui
    Instance.new("UICorner", targetRing).CornerRadius = UDim.new(1, 0)
    local targetStroke = Instance.new("UIStroke", targetRing)
    targetStroke.Color     = Color3.fromRGB(255, 50, 50)
    targetStroke.Thickness = 2

    local targetLabel = Instance.new("TextLabel", targetRing)
    targetLabel.Size = UDim2.new(0, 120, 0, 16)
    targetLabel.AnchorPoint = Vector2.new(0.5, 0)
    targetLabel.Position = UDim2.new(0.5, 0, 1, 4)
    targetLabel.BackgroundTransparency = 1
    targetLabel.Font = Enum.Font.GothamBold
    targetLabel.TextSize = 11
    targetLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
    targetLabel.TextStrokeTransparency = 0
    targetLabel.Text = ""

    -- ── Target selection — screen-space, within FOV circle ───────────────────
    -- Must be declared before _targetRender so the closure can capture it.
    local function nearestEnemy()
        if not getgenv()._mm2_silentaim then return nil end
        local vp = camera.ViewportSize
        local cx, cy = vp.X / 2, vp.Y / 2
        local best, bestDist = nil, math.huge
        for _, p in Players:GetPlayers() do
            if p ~= player and p.Character then
                if getgenv()._mm2_sheriffonly and getPlayerRole(p) ~= "Murderer" then
                    continue
                end
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local sp, onScreen = camera:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        local dx, dy = sp.X - cx, sp.Y - cy
                        local d = math.sqrt(dx * dx + dy * dy)
                        if d <= _fovRadius and d < bestDist then
                            best, bestDist = hrp, d
                        end
                    end
                end
            end
        end
        return best
    end

    -- ── RenderStepped: update FOV circle size + drive target ring ─────────────
    local _targetRender = RunSvc.RenderStepped:Connect(function()
        local active = getgenv()._mm2_silentaim

        -- Keep FOV circle size in sync with _fovRadius
        fovCircle.Size    = UDim2.new(0, _fovRadius * 2, 0, _fovRadius * 2)
        fovCircle.Visible = active

        if not active then
            targetRing.Visible = false
            _lockedTarget = nil
            return
        end

        local hrp = nearestEnemy()
        if not hrp then
            targetRing.Visible = false
            _lockedTarget = nil
            return
        end

        -- Refresh label/color only when the target changes
        if hrp ~= _lockedTarget then
            _lockedTarget = hrp
            local p = Players:GetPlayerFromCharacter(hrp.Parent)
            if p then
                local role = getPlayerRole(p)
                local c = role == "Murderer" and Color3.fromRGB(255, 50, 50)
                       or role == "Sheriff"  and Color3.fromRGB(80, 180, 255)
                       or Color3.fromRGB(200, 200, 200)
                targetStroke.Color    = c
                targetLabel.TextColor3 = c
                targetLabel.Text      = p.Name
            end
        end

        local sp, onScreen = camera:WorldToViewportPoint(hrp.Position)
        if onScreen then
            targetRing.Position = UDim2.new(0, sp.X, 0, sp.Y)
            targetRing.Visible  = true
        else
            targetRing.Visible = false
        end
    end)

    -- ── Build character-only raycast params (through-walls) ───────────────────
    local function buildCharParams()
        local chars = {}
        for _, p in Players:GetPlayers() do
            if p ~= player and p.Character then
                table.insert(chars, p.Character)
            end
        end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Include
        params.FilterDescendantsInstances = chars
        return params
    end

    -- ── WeaponService hook ────────────────────────────────────────────────────
    WeaponService.GetMouseTargetCFrame = function(self)
        if getgenv()._mm2_silentaim and _lockedTarget and _lockedTarget.Parent then
            return CFrame.new(_lockedTarget.Position)
        end
        if getgenv()._mm2_wallcheck then
            local UIS   = game:GetService("UserInputService")
            local mouse = UIS:GetMouseLocation()
            local ray   = camera:ViewportPointToRay(mouse.X, mouse.Y)
            local result = workspace:Raycast(ray.Origin, ray.Direction * 500, buildCharParams())
            if result then return CFrame.new(result.Position) end
        end
        return origGetTarget(self)
    end

    elements:Toggle("Silent Aim", section, function(v)
        getgenv()._mm2_silentaim = v
        if not v then
            targetRing.Visible = false
            fovCircle.Visible  = false
            _lockedTarget = nil
        end
    end)

    elements:Toggle("Sheriff Only (aim murderer)", section, function(v)
        getgenv()._mm2_sheriffonly = v
    end)

    elements:Toggle("Through Walls", section, function(v)
        getgenv()._mm2_wallcheck = v
    end)

    elements:Slider("FOV Radius", section, 30, 400, _fovRadius, function(v)
        _fovRadius = v
    end)

    -- ── Player ESP ────────────────────────────────────────────────────────────
    -- BillboardGui above each player's head showing their role and distance.
    getgenv()._mm2_esp = false
    local espBills = {}

    local ROLE_COLOR = {
        Murderer = Color3.fromRGB(255, 60, 60),
        Sheriff  = Color3.fromRGB(80, 180, 255),
        Innocent = Color3.fromRGB(200, 200, 200),
    }

    local function makeESPFor(p)
        if p == player then return end
        local function attach()
            local char = p.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local bb = Instance.new("BillboardGui")
            bb.Name = "_mm2esp"
            bb.Size = UDim2.new(0, 120, 0, 40)
            bb.StudsOffset = Vector3.new(0, 3, 0)
            bb.AlwaysOnTop = true
            bb.Adornee = hrp
            bb.Parent = game.CoreGui

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 13
            lbl.TextStrokeTransparency = 0
            lbl.Parent = bb

            espBills[p] = { bb = bb, lbl = lbl, hrp = hrp }
        end

        attach()
        p.CharacterAdded:Connect(function()
            task.wait(0.5)
            if espBills[p] then
                espBills[p].bb:Destroy()
                espBills[p] = nil
            end
            if getgenv()._mm2_esp then attach() end
        end)
    end

    local function removeESPFor(p)
        if espBills[p] then
            espBills[p].bb:Destroy()
            espBills[p] = nil
        end
    end

    local _espRender
    local _espPlayerAdded, _espPlayerRemoving

    local function startESP()
        for _, p in Players:GetPlayers() do
            makeESPFor(p)
        end
        _espPlayerAdded = Players.PlayerAdded:Connect(makeESPFor)
        _espPlayerRemoving = Players.PlayerRemoving:Connect(removeESPFor)

        _espRender = RunSvc.RenderStepped:Connect(function()
            local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            for p, data in pairs(espBills) do
                if not data.bb.Parent then
                    espBills[p] = nil
                    continue
                end
                local role = getPlayerRole(p)
                local dist = myHRP and math.floor((data.hrp.Position - myHRP.Position).Magnitude) or 0
                data.lbl.Text = string.format("[%s] %s\n%dm", role, p.Name, dist)
                data.lbl.TextColor3 = ROLE_COLOR[role] or ROLE_COLOR.Innocent
            end
        end)
    end

    local function stopESP()
        if _espRender then _espRender:Disconnect() _espRender = nil end
        if _espPlayerAdded then _espPlayerAdded:Disconnect() _espPlayerAdded = nil end
        if _espPlayerRemoving then _espPlayerRemoving:Disconnect() _espPlayerRemoving = nil end
        for p, data in pairs(espBills) do
            data.bb:Destroy()
            espBills[p] = nil
        end
    end

    elements:Toggle("Player ESP", section, function(v)
        getgenv()._mm2_esp = v
        if v then startESP() else stopESP() end
    end)

    -- ── Role Reveal (console) ─────────────────────────────────────────────────
    -- Prints murderer names to dev console when ShowTeammates fires.
    getgenv()._mm2_rolereveal = false
    table.insert(_roleConns, ShowTeammates.OnClientEvent:Connect(function(names)
        if not getgenv()._mm2_rolereveal then return end
        for _, name in ipairs(names) do
            print("[MM2] Murderer detected:", name)
        end
    end))
    -- Also scan all players by weapon tag on demand each second
    table.insert(_roleConns, RunSvc.Heartbeat:Connect(function()
        if not getgenv()._mm2_rolereveal then return end
        for _, p in Players:GetPlayers() do
            if p ~= player then
                local role = getPlayerRole(p)
                if role ~= "Innocent" then
                    -- only print once per role assignment (stored in _knownMurderers for murderers)
                    if role == "Murderer" and not _knownMurderers[p.Name .. "_printed"] then
                        _knownMurderers[p.Name .. "_printed"] = true
                        print("[MM2]", role, "->", p.Name)
                    end
                end
            end
        end
    end))

    elements:Toggle("Role Reveal (console)", section, function(v)
        getgenv()._mm2_rolereveal = v
    end)



    local CollectionService = game:GetService("CollectionService")
    local CoinCollected     = GameplayR:WaitForChild("CoinCollected")

    local COIN_SPEED = 60
    local COIN_REACH = 5

    getgenv()._mm2_coins = false

    local function setCoinNoclip(char, on)
        if not char then return end
        for _, part in char:GetDescendants() do
            if part:IsA("BasePart") then part.CanCollide = not on end
        end
    end

    local function getNearestCoin(hrp)
        local best, bestDist = nil, math.huge
        for _, server in CollectionService:GetTagged("ServerCoinPart") do
            if server and server.Parent then
                local d = (server.Position - hrp.Position).Magnitude
                if d < bestDist then best, bestDist = server, d end
            end
        end
        return best
    end

    local function coinFarmLoop()
        local pouched   = 0
        local countConn = CoinCollected.OnClientEvent:Connect(function(_, count)
            if type(count) == "number" then pouched = count end
        end)

        while getgenv()._mm2_coins and pouched < 40 do
            local char = player.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then task.wait(1) continue end

            local server = getNearestCoin(hrp)
            if not server then task.wait(1) continue end

            -- fly setup — same pattern as Astro universal fly
            local bv = Instance.new("BodyVelocity", hrp)
            bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            bv.Velocity = Vector3.zero

            local bg = Instance.new("BodyGyro", hrp)
            bg.MaxTorque = Vector3.new(9e4, 9e4, 9e4)
            bg.P         = 9e4
            bg.D         = 1e3
            bg.CFrame    = hrp.CFrame

            setCoinNoclip(char, true)

            local target = server.Position
            RunSvc:BindToRenderStep("CoinFly", Enum.RenderPriority.Character.Value + 1, function()
                if not hrp or not hrp.Parent then return end
                local diff = target - hrp.Position
                if diff.Magnitude < COIN_REACH then
                    bv.Velocity = Vector3.zero
                    return
                end
                bv.Velocity = diff.Unit * COIN_SPEED
                bg.CFrame   = CFrame.new(hrp.Position, hrp.Position + diff)
            end)

            local deadline = os.clock() + 8
            while getgenv()._mm2_coins and os.clock() < deadline do
                if not server or not server.Parent then break end
                if (hrp.Position - target).Magnitude <= COIN_REACH then break end
                RunSvc.Heartbeat:Wait()
            end

            RunSvc:UnbindFromRenderStep("CoinFly")
            bv:Destroy()
            bg:Destroy()
            setCoinNoclip(char, false)

            pcall(firetouchinterest, server, hrp, 0)
            pcall(firetouchinterest, server, hrp, 1)
        end

        countConn:Disconnect()
        getgenv()._mm2_coins = false
    end

    elements:Toggle("Auto Collect Coins", section, function(v)
        getgenv()._mm2_coins = v
        if v then task.spawn(coinFarmLoop) end
    end)

    elements:Slider("Coin Farm Speed", section, 20, 150, COIN_SPEED, function(v)
        COIN_SPEED = v
    end)

    -- ── Unload ────────────────────────────────────────────────────────────────
    section.AncestorRemoving:Connect(function()
        getgenv()._mm2_silentaim   = false
        getgenv()._mm2_sheriffonly = false
        getgenv()._mm2_wallcheck   = false
        getgenv()._mm2_esp         = false
        getgenv()._mm2_rolereveal  = false
        getgenv()._mm2_coins       = false
        setCoinNoclip(player.Character, false)

        WeaponService.GetMouseTargetCFrame = origGetTarget

        _targetRender:Disconnect()
        targetGui:Destroy()   -- destroys fovCircle + targetRing
        _lockedTarget = nil
        _fovRadius    = 150

        stopESP()

        if _speedConn then _speedConn:Disconnect() _speedConn = nil end

        for _, conn in ipairs(_roleConns) do conn:Disconnect() end
        table.clear(_roleConns)
    end)
end

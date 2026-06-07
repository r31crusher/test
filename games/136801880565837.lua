-- Flick (PlaceId 136801880565837)
-- Hook: RS.ModuleScripts.GunModules.BulletHandler.Fire(data) — redirects data.Direction

return function(section)
    local elements = getgenv()._astroElements
    local Players  = game:GetService("Players")
    local RS       = game:GetService("ReplicatedStorage")
    local RunSvc   = game:GetService("RunService")
    local UIS      = game:GetService("UserInputService")
    local player   = Players.LocalPlayer
    local camera   = workspace.CurrentCamera

    -- ── State ─────────────────────────────────────────────────────────────────
    getgenv()._flkSA   = false
    getgenv()._flkRage = false
    getgenv()._flkESP  = false
    getgenv()._flkFOV  = false
    getgenv()._flkSnap = false

    local _fovRadius  = 150
    local _hitchance  = 100
    local _hitpart    = "Head"
    local _predBase   = 0.12
    local _predScale  = 0.0001
    local _rageCPS    = 15
    local _rageNext   = 0

    -- ── Velocity cache for prediction ─────────────────────────────────────────
    local _velCache = {}

    RunSvc.Heartbeat:Connect(function()
        for _, p in Players:GetPlayers() do
            if p == player then continue end
            local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local now  = tick()
                local prev = _velCache[root]
                if prev then
                    local dt = now - prev.t
                    if dt > 0 then
                        _velCache[root] = { vel = (root.Position - prev.pos) / dt, pos = root.Position, t = now }
                    end
                else
                    _velCache[root] = { vel = Vector3.zero, pos = root.Position, t = now }
                end
            end
        end
    end)

    -- ── Helpers ────────────────────────────────────────────────────────────────
    local function isEnemy(p)
        return p ~= player and not (p.Team and p.Team == player.Team)
    end

    local function isVisible(part)
        local origin = camera.CFrame.Position
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = { player.Character, camera }
        params.FilterType = Enum.RaycastFilterType.Blacklist
        local result = workspace:Raycast(origin, part.Position - origin, params)
        if result then return result.Instance:IsDescendantOf(part.Parent) end
        return true
    end

    local function getClosestTarget(fovOverride)
        local radius   = fovOverride or _fovRadius
        local mousePos = UIS:GetMouseLocation()
        local best, bestDist = nil, radius
        for _, p in Players:GetPlayers() do
            if not isEnemy(p) then continue end
            local char = p.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local part = char and char:FindFirstChild(_hitpart)
            if not (char and hum and part and hum.Health > 0) then continue end
            local sp, onScreen = camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local d = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                if d < bestDist and isVisible(part) then
                    bestDist = d; best = part
                end
            end
        end
        return best
    end

    local function getAimPos(origin, part)
        local root = part.Parent and part.Parent:FindFirstChild("HumanoidRootPart")
        local vel  = root and _velCache[root] and _velCache[root].vel or Vector3.zero
        local dist = (origin - part.Position).Magnitude
        local fac  = _predBase + dist * _predScale
        return part.Position + vel * fac
    end

    -- ── BulletHandler hook ────────────────────────────────────────────────────
    local _bhOld
    task.spawn(function()
        local ok, bh = pcall(function()
            return require(
                RS:WaitForChild("ModuleScripts", 15)
                  :WaitForChild("GunModules", 15)
                  :WaitForChild("BulletHandler", 15)
            )
        end)
        if not ok or not bh then return end

        _bhOld = hookfunction(bh.Fire, function(data)
            if getgenv()._flkSA and math.random(1, 100) <= _hitchance then
                local tgt = getClosestTarget()
                if tgt and tgt.Parent then
                    local origin = data.Origin or camera.CFrame.Position
                    data.Direction = (getAimPos(origin, tgt) - origin).Unit
                end
            end
            return _bhOld(data)
        end)
    end)

    -- ── Drawings ──────────────────────────────────────────────────────────────
    local _draws = {}
    local function newDraw(kind, props)
        local d = Drawing.new(kind)
        for k, v in pairs(props) do d[k] = v end
        _draws[#_draws + 1] = d
        return d
    end

    local fovOutline = newDraw("Circle", { Visible=false, Filled=false, Color=Color3.new(0,0,0),           Thickness=3, NumSides=60 })
    local fovMain    = newDraw("Circle", { Visible=false, Filled=false, Color=Color3.fromRGB(255,255,255), Thickness=1, NumSides=60 })
    local snapLine   = newDraw("Line",   { Visible=false, Color=Color3.fromRGB(255,255,255), Thickness=1, Transparency=1 })

    local _renderConn = RunSvc.RenderStepped:Connect(function()
        local mousePos = UIS:GetMouseLocation()
        local tgt      = getClosestTarget()

        -- FOV circle
        if getgenv()._flkFOV then
            local col = tgt and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(255, 255, 255)
            fovOutline.Visible = true; fovOutline.Position = mousePos; fovOutline.Radius = _fovRadius
            fovMain.Visible    = true; fovMain.Position    = mousePos; fovMain.Radius    = _fovRadius; fovMain.Color = col
        else
            fovMain.Visible = false; fovOutline.Visible = false
        end

        -- Snap line
        if getgenv()._flkSnap and tgt then
            local sp     = camera:WorldToViewportPoint(tgt.Position)
            local bottom = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
            snapLine.Visible = true; snapLine.From = bottom; snapLine.To = Vector2.new(sp.X, sp.Y)
        else
            snapLine.Visible = false
        end
    end)

    -- ── RageBot ───────────────────────────────────────────────────────────────
    RunSvc.Heartbeat:Connect(function()
        if not getgenv()._flkRage then return end
        if tick() < _rageNext then return end
        if not getClosestTarget(9999) then return end
        _rageNext = tick() + 1 / _rageCPS
        mouse1click()
    end)

    -- ── ESP ───────────────────────────────────────────────────────────────────
    local _espBills = {}

    local function attachESP(p)
        local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local bb = Instance.new("BillboardGui")
        bb.Name = "_flkB"; bb.Size = UDim2.new(0,140,0,44)
        bb.StudsOffset = Vector3.new(0,3.5,0); bb.AlwaysOnTop = true
        bb.Adornee = hrp; bb.Parent = game.CoreGui
        local nLbl = Instance.new("TextLabel", bb)
        nLbl.Size = UDim2.new(1,0,0.55,0); nLbl.BackgroundTransparency = 1
        nLbl.Font = Enum.Font.GothamBold; nLbl.TextSize = 13
        nLbl.TextStrokeTransparency = 0; nLbl.TextColor3 = Color3.fromRGB(255,255,255)
        nLbl.Text = p.Name
        local iLbl = Instance.new("TextLabel", bb)
        iLbl.Size = UDim2.new(1,0,0.45,0); iLbl.Position = UDim2.new(0,0,0.55,0)
        iLbl.BackgroundTransparency = 1; iLbl.Font = Enum.Font.Gotham
        iLbl.TextSize = 11; iLbl.TextStrokeTransparency = 0
        iLbl.TextColor3 = Color3.fromRGB(200,200,200)
        _espBills[p] = { bb=bb, nLbl=nLbl, iLbl=iLbl, hrp=hrp }
    end

    local function makeESP(p)
        if not isEnemy(p) then return end
        attachESP(p)
        p.CharacterAdded:Connect(function()
            task.wait(0.5)
            if _espBills[p] then _espBills[p].bb:Destroy(); _espBills[p] = nil end
            if getgenv()._flkESP then attachESP(p) end
        end)
    end

    local function removeESP(p)
        if _espBills[p] then _espBills[p].bb:Destroy(); _espBills[p] = nil end
    end

    local _espRender, _espAdded, _espRemoving

    local function startESP()
        for _, p in Players:GetPlayers() do makeESP(p) end
        _espAdded    = Players.PlayerAdded:Connect(makeESP)
        _espRemoving = Players.PlayerRemoving:Connect(removeESP)
        _espRender   = RunSvc.RenderStepped:Connect(function()
            local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local tgt   = getClosestTarget()
            for p, data in pairs(_espBills) do
                if not data.bb.Parent then _espBills[p] = nil; continue end
                local hum    = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
                local dist   = myHRP and math.floor((data.hrp.Position - myHRP.Position).Magnitude) or 0
                local onTgt  = tgt and tgt.Parent == p.Character
                data.nLbl.TextColor3 = onTgt and Color3.fromRGB(255,60,60) or Color3.fromRGB(255,255,255)
                data.nLbl.Text = p.Name
                data.iLbl.Text = hum and string.format("HP: %d  [%dm]", math.floor(hum.Health), dist) or ""
            end
        end)
    end

    local function stopESP()
        if _espRender   then _espRender:Disconnect();   _espRender   = nil end
        if _espAdded    then _espAdded:Disconnect();    _espAdded    = nil end
        if _espRemoving then _espRemoving:Disconnect(); _espRemoving = nil end
        for _, data in pairs(_espBills) do data.bb:Destroy() end
        table.clear(_espBills)
    end

    -- ── Menu ──────────────────────────────────────────────────────────────────
    elements:Toggle("Silent Aim",   section, function(v) getgenv()._flkSA   = v end)
    elements:Toggle("FOV Circle",   section, function(v) getgenv()._flkFOV  = v end)
    elements:Slider("FOV Radius",   section, 10, 500, 150, function(v) _fovRadius = v end)
    elements:Toggle("Snap Line",    section, function(v) getgenv()._flkSnap = v end)
    elements:Slider("Hit Chance %", section, 1, 100, 100, function(v) _hitchance = v end)
    elements:Slider("Prediction",   section, 0,  50,  12, function(v) _predBase  = v / 100 end)

    elements:Toggle("RageBot",      section, function(v) getgenv()._flkRage = v end)
    elements:Slider("RageBot CPS",  section, 1,  30,  15, function(v) _rageCPS  = v end)

    elements:Toggle("ESP",          section, function(v)
        getgenv()._flkESP = v
        if v then startESP() else stopESP() end
    end)

    -- ── Unload ────────────────────────────────────────────────────────────────
    section.AncestorRemoving:Connect(function()
        getgenv()._flkSA   = false
        getgenv()._flkRage = false
        getgenv()._flkESP  = false
        getgenv()._flkFOV  = false
        getgenv()._flkSnap = false

        if _renderConn then _renderConn:Disconnect() end
        stopESP()
        for _, d in pairs(_draws) do pcall(d.Remove, d) end

        if _bhOld then
            pcall(function()
                local bh = require(RS.ModuleScripts.GunModules.BulletHandler)
                hookfunction(bh.Fire, _bhOld)
            end)
        end
    end)
end

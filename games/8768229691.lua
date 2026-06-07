-- SkyWars (PlaceId 8768229691)
-- Framework: Flamework (TypeScript/rbxts compiled)
-- Remote UUIDs discovered at runtime by scanning controller constants

return function(section)
    local elements = getgenv()._astroElements
    local Players  = game:GetService("Players")
    local RS       = game:GetService("ReplicatedStorage")
    local RunSvc   = game:GetService("RunService")
    local UIS      = game:GetService("UserInputService")
    local player   = Players.LocalPlayer
    local camera   = workspace.CurrentCamera

    -- ── Remotes bootstrap (Knit — loads fast, no Flamework dependency) ────────
    local swKnitRemotes = nil

    task.spawn(function()
        local ok, result = pcall(function()
            return require(
                RS:WaitForChild("TS", 30)
                  :WaitForChild("remotes", 30)
            ).default
        end)
        if ok and result then swKnitRemotes = result end
    end)

    -- ── Flamework bootstrap ────────────────────────────────────────────────────
    local sw      = {}
    local Remotes = nil
    local _loaded = false

    local function _scanFnForUUIDs(fn, out)
        local ok, consts = pcall(debug.getconstants, fn)
        if not ok then return end
        for _, c in pairs(consts) do
            if type(c) == "string" and #c == 36 and c:sub(9, 9) == "-" then
                out[#out + 1] = c
            end
        end
    end

    local function _scanObjForUUIDs(obj, out)
        local ok, mt = pcall(getrawmetatable, obj)
        if not ok or type(mt) ~= "table" then return end
        for _, v in pairs(mt) do
            if type(v) == "function" then _scanFnForUUIDs(v, out) end
        end
    end

    task.spawn(function()
        local ok, Flamework = pcall(function()
            return require(
                RS:WaitForChild("rbxts_include", 30)
                  :WaitForChild("node_modules", 30)
                  :WaitForChild("@flamework", 30)
                  :WaitForChild("core", 30)
                  :WaitForChild("out", 30)
            ).Flamework
        end)
        if not ok then return end

        local waited = 0
        while waited < 30 do
            local ok2, v = pcall(debug.getupvalue, Flamework.ignite, 1)
            if ok2 and v then break end
            task.wait(0.1); waited += 0.1
        end
        if waited >= 30 then return end

        local fwData = debug.getupvalue(Flamework.ignite, 2)
        if not fwData or not fwData.idToObj then return end

        for id in fwData.idToObj do
            local ok2, ctrl = pcall(function() return Flamework:resolveDependency(id) end)
            if ok2 and type(ctrl) == "table" then
                local name = tostring(ctrl):lower()
                if name:find("melee")      then sw.MeleeController      = ctrl end
                if name:find("projectile") then sw.ProjectileController  = ctrl end
                if name:find("hotbar")     then sw.HotbarController      = ctrl end
                if name:find("shop")       then sw.ShopController        = ctrl end
                if name:find("remote")     then sw.RemoteController      = ctrl end
                if name:find("chest")      then sw.ChestController       = ctrl end
                if name:find("player")     then sw.PlayerController      = ctrl end
                if name:find("camera")     then sw.CameraController      = ctrl end
            end
        end

        -- Locate the Remotes table from RemoteController upvalues
        for _, methName in {"_start", "start", "init", "onStart", "onInit"} do
            local fn = sw.RemoteController and rawget(sw.RemoteController, methName)
            if type(fn) == "function" then
                local allUUIDs = {}
                _scanObjForUUIDs(sw.RemoteController, allUUIDs)
                local firstUUID = allUUIDs[1]
                for i = 1, 20 do
                    local ok3, uv = pcall(debug.getupvalue, fn, i)
                    if not ok3 then break end
                    if type(uv) == "table" and firstUUID and rawget(uv, firstUUID) then
                        Remotes = uv; break
                    end
                end
                if Remotes then break end
            end
        end

        -- Map controller UUIDs to named remote slots
        if sw.MeleeController then
            local uuids = {}; _scanObjForUUIDs(sw.MeleeController, uuids)
            sw._remoteStrikeDesktop = uuids[1]
        end
        if sw.ProjectileController then
            local uuids = {}; _scanObjForUUIDs(sw.ProjectileController, uuids)
            sw._remoteChargeBow = uuids[1]
        end
        if sw.ShopController then
            local uuids = {}; _scanObjForUUIDs(sw.ShopController, uuids)
            sw._remoteBuyItem = uuids[1]
            sw._remoteBuyTeam = uuids[2]
        end
        if sw.ChestController then
            local uuids = {}; _scanObjForUUIDs(sw.ChestController, uuids)
            sw._remoteOpenChest = uuids[1]
        end

        -- CameraUtil provides the cursor direction used by bows
        local ok4, CU = pcall(function()
            return require(player.PlayerScripts
                :WaitForChild("TS"):WaitForChild("util")
                :WaitForChild("camera-util")).CameraUtil
        end)
        if ok4 and CU then sw.CameraUtil = CU end

        _loaded = true
    end)

    -- ── Helpers ───────────────────────────────────────────────────────────────
    local function isEnemy(p)
        return p ~= player and not (p.Team and p.Team == player.Team)
    end

    local function getNearestEnemy(range)
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        local best, bestDist = nil, range or 10
        for _, p in Players:GetPlayers() do
            if not isEnemy(p) then continue end
            local eh = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            local hm = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
            if eh and hm and hm.Health > 0 then
                local d = (hrp.Position - eh.Position).Magnitude
                if d < bestDist then best = p; bestDist = d end
            end
        end
        return best
    end

    local function predictPos(origin, part, projSpeed)
        local dist = (origin - part.Position).Magnitude
        return part.Position + part.AssemblyLinearVelocity * (dist / projSpeed)
    end

    local function getScreenTarget(fov)
        local vp     = camera.ViewportSize
        local cx, cy = vp.X / 2, vp.Y / 2
        local best, bestDist = nil, fov
        for _, p in Players:GetPlayers() do
            if not isEnemy(p) then continue end
            local h  = p.Character and p.Character:FindFirstChild("Head")
            local hm = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
            if h and hm and hm.Health > 0 then
                local sp, on = camera:WorldToViewportPoint(h.Position)
                if on then
                    local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(cx, cy)).Magnitude
                    if d < bestDist then best = h; bestDist = d end
                end
            end
        end
        return best
    end

    local function getTool()
        local char = player.Character
        return char and char:FindFirstChildOfClass("Tool")
    end

    local function fireRemote(uuid, ...)
        if not Remotes or not uuid then return false end
        local r = rawget(Remotes, uuid)
        if r and r.fire then pcall(r.fire, r, ...); return true end
        return false
    end

    local function fireSwordHit(tgtChar)
        if not swKnitRemotes then return false end
        local char = player.Character
        if not char or not char.PrimaryPart then return false end
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then return false end
        if not tgtChar or not tgtChar.PrimaryPart then return false end
        local selfPos = char:GetPivot().Position
        local tgtPos  = tgtChar:GetPivot().Position
        local ok2, remote = pcall(function() return swKnitRemotes.Client:Get("SwordHit") end)
        if not ok2 or not remote then return false end
        pcall(function()
            remote:SendToServer({
                weapon         = tool,
                entityInstance = tgtChar,
                validate       = {
                    targetPosition = { value = tgtPos  },
                    selfPosition   = { value = selfPos },
                },
                chargedAttack  = { chargeRatio = 0 },
            })
        end)
        return true
    end

    -- ── KillAura ──────────────────────────────────────────────────────────────
    getgenv()._swKillaura = false
    local _kaCPS   = 12
    local _kaRange = 6
    local _kaNext  = 0

    elements:Toggle("KillAura", section, function(v) getgenv()._swKillaura = v end)
    elements:Slider("KillAura Range", section, 1, 16, 6,  function(v) _kaRange = v end)
    elements:Slider("KillAura CPS",   section, 1, 20, 12, function(v) _kaCPS  = v end)

    RunSvc.Heartbeat:Connect(function()
        if not getgenv()._swKillaura or tick() < _kaNext then return end
        local tgt = getNearestEnemy(_kaRange)
        if not tgt or not tgt.Character then return end
        _kaNext = tick() + 1 / _kaCPS
        fireSwordHit(tgt.Character)
    end)

    -- ── Reach ─────────────────────────────────────────────────────────────────
    getgenv()._swReach = false
    local _reachDist = 10

    elements:Toggle("Reach", section, function(v) getgenv()._swReach = v end)
    elements:Slider("Reach Distance", section, 4, 20, 10, function(v) _reachDist = v end)

    RunSvc.Heartbeat:Connect(function()
        if not getgenv()._swReach then return end
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local tgt  = getNearestEnemy(50)
        if not hrp or not tgt or not tgt.Character then return end
        local eh  = tgt.Character:FindFirstChild("HumanoidRootPart")
        if not eh then return end
        local dir    = (eh.Position - hrp.Position).Unit
        local realCF = hrp.CFrame
        hrp.CFrame   = CFrame.new(eh.Position - dir * (_reachDist - 0.5))
        RunSvc.Heartbeat:Wait()
        hrp.CFrame   = realCF
    end)

    -- ── AutoClicker ───────────────────────────────────────────────────────────
    getgenv()._swAutoClick = false
    local _acCPS = 15

    elements:Toggle("AutoClicker", section, function(v)
        getgenv()._swAutoClick = v
        if v then
            task.spawn(function()
                while getgenv()._swAutoClick do
                    if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                        local tgt = getNearestEnemy(8)
                        if tgt and tgt.Character then fireSwordHit(tgt.Character) end
                    end
                    task.wait(1 / _acCPS)
                end
            end)
        end
    end)
    elements:Slider("AutoClicker CPS", section, 1, 20, 15, function(v) _acCPS = v end)

    -- ── TriggerBot ────────────────────────────────────────────────────────────
    getgenv()._swTriggerbot = false

    elements:Toggle("TriggerBot", section, function(v) getgenv()._swTriggerbot = v end)

    RunSvc.Heartbeat:Connect(function()
        if not getgenv()._swTriggerbot then return end
        local char = player.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        if not tool then return end
        local vp     = camera.ViewportSize
        local ray    = camera:ViewportPointToRay(vp.X / 2, vp.Y / 2)
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {char}
        params.FilterType = Enum.RaycastFilterType.Exclude
        local result = workspace:Raycast(ray.Origin, ray.Direction * 60, params)
        if result then
            for _, p in Players:GetPlayers() do
                if isEnemy(p) and p.Character and result.Instance:IsDescendantOf(p.Character) then
                    tool:Activate(); break
                end
            end
        end
    end)

    -- ── Velocity ──────────────────────────────────────────────────────────────
    getgenv()._swVelocity = false
    local _velH = 0
    local _velV = 50
    local _velHook

    elements:Toggle("Velocity", section, function(v)
        getgenv()._swVelocity = v
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if v and hrp then
            _velHook = hrp:GetPropertyChangedSignal("AssemblyLinearVelocity"):Connect(function()
                if not getgenv()._swVelocity then return end
                local vel = hrp.AssemblyLinearVelocity
                hrp.AssemblyLinearVelocity = Vector3.new(
                    vel.X * (_velH / 100), vel.Y * (_velV / 100), vel.Z * (_velH / 100))
            end)
        elseif _velHook then _velHook:Disconnect(); _velHook = nil end
    end)
    elements:Slider("Velocity Horiz %", section, 0, 100, 0,  function(v) _velH = v end)
    elements:Slider("Velocity Vert %",  section, 0, 100, 50, function(v) _velV = v end)

    -- ── Criticals ─────────────────────────────────────────────────────────────
    getgenv()._swCrits = false
    local _critsConn

    elements:Toggle("Criticals", section, function(v)
        getgenv()._swCrits = v
        if v then
            _critsConn = UIS.InputBegan:Connect(function(inp)
                if not getgenv()._swCrits then return end
                if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                local char = player.Character
                local hum  = char and char:FindFirstChildOfClass("Humanoid")
                if hum and hum.FloorMaterial ~= Enum.Material.Air then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        elseif _critsConn then _critsConn:Disconnect(); _critsConn = nil end
    end)

    -- ── HitBoxes ──────────────────────────────────────────────────────────────
    getgenv()._swHitboxes = false
    local _hbSize      = 8
    local _hbOrigSizes = {}

    local function _applyHB(p)
        if not isEnemy(p) then return end
        local h = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if h and not _hbOrigSizes[p.UserId] then
            _hbOrigSizes[p.UserId] = h.Size
            h.Size = Vector3.new(_hbSize, _hbSize, _hbSize)
        end
    end
    local function _clearHB(p)
        local h = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if h and _hbOrigSizes[p.UserId] then h.Size = _hbOrigSizes[p.UserId] end
        _hbOrigSizes[p.UserId] = nil
    end

    elements:Toggle("Hitboxes", section, function(v)
        getgenv()._swHitboxes = v
        if v then for _, p in Players:GetPlayers() do _applyHB(p) end
        else  for _, p in Players:GetPlayers() do _clearHB(p) end end
    end)
    elements:Slider("Hitbox Size", section, 2, 20, 8, function(v)
        _hbSize = v
        if getgenv()._swHitboxes then _hbOrigSizes = {}; for _, p in Players:GetPlayers() do _applyHB(p) end end
    end)
    for _, p in Players:GetPlayers() do
        p.CharacterAdded:Connect(function() task.wait(0.2); if getgenv()._swHitboxes then _applyHB(p) end end)
    end
    Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function() task.wait(0.2); if getgenv()._swHitboxes then _applyHB(p) end end)
    end)

    -- ── ProjectileAimbot ──────────────────────────────────────────────────────
    getgenv()._swProjAim = false
    local _paSpeed = 180
    local _paFOV   = 500
    local _paOldDir, _paOldGet

    local function _aimDir()
        local tgt = getScreenTarget(_paFOV)
        if not tgt then return nil end
        local origin    = camera.CFrame.Position
        local predicted = predictPos(origin, tgt, _paSpeed)
        return (predicted - origin).Unit
    end

    elements:Toggle("Projectile Aimbot", section, function(v)
        getgenv()._swProjAim = v
        if v and _loaded and sw.CameraUtil then
            pcall(function()
                _paOldDir = hookfunction(sw.CameraUtil.getCursorDirection, function(...)
                    if not getgenv()._swProjAim then return _paOldDir(...) end
                    return _aimDir() or _paOldDir(...)
                end)
            end)
            pcall(function()
                _paOldGet = hookfunction(sw.CameraUtil.getDirection, function(...)
                    if not getgenv()._swProjAim then return _paOldGet(...) end
                    return _aimDir() or _paOldGet(...)
                end)
            end)
        elseif _paOldDir then
            pcall(hookfunction, sw.CameraUtil.getCursorDirection, _paOldDir); _paOldDir = nil
            if _paOldGet then pcall(hookfunction, sw.CameraUtil.getDirection, _paOldGet); _paOldGet = nil end
        end
    end)
    elements:Slider("Proj Speed (st/s)", section, 50, 500, 180, function(v) _paSpeed = v end)
    elements:Slider("Proj Aimbot FOV",   section, 50, 1000, 500, function(v) _paFOV  = v end)

    -- ── ProjectileAura ────────────────────────────────────────────────────────
    getgenv()._swProjAura = false
    local _auraRange = 40

    elements:Toggle("Projectile Aura", section, function(v)
        getgenv()._swProjAura = v
        if v then
            task.spawn(function()
                while getgenv()._swProjAura do
                    if _loaded then
                        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                        local tgt = getNearestEnemy(_auraRange)
                        if hrp and tgt and tgt.Character then
                            local head = tgt.Character:FindFirstChild("Head") or tgt.Character:FindFirstChild("HumanoidRootPart")
                            if head and sw._remoteChargeBow then
                                local dir = (predictPos(hrp.Position, head, _paSpeed) - hrp.Position).Unit
                                fireRemote(sw._remoteChargeBow, dir, 1)
                            end
                        end
                    end
                    task.wait(0.4)
                end
            end)
        end
    end)
    elements:Slider("Proj Aura Range", section, 5, 80, 40, function(v) _auraRange = v end)

    -- ── AutoBuy ───────────────────────────────────────────────────────────────
    getgenv()._swAutoBuy = false

    elements:Toggle("AutoBuy (Blacksmith)", section, function(v)
        getgenv()._swAutoBuy = v
        if v then
            task.spawn(function()
                while getgenv()._swAutoBuy do
                    if _loaded and sw._remoteBuyItem then
                        pcall(function()
                            fireRemote(sw._remoteBuyItem, "Blacksmith", 1)
                            task.wait(0.15)
                            fireRemote(sw._remoteBuyItem, "Blacksmith", 2)
                        end)
                    end
                    task.wait(2)
                end
            end)
        end
    end)

    -- ── NoFall ────────────────────────────────────────────────────────────────
    -- Two layers: hook Flamework PlayerController fall handler + local void catch.
    getgenv()._swNoFall = false
    local _nofallOrig
    local _nofallLastSafe = nil

    elements:Toggle("NoFall", section, function(v)
        getgenv()._swNoFall = v
        if v and _loaded and sw.PlayerController then
            -- Try to hook the fall damage method in PlayerController
            for _, methName in {"takeFallDamage", "onFallDamage", "applyFallDamage", "_takeFallDamage"} do
                local fn = rawget(sw.PlayerController, methName)
                if type(fn) == "function" then
                    _nofallOrig = hookfunction(fn, function(...)
                        if getgenv()._swNoFall then return end
                        return _nofallOrig(...)
                    end)
                    break
                end
            end
        elseif _nofallOrig then
            -- No clean way to restore without knowing which function we hooked; just disable the guard
            _nofallOrig = nil
        end
    end)

    RunSvc.Heartbeat:Connect(function()
        if not getgenv()._swNoFall then return end
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        if hum.FloorMaterial ~= Enum.Material.Air then
            _nofallLastSafe = hrp.CFrame
        elseif _nofallLastSafe and hrp.Position.Y < (_nofallLastSafe.Position.Y - 60) then
            hrp.CFrame = _nofallLastSafe
        end
    end)

    -- ── ChestSteal ────────────────────────────────────────────────────────────
    -- Fires the openChest remote for every chest in the workspace on demand,
    -- then on a loop while the toggle is active.
    getgenv()._swChestSteal = false
    local _csRange = 60

    local function _stealChests()
        if not _loaded then return end
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        for _, obj in workspace:GetDescendants() do
            local nameLower = obj.Name:lower()
            if nameLower:find("chest") and not nameLower:find("chestplate") then
                local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")) or obj
                if part and part:IsA("BasePart") and (part.Position - hrp.Position).Magnitude < _csRange then
                    if sw._remoteOpenChest then
                        fireRemote(sw._remoteOpenChest, obj)
                    else
                        -- Fallback: proximity trigger on the chest part
                        pcall(firetouchinterest, part, hrp, 0)
                        task.wait(0.05)
                        pcall(firetouchinterest, part, hrp, 1)
                    end
                end
            end
        end
    end

    elements:Toggle("ChestSteal", section, function(v)
        getgenv()._swChestSteal = v
        if v then
            _stealChests()
            task.spawn(function()
                while getgenv()._swChestSteal do
                    task.wait(2)
                    _stealChests()
                end
            end)
        end
    end)
    elements:Slider("Chest Range", section, 10, 150, 60, function(v) _csRange = v end)
    elements:Button("Steal Now", section, _stealChests)

    -- ── AutoTeamUpgrade ───────────────────────────────────────────────────────
    -- Purchases team upgrades at the Merchant NPC via Flamework remotes.
    getgenv()._swAutoTeam = false

    elements:Toggle("AutoTeamUpgrade", section, function(v)
        getgenv()._swAutoTeam = v
        if v then
            task.spawn(function()
                while getgenv()._swAutoTeam do
                    if _loaded and sw._remoteBuyTeam then
                        pcall(function()
                            fireRemote(sw._remoteBuyTeam, "Merchant", 1)
                            task.wait(0.15)
                            fireRemote(sw._remoteBuyTeam, "Merchant", 2)
                        end)
                    end
                    task.wait(3)
                end
            end)
        end
    end)

    -- ── RapidFire ─────────────────────────────────────────────────────────────
    -- Fires chargeBow remote at full power instantly rather than waiting for
    -- the charge animation. Effectively removes bow charge time.
    getgenv()._swRapidFire = false
    local _rfDelay = 0

    elements:Toggle("RapidFire", section, function(v) getgenv()._swRapidFire = v end)

    RunSvc.Heartbeat:Connect(function()
        if not getgenv()._swRapidFire or not _loaded or tick() < _rfDelay then return end
        if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return end
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        -- Check if holding a bow-type tool
        local tool = getTool()
        if not tool or not (tool.Name:lower():find("bow") or tool.Name:lower():find("crossbow")) then return end

        _rfDelay = tick() + 0.25
        if sw._remoteChargeBow then
            local dir = camera.CFrame.LookVector
            local tgt = getScreenTarget(500)
            if tgt then dir = (predictPos(camera.CFrame.Position, tgt, _paSpeed) - camera.CFrame.Position).Unit end
            fireRemote(sw._remoteChargeBow, dir, 1)
        end
    end)

    -- ── AntiKnockback ─────────────────────────────────────────────────────────
    -- Completely nullifies knockback by zeroing horizontal velocity changes
    -- not caused by player movement. More aggressive than Velocity.
    getgenv()._swAntiKB = false
    local _akbHook

    elements:Toggle("AntiKnockback", section, function(v)
        getgenv()._swAntiKB = v
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if v and hrp then
            _akbHook = hrp:GetPropertyChangedSignal("AssemblyLinearVelocity"):Connect(function()
                if not getgenv()._swAntiKB then return end
                local vel = hrp.AssemblyLinearVelocity
                -- Cancel any sudden horizontal velocity spike (knockback signature)
                if Vector2.new(vel.X, vel.Z).Magnitude > 25 then
                    hrp.AssemblyLinearVelocity = Vector3.new(0, vel.Y, 0)
                end
            end)
        elseif _akbHook then _akbHook:Disconnect(); _akbHook = nil end
    end)

    -- ── ESP ───────────────────────────────────────────────────────────────────
    -- BillboardGui enemies with name, HP, distance, colored by team.
    getgenv()._swESP = false
    local _espBills = {}

    local function _makeESP(p)
        if not isEnemy(p) then return end
        local function attach()
            local char = p.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local bb = Instance.new("BillboardGui")
            bb.Name = "_swESP"
            bb.Size = UDim2.new(0, 140, 0, 44)
            bb.StudsOffset = Vector3.new(0, 3.5, 0)
            bb.AlwaysOnTop = true
            bb.Adornee = hrp
            bb.Parent = game.CoreGui

            local nameLbl = Instance.new("TextLabel", bb)
            nameLbl.Size = UDim2.new(1, 0, 0.55, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Font = Enum.Font.GothamBold
            nameLbl.TextSize = 13
            nameLbl.TextStrokeTransparency = 0
            nameLbl.TextColor3 = p.Team and p.Team.TeamColor.Color or Color3.fromRGB(255, 80, 80)
            nameLbl.Text = p.Name

            local infoLbl = Instance.new("TextLabel", bb)
            infoLbl.Size = UDim2.new(1, 0, 0.45, 0)
            infoLbl.Position = UDim2.new(0, 0, 0.55, 0)
            infoLbl.BackgroundTransparency = 1
            infoLbl.Font = Enum.Font.Gotham
            infoLbl.TextSize = 11
            infoLbl.TextStrokeTransparency = 0
            infoLbl.TextColor3 = Color3.fromRGB(200, 200, 200)

            _espBills[p] = {bb = bb, nameLbl = nameLbl, infoLbl = infoLbl, hrp = hrp}
        end

        attach()
        p.CharacterAdded:Connect(function()
            task.wait(0.5)
            if _espBills[p] then _espBills[p].bb:Destroy(); _espBills[p] = nil end
            if getgenv()._swESP then attach() end
        end)
    end

    local function _removeESP(p)
        if _espBills[p] then _espBills[p].bb:Destroy(); _espBills[p] = nil end
    end

    local _espRender, _espAdded, _espRemoving

    local function _startESP()
        for _, p in Players:GetPlayers() do _makeESP(p) end
        _espAdded    = Players.PlayerAdded:Connect(_makeESP)
        _espRemoving = Players.PlayerRemoving:Connect(_removeESP)
        _espRender   = RunSvc.RenderStepped:Connect(function()
            local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            for p, data in pairs(_espBills) do
                if not data.bb.Parent then _espBills[p] = nil; continue end
                local hum  = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
                local dist = myHRP and math.floor((data.hrp.Position - myHRP.Position).Magnitude) or 0
                data.nameLbl.TextColor3 = p.Team and p.Team.TeamColor.Color or Color3.fromRGB(255, 80, 80)
                data.nameLbl.Text = p.Name
                data.infoLbl.Text = hum and string.format("HP: %d  [%dm]", math.floor(hum.Health), dist) or ""
            end
        end)
    end

    local function _stopESP()
        if _espRender   then _espRender:Disconnect()   _espRender   = nil end
        if _espAdded    then _espAdded:Disconnect()    _espAdded    = nil end
        if _espRemoving then _espRemoving:Disconnect() _espRemoving = nil end
        for _, data in pairs(_espBills) do data.bb:Destroy() end
        table.clear(_espBills)
    end

    elements:Toggle("ESP", section, function(v)
        getgenv()._swESP = v
        if v then _startESP() else _stopESP() end
    end)

    -- ── Unload ────────────────────────────────────────────────────────────────
    section.AncestorRemoving:Connect(function()
        getgenv()._swKillaura   = false
        getgenv()._swReach      = false
        getgenv()._swAutoClick  = false
        getgenv()._swTriggerbot = false
        getgenv()._swVelocity   = false
        getgenv()._swCrits      = false
        getgenv()._swHitboxes   = false
        getgenv()._swProjAim    = false
        getgenv()._swProjAura   = false
        getgenv()._swAutoBuy    = false
        getgenv()._swNoFall     = false
        getgenv()._swChestSteal = false
        getgenv()._swAutoTeam   = false
        getgenv()._swRapidFire  = false
        getgenv()._swAntiKB     = false
        getgenv()._swESP        = false

        if _velHook   then _velHook:Disconnect() end
        if _critsConn then _critsConn:Disconnect() end
        if _akbHook   then _akbHook:Disconnect() end
        if _paOldDir and sw.CameraUtil then
            pcall(hookfunction, sw.CameraUtil.getCursorDirection, _paOldDir)
        end
        if _paOldGet and sw.CameraUtil then
            pcall(hookfunction, sw.CameraUtil.getDirection, _paOldGet)
        end
        for _, p in Players:GetPlayers() do _clearHB(p) end
        _stopESP()
    end)
end

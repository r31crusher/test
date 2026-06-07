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

    -- ── Flamework bootstrap ────────────────────────────────────────────────────
    -- All controllers live inside Flamework's idToObj table after ignition.
    -- Remote UUIDs are 36-char strings (8-4-4-4-12 format) baked into compiled TS.
    local sw      = {}   -- named controllers
    local Remotes = nil  -- the game's Remotes table (maps UUID → RemoteSignal)
    local _loaded = false

    -- Collect all UUID constants from a function's upvalue tree
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
        local mt = pcall(getrawmetatable, obj) and getrawmetatable(obj)
        if type(mt) ~= "table" then return end
        for _, v in pairs(mt) do
            if type(v) == "function" then _scanFnForUUIDs(v, out) end
        end
    end

    task.spawn(function()
        -- Load Flamework module
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

        -- Wait for Flamework.ignite to have resolved its dependency table
        local waited = 0
        while waited < 30 do
            local ok2, v = pcall(debug.getupvalue, Flamework.ignite, 1)
            if ok2 and v then break end
            task.wait(0.1); waited += 0.1
        end
        if waited >= 30 then return end

        local fwData = debug.getupvalue(Flamework.ignite, 2)
        if not fwData or not fwData.idToObj then return end

        -- Resolve every controller and file by name fragment
        for id in fwData.idToObj do
            local ok2, ctrl = pcall(function() return Flamework:resolveDependency(id) end)
            if ok2 and type(ctrl) == "table" then
                local name = tostring(ctrl):lower()
                if name:find("melee")      then sw.MeleeController      = ctrl end
                if name:find("projectile") then sw.ProjectileController  = ctrl end
                if name:find("hotbar")     then sw.HotbarController      = ctrl end
                if name:find("shop")       then sw.ShopController        = ctrl end
                if name:find("remote")     then sw.RemoteController      = ctrl end
                if name:find("camera")     then sw.CameraController      = ctrl end
            end
        end

        -- Locate the Remotes table: upvalue of RemoteController.init/start
        -- It maps UUID → RemoteSignal with :fire() / :invoke() methods
        for _, methName in {"_start", "start", "init", "onStart", "onInit"} do
            local fn = sw.RemoteController and rawget(sw.RemoteController, methName)
            if type(fn) == "function" then
                for i = 1, 20 do
                    local ok3, uv = pcall(debug.getupvalue, fn, i)
                    if not ok3 then break end
                    if type(uv) == "table" then
                        -- Remotes table has UUID keys
                        local uuids = {}
                        _scanObjForUUIDs(sw.RemoteController, uuids)
                        local firstUUID = uuids[1]
                        if firstUUID and rawget(uv, firstUUID) then
                            Remotes = uv; break
                        end
                    end
                end
                if Remotes then break end
            end
        end

        -- Discover remote UUID → purpose mapping by scanning MeleeController
        -- constants. We map by the order VapeV4 finds them:
        -- strikeDesktop, chargeBow, purchaseItemUpgrade, purchaseTeamUpgrade, openChest
        if sw.MeleeController then
            local uuids = {}
            _scanObjForUUIDs(sw.MeleeController, uuids)
            sw._remoteStrikeDesktop = uuids[1]   -- first UUID = strike remote
        end
        if sw.ProjectileController then
            local uuids = {}
            _scanObjForUUIDs(sw.ProjectileController, uuids)
            sw._remoteChargeBow = uuids[1]        -- first UUID = charge bow
        end
        if sw.ShopController then
            local uuids = {}
            _scanObjForUUIDs(sw.ShopController, uuids)
            sw._remoteBuyItem   = uuids[1]
            sw._remoteBuyTeam   = uuids[2]
        end

        -- CameraUtil: used by ProjectileController for cursor direction
        local ok4, CU = pcall(function()
            return require(player.PlayerScripts
                :WaitForChild("TS"):WaitForChild("util")
                :WaitForChild("camera-util")).CameraUtil
        end)
        if ok4 and CU then sw.CameraUtil = CU end

        _loaded = true
    end)

    -- ── Helpers ───────────────────────────────────────────────────────────────
    local function getNearestEnemy(range)
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        local best, bestDist = nil, range or 10
        for _, p in Players:GetPlayers() do
            if p == player then continue end
            local ec = p.Character
            local eh = ec and ec:FindFirstChild("HumanoidRootPart")
            local hm = ec and ec:FindFirstChildOfClass("Humanoid")
            if eh and hm and hm.Health > 0 then
                local d = (hrp.Position - eh.Position).Magnitude
                if d < bestDist then best = p; bestDist = d end
            end
        end
        return best
    end

    local function predictPos(origin, part, projSpeed)
        local dist = (origin - part.Position).Magnitude
        local dt   = dist / projSpeed
        return part.Position + part.AssemblyLinearVelocity * dt
    end

    local function getScreenTarget(fov)
        local vp     = camera.ViewportSize
        local cx, cy = vp.X / 2, vp.Y / 2
        local best, bestDist = nil, fov
        for _, p in Players:GetPlayers() do
            if p == player then continue end
            local c  = p.Character
            local h  = c and c:FindFirstChild("Head")
            local hm = c and c:FindFirstChildOfClass("Humanoid")
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

    -- ── KillAura ──────────────────────────────────────────────────────────────
    -- Uses MeleeController:strike for native hit registration.
    -- Falls back to firetouchinterest when Flamework isn't loaded yet.
    getgenv()._swKillaura = false
    local _kaCPS   = 12
    local _kaRange = 6
    local _kaNext  = 0

    elements:Toggle("KillAura", section, function(v) getgenv()._swKillaura = v end)
    elements:Slider("KillAura Range", section, 1, 16, 6,  function(v) _kaRange = v end)
    elements:Slider("KillAura CPS",   section, 1, 20, 12, function(v) _kaCPS  = v end)

    RunSvc.Heartbeat:Connect(function()
        if not getgenv()._swKillaura or tick() < _kaNext then return end
        local tgt  = getNearestEnemy(_kaRange)
        local tool = getTool()
        if not tgt or not tgt.Character then return end

        _kaNext = tick() + 1 / _kaCPS

        if _loaded and sw.MeleeController then
            -- Native: strike via controller + fire strike remote to server
            pcall(function()
                sw.MeleeController:strike(tool)
            end)
            if sw._remoteStrikeDesktop then
                fireRemote(sw._remoteStrikeDesktop, tgt)
            end
        else
            -- Universal fallback: touch interaction
            local eh = tgt.Character:FindFirstChild("HumanoidRootPart")
            if eh and tool then
                firetouchinterest(eh, tool, 0)
                task.wait(); firetouchinterest(eh, tool, 1)
            end
        end
    end)

    -- ── Reach ─────────────────────────────────────────────────────────────────
    -- Enlarges the hit region by temporarily moving HRP toward the target
    -- and back within one frame (server sees the extended reach).
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
        local eh = tgt.Character:FindFirstChild("HumanoidRootPart")
        if not eh then return end
        local dir     = (eh.Position - hrp.Position).Unit
        local realCF  = hrp.CFrame
        hrp.CFrame    = CFrame.new(eh.Position - dir * (_reachDist - 0.5))
        RunSvc.Heartbeat:Wait()
        hrp.CFrame    = realCF
    end)

    -- ── AutoClicker ───────────────────────────────────────────────────────────
    getgenv()._swAutoClick = false
    local _acCPS = 15

    elements:Toggle("AutoClicker", section, function(v)
        getgenv()._swAutoClick = v
        if v then
            task.spawn(function()
                while getgenv()._swAutoClick do
                    local tool = getTool()
                    if tool and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                        tool:Activate()
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
                if p ~= player and p.Character
                        and result.Instance:IsDescendantOf(p.Character) then
                    tool:Activate()
                    break
                end
            end
        end
    end)

    -- ── Velocity ──────────────────────────────────────────────────────────────
    -- Clamps knockback applied to the local HRP.
    getgenv()._swVelocity = false
    local _velH = 0
    local _velV = 50

    local _velHook
    elements:Toggle("Velocity", section, function(v)
        getgenv()._swVelocity = v
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if v and hrp then
            _velHook = hrp:GetPropertyChangedSignal("AssemblyLinearVelocity"):Connect(function()
                if not getgenv()._swVelocity then return end
                local vel = hrp.AssemblyLinearVelocity
                hrp.AssemblyLinearVelocity = Vector3.new(
                    vel.X * (_velH / 100),
                    vel.Y * (_velV / 100),
                    vel.Z * (_velH / 100))
            end)
        elseif _velHook then
            _velHook:Disconnect(); _velHook = nil
        end
    end)
    elements:Slider("Velocity Horiz %", section, 0, 100, 0,  function(v) _velH = v end)
    elements:Slider("Velocity Vert %",  section, 0, 100, 50, function(v) _velV = v end)

    -- ── Criticals ─────────────────────────────────────────────────────────────
    -- Bounces the player upward just before each swing so the hit registers
    -- as a critical (falling = crit in most Roblox combat systems).
    getgenv()._swCrits = false
    local _critsConn

    elements:Toggle("Criticals", section, function(v)
        getgenv()._swCrits = v
        if v then
            _critsConn = UIS.InputBegan:Connect(function(inp)
                if not getgenv()._swCrits then return end
                if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                local char = player.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                local hum  = char and char:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.FloorMaterial ~= Enum.Material.Air then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        elseif _critsConn then
            _critsConn:Disconnect(); _critsConn = nil
        end
    end)

    -- ── HitBoxes ──────────────────────────────────────────────────────────────
    getgenv()._swHitboxes  = false
    local _hbSize      = 8
    local _hbOrigSizes = {}

    local function _applyHB(p)
        if p == player then return end
        local c = p.Character
        local h = c and c:FindFirstChild("HumanoidRootPart")
        if h and not _hbOrigSizes[p.UserId] then
            _hbOrigSizes[p.UserId] = h.Size
            h.Size = Vector3.new(_hbSize, _hbSize, _hbSize)
        end
    end
    local function _clearHB(p)
        local c = p.Character
        local h = c and c:FindFirstChild("HumanoidRootPart")
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
        if getgenv()._swHitboxes then
            _hbOrigSizes = {}
            for _, p in Players:GetPlayers() do _applyHB(p) end
        end
    end)
    for _, p in Players:GetPlayers() do
        p.CharacterAdded:Connect(function()
            task.wait(0.2)
            if getgenv()._swHitboxes then _applyHB(p) end
        end)
    end
    Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function()
            task.wait(0.2)
            if getgenv()._swHitboxes then _applyHB(p) end
        end)
    end)

    -- ── ProjectileAimbot ──────────────────────────────────────────────────────
    -- Hooks CameraUtil.getCursorDirection / getDirection to redirect projectile
    -- firing toward a predicted intercept point.
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
    -- Auto-fires the charged bow remote at the nearest enemy.
    getgenv()._swProjAura = false
    local _auraRange = 40

    elements:Toggle("Projectile Aura", section, function(v)
        getgenv()._swProjAura = v
        if v then
            task.spawn(function()
                while getgenv()._swProjAura do
                    if _loaded then
                        local char = player.Character
                        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                        local tgt  = getNearestEnemy(_auraRange)
                        if hrp and tgt and tgt.Character then
                            local head = tgt.Character:FindFirstChild("Head")
                                      or tgt.Character:FindFirstChild("HumanoidRootPart")
                            if head and sw._remoteChargeBow then
                                local predicted = predictPos(hrp.Position, head, _paSpeed)
                                local dir = (predicted - hrp.Position).Unit
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

        if _velHook    then _velHook:Disconnect() end
        if _critsConn  then _critsConn:Disconnect() end
        if _paOldDir and sw.CameraUtil then
            pcall(hookfunction, sw.CameraUtil.getCursorDirection, _paOldDir)
        end
        if _paOldGet and sw.CameraUtil then
            pcall(hookfunction, sw.CameraUtil.getDirection, _paOldGet)
        end
        for _, p in Players:GetPlayers() do _clearHB(p) end
    end)
end

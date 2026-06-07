-- Bedwars (PlaceId 6872274481)
-- Framework: Knit + Blink RPC
-- Based on VapeV4 139566161526375 analysis

return function(section)
    local elements = getgenv()._astroElements
    local Players  = game:GetService("Players")
    local RS       = game:GetService("ReplicatedStorage")
    local RunSvc   = game:GetService("RunService")
    local CS       = game:GetService("CollectionService")
    local UIS      = game:GetService("UserInputService")
    local player   = Players.LocalPlayer
    local camera   = workspace.CurrentCamera

    -- ── Knit + Blink bootstrap ────────────────────────────────────────────────
    local bd      = {}
    local _loaded = false

    task.spawn(function()
        local ok, Knit = pcall(require,
            RS:WaitForChild("Modules", 30)
              :WaitForChild("Knit", 30)
              :WaitForChild("Client", 30))
        if not ok then return end

        local waited = 0
        while not debug.getupvalue(Knit.Start, 1) and waited < 30 do
            task.wait(0.1); waited += 0.1
        end

        bd = setmetatable({
            Knit         = Knit,
            Blink        = require(RS:WaitForChild("Blink"):WaitForChild("Client")),
            Entity       = require(RS:WaitForChild("Modules"):WaitForChild("Entity")),
            BowClient    = require(RS:WaitForChild("Client"):WaitForChild("Components")
                                     :WaitForChild("All"):WaitForChild("Tools")
                                     :WaitForChild("BowClient")),
            CombatConsts = require(RS:WaitForChild("Constants"):WaitForChild("Melee")),
        }, {
            __index = function(self, k)
                local ok2, v = pcall(function()
                    return k:find("Service") and Knit.GetService(k) or Knit.GetController(k)
                end)
                if ok2 then rawset(self, k, v) end
                return ok2 and v or nil
            end
        })
        _loaded = true
    end)

    -- ── Helpers ───────────────────────────────────────────────────────────────
    local function getTool()
        local char = player.Character
        return char and char:FindFirstChildOfClass("Tool")
    end

    local function getNearestEnemy(range)
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        local best, bestDist = nil, range or 10
        for _, p in Players:GetPlayers() do
            if p == player or (p.Team and p.Team == player.Team) then continue end
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

    local function isEnemy(p)
        return p ~= player and not (p.Team and p.Team == player.Team)
    end

    -- ── KillAura ──────────────────────────────────────────────────────────────
    getgenv()._bdKillaura = false
    local _kaCPS   = 12
    local _kaRange = 6
    local _kaNext  = 0

    elements:Toggle("KillAura", section, function(v) getgenv()._bdKillaura = v end)
    elements:Slider("KillAura Range", section, 1, 16, 6,  function(v) _kaRange = v end)
    elements:Slider("KillAura CPS",   section, 1, 20, 12, function(v) _kaCPS  = v end)

    RunSvc.Heartbeat:Connect(function()
        if not getgenv()._bdKillaura or tick() < _kaNext then return end
        local tool = getTool()
        local tgt  = getNearestEnemy(_kaRange)
        if not tool or not tgt or not tgt.Character then return end
        _kaNext = tick() + 1 / _kaCPS

        local hrp    = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local isCrit = hrp and hrp.AssemblyLinearVelocity.Y < 0 or false

        if _loaded then
            local ok, bdEnt = pcall(function() return bd.Entity.FindByCharacter(tgt.Character) end)
            if ok and bdEnt then
                pcall(function()
                    bd.Blink.item_action.attack_entity.fire({
                        target_entity_id = bdEnt.Id,
                        is_crit   = isCrit,
                        weapon_name = tool.Name,
                    })
                end)
                return
            end
        end
        local eh = tgt.Character:FindFirstChild("HumanoidRootPart")
        if eh then firetouchinterest(eh, tool, 0); task.wait(); firetouchinterest(eh, tool, 1) end
    end)

    -- ── Reach ─────────────────────────────────────────────────────────────────
    getgenv()._bdReach = false
    local _reachDist = 10
    local _reachOrig = nil

    elements:Toggle("Reach", section, function(v)
        getgenv()._bdReach = v
        if not v and _loaded and _reachOrig ~= nil then
            pcall(function() rawset(bd.CombatConsts, "REACH_IN_STUDS", _reachOrig) end)
            _reachOrig = nil
        end
    end)
    elements:Slider("Reach Distance", section, 4, 20, 10, function(v) _reachDist = v end)

    RunSvc.Heartbeat:Connect(function()
        if not getgenv()._bdReach or not _loaded then return end
        pcall(function()
            local cc = bd.CombatConsts
            if _reachOrig == nil then _reachOrig = rawget(cc, "REACH_IN_STUDS") end
            rawset(cc, "REACH_IN_STUDS", _reachDist)
        end)
    end)

    -- ── AutoClicker ───────────────────────────────────────────────────────────
    getgenv()._bdAutoClick = false
    local _acCPS = 15

    elements:Toggle("AutoClicker", section, function(v)
        getgenv()._bdAutoClick = v
        if v then
            task.spawn(function()
                while getgenv()._bdAutoClick do
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
    getgenv()._bdTriggerbot = false

    elements:Toggle("TriggerBot", section, function(v) getgenv()._bdTriggerbot = v end)

    RunSvc.Heartbeat:Connect(function()
        if not getgenv()._bdTriggerbot then return end
        local char = player.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        if not tool then return end
        local vp  = camera.ViewportSize
        local ray = camera:ViewportPointToRay(vp.X / 2, vp.Y / 2)
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {char}
        params.FilterType = Enum.RaycastFilterType.Exclude
        local result = workspace:Raycast(ray.Origin, ray.Direction * 60, params)
        if result then
            for _, p in Players:GetPlayers() do
                if isEnemy(p) and p.Character
                        and result.Instance:IsDescendantOf(p.Character) then
                    tool:Activate(); break
                end
            end
        end
    end)

    -- ── Velocity ──────────────────────────────────────────────────────────────
    getgenv()._bdVelocity = false
    local _velH = 0
    local _velV = 50
    local _velOrig, _velConn

    elements:Toggle("Velocity", section, function(v)
        getgenv()._bdVelocity = v
        if v and _loaded then
            pcall(function()
                local conns = getconnections(bd.CombatService.KnockBackApplied._re.OnClientEvent)
                _velConn = conns and conns[1]
                if _velConn then
                    _velOrig = hookfunction(_velConn.Function, function(velo, ...)
                        if getgenv()._bdVelocity then
                            velo = Vector3.new(
                                velo.X * (_velH / 100),
                                velo.Y * (_velV / 100),
                                velo.Z * (_velH / 100))
                        end
                        return _velOrig(velo, ...)
                    end)
                end
            end)
        elseif _velOrig and _velConn then
            pcall(hookfunction, _velConn.Function, _velOrig)
            _velOrig = nil; _velConn = nil
        end
    end)
    elements:Slider("Velocity Horiz %", section, 0, 100, 0,  function(v) _velH = v end)
    elements:Slider("Velocity Vert %",  section, 0, 100, 50, function(v) _velV = v end)

    -- ── Criticals ─────────────────────────────────────────────────────────────
    getgenv()._bdCrits = false
    local _critsOrig

    elements:Toggle("Criticals", section, function(v)
        getgenv()._bdCrits = v
        if v and _loaded then
            pcall(function()
                _critsOrig = hookfunction(bd.Blink.item_action.attack_entity.fire,
                    function(data, ...)
                        if getgenv()._bdCrits and type(data) == "table" then
                            rawset(data, "is_crit", true)
                        end
                        return _critsOrig(data, ...)
                    end)
            end)
        elseif _critsOrig then
            pcall(function() hookfunction(bd.Blink.item_action.attack_entity.fire, _critsOrig) end)
            _critsOrig = nil
        end
    end)

    -- ── HitBoxes ──────────────────────────────────────────────────────────────
    getgenv()._bdHitboxes = false
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
        getgenv()._bdHitboxes = v
        if v then for _, p in Players:GetPlayers() do _applyHB(p) end
        else  for _, p in Players:GetPlayers() do _clearHB(p) end end
    end)
    elements:Slider("Hitbox Size", section, 2, 20, 8, function(v)
        _hbSize = v
        if getgenv()._bdHitboxes then _hbOrigSizes = {}; for _, p in Players:GetPlayers() do _applyHB(p) end end
    end)
    for _, p in Players:GetPlayers() do
        p.CharacterAdded:Connect(function() task.wait(0.2); if getgenv()._bdHitboxes then _applyHB(p) end end)
    end
    Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function() task.wait(0.2); if getgenv()._bdHitboxes then _applyHB(p) end end)
    end)

    -- ── ProjectileAimbot ──────────────────────────────────────────────────────
    getgenv()._bdProjAim = false
    local _paSpeed = 180
    local _paFOV   = 500
    local _paOld

    local function _getScreenTarget(fov)
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

    elements:Toggle("Projectile Aimbot", section, function(v)
        getgenv()._bdProjAim = v
        if v and _loaded then
            pcall(function()
                local bowFn = debug.getupvalue(bd.BowClient.Start, 11)
                _paOld = hookfunction(bowFn, function(...)
                    if not getgenv()._bdProjAim then return _paOld(...) end
                    local tgt = _getScreenTarget(_paFOV)
                    if tgt then
                        local origin    = camera.CFrame.Position
                        local predicted = predictPos(origin, tgt, _paSpeed)
                        return (predicted - origin).Unit
                    end
                    return _paOld(...)
                end)
            end)
        elseif _paOld then
            pcall(function() hookfunction(debug.getupvalue(bd.BowClient.Start, 11), _paOld); _paOld = nil end)
        end
    end)
    elements:Slider("Proj Speed (st/s)", section, 50, 500, 180, function(v) _paSpeed = v end)
    elements:Slider("Proj Aimbot FOV",   section, 50, 1000, 500, function(v) _paFOV  = v end)

    -- ── ProjectileAura ────────────────────────────────────────────────────────
    getgenv()._bdProjAura = false
    local _auraRange = 40

    elements:Toggle("Projectile Aura", section, function(v)
        getgenv()._bdProjAura = v
        if v then
            task.spawn(function()
                while getgenv()._bdProjAura do
                    if _loaded then
                        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                        local tgt = getNearestEnemy(_auraRange)
                        if hrp and tgt and tgt.Character then
                            local head = tgt.Character:FindFirstChild("Head") or tgt.Character:FindFirstChild("HumanoidRootPart")
                            if head then
                                local dir = (predictPos(hrp.Position, head, _paSpeed) - hrp.Position).Unit
                                pcall(function() bd.Blink.item_action.charge_bow.fire(dir, 1) end)
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
    getgenv()._bdAutoBuy = false

    elements:Toggle("AutoBuy (near shop)", section, function(v)
        getgenv()._bdAutoBuy = v
        if v then
            task.spawn(function()
                while getgenv()._bdAutoBuy do
                    if _loaded then
                        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            for _, obj in CS:GetTagged("menu_opener") do
                                local npc  = obj.Parent
                                local nhrp = npc and npc:FindFirstChild("HumanoidRootPart")
                                if nhrp and (nhrp.Position - hrp.Position).Magnitude <= 12 then
                                    pcall(function()
                                        bd.Blink.player_state.bedwars_buy_item.invoke({item = "Sword", tier = 2})
                                        task.wait(0.2)
                                        bd.Blink.player_state.bedwars_buy_item.invoke({item = "Armor", tier = 2})
                                        task.wait(0.2)
                                        bd.Blink.player_state.bedwars_buy_upgrade.invoke("SwordDamage")
                                    end)
                                    break
                                end
                            end
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    end)

    -- ── NoFall ────────────────────────────────────────────────────────────────
    -- Two layers: (1) hook Blink fall damage remote to noop it server-side,
    -- (2) local AntiFall that teleports back from the void.
    getgenv()._bdNoFall = false
    local _nofallOrig
    local _nofallLastSafe = nil

    elements:Toggle("NoFall", section, function(v)
        getgenv()._bdNoFall = v
        if v and _loaded then
            pcall(function()
                _nofallOrig = hookfunction(bd.Blink.player_state.take_fall_damage.fire,
                    function(...)
                        if getgenv()._bdNoFall then return end
                        return _nofallOrig(...)
                    end)
            end)
        elseif _nofallOrig then
            pcall(function() hookfunction(bd.Blink.player_state.take_fall_damage.fire, _nofallOrig) end)
            _nofallOrig = nil
        end
    end)

    RunSvc.Heartbeat:Connect(function()
        if not getgenv()._bdNoFall then return end
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

    -- ── Scaffold ──────────────────────────────────────────────────────────────
    -- Places a block below the player each step while they're in the air.
    -- Detects blocks in backpack by the Bedwars "Blocks" CollectionService tag.
    getgenv()._bdScaffold = false
    local _scaffoldLast = Vector3.zero
    local _scaffoldDelay = 0

    elements:Toggle("Scaffold", section, function(v) getgenv()._bdScaffold = v end)

    RunSvc.Heartbeat:Connect(function()
        if not getgenv()._bdScaffold or not _loaded or tick() < _scaffoldDelay then return end
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end

        -- Only scaffold while moving through air or near an edge
        local blockTool
        for _, item in player.Backpack:GetChildren() do
            if CS:HasTag(item, "Blocks") or item.Name:lower():find("block")
                    or item.Name:lower():find("wool") or item.Name:lower():find("plank") then
                blockTool = item; break
            end
        end
        if not blockTool then return end

        -- Snap to grid and place below feet
        local pos = Vector3.new(
            math.round(hrp.Position.X),
            math.round(hrp.Position.Y - 3),
            math.round(hrp.Position.Z))
        if (pos - _scaffoldLast).Magnitude < 1.5 then return end
        _scaffoldLast = pos
        _scaffoldDelay = tick() + 0.15

        pcall(function()
            bd.Blink.item_action.place_block.invoke({
                position   = pos,
                block_type = blockTool.Name,
                extra      = {},
            })
        end)
    end)

    -- ── BedDefender ───────────────────────────────────────────────────────────
    -- Detects when an enemy gets within range of the local team's bed and
    -- places blocks around it using Blink place_block.
    getgenv()._bdBedDefender = false
    local _bedDefRange = 8
    local _bedPart     = nil

    local function _findLocalBed()
        local myTeam = player.Team
        for _, obj in workspace:GetDescendants() do
            if obj:IsA("BasePart") and obj.Name:lower():find("bed") then
                if myTeam and obj.Color == myTeam.TeamColor.Color then return obj end
                -- Fallback: closest bed to spawn
                if not myTeam then return obj end
            end
        end
        return nil
    end

    elements:Toggle("BedDefender", section, function(v)
        getgenv()._bdBedDefender = v
        if v then _bedPart = _findLocalBed() end
    end)
    elements:Slider("Bed Defend Range", section, 4, 20, 8, function(v) _bedDefRange = v end)

    RunSvc.Heartbeat:Connect(function()
        if not getgenv()._bdBedDefender or not _loaded then return end
        if not _bedPart or not _bedPart.Parent then _bedPart = _findLocalBed() end
        if not _bedPart then return end

        for _, p in Players:GetPlayers() do
            if not isEnemy(p) then continue end
            local eh = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if eh and (eh.Position - _bedPart.Position).Magnitude < _bedDefRange then
                -- Place a ring of blocks around the bed
                for dx = -2, 2, 2 do
                    for dz = -2, 2, 2 do
                        for dy = 0, 2 do
                            local pos = _bedPart.Position + Vector3.new(dx, dy, dz)
                            pos = Vector3.new(math.round(pos.X), math.round(pos.Y), math.round(pos.Z))
                            pcall(function()
                                bd.Blink.item_action.place_block.invoke({
                                    position   = pos,
                                    block_type = "OakPlanks",
                                    extra      = {},
                                })
                            end)
                        end
                    end
                end
            end
        end
    end)

    -- ── ChestFarm ─────────────────────────────────────────────────────────────
    -- Automatically opens all chests within range using the Blink chest remote.
    getgenv()._bdChestFarm = false
    local _chestRange = 20

    elements:Toggle("ChestFarm", section, function(v)
        getgenv()._bdChestFarm = v
        if v then
            task.spawn(function()
                while getgenv()._bdChestFarm do
                    if _loaded then
                        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            for _, obj in workspace:GetDescendants() do
                                if obj:IsA("BasePart") or obj:IsA("Model") then
                                    local nameLower = obj.Name:lower()
                                    if nameLower:find("chest") and not nameLower:find("chestplate") then
                                        local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")) or obj
                                        if part and (part.Position - hrp.Position).Magnitude < _chestRange then
                                            pcall(function()
                                                bd.Blink.item_action.open_chest.fire({chest_id = obj:GetFullName()})
                                            end)
                                        end
                                    end
                                end
                            end
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    end)
    elements:Slider("Chest Range", section, 5, 50, 20, function(v) _chestRange = v end)

    -- ── AutoArmor ─────────────────────────────────────────────────────────────
    -- Scans the backpack for armor items and equips them via Blink on respawn.
    getgenv()._bdAutoArmor = false
    local _armorSlots = {"helmet", "chestplate", "leggings", "boots"}

    local function _tryEquipArmor()
        if not _loaded then return end
        for _, item in player.Backpack:GetChildren() do
            local nameLower = item.Name:lower()
            for _, slot in _armorSlots do
                if nameLower:find(slot) then
                    pcall(function()
                        bd.Blink.player_state.equip_item.invoke({
                            slot = slot,
                            item = item.Name,
                        })
                    end)
                    break
                end
            end
        end
    end

    elements:Toggle("AutoArmor", section, function(v)
        getgenv()._bdAutoArmor = v
        if v then _tryEquipArmor() end
    end)

    player.CharacterAdded:Connect(function()
        task.wait(1)
        if getgenv()._bdAutoArmor then _tryEquipArmor() end
    end)

    -- ── ESP ───────────────────────────────────────────────────────────────────
    -- Shows enemies with name, health bar, and distance via BillboardGui.
    -- Colors by the enemy's team color; always uses AlwaysOnTop so walls don't hide it.
    getgenv()._bdESP = false
    local _espBills = {}

    local function _makeESP(p)
        if not isEnemy(p) then return end
        local function attach()
            local char = p.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local bb = Instance.new("BillboardGui")
            bb.Name = "_bdESP"
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

            local healthLbl = Instance.new("TextLabel", bb)
            healthLbl.Size = UDim2.new(1, 0, 0.45, 0)
            healthLbl.Position = UDim2.new(0, 0, 0.55, 0)
            healthLbl.BackgroundTransparency = 1
            healthLbl.Font = Enum.Font.Gotham
            healthLbl.TextSize = 11
            healthLbl.TextStrokeTransparency = 0
            healthLbl.TextColor3 = Color3.fromRGB(200, 200, 200)

            _espBills[p] = {bb = bb, nameLbl = nameLbl, healthLbl = healthLbl, hrp = hrp}
        end

        attach()
        p.CharacterAdded:Connect(function()
            task.wait(0.5)
            if _espBills[p] then _espBills[p].bb:Destroy(); _espBills[p] = nil end
            if getgenv()._bdESP then attach() end
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
                local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
                local dist = myHRP and math.floor((data.hrp.Position - myHRP.Position).Magnitude) or 0
                data.nameLbl.TextColor3 = p.Team and p.Team.TeamColor.Color or Color3.fromRGB(255, 80, 80)
                data.nameLbl.Text = p.Name
                data.healthLbl.Text = hum and string.format("HP: %d  [%dm]", math.floor(hum.Health), dist) or ""
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
        getgenv()._bdESP = v
        if v then _startESP() else _stopESP() end
    end)

    -- ── Unload ────────────────────────────────────────────────────────────────
    section.AncestorRemoving:Connect(function()
        getgenv()._bdKillaura    = false
        getgenv()._bdReach       = false
        getgenv()._bdAutoClick   = false
        getgenv()._bdTriggerbot  = false
        getgenv()._bdVelocity    = false
        getgenv()._bdCrits       = false
        getgenv()._bdHitboxes    = false
        getgenv()._bdProjAim     = false
        getgenv()._bdProjAura    = false
        getgenv()._bdAutoBuy     = false
        getgenv()._bdNoFall      = false
        getgenv()._bdScaffold    = false
        getgenv()._bdBedDefender = false
        getgenv()._bdChestFarm   = false
        getgenv()._bdAutoArmor   = false
        getgenv()._bdESP         = false

        if _velOrig and _velConn then pcall(hookfunction, _velConn.Function, _velOrig) end
        if _critsOrig and _loaded then
            pcall(function() hookfunction(bd.Blink.item_action.attack_entity.fire, _critsOrig) end)
        end
        if _paOld and _loaded then
            pcall(function() hookfunction(debug.getupvalue(bd.BowClient.Start, 11), _paOld) end)
        end
        if _nofallOrig and _loaded then
            pcall(function() hookfunction(bd.Blink.player_state.take_fall_damage.fire, _nofallOrig) end)
        end
        if _reachOrig ~= nil and _loaded then
            pcall(function() rawset(bd.CombatConsts, "REACH_IN_STUDS", _reachOrig) end)
        end
        for _, p in Players:GetPlayers() do _clearHB(p) end
        _stopESP()
    end)
end

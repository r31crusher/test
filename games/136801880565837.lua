-- Flick (PlaceId 136801880565837)
-- Silent aim: RS.ModuleScripts.GunModules.BulletHandler.Fire(data)
-- Targets: all workspace Models with Humanoids (players + AI)
-- ESP: AI-only box/health/chams/names (players covered by universal)

return function(section)
    local elements = getgenv()._astroElements
    local Players  = game:GetService("Players")
    local RS       = game:GetService("ReplicatedStorage")
    local RunSvc   = game:GetService("RunService")
    local UIS      = game:GetService("UserInputService")
    local Debris   = game:GetService("Debris")
    local player   = Players.LocalPlayer
    local camera   = workspace.CurrentCamera

    -- ── Settings ──────────────────────────────────────────────────────────────
    local cfg = {
        sa_enabled  = false,
        sa_hitpart  = "Head",
        sa_hitchance= 100,
        sa_vischeck = true,
        fov_enabled = false,
        fov_radius  = 150,
        snap_enabled= false,
        tracers     = false,
        pred_base   = 0.12,
        pred_scale  = 0.0001,
        tgt_color   = Color3.fromRGB(255, 0, 0),
        tracer_img  = "rbxassetid://3517446796",
        tracer_col  = Color3.fromRGB(255, 255, 255),
        tracer_w    = 0.5,
        tracer_dur  = 1,

        rage_enabled = false,
        rage_cps     = 15,
        rage_vischeck= true,

        esp_enabled  = false,
        lod_enabled  = true,
        lod_dist     = 150,
        max_dist     = 2500,
        box_enabled  = true,
        box_type     = "Corner",    -- "Full" or "Corner"
        box_fill     = true,
        health_enabled = true,
        names_enabled  = true,
        dist_enabled   = true,
        chams_enabled  = true,
        chams_transp   = 0.6,
        esp_color      = Color3.fromRGB(255, 255, 255),
    }

    -- ── Helpers ────────────────────────────────────────────────────────────────
    local function isPlayerChar(model)
        if model == player.Character then return true end
        for _, p in Players:GetPlayers() do
            if p.Character == model then return true end
        end
        return false
    end

    local function isVisible(part)
        local myChar = player.Character
        local myHead = myChar and myChar:FindFirstChild("Head")
        local origin = myHead and myHead.Position or camera.CFrame.Position
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = { myChar, camera }
        params.FilterType = Enum.RaycastFilterType.Blacklist
        local result = workspace:Raycast(origin, part.Position - origin, params)
        if result then return result.Instance:IsDescendantOf(part.Parent) end
        return true
    end

    -- ── Velocity DB (all workspace humanoid models) ───────────────────────────
    local _velDB = {}   -- key = HumanoidRootPart instance

    RunSvc.Heartbeat:Connect(function()
        for _, model in workspace:GetChildren() do
            if not model:IsA("Model") or model == player.Character then continue end
            local root = model:FindFirstChild("HumanoidRootPart")
            if root then
                local now  = tick()
                local prev = _velDB[root]
                if prev then
                    local dt = now - prev.t
                    if dt > 0 then
                        _velDB[root] = { vel=(root.Position - prev.pos)/dt, pos=root.Position, t=now }
                    end
                else
                    _velDB[root] = { vel=Vector3.zero, pos=root.Position, t=now }
                end
            end
        end
    end)

    -- ── Target finder (players + AI) ──────────────────────────────────────────
    local function getClosestTarget(fovOverride)
        local radius   = fovOverride or cfg.fov_radius
        local mousePos = UIS:GetMouseLocation()
        local best, bestDist = nil, radius

        for _, model in workspace:GetChildren() do
            if not model:IsA("Model") or model == player.Character then continue end
            local hum  = model:FindFirstChildOfClass("Humanoid")
            local part = model:FindFirstChild(cfg.sa_hitpart) or model:FindFirstChild("HumanoidRootPart")
            if not (hum and part and hum.Health > 0) then continue end
            local sp, onScreen = camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local d = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                if d < bestDist and (not cfg.sa_vischeck or isVisible(part)) then
                    bestDist = d; best = part
                end
            end
        end
        return best
    end

    local function getAimPos(origin, part)
        local root = part.Parent and part.Parent:FindFirstChild("HumanoidRootPart")
        local vel  = root and _velDB[root] and _velDB[root].vel or Vector3.zero
        local dist = (origin - part.Position).Magnitude
        return part.Position + vel * (cfg.pred_base + dist * cfg.pred_scale)
    end

    -- ── Tracer helper ─────────────────────────────────────────────────────────
    local function spawnTracer(origin, endPos)
        local a0 = Instance.new("Attachment"); a0.Position = origin; a0.Parent = workspace.Terrain
        local a1 = Instance.new("Attachment"); a1.Position = endPos;  a1.Parent = workspace.Terrain
        local b  = Instance.new("Beam")
        b.Texture=cfg.tracer_img; b.Color=ColorSequence.new(cfg.tracer_col)
        b.FaceCamera=true; b.Width0=cfg.tracer_w; b.Width1=cfg.tracer_w
        b.LightEmission=1; b.LightInfluence=0; b.Attachment0=a0; b.Attachment1=a1; b.Parent=workspace.Terrain
        Debris:AddItem(a0, cfg.tracer_dur); Debris:AddItem(a1, cfg.tracer_dur); Debris:AddItem(b, cfg.tracer_dur)
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
        if not ok or not bh then warn("[Flick] BulletHandler not found") return end

        _bhOld = hookfunction(bh.Fire, function(data)
            local myHead = player.Character and player.Character:FindFirstChild("Head")
            if myHead then data.Origin = myHead.Position end
            local origin    = data.Origin or camera.CFrame.Position
            local direction = data.Direction

            if cfg.sa_enabled and math.random(1, 100) <= cfg.sa_hitchance then
                local tgt = getClosestTarget()
                if tgt and tgt.Parent then
                    direction = (getAimPos(origin, tgt) - origin).Unit
                    data.Direction = direction
                end
            end

            if cfg.tracers then
                local tgt    = getClosestTarget()
                local endPos = origin + direction * 300
                if tgt and cfg.sa_enabled then
                    endPos = getAimPos(origin, tgt)
                end
                spawnTracer(origin, endPos)
            end

            return _bhOld(data)
        end)
    end)

    -- ── Drawing factory ───────────────────────────────────────────────────────
    local _globalDraws = {}
    local function newDraw(kind, props)
        local d = Drawing.new(kind)
        for k, v in pairs(props) do d[k] = v end
        _globalDraws[#_globalDraws + 1] = d
        return d
    end

    -- FOV + snap (not ESP, no per-model cleanup needed)
    local fovOutline = newDraw("Circle", {Visible=false,Filled=false,Color=Color3.new(0,0,0),Thickness=3,NumSides=60})
    local fovMain    = newDraw("Circle", {Visible=false,Filled=false,Color=Color3.fromRGB(255,255,255),Thickness=1,NumSides=60})
    local snapLine   = newDraw("Line",   {Visible=false,Color=Color3.fromRGB(255,255,255),Thickness=1,Transparency=1})

    -- ── AI ESP database (keyed by Model) ──────────────────────────────────────
    local esp_db = {}

    local function initESP(model)
        if esp_db[model] then return end
        local function d(kind, props)
            local dr = Drawing.new(kind)
            for k, v in pairs(props) do dr[k] = v end
            return dr
        end
        local o = { Drawings={}, Chams={}, Character=model, LastPosition=nil, LastTick=0, Velocity=Vector3.zero }
        local dr = o.Drawings
        dr.BoxOutline = d("Square",{Visible=false,Thickness=3,Color=Color3.new(0,0,0),Filled=false})
        dr.Box        = d("Square",{Visible=false,Thickness=1,Filled=false})
        dr.Fill       = d("Square",{Visible=false,Filled=true,Transparency=0.75})
        for i = 1, 8 do dr["C"..i] = d("Line",{Visible=false,Thickness=1,Color=Color3.fromRGB(255,255,255)}) end
        dr.HealthBack = d("Square",{Visible=false,Filled=true,Color=Color3.new(0,0,0)})
        dr.HealthBar  = d("Square",{Visible=false,Filled=true,Color=Color3.fromRGB(0,255,0)})
        dr.HealthText = d("Text",  {Visible=false,Center=true,Outline=true,Font=2,Size=13,Color=Color3.fromRGB(255,255,255)})
        dr.Name       = d("Text",  {Visible=false,Center=true,Outline=true,Font=2,Size=13,Color=Color3.fromRGB(255,255,255)})
        dr.Distance   = d("Text",  {Visible=false,Center=true,Outline=true,Font=2,Size=13,Color=Color3.fromRGB(200,200,200)})
        esp_db[model] = o
    end

    local function removeESP(model)
        if not esp_db[model] then return end
        for _, dr in pairs(esp_db[model].Drawings) do pcall(dr.Remove, dr) end
        for _, c  in pairs(esp_db[model].Chams)    do pcall(c.Destroy, c)  end
        esp_db[model] = nil
    end

    local function hideESP(model)
        if not esp_db[model] then return end
        for _, dr in pairs(esp_db[model].Drawings) do dr.Visible = false end
        for _, c  in pairs(esp_db[model].Chams)    do c.Visible  = false end
    end

    -- ── Triggerbot state ──────────────────────────────────────────────────────
    local _triggerCooldown = false
    local _rageNext        = 0

    -- ── Main render loop ──────────────────────────────────────────────────────
    local _renderConn = RunSvc.RenderStepped:Connect(function()
        local mousePos = UIS:GetMouseLocation()
        local tgtPart  = getClosestTarget()
        local tgtModel = tgtPart and tgtPart.Parent

        -- Triggerbot / RageBot
        if cfg.rage_enabled and tgtPart and tick() >= _rageNext then
            local ok = true
            if cfg.rage_vischeck and not isVisible(tgtPart) then ok = false end
            local char = player.Character
            if not (char and char:FindFirstChildOfClass("Tool")) then ok = false end
            if ok and not _triggerCooldown then
                _triggerCooldown = true
                _rageNext = tick() + 1 / cfg.rage_cps
                task.delay(0, function() mouse1click(); _triggerCooldown = false end)
            end
        end

        -- FOV circle
        if cfg.fov_enabled then
            local col = tgtPart and cfg.tgt_color or Color3.fromRGB(255,255,255)
            fovOutline.Visible=true; fovOutline.Position=mousePos; fovOutline.Radius=cfg.fov_radius
            fovMain.Visible=true;    fovMain.Position=mousePos;    fovMain.Radius=cfg.fov_radius; fovMain.Color=col
        else
            fovMain.Visible=false; fovOutline.Visible=false
        end

        -- Snap line
        if cfg.snap_enabled and tgtPart then
            local sp = camera:WorldToViewportPoint(tgtPart.Position)
            snapLine.Visible=true
            snapLine.From=Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y)
            snapLine.To=Vector2.new(sp.X, sp.Y)
        else
            snapLine.Visible=false
        end

        -- AI ESP
        if not cfg.esp_enabled then
            for model in pairs(esp_db) do hideESP(model) end
            return
        end

        local seen = {}
        for _, model in workspace:GetChildren() do
            if not model:IsA("Model") or isPlayerChar(model) then continue end
            local hum  = model:FindFirstChildOfClass("Humanoid")
            local root = model:FindFirstChild("HumanoidRootPart")
            if not (hum and root and hum.Health > 0) then
                if esp_db[model] then removeESP(model) end
                continue
            end
            seen[model] = true

            if esp_db[model] and esp_db[model].Character ~= model then removeESP(model) end
            initESP(model)

            local o   = esp_db[model]
            local dr  = o.Drawings

            -- Update velocity for prediction (also done in Heartbeat, but keep here for ESP accuracy)
            local now = tick()
            if o.LastPosition then
                local dt = now - o.LastTick
                if dt > 0 then o.Velocity = (root.Position - o.LastPosition) / dt end
            end
            o.LastPosition = root.Position; o.LastTick = now

            local vec, onScreen = camera:WorldToViewportPoint(root.Position)
            local dist    = (camera.CFrame.Position - root.Position).Magnitude
            local inRange = dist <= cfg.max_dist
            local isTarget= tgtModel == model
            local mainCol = isTarget and cfg.tgt_color or cfg.esp_color
            local textCol = mainCol

            if not (onScreen and inRange) then hideESP(model); continue end

            local hiDet = not cfg.lod_enabled or dist <= cfg.lod_dist
            local scale  = (1 / ((dist/3) * math.tan(math.rad(camera.FieldOfView/2)) * 2)) * 1150
            local w      = math.floor(scale * 1.3)
            local h      = math.floor(scale * 2.1)
            local bPos   = Vector2.new(math.floor(vec.X - w/2), math.floor(vec.Y - h/2))
            local bSize  = Vector2.new(w, h)

            -- Box
            if cfg.box_enabled then
                dr.BoxOutline.Visible=true; dr.BoxOutline.Position=bPos; dr.BoxOutline.Size=bSize
                local isCorner = cfg.box_type == "Corner"
                dr.Box.Visible = not isCorner; dr.Box.Position=bPos; dr.Box.Size=bSize; dr.Box.Color=mainCol
                for i=1,8 do dr["C"..i].Visible = isCorner end
                if isCorner then
                    local ll = math.floor(w/3); local x,y = bPos.X,bPos.Y
                    local function dl(l,x1,y1,x2,y2) l.Color=mainCol;l.From=Vector2.new(x1,y1);l.To=Vector2.new(x2,y2) end
                    dl(dr.C1,x,y,x+ll,y);   dl(dr.C2,x,y,x,y+ll)
                    dl(dr.C3,x+w-ll,y,x+w,y); dl(dr.C4,x+w,y,x+w,y+ll)
                    dl(dr.C5,x,y+h-ll,x,y+h); dl(dr.C6,x,y+h,x+ll,y+h)
                    dl(dr.C7,x+w,y+h-ll,x+w,y+h); dl(dr.C8,x+w-ll,y+h,x+w,y+h)
                end
                dr.Fill.Visible=cfg.box_fill; dr.Fill.Position=bPos; dr.Fill.Size=bSize; dr.Fill.Color=mainCol; dr.Fill.Transparency=0.75
            else
                dr.BoxOutline.Visible=false; dr.Box.Visible=false; dr.Fill.Visible=false
                for i=1,8 do dr["C"..i].Visible=false end
            end

            -- Health bar
            if cfg.health_enabled then
                local hp    = math.clamp(hum.Health/hum.MaxHealth, 0, 1)
                local barH  = math.floor(h * hp); local barW,off = 2,4
                local barX  = math.floor(bPos.X - off - barW)
                local barY  = math.floor(bPos.Y + (h - barH))
                local hpCol = Color3.fromRGB(255,0,0):Lerp(Color3.fromRGB(0,255,0), hp)
                dr.HealthBack.Visible=true; dr.HealthBack.Size=Vector2.new(barW+2,h+2); dr.HealthBack.Position=Vector2.new(barX-1,math.floor(bPos.Y)-1)
                dr.HealthBar.Visible=true;  dr.HealthBar.Size=Vector2.new(barW,barH);   dr.HealthBar.Position=Vector2.new(barX,barY); dr.HealthBar.Color=hpCol
                dr.HealthText.Visible= hiDet
                if hiDet then
                    dr.HealthText.Text=math.floor(hum.Health).."HP"; dr.HealthText.Color=textCol
                    dr.HealthText.Position=Vector2.new(math.floor(barX-19), math.floor(barY-(dr.HealthText.Size/2)+1))
                end
            else
                dr.HealthBack.Visible=false; dr.HealthBar.Visible=false; dr.HealthText.Visible=false
            end

            -- Name
            dr.Name.Visible=cfg.names_enabled; dr.Name.Text=model.Name; dr.Name.Color=textCol
            dr.Name.Position=Vector2.new(math.floor(bPos.X+w/2), math.floor(bPos.Y-18))

            -- Distance
            dr.Distance.Visible=cfg.dist_enabled; dr.Distance.Text=math.floor(dist).."m"; dr.Distance.Color=textCol
            dr.Distance.Position=Vector2.new(math.floor(bPos.X+w/2), math.floor(bPos.Y+h+2))

            -- Chams
            if cfg.chams_enabled then
                for _, part in model:GetChildren() do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Transparency < 1 then
                        if not o.Chams[part] then
                            local c = Instance.new("BoxHandleAdornment")
                            c.Adornee=part; c.AlwaysOnTop=true; c.ZIndex=5
                            c.Size=part.Size+Vector3.new(0.05,0.05,0.05)
                            c.Transparency=cfg.chams_transp; c.Color3=mainCol; c.Parent=part
                            o.Chams[part] = c
                        else o.Chams[part].Color3 = mainCol; o.Chams[part].Visible = true end
                    end
                end
            else
                for _, c in pairs(o.Chams) do pcall(c.Destroy, c) end; table.clear(o.Chams)
            end
        end

        -- Clean up models that left workspace
        for model in pairs(esp_db) do
            if not seen[model] then removeESP(model) end
        end
    end)

    -- ── Menu ──────────────────────────────────────────────────────────────────
    -- Silent Aim
    elements:Toggle("Silent Aim",    section, function(v) cfg.sa_enabled  = v end)
    elements:Toggle("Vis Check",     section, function(v) cfg.sa_vischeck = v end)
    elements:Toggle("FOV Circle",    section, function(v) cfg.fov_enabled = v end)
    elements:Slider("FOV Radius",    section, 10, 500, 150, function(v) cfg.fov_radius  = v end)
    elements:Toggle("Snap Line",     section, function(v) cfg.snap_enabled= v end)
    elements:Toggle("Tracers",       section, function(v) cfg.tracers     = v end)
    elements:Slider("Hit Chance %",  section, 1, 100, 100, function(v) cfg.sa_hitchance= v end)
    elements:Slider("Prediction",    section, 0,  50,  12, function(v) cfg.pred_base   = v / 100 end)
    -- RageBot
    elements:Toggle("RageBot",       section, function(v) cfg.rage_enabled  = v end)
    elements:Slider("RageBot CPS",   section, 1,  30,  15, function(v) cfg.rage_cps    = v end)
    elements:Toggle("Rage Vis Check",section, function(v) cfg.rage_vischeck = v end)
    -- AI ESP
    elements:Toggle("AI ESP",        section, function(v)
        cfg.esp_enabled = v
        if not v then for model in pairs(esp_db) do removeESP(model) end end
    end)
    elements:Toggle("Chams",         section, function(v) cfg.chams_enabled  = v end)
    elements:Toggle("Health Bar",    section, function(v) cfg.health_enabled  = v end)
    elements:Toggle("Names",         section, function(v) cfg.names_enabled   = v end)
    elements:Toggle("Distance",      section, function(v) cfg.dist_enabled    = v end)

    -- ── Unload ────────────────────────────────────────────────────────────────
    section.AncestorRemoving:Connect(function()
        cfg.sa_enabled   = false
        cfg.rage_enabled = false
        cfg.esp_enabled  = false
        cfg.fov_enabled  = false
        cfg.snap_enabled = false

        if _renderConn then _renderConn:Disconnect() end
        for _, d in pairs(_globalDraws) do pcall(d.Remove, d) end
        for model in pairs(esp_db) do removeESP(model) end

        if _bhOld then
            pcall(function()
                local bh = require(RS.ModuleScripts.GunModules.BulletHandler)
                hookfunction(bh.Fire, _bhOld)
            end)
        end
    end)
end

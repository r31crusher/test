-- Flick (PlaceId 136801880565837)
-- streSSed architecture wrapped for Astro hub
-- Targets: all workspace Models with Humanoids (players + AI)
-- AI ESP only — universal handles player ESP

return function(section)
    local elements         = getgenv()._astroElements
    local run_service      = game:GetService("RunService")
    local players          = game:GetService("Players")
    local replicated_storage = game:GetService("ReplicatedStorage")
    local debris           = game:GetService("Debris")
    local camera           = workspace.CurrentCamera
    local local_player     = players.LocalPlayer
    local user_input_service = game:GetService("UserInputService")

    -- Cleanup any previous instance of these render steps
    pcall(function() run_service:UnbindFromRenderStep("plinian_loop") end)
    pcall(function() run_service:UnbindFromRenderStep("plinian_thirdperson") end)
    pcall(function() run_service:UnbindFromRenderStep("plinian_misc") end)
    pcall(function() run_service:UnbindFromRenderStep("plinian_antiaim") end)

    -- Drawing/instance cache for cleanup
    local cache = {}
    local function new_drawing(t, props)
        local d = Drawing.new(t)
        for k, v in pairs(props) do d[k] = v end
        table.insert(cache, d)
        return d
    end
    local function track(obj) table.insert(cache, obj); return obj end

    -- ── Settings ──────────────────────────────────────────────────────────────
    local aim_settings = {
        fire_point_override = "Character",
        enabled    = false,
        hitpart    = "Head",
        hitchance  = 100,
        visible_check = true,
        triggerbot = { enabled=false, delay=0, weapon_check=true, visible_check=true },
        target_highlight = { enabled=true, color=Color3.fromRGB(255,0,0) },
        tracers    = { enabled=false, image="rbxassetid://3517446796", color=Color3.fromRGB(255,255,255), width=0.5, duration=1 },
        fov        = { radius=150, sides=60, thickness=1, target_highlight=true, target_highlight_color=Color3.fromRGB(255,0,0),
                       main    = { enabled=false, color=Color3.fromRGB(255,255,255), transparency=1 },
                       outline = { enabled=true,  color=Color3.new(0,0,0),          transparency=1 },
                       fill    = { enabled=false,  color=Color3.fromRGB(255,255,255),transparency=0.25 } },
        snapline   = { enabled=false, color=Color3.fromRGB(255,255,255), thickness=1, origin="bottom" },
        prediction = { enabled=true, adaptable=true, base_factor=0.12, scaling_per_stud=0.0001 },
    }

    local esp_settings = {
        master_switch = false,
        lod_enabled   = true,
        lod_distance  = 150,
        max_distance  = { enabled=true, limit=2500 },
        text          = { size=13, font=2 },
        box           = { enabled=true, type="Corner", color=Color3.fromRGB(255,255,255),
                          fill={ enabled=true, color=Color3.fromRGB(255,255,255), transparency=0.75 } },
        names         = { enabled=true,  color=Color3.fromRGB(255,255,255) },
        health        = { enabled=true,  low_color=Color3.fromRGB(255,0,0), high_color=Color3.fromRGB(0,255,0), text=true, text_color=Color3.fromRGB(255,255,255) },
        distance      = { enabled=true,  color=Color3.fromRGB(255,255,255) },
        chams         = { enabled=true,  color=Color3.fromRGB(255,255,255), transparency=0.6 },
    }

    local thirdperson_settings = { enabled=false, keybind=Enum.KeyCode.E, distance=8 }
    local misc_settings        = { no_animations={ enabled=false } }
    local anti_aim_settings    = { enabled=false, mode="Static", yaw_offset=180, spin_speed=5,
                                   jitter_offset=45, jitter_speed=10, sway_angle=30, sway_speed=5 }

    -- ── Tracer helper ─────────────────────────────────────────────────────────
    local function spawn_tracer(origin, end_pos)
        local a0=Instance.new("Attachment"); local a1=Instance.new("Attachment")
        a0.Position=origin; a1.Position=end_pos; a0.Parent=workspace.Terrain; a1.Parent=workspace.Terrain
        local b=Instance.new("Beam"); b.Texture=aim_settings.tracers.image; b.Color=ColorSequence.new(aim_settings.tracers.color)
        b.FaceCamera=true; b.Width0=aim_settings.tracers.width; b.Width1=aim_settings.tracers.width
        b.LightEmission=1; b.LightInfluence=0; b.Attachment0=a0; b.Attachment1=a1; b.Parent=workspace.Terrain
        track(a0); track(a1); track(b)
        debris:AddItem(a0,aim_settings.tracers.duration); debris:AddItem(a1,aim_settings.tracers.duration); debris:AddItem(b,aim_settings.tracers.duration)
    end

    -- ── Aim visuals ───────────────────────────────────────────────────────────
    local fov_fill    = new_drawing("Circle", {Visible=false,Filled=true})
    local fov_outline = new_drawing("Circle", {Visible=false,Filled=false})
    local fov_main    = new_drawing("Circle", {Visible=false,Filled=false})
    local snap_line   = new_drawing("Line",   {Visible=false})

    -- ── AI ESP database (keyed by Model) ──────────────────────────────────────
    local esp_database = {}

    local function init_esp(model)
        if esp_database[model] then return end
        local obj = { Drawings={}, Chams={}, Character=model, LastPosition=nil, LastTick=0, Velocity=Vector3.new() }
        local D = obj.Drawings
        D.BoxOutline = new_drawing("Square",{Visible=false,Thickness=3,Color=Color3.new(0,0,0),Filled=false})
        D.Box        = new_drawing("Square",{Visible=false,Thickness=1,Filled=false})
        D.Fill       = new_drawing("Square",{Visible=false,Filled=true,Transparency=esp_settings.box.fill.transparency})
        for i=1,8 do D["C"..i] = new_drawing("Line",{Visible=false,Thickness=1}) end
        D.HealthBack = new_drawing("Square",{Visible=false,Filled=true,Color=Color3.new(0,0,0)})
        D.HealthBar  = new_drawing("Square",{Visible=false,Filled=true,Color=esp_settings.health.high_color})
        D.HealthText = new_drawing("Text",  {Visible=false,Center=true,Outline=true,Font=esp_settings.text.font,Size=esp_settings.text.size,Color=esp_settings.health.text_color})
        D.Name       = new_drawing("Text",  {Visible=false,Center=true,Outline=true,Font=esp_settings.text.font,Size=esp_settings.text.size,Color=esp_settings.names.color})
        D.Distance   = new_drawing("Text",  {Visible=false,Center=true,Outline=true,Font=esp_settings.text.font,Size=esp_settings.text.size,Color=esp_settings.distance.color})
        esp_database[model] = obj
    end

    local function remove_esp(model)
        if not esp_database[model] then return end
        for _,d in pairs(esp_database[model].Drawings) do d:Remove() end
        for _,c in pairs(esp_database[model].Chams) do c:Destroy() end
        esp_database[model] = nil
    end

    -- ── Velocity DB (all workspace models — needed for SA prediction on AI) ───
    local _velDB = {}
    local _velConn = run_service.Heartbeat:Connect(function()
        for _, model in workspace:GetChildren() do
            if not model:IsA("Model") or model == local_player.Character then continue end
            local root = model:FindFirstChild("HumanoidRootPart")
            if root then
                local now  = tick()
                local prev = _velDB[root]
                if prev then
                    local dt = now - prev.t
                    if dt > 0 then _velDB[root]={ vel=(root.Position-prev.pos)/dt, pos=root.Position, t=now } end
                else _velDB[root]={ vel=Vector3.zero, pos=root.Position, t=now } end
            end
        end
    end)

    -- ── Visibility checks ─────────────────────────────────────────────────────
    local function is_visible(target_part)
        local origin=camera.CFrame.Position; local params=RaycastParams.new()
        params.FilterDescendantsInstances={local_player.Character,camera}; params.FilterType=Enum.RaycastFilterType.Blacklist
        local result=workspace:Raycast(origin,(target_part.Position-origin),params)
        if result then return result.Instance:IsDescendantOf(target_part.Parent) end; return true
    end

    local function is_visible_from_character(target_part)
        local my_char=local_player.Character; if not my_char then return false end
        local my_head=my_char:FindFirstChild("Head"); if not my_head then return false end
        local params=RaycastParams.new(); params.FilterDescendantsInstances={my_char,camera}; params.FilterType=Enum.RaycastFilterType.Blacklist
        local result=workspace:Raycast(my_head.Position,(target_part.Position-my_head.Position),params)
        if result then return result.Instance:IsDescendantOf(target_part.Parent) end; return true
    end

    -- ── Target finder: all workspace Models with Humanoids (AI + players) ─────
    local function get_closest_target()
        local closest, min_dist = nil, 9e9
        if aim_settings.fov.main.enabled then min_dist = aim_settings.fov.radius end
        local mouse_pos = user_input_service:GetMouseLocation()
        for _, model in workspace:GetChildren() do
            if not model:IsA("Model") or model == local_player.Character then continue end
            local hum         = model:FindFirstChildOfClass("Humanoid")
            local target_part = model:FindFirstChild(aim_settings.hitpart) or model:FindFirstChild("HumanoidRootPart")
            if not (hum and target_part and hum.Health > 0) then continue end
            local screen_pos, on_screen = camera:WorldToViewportPoint(target_part.Position)
            if on_screen then
                local dist = (Vector2.new(screen_pos.X, screen_pos.Y) - mouse_pos).Magnitude
                if dist < min_dist then
                    local visible = not aim_settings.visible_check or
                        (aim_settings.fire_point_override == "Character" and is_visible_from_character(target_part)) or
                        (aim_settings.fire_point_override ~= "Character" and is_visible(target_part))
                    if visible then min_dist=dist; closest=target_part end
                end
            end
        end
        return closest
    end

    local function get_velocity(part)
        local root = part.Parent and part.Parent:FindFirstChild("HumanoidRootPart")
        return root and _velDB[root] and _velDB[root].vel or Vector3.zero
    end

    local function is_player_char(model)
        if model == local_player.Character then return true end
        for _, p in players:GetPlayers() do if p.Character == model then return true end end
        return false
    end

    -- ── BulletHandler hook (silent aim) ───────────────────────────────────────
    local _bhOld
    task.spawn(function()
        local ok, bh = pcall(function()
            return require(replicated_storage:WaitForChild("ModuleScripts",15):WaitForChild("GunModules",15):WaitForChild("BulletHandler",15))
        end)
        if not ok or not bh then warn("[Flick] BulletHandler not found"); return end
        _bhOld = hookfunction(bh.Fire, function(data)
            local origin, direction = data.Origin, data.Direction
            if aim_settings.fire_point_override == "Character" then
                local my_head = local_player.Character and local_player.Character:FindFirstChild("Head")
                if my_head then data.Origin=my_head.Position; origin=my_head.Position end
            end
            if aim_settings.enabled and math.random(1,100) <= aim_settings.hitchance then
                local target = get_closest_target()
                if target and target.Parent then
                    local vel = get_velocity(target)
                    local aim_at = target.Position
                    if aim_settings.prediction.enabled then
                        local d_to_t = (origin - target.Position).Magnitude
                        local fac    = aim_settings.prediction.base_factor + (aim_settings.prediction.adaptable and d_to_t*aim_settings.prediction.scaling_per_stud or 0)
                        aim_at = target.Position + vel * fac
                    end
                    direction = (aim_at - origin).Unit; data.Direction = direction
                end
            end
            if aim_settings.tracers.enabled and origin then
                local end_pos = origin + (direction * 300)
                local target  = get_closest_target()
                if target and target.Parent and aim_settings.enabled then
                    local vel = get_velocity(target)
                    if aim_settings.prediction.enabled then
                        local d_to_t = (origin - target.Position).Magnitude
                        local fac    = aim_settings.prediction.base_factor + (aim_settings.prediction.adaptable and d_to_t*aim_settings.prediction.scaling_per_stud or 0)
                        end_pos = target.Position + vel * fac
                    else end_pos = target.Position end
                end
                spawn_tracer(origin, end_pos)
            end
            return _bhOld(data)
        end)
    end)

    -- ── Main ESP / aim loop ───────────────────────────────────────────────────
    local trigger_cooldown = false
    run_service:BindToRenderStep("plinian_loop", Enum.RenderPriority.Camera.Value + 1, function()
        local mouse_pos   = user_input_service:GetMouseLocation()
        local center      = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
        local target_part = get_closest_target()
        local target_char = target_part and target_part.Parent

        -- Triggerbot
        if aim_settings.enabled and aim_settings.triggerbot.enabled and target_part then
            local can_shoot = true
            if aim_settings.triggerbot.visible_check then
                local tv = aim_settings.fire_point_override=="Character" and is_visible_from_character(target_part) or is_visible(target_part)
                if not tv then can_shoot=false end
            end
            if aim_settings.triggerbot.weapon_check and not (local_player.Character and local_player.Character:FindFirstChildOfClass("Tool")) then can_shoot=false end
            if can_shoot and not trigger_cooldown then
                trigger_cooldown=true
                task.delay(aim_settings.triggerbot.delay, function() mouse1click(); trigger_cooldown=false end)
            end
        end

        -- FOV circle
        if aim_settings.enabled and aim_settings.fov.main.enabled then
            local main_color = (target_part and aim_settings.fov.target_highlight) and aim_settings.fov.target_highlight_color or aim_settings.fov.main.color
            if aim_settings.fov.fill.enabled then fov_fill.Visible=true;fov_fill.Position=mouse_pos;fov_fill.Radius=aim_settings.fov.radius;fov_fill.Color=aim_settings.fov.fill.color;fov_fill.Transparency=aim_settings.fov.fill.transparency;fov_fill.NumSides=aim_settings.fov.sides else fov_fill.Visible=false end
            if aim_settings.fov.outline.enabled then fov_outline.Visible=true;fov_outline.Position=mouse_pos;fov_outline.Radius=aim_settings.fov.radius;fov_outline.Color=aim_settings.fov.outline.color;fov_outline.Transparency=aim_settings.fov.outline.transparency;fov_outline.Thickness=aim_settings.fov.thickness+2;fov_outline.NumSides=aim_settings.fov.sides else fov_outline.Visible=false end
            fov_main.Visible=true;fov_main.Position=mouse_pos;fov_main.Radius=aim_settings.fov.radius;fov_main.Color=main_color;fov_main.Transparency=aim_settings.fov.main.transparency;fov_main.Thickness=aim_settings.fov.thickness;fov_main.NumSides=aim_settings.fov.sides
        else fov_fill.Visible=false;fov_outline.Visible=false;fov_main.Visible=false end

        -- Snap line
        if aim_settings.enabled and aim_settings.snapline.enabled and target_part then
            local pos = camera:WorldToViewportPoint(target_part.Position)
            snap_line.Visible=true;snap_line.Color=aim_settings.snapline.color;snap_line.Thickness=aim_settings.snapline.thickness;snap_line.Transparency=1;snap_line.To=Vector2.new(pos.X,pos.Y)
            local so=string.lower(aim_settings.snapline.origin)
            snap_line.From = so=="bottom" and Vector2.new(center.X,camera.ViewportSize.Y) or so=="center" and center or mouse_pos
        else snap_line.Visible=false end

        -- AI ESP
        if esp_settings.master_switch then
            local seen = {}
            for _, model in workspace:GetChildren() do
                if not model:IsA("Model") or is_player_char(model) then continue end
                local hum  = model:FindFirstChildOfClass("Humanoid")
                local root = model:FindFirstChild("HumanoidRootPart")
                if not (hum and root and hum.Health > 0) then if esp_database[model] then remove_esp(model) end; continue end
                seen[model] = true
                if esp_database[model] and esp_database[model].Character ~= model then remove_esp(model) end
                init_esp(model)

                local o = esp_database[model]; local d = o.Drawings
                local is_target   = (target_char == model) and aim_settings.target_highlight.enabled
                local main_color  = is_target and aim_settings.target_highlight.color or esp_settings.box.color
                local text_color  = is_target and aim_settings.target_highlight.color or esp_settings.names.color

                local now = tick()
                if o.LastPosition then local dt=now-o.LastTick; if dt>0 then o.Velocity=(root.Position-o.LastPosition)/dt end end
                o.LastPosition=root.Position; o.LastTick=now

                local vec, on_screen = camera:WorldToViewportPoint(root.Position)
                local dist    = (camera.CFrame.Position - root.Position).Magnitude
                local in_range= not esp_settings.max_distance.enabled or dist <= esp_settings.max_distance.limit

                if on_screen and in_range then
                    for _, drawing in pairs(d) do drawing.Visible=true end
                    for _, cham in pairs(o.Chams) do cham.Visible=true end

                    local scale  = (1/((dist/3)*math.tan(math.rad(camera.FieldOfView/2))*2))*1150
                    local width  = math.floor(scale*1.3); local height=math.floor(scale*2.1)
                    local box_pos= Vector2.new(math.floor(vec.X-width/2),math.floor(vec.Y-height/2))
                    local box_size=Vector2.new(width,height)
                    local is_high_detail = not esp_settings.lod_enabled or dist<=esp_settings.lod_distance

                    -- Box
                    if esp_settings.box.enabled then
                        d.BoxOutline.Position=box_pos;d.BoxOutline.Size=box_size
                        d.Box.Visible=esp_settings.box.type=="Full";d.Box.Position=box_pos;d.Box.Size=box_size;d.Box.Color=main_color
                        local ic=esp_settings.box.type=="Corner"
                        d.C1.Visible=ic;d.C2.Visible=ic;d.C3.Visible=ic;d.C4.Visible=ic;d.C5.Visible=ic;d.C6.Visible=ic;d.C7.Visible=ic;d.C8.Visible=ic
                        if ic then
                            local ll,x,y,w,h=math.floor(width/3),box_pos.X,box_pos.Y,width,height
                            local function dl(l,x1,y1,x2,y2) l.Color=main_color;l.From=Vector2.new(x1,y1);l.To=Vector2.new(x2,y2) end
                            dl(d.C1,x,y,x+ll,y);dl(d.C2,x,y,x,y+ll);dl(d.C3,x+w-ll,y,x+w,y);dl(d.C4,x+w,y,x+w,y+ll)
                            dl(d.C5,x,y+h-ll,x,y+h);dl(d.C6,x,y+h,x+ll,y+h);dl(d.C7,x+w,y+h-ll,x+w,y+h);dl(d.C8,x+w-ll,y+h,x+w,y+h)
                        end
                        d.Fill.Visible=esp_settings.box.fill.enabled;d.Fill.Position=box_pos;d.Fill.Size=box_size;d.Fill.Color=main_color;d.Fill.Transparency=esp_settings.box.fill.transparency
                    else d.BoxOutline.Visible=false;d.Box.Visible=false;d.Fill.Visible=false;for i=1,8 do d["C"..i].Visible=false end end

                    -- Name
                    d.Name.Visible=esp_settings.names.enabled;d.Name.Text=model.Name;d.Name.Color=text_color;d.Name.Position=Vector2.new(math.floor(box_pos.X+width/2),math.floor(box_pos.Y-18))

                    -- Distance
                    d.Distance.Visible=esp_settings.distance.enabled;d.Distance.Text=tostring(math.floor(dist)).."m";d.Distance.Color=text_color;d.Distance.Position=Vector2.new(math.floor(box_pos.X+width/2),math.floor(box_pos.Y+height+2))

                    -- Health bar
                    if esp_settings.health.enabled then
                        local hp=math.clamp(hum.Health/hum.MaxHealth,0,1);local bar_h,bar_w,offset=math.floor(height*hp),2,4
                        local bar_x,bar_y=math.floor(box_pos.X-offset-bar_w),math.floor(box_pos.Y+(height-bar_h))
                        local hc=esp_settings.health.low_color:Lerp(esp_settings.health.high_color,hp)
                        d.HealthBack.Size=Vector2.new(bar_w+2,height+2);d.HealthBack.Position=Vector2.new(bar_x-1,math.floor(box_pos.Y)-1)
                        d.HealthBar.Size=Vector2.new(bar_w,bar_h);d.HealthBar.Position=Vector2.new(bar_x,bar_y);d.HealthBar.Color=hc
                        if is_high_detail then d.HealthText.Visible=esp_settings.health.text;d.HealthText.Text=tostring(math.floor(hum.Health)).."HP";d.HealthText.Color=text_color;d.HealthText.Position=Vector2.new(math.floor(bar_x-19),math.floor(bar_y-(d.HealthText.Size/2)+1)) else d.HealthText.Visible=false end
                    else d.HealthBack.Visible=false;d.HealthBar.Visible=false;d.HealthText.Visible=false end

                    -- Chams
                    if esp_settings.chams.enabled then
                        for _, part in pairs(model:GetChildren()) do
                            if part:IsA("BasePart") and part.Name~="HumanoidRootPart" and part.Transparency<1 then
                                local cc=is_target and aim_settings.target_highlight.color or esp_settings.chams.color
                                if not o.Chams[part] then
                                    local c=Instance.new("BoxHandleAdornment");c.Name="Cham";c.Adornee=part;c.AlwaysOnTop=true;c.ZIndex=5
                                    c.Size=part.Size+Vector3.new(0.05,0.05,0.05);c.Transparency=esp_settings.chams.transparency;c.Color3=cc;c.Parent=part
                                    track(c);o.Chams[part]=c
                                else o.Chams[part].Color3=cc end
                            end
                        end
                    else for _,c in pairs(o.Chams) do c:Destroy() end; table.clear(o.Chams) end
                else
                    for _,drawing in pairs(esp_database[model].Drawings) do drawing.Visible=false end
                    for _,cham in pairs(esp_database[model].Chams) do cham.Visible=false end
                end
            end
            for model in pairs(esp_database) do if not seen[model] then remove_esp(model) end end
        else
            for _,p in pairs(esp_database) do for _,dr in pairs(p.Drawings) do dr.Visible=false end; for _,c in pairs(p.Chams) do c.Visible=false end end
        end
    end)

    -- ── Anti-aim ──────────────────────────────────────────────────────────────
    local last_jitter_flip, jitter_direction = 0, 1
    run_service:BindToRenderStep("plinian_antiaim", Enum.RenderPriority.Last.Value, function()
        local character=local_player.Character; local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            if anti_aim_settings.enabled then
                humanoid.AutoRotate=false; local hrp=character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local orig=camera.CFrame; local root_pos=hrp.Position; local nlc=nil
                    local _,cwy=orig:ToOrientation()
                    if anti_aim_settings.mode=="Jitter" then
                        if tick()-last_jitter_flip>1/anti_aim_settings.jitter_speed then jitter_direction=-jitter_direction;last_jitter_flip=tick() end
                        nlc=CFrame.new(root_pos)*CFrame.Angles(0,cwy+math.rad(anti_aim_settings.yaw_offset)+math.rad(anti_aim_settings.jitter_offset*jitter_direction),0)
                    elseif anti_aim_settings.mode=="Spin" then
                        nlc=CFrame.new(root_pos)*CFrame.Angles(0,math.rad((tick()*(anti_aim_settings.spin_speed*60))%360),0)
                    elseif anti_aim_settings.mode=="Sway" then
                        nlc=CFrame.new(root_pos)*CFrame.Angles(0,cwy+math.rad(anti_aim_settings.sway_angle*math.sin(tick()*anti_aim_settings.sway_speed)),0)
                    elseif anti_aim_settings.mode=="Static" then
                        nlc=CFrame.new(root_pos)*CFrame.Angles(0,cwy+math.rad(anti_aim_settings.yaw_offset),0)
                    end
                    if nlc then hrp.CFrame=CFrame.new(hrp.CFrame.Position,hrp.CFrame.Position+nlc.LookVector) end
                    camera.CFrame=orig
                end
            else if humanoid.AutoRotate==false then humanoid.AutoRotate=true end end
        end
    end)

    -- ── Third-person ──────────────────────────────────────────────────────────
    local third_person_active, yaw, pitch, calib_const = false, 0, 0, 0.03
    user_input_service.InputBegan:Connect(function(input, gp)
        if not thirdperson_settings.enabled or gp then return end
        if input.KeyCode == thirdperson_settings.keybind then
            third_person_active = not third_person_active
            user_input_service.MouseBehavior = third_person_active and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
            if not third_person_active and local_player.Character then
                camera.CameraType=Enum.CameraType.Custom; camera.CameraSubject=local_player.Character:FindFirstChildOfClass("Humanoid")
            else local p,y,_=camera.CFrame:ToEulerAnglesYXZ(); yaw=y; pitch=p end
        end
    end)
    run_service:BindToRenderStep("plinian_thirdperson", Enum.RenderPriority.Camera.Value+10, function()
        if not third_person_active or not thirdperson_settings.enabled then return end
        local character=local_player.Character; if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        local rp=character.HumanoidRootPart; camera.CameraType=Enum.CameraType.Scriptable; user_input_service.MouseBehavior=Enum.MouseBehavior.LockCenter
        for _,part in ipairs(character:GetDescendants()) do if part:IsA("BasePart") then part.LocalTransparencyModifier=0 end end
        local md=user_input_service:GetMouseDelta(); local us=user_input_service.MouseDeltaSensitivity
        yaw=yaw-(md.X*us*calib_const); pitch=math.clamp(pitch-(md.Y*us*calib_const),math.rad(-80),math.rad(80))
        local rot=CFrame.fromEulerAnglesYXZ(pitch,yaw,0); local fp=rp.Position+Vector3.new(0,1.5,0)
        local gp=fp+(rot*CFrame.new(0,0,thirdperson_settings.distance)).Position
        local rp2=RaycastParams.new(); rp2.FilterType=Enum.RaycastFilterType.Exclude; rp2.FilterDescendantsInstances={character}
        local dir=gp-fp; local res=workspace:Raycast(fp,dir,rp2)
        camera.CFrame=CFrame.new(res and fp+(dir.Unit*(res.Distance-0.3)) or gp, fp)
    end)

    -- ── Misc ──────────────────────────────────────────────────────────────────
    run_service:BindToRenderStep("plinian_misc", Enum.RenderPriority.Character.Value, function()
        local character=local_player.Character; if not character then return end
        local anim=character:FindFirstChild("Animate"); if not anim then return end
        local ds=misc_settings.no_animations.enabled; if anim.Disabled~=ds then anim.Disabled=ds end
    end)

    -- ── Menu ──────────────────────────────────────────────────────────────────
    elements:Toggle("Silent Aim",       section, function(v) aim_settings.enabled = v end)
    elements:Toggle("FOV Circle",       section, function(v) aim_settings.fov.main.enabled = v end)
    elements:Slider("FOV Radius",       section, 10, 500, 150, function(v) aim_settings.fov.radius = v end)
    elements:Toggle("Snap Line",        section, function(v) aim_settings.snapline.enabled = v end)
    elements:Toggle("Tracers",          section, function(v) aim_settings.tracers.enabled = v end)
    elements:Slider("Hit Chance %",     section, 1, 100, 100, function(v) aim_settings.hitchance = v end)
    elements:Slider("Prediction",       section, 0, 50, 12,   function(v) aim_settings.prediction.base_factor = v/100 end)
    elements:Toggle("Vis Check",        section, function(v) aim_settings.visible_check = v end)
    elements:Toggle("Triggerbot",       section, function(v) aim_settings.triggerbot.enabled = v end)
    elements:Toggle("AI ESP",           section, function(v) esp_settings.master_switch = v; if not v then for m in pairs(esp_database) do remove_esp(m) end end end)
    elements:Toggle("Chams",            section, function(v) esp_settings.chams.enabled = v end)
    elements:Toggle("Health Bar",       section, function(v) esp_settings.health.enabled = v end)
    elements:Toggle("Names",            section, function(v) esp_settings.names.enabled = v end)
    elements:Toggle("Distance",         section, function(v) esp_settings.distance.enabled = v end)
    elements:Toggle("Third Person (E)", section, function(v) thirdperson_settings.enabled = v end)
    elements:Toggle("No Animations",    section, function(v) misc_settings.no_animations.enabled = v end)
    elements:Toggle("Anti-Aim",         section, function(v) anti_aim_settings.enabled = v end)

    -- ── Unload ────────────────────────────────────────────────────────────────
    section.AncestorRemoving:Connect(function()
        aim_settings.enabled=false; aim_settings.triggerbot.enabled=false; aim_settings.fov.main.enabled=false
        aim_settings.snapline.enabled=false; esp_settings.master_switch=false; anti_aim_settings.enabled=false
        thirdperson_settings.enabled=false; misc_settings.no_animations.enabled=false

        pcall(function() run_service:UnbindFromRenderStep("plinian_loop") end)
        pcall(function() run_service:UnbindFromRenderStep("plinian_thirdperson") end)
        pcall(function() run_service:UnbindFromRenderStep("plinian_misc") end)
        pcall(function() run_service:UnbindFromRenderStep("plinian_antiaim") end)
        pcall(function()
            if local_player.Character and local_player.Character:FindFirstChild("Humanoid") then
                local_player.Character.Humanoid.AutoRotate=true
            end
            camera.CameraType=Enum.CameraType.Custom
            camera.CameraSubject=local_player.Character and local_player.Character:FindFirstChildOfClass("Humanoid")
            user_input_service.MouseBehavior=Enum.MouseBehavior.Default
        end)

        _velConn:Disconnect()
        for model in pairs(esp_database) do remove_esp(model) end
        for _, v in pairs(cache) do
            if v.Remove then pcall(v.Remove, v) elseif v.Destroy then pcall(v.Destroy, v) end
        end
        if _bhOld then
            pcall(function()
                local bh = require(replicated_storage.ModuleScripts.GunModules.BulletHandler)
                hookfunction(bh.Fire, _bhOld)
            end)
        end
    end)
end

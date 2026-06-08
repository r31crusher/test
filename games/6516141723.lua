-- Doors (PlaceId 6516141723)
-- Reference: Abysall hub (bocaj111004/Abysall)
-- Remotes live in ReplicatedStorage (found via FindFirstChild scan)
-- Damage events: Screech, ShadeResult (Halt), A90, SurgeRemote

return function(section)
    local elements  = getgenv()._astroElements
    local Players   = game:GetService("Players")
    local RS        = game:GetService("ReplicatedStorage")
    local RunSvc    = game:GetService("RunService")
    local player    = Players.LocalPlayer

    -- ── Find remotes folder ───────────────────────────────────────────────────
    -- Doors stores remotes directly in ReplicatedStorage; folder name varies by
    -- floor so we scan for the child that owns "EBF" or "Screech".
    local RemotesFolder
    do
        local candidates = { "Remotes", "GameRemotes", "Events" }
        for _, name in candidates do
            local f = RS:FindFirstChild(name)
            if f then RemotesFolder = f; break end
        end
        if not RemotesFolder then
            -- fallback: search RS children for one that has a known remote
            for _, child in RS:GetChildren() do
                if child:FindFirstChild("EBF") or child:FindFirstChild("Screech") then
                    RemotesFolder = child; break
                end
            end
        end
        if not RemotesFolder then RemotesFolder = RS end
    end

    local conns  = {}
    local loops  = {}
    local fakeEvents = {}

    local function addConn(c) table.insert(conns, c) end
    local function stopLoop(key)
        if loops[key] then task.cancel(loops[key]); loops[key] = nil end
    end

    -- ── Fake remote helper ────────────────────────────────────────────────────
    -- Swaps real RemoteEvent with a dummy so server packets are silently dropped.
    local function swapFake(name, enable)
        if not fakeEvents[name] then
            local real = RemotesFolder:FindFirstChild(name)
            if not real then return end
            fakeEvents[name] = {
                real  = real,
                dummy = Instance.new("RemoteEvent"),
            }
            fakeEvents[name].dummy.Name = name
        end
        local entry = fakeEvents[name]
        if enable then
            entry.real.Parent  = nil
            entry.dummy.Parent = RemotesFolder
        else
            entry.dummy.Parent = nil
            entry.real.Parent  = RemotesFolder
        end
    end

    local function restoreAll()
        for name, entry in pairs(fakeEvents) do
            entry.dummy.Parent = nil
            entry.real.Parent  = RemotesFolder
        end
    end

    -- ── Entity helpers ────────────────────────────────────────────────────────
    -- Danger entities that roam the halls
    local DANGER_NAMES = {
        RushMoving = true, AmbushMoving = true, BlitzMoving = true,
        Rush = true, Ambush = true, Blitz = true,
        Seek = true, Figure = true,
    }

    local function getNearestDanger()
        local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then return nil, math.huge end
        local best, bestDist = nil, math.huge
        for _, obj in workspace:GetChildren() do
            if DANGER_NAMES[obj.Name] and obj.PrimaryPart then
                local d = (obj.PrimaryPart.Position - myHRP.Position).Magnitude
                if d < bestDist then best, bestDist = obj, d end
            end
        end
        return best, bestDist
    end

    -- ── Entity ESP ────────────────────────────────────────────────────────────
    getgenv()._doors_entityesp = false
    local espBills = {}

    local ENTITY_COLOR = {
        Rush       = Color3.fromRGB(255, 80,  80),
        RushMoving = Color3.fromRGB(255, 80,  80),
        Ambush     = Color3.fromRGB(255, 140, 0),
        AmbushMoving = Color3.fromRGB(255, 140, 0),
        Blitz      = Color3.fromRGB(255, 200, 0),
        BlitzMoving = Color3.fromRGB(255, 200, 0),
        Seek       = Color3.fromRGB(180, 0,   255),
        Figure     = Color3.fromRGB(255, 0,   0),
        Eyes       = Color3.fromRGB(255, 255, 100),
        Screech    = Color3.fromRGB(200, 80,  255),
    }
    local TRACKED_ENTITIES = {
        "Rush","RushMoving","Ambush","AmbushMoving","Blitz","BlitzMoving",
        "Seek","Figure","Eyes","Screech","Halt","Dupe","Hide","Timothy","Snare","Glitch",
    }
    local ENTITY_SET = {}
    for _, n in TRACKED_ENTITIES do ENTITY_SET[n] = true end

    local _espRender

    local function buildESP()
        -- scan workspace for current entities
        for _, obj in workspace:GetChildren() do
            if ENTITY_SET[obj.Name] and not espBills[obj] then
                local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    local bb = Instance.new("BillboardGui")
                    bb.Name           = "_doorsESP"
                    bb.Size           = UDim2.new(0, 120, 0, 36)
                    bb.StudsOffset    = Vector3.new(0, 4, 0)
                    bb.AlwaysOnTop    = true
                    bb.Adornee        = part
                    bb.Parent         = game.CoreGui
                    local lbl = Instance.new("TextLabel", bb)
                    lbl.Size                  = UDim2.new(1, 0, 1, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.Font                  = Enum.Font.GothamBold
                    lbl.TextSize              = 13
                    lbl.TextColor3            = ENTITY_COLOR[obj.Name] or Color3.fromRGB(255,255,255)
                    lbl.TextStrokeTransparency = 0
                    lbl.Text                  = obj.Name
                    espBills[obj] = { bb = bb, lbl = lbl, part = part }
                end
            end
        end
        -- remove stale entries
        for obj, data in pairs(espBills) do
            if not obj.Parent then
                data.bb:Destroy()
                espBills[obj] = nil
            end
        end
    end

    local function startEntityESP()
        buildESP()
        -- watch for new entities
        addConn(workspace.ChildAdded:Connect(function(child)
            if not getgenv()._doors_entityesp then return end
            if ENTITY_SET[child.Name] then
                task.wait(0.1)
                buildESP()
            end
        end))
        addConn(workspace.ChildRemoved:Connect(function(child)
            if espBills[child] then
                espBills[child].bb:Destroy()
                espBills[child] = nil
            end
        end))
        _espRender = RunSvc.RenderStepped:Connect(function()
            if not getgenv()._doors_entityesp then return end
            local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            for obj, data in pairs(espBills) do
                if not obj.Parent then
                    data.bb:Destroy()
                    espBills[obj] = nil
                elseif data.part and data.part.Parent then
                    local dist = myHRP and math.floor((data.part.Position - myHRP.Position).Magnitude) or 0
                    data.lbl.Text = string.format("%s  [%dm]", obj.Name, dist)
                end
            end
        end)
    end

    local function stopEntityESP()
        if _espRender then _espRender:Disconnect(); _espRender = nil end
        for _, data in pairs(espBills) do data.bb:Destroy() end
        table.clear(espBills)
    end

    elements:Toggle("Entity ESP", section, function(v)
        getgenv()._doors_entityesp = v
        if v then startEntityESP() else stopEntityESP() end
    end)

    -- ── No Damage ─────────────────────────────────────────────────────────────
    -- Block server→client damage packets by replacing real RemoteEvents with dummies.
    getgenv()._doors_nodmg = false

    local DAMAGE_REMOTES = { "Screech", "ShadeResult", "A90", "SurgeRemote" }

    elements:Toggle("No Damage (Screech/Halt/A90/Surge)", section, function(v)
        getgenv()._doors_nodmg = v
        for _, name in DAMAGE_REMOTES do
            swapFake(name, v)
        end
    end)

    -- ── Auto Closet ───────────────────────────────────────────────────────────
    -- When Rush/Ambush/Blitz is within threshold, fire the nearest closet prompt.
    getgenv()._doors_autocloset = false
    local CLOSET_DIST = 60  -- studs; entity must be closer than this to trigger

    local function findNearestClosetPrompt()
        local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then return nil end
        local best, bestDist = nil, math.huge
        for _, obj in workspace:GetDescendants() do
            if obj:IsA("ProximityPrompt") and (
                obj.ActionText:lower():find("hide") or
                obj.Parent.Name:lower():find("wardrobe") or
                obj.Parent.Name:lower():find("closet") or
                obj.Parent.Name:lower():find("locker")
            ) then
                local part = obj.Parent:IsA("BasePart") and obj.Parent
                          or obj.Parent:FindFirstChildWhichIsA("BasePart")
                if part then
                    local d = (part.Position - myHRP.Position).Magnitude
                    if d < bestDist then best, bestDist = obj, d end
                end
            end
        end
        return best
    end

    local _closetLoop
    local function startCloset()
        _closetLoop = task.spawn(function()
            while getgenv()._doors_autocloset do
                local _, dist = getNearestDanger()
                if dist < CLOSET_DIST then
                    local prompt = findNearestClosetPrompt()
                    if prompt then
                        fireproximityprompt(prompt)
                    end
                end
                task.wait(0.25)
            end
        end)
    end

    elements:Toggle("Auto Closet", section, function(v)
        getgenv()._doors_autocloset = v
        if v then startCloset() end
    end)

    -- ── Prompt Tweaks ─────────────────────────────────────────────────────────
    getgenv()._doors_promptreach   = 1
    getgenv()._doors_instantprompt = false
    getgenv()._doors_promptclip    = false

    local promptOriginals = {} -- [prompt] = { maxDist, holdDur, los }

    local function cachePrompt(p)
        if not promptOriginals[p] then
            promptOriginals[p] = {
                maxDist = p.MaxActivationDistance,
                holdDur = p.HoldDuration,
                los     = p.RequiresLineOfSight,
            }
        end
    end

    local function applyPromptSettings(p)
        cachePrompt(p)
        local orig = promptOriginals[p]
        p.MaxActivationDistance = orig.maxDist * getgenv()._doors_promptreach
        p.HoldDuration          = getgenv()._doors_instantprompt and 0 or orig.holdDur
        p.RequiresLineOfSight   = getgenv()._doors_promptclip and false or orig.los
    end

    local function applyAllPrompts()
        for _, obj in workspace:GetDescendants() do
            if obj:IsA("ProximityPrompt") then applyPromptSettings(obj) end
        end
    end

    local function restoreAllPrompts()
        for p, orig in pairs(promptOriginals) do
            if p and p.Parent then
                p.MaxActivationDistance = orig.maxDist
                p.HoldDuration          = orig.holdDur
                p.RequiresLineOfSight   = orig.los
            end
        end
        table.clear(promptOriginals)
    end

    -- Watch for new prompts
    addConn(workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("ProximityPrompt") then
            task.wait(0.05)
            applyPromptSettings(obj)
        end
    end))

    elements:Slider("Prompt Reach", section, 1, 10, 1, function(v)
        getgenv()._doors_promptreach = v
        applyAllPrompts()
    end)

    elements:Toggle("Instant Prompts", section, function(v)
        getgenv()._doors_instantprompt = v
        applyAllPrompts()
    end)

    elements:Toggle("No Prompt LoS", section, function(v)
        getgenv()._doors_promptclip = v
        applyAllPrompts()
    end)

    -- ── Auto Breaker Box ──────────────────────────────────────────────────────
    -- Fires EBF remote to solve the breaker box minigame instantly.
    elements:Button("Auto Breaker Box", section, function()
        local ebf = RemotesFolder:FindFirstChild("EBF")
        if ebf then
            ebf:FireServer()
        end
    end)

    -- ── Speed ─────────────────────────────────────────────────────────────────
    getgenv()._doors_speed = false
    local _speedConn

    local function applySpeed(multiplier)
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16 * multiplier
        end
    end

    elements:Toggle("Speed Boost", section, function(v)
        getgenv()._doors_speed = v
        if v then
            applySpeed(2)
            _speedConn = player.CharacterAdded:Connect(function()
                task.wait(1)
                if getgenv()._doors_speed then applySpeed(2) end
            end)
        else
            applySpeed(1)
            if _speedConn then _speedConn:Disconnect(); _speedConn = nil end
        end
    end)

    -- ── Remove Seek / Figure ──────────────────────────────────────────────────
    -- Deletes the model from workspace (client-side only; they respawn server-side).
    elements:Button("Remove Entities (client)", section, function()
        for _, obj in workspace:GetChildren() do
            if ENTITY_SET[obj.Name] then
                obj:Destroy()
            end
        end
    end)

    -- ── Revive ────────────────────────────────────────────────────────────────
    elements:Button("Revive Self", section, function()
        local rev = RemotesFolder:FindFirstChild("Revive")
        if rev then rev:FireServer() end
    end)

    -- ── Unload ────────────────────────────────────────────────────────────────
    section.AncestorRemoving:Connect(function()
        getgenv()._doors_entityesp   = false
        getgenv()._doors_nodmg       = false
        getgenv()._doors_autocloset  = false
        getgenv()._doors_instantprompt = false
        getgenv()._doors_promptclip  = false
        getgenv()._doors_speed       = false
        getgenv()._doors_promptreach = 1

        stopEntityESP()
        restoreAll()
        restoreAllPrompts()

        if _closetLoop then task.cancel(_closetLoop); _closetLoop = nil end
        if _speedConn  then _speedConn:Disconnect();  _speedConn  = nil end
        applySpeed(1)

        for _, c in ipairs(conns) do c:Disconnect() end
        table.clear(conns)
    end)
end

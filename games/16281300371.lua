-- Blade Ball (PlaceId 16281300371 | Training: 15234596844)

return function(section)
    local elements  = getgenv()._astroElements
    local Players   = game:GetService("Players")
    local RS        = game:GetService("ReplicatedStorage")
    local RunSvc    = game:GetService("RunService")
    local player    = Players.LocalPlayer

    local VIM         = game:GetService("VirtualInputManager")
    local BallsFolder = workspace:WaitForChild("Balls")

    if typeof(PluginManager) ~= "nil" then
        getgenv().PluginManager = function() error("not in studio") end
    end

    local function resolveBlockKey()
        local ok, Replion = pcall(require, RS.Packages:WaitForChild("Replion"))
        if not ok then return Enum.KeyCode.F end
        local ok2, data = pcall(function() return Replion.Client:WaitReplion("Data") end)
        if not ok2 or not data then return Enum.KeyCode.F end
        local binds = data:Get({ "Settings", "Keybinds", "Block" })
        local bind1 = binds and binds.PC and binds.PC.Bind1
        if not bind1 or bind1 == "" then return Enum.KeyCode.F end
        return Enum.KeyCode[bind1] or Enum.KeyCode.F
    end

    local BLOCK_KEY = resolveBlockKey()

    local _autoParry  = false
    local PARRY_DIST  = 35
    local PARRY_DELAY = 0
    local PARRY_HIT   = 100

    local function pressBlockKey()
        VIM:SendKeyEvent(true,  BLOCK_KEY, false, game)
        task.delay(0.07, function()
            VIM:SendKeyEvent(false, BLOCK_KEY, false, game)
        end)
    end

    local function fireParry()
        pressBlockKey()
    end

    local function doParry()
        if math.random(1, 100) > PARRY_HIT then return end
        if PARRY_DELAY > 0 then
            task.delay(PARRY_DELAY / 1000, fireParry)
        else
            fireParry()
        end
    end

    local _ballTrackers  = {}
    local _ballAttrConns = {}
    local _addedConn     = nil
    local _removedConn   = nil

    local function stopTracker(ball)
        if _ballTrackers[ball] then
            _ballTrackers[ball]:Disconnect()
            _ballTrackers[ball] = nil
        end
    end

    local function startTracker(ball)
        stopTracker(ball)
        _ballTrackers[ball] = RunSvc.Heartbeat:Connect(function()
            if not _autoParry then return end
            if ball:GetAttribute("target") ~= player.Name then
                stopTracker(ball)
                return
            end
            local char = player.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            if char.Parent ~= workspace.Alive then return end
            local ok, pos = pcall(function() return ball.Position end)
            if not ok then stopTracker(ball) return end
            if (pos - hrp.Position).Magnitude <= PARRY_DIST then
                stopTracker(ball)
                doParry()
            end
        end)
    end

    local function watchBall(ball)
        if not ball or not ball.Parent then return end
        if ball:GetAttribute("realBall") == false then return end

        local function tryStart()
            if not ball or not ball.Parent then return end
            if ball:GetAttribute("realBall") == false then return end
            if ball:GetAttribute("target") == player.Name then
                startTracker(ball)
            end
        end

        -- connect signal first so we never miss a target change
        _ballAttrConns[ball] = ball:GetAttributeChangedSignal("target"):Connect(function()
            if not _autoParry then return end
            if ball:GetAttribute("realBall") == false then return end
            if ball:GetAttribute("target") == player.Name then
                startTracker(ball)
            else
                stopTracker(ball)
            end
        end)

        -- check immediately in case attributes already set
        tryStart()
        -- deferred check as fallback if attributes hadn't replicated yet
        task.defer(tryStart)
    end

    local function unwatchBall(ball)
        stopTracker(ball)
        if _ballAttrConns[ball] then
            _ballAttrConns[ball]:Disconnect()
            _ballAttrConns[ball] = nil
        end
    end

    local function startAutoParry()
        for _, ball in BallsFolder:GetChildren() do watchBall(ball) end
        _addedConn   = BallsFolder.ChildAdded:Connect(watchBall)
        _removedConn = BallsFolder.ChildRemoved:Connect(unwatchBall)
    end

    local function stopAutoParry()
        if _addedConn   then _addedConn:Disconnect();   _addedConn   = nil end
        if _removedConn then _removedConn:Disconnect(); _removedConn = nil end
        for ball in table.clone(_ballAttrConns) do unwatchBall(ball) end
    end

    local _espHighlights = {}
    local _espAdded      = nil
    local _espRemoved    = nil

    local COLOR_TARGET = Color3.fromRGB(255, 50,  50)
    local COLOR_OTHER  = Color3.fromRGB(255, 255, 255)

    local function addHighlight(ball)
        if _espHighlights[ball] then return end
        local hl = Instance.new("Highlight")
        hl.FillTransparency    = 1
        hl.OutlineTransparency = 0
        hl.OutlineColor = ball:GetAttribute("target") == player.Name
            and COLOR_TARGET or COLOR_OTHER
        hl.Parent = ball
        _espHighlights[ball] = hl
        ball:GetAttributeChangedSignal("target"):Connect(function()
            if _espHighlights[ball] then
                _espHighlights[ball].OutlineColor = ball:GetAttribute("target") == player.Name
                    and COLOR_TARGET or COLOR_OTHER
            end
        end)
    end

    local function removeHighlight(ball)
        local hl = _espHighlights[ball]
        if hl then hl:Destroy(); _espHighlights[ball] = nil end
    end

    local function startESP()
        for _, ball in BallsFolder:GetChildren() do
            addHighlight(ball)
        end
        _espAdded   = BallsFolder.ChildAdded:Connect(function(ball)
            task.defer(function()
                if ball and ball.Parent then addHighlight(ball) end
            end)
        end)
        _espRemoved = BallsFolder.ChildRemoved:Connect(removeHighlight)
    end

    local function stopESP()
        if _espAdded   then _espAdded:Disconnect();   _espAdded   = nil end
        if _espRemoved then _espRemoved:Disconnect(); _espRemoved = nil end
        for ball, hl in _espHighlights do hl:Destroy() end
        table.clear(_espHighlights)
    end

    elements:Toggle("Auto Parry", section, function(state)
        _autoParry = state
        if state then startAutoParry() else stopAutoParry() end
    end)

    elements:Slider("Parry Distance (studs)", section, 10, 50, PARRY_DIST, function(val)
        PARRY_DIST = val
    end)

    elements:Slider("Parry Delay (ms)", section, 0, 300, PARRY_DELAY, function(val)
        PARRY_DELAY = val
    end)

    elements:Slider("Parry Hit Chance (%)", section, 1, 100, PARRY_HIT, function(val)
        PARRY_HIT = val
    end)

    elements:Toggle("Ball ESP", section, function(state)
        if state then startESP() else stopESP() end
    end)
end

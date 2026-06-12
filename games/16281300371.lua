-- Blade Ball (PlaceId 16281300371 | Training: 15234596844)

return function(section)
    local elements  = getgenv()._astroElements
    local Players   = game:GetService("Players")
    local RS        = game:GetService("ReplicatedStorage")
    local RunSvc    = game:GetService("RunService")
    local player    = Players.LocalPlayer

    local VIM         = game:GetService("VirtualInputManager")
    local BallsFolder = workspace:WaitForChild("Balls")

    -- Neutralise the PluginManager executor-detection check inside u67
    if typeof(PluginManager) ~= "nil" then
        getgenv().PluginManager = function() error("not in studio") end
    end

    -- Read the player's Block keybind from Replion (Settings.Keybinds.Block.PC.Bind1).
    -- Falls back to the game default "F" if the data isn't ready or isn't a KeyCode.
    local function resolveBlockKey()
        local ok, Replion = pcall(require, RS.Packages:WaitForChild("Replion"))
        if not ok then return Enum.KeyCode.F end

        local ok2, data = pcall(function()
            return Replion.Client:WaitReplion("Data")
        end)
        if not ok2 or not data then return Enum.KeyCode.F end

        local binds = data:Get({ "Settings", "Keybinds", "Block" })
        local bind1 = binds and binds.PC and binds.PC.Bind1
        if not bind1 or bind1 == "" then return Enum.KeyCode.F end

        return Enum.KeyCode[bind1] or Enum.KeyCode.F
    end

    local BLOCK_KEY = resolveBlockKey()

    -- ── Auto Parry ────────────────────────────────────────────────────────────

    local _autoParry = false
    local PARRY_DIST  = 35
    local PARRY_DELAY = 0    -- ms, added before firing
    local PARRY_HIT   = 100  -- % chance to actually fire

    local function pressBlockKey()
        VIM:SendKeyEvent(true,  BLOCK_KEY, false, game)
        task.delay(0.07, function()
            VIM:SendKeyEvent(false, BLOCK_KEY, false, game)
        end)
    end

    local _heartbeat

    local function startAutoParry()
        if _heartbeat then return end
        _heartbeat = RunSvc.Heartbeat:Connect(function()
            if not _autoParry then return end

            local char = player.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            if char.Parent ~= workspace.Alive then return end

            for _, ball in BallsFolder:GetChildren() do
                if ball:GetAttribute("realBall") == false then continue end
                if ball:GetAttribute("target") ~= player.Name then continue end

                local ok, ballPos = pcall(function() return ball.Position end)
                if not ok then continue end

                if (ballPos - hrp.Position).Magnitude <= PARRY_DIST then
                    if math.random(1, 100) <= PARRY_HIT then
                        if PARRY_DELAY > 0 then
                            task.delay(PARRY_DELAY / 1000, pressBlockKey)
                        else
                            pressBlockKey()
                        end
                    end
                    break
                end
            end
        end)
    end

    local function stopAutoParry()
        if _heartbeat then
            _heartbeat:Disconnect()
            _heartbeat = nil
        end
    end

    -- ── Ball ESP ──────────────────────────────────────────────────────────────

    local _espEnabled  = false
    local _espHighlights = {}  -- ball → Highlight

    local COLOR_TARGET = Color3.fromRGB(255, 50,  50)   -- red   = heading at you
    local COLOR_OTHER  = Color3.fromRGB(255, 255, 255)  -- white = targeting someone else

    local function addHighlight(ball)
        if _espHighlights[ball] then return end
        local hl = Instance.new("Highlight")
        hl.FillTransparency    = 1
        hl.OutlineTransparency = 0
        hl.OutlineColor = ball:GetAttribute("target") == player.Name
            and COLOR_TARGET or COLOR_OTHER
        hl.Parent = ball
        _espHighlights[ball] = hl

        -- keep colour updated as the target attribute changes
        ball:GetAttributeChangedSignal("target"):Connect(function()
            if _espHighlights[ball] then
                _espHighlights[ball].OutlineColor = ball:GetAttribute("target") == player.Name
                    and COLOR_TARGET or COLOR_OTHER
            end
        end)
    end

    local function removeHighlight(ball)
        local hl = _espHighlights[ball]
        if hl then
            hl:Destroy()
            _espHighlights[ball] = nil
        end
    end

    local _espAdded   = nil
    local _espRemoved = nil

    local function startESP()
        for _, ball in BallsFolder:GetChildren() do
            if ball:GetAttribute("realBall") ~= false then
                addHighlight(ball)
            end
        end
        _espAdded = BallsFolder.ChildAdded:Connect(function(ball)
            if ball:GetAttribute("realBall") ~= false then
                addHighlight(ball)
            end
        end)
        _espRemoved = BallsFolder.ChildRemoved:Connect(removeHighlight)
    end

    local function stopESP()
        if _espAdded   then _espAdded:Disconnect();   _espAdded   = nil end
        if _espRemoved then _espRemoved:Disconnect(); _espRemoved = nil end
        for ball, hl in _espHighlights do
            hl:Destroy()
        end
        table.clear(_espHighlights)
    end

    -- ── UI ────────────────────────────────────────────────────────────────────
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
        _espEnabled = state
        if state then startESP() else stopESP() end
    end)
end

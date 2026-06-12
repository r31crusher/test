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

    local BLOCK_KEY  = resolveBlockKey()

    -- ── Auto Parry ────────────────────────────────────────────────────────────

    local _autoParry = false
    local _lastParry = 0
    local COOLDOWN   = 0.3
    local PARRY_DIST = 35

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

            local now = os.clock()
            if now - _lastParry < COOLDOWN then return end

            for _, ball in BallsFolder:GetChildren() do
                if ball:GetAttribute("realBall") == false then continue end
                if ball:GetAttribute("target") ~= player.Name then continue end

                local ok, ballPos = pcall(function() return ball.Position end)
                if not ok then continue end

                if (ballPos - hrp.Position).Magnitude <= PARRY_DIST then
                    _lastParry = now
                    pressBlockKey()
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

    -- ── UI ────────────────────────────────────────────────────────────────────
    elements:Toggle("Auto Parry", section, function(state)
        _autoParry = state
        if state then
            startAutoParry()
        else
            stopAutoParry()
        end
    end)

    elements:Slider("Parry Distance (studs)", section, 10, 50, PARRY_DIST, function(val)
        PARRY_DIST = val
    end)
end

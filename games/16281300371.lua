-- Blade Ball (PlaceId 16281300371 | Training: 15234596844)

return function(section)
    local elements  = getgenv()._astroElements
    local Players   = game:GetService("Players")
    local RS        = game:GetService("ReplicatedStorage")
    local RunSvc    = game:GetService("RunService")
    local CS        = game:GetService("CollectionService")
    local player    = Players.LocalPlayer

    local Remotes      = RS:WaitForChild("Remotes")
    local ParryAttempt = Remotes:WaitForChild("ParryAttempt")

    -- workspace.TrainingBalls is a lobby-mode folder inside the main game.
    -- The separate training server (15234596844) is a full game server that
    -- uses workspace.Balls just like the main server.
    local BallsFolder = workspace:WaitForChild("Balls")

    -- ── Neutralise the executor-detection check inside the game's parry fn ────
    -- SwordsController.u67 calls PluginManager():CreatePlugin():Deactivate()
    -- inside an xpcall. In a normal game this errors (caught silently). In an
    -- executor PluginManager may succeed, behaving differently and flagging BAC.
    -- Override it to always error so the xpcall path is identical to a normal client.
    if typeof(PluginManager) ~= "nil" then
        getgenv().PluginManager = function()
            error("not in studio")
        end
    end

    -- ── Auto Parry ────────────────────────────────────────────────────────────
    local _autoParry = false
    local _lastParry = 0
    local COOLDOWN   = 0.4
    local PARRY_DIST = 12

    local _heartbeat

    local function doParry()
        local btns = CS:GetTagged("BlockButton")
        if btns[1] then
            firesignal(btns[1].Activated)
        end
    end

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
                    doParry()
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

    elements:Slider("Parry Distance (studs)", section, 5, 25, PARRY_DIST, function(val)
        PARRY_DIST = val
    end)
end

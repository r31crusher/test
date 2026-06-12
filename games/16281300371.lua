-- Blade Ball (PlaceId 16281300371)

return function(section)
    local elements  = getgenv()._astroElements
    local Players   = game:GetService("Players")
    local RS        = game:GetService("ReplicatedStorage")
    local RunSvc    = game:GetService("RunService")
    local player    = Players.LocalPlayer

    local Remotes       = RS:WaitForChild("Remotes")
    local ParryAttempt  = Remotes:WaitForChild("ParryAttempt")
    local ParrySuccess  = Remotes:WaitForChild("ParrySuccess")

    -- ── Auto Parry ────────────────────────────────────────────────────────────
    -- Each ball in workspace.Balls has a "target" string attribute (player name).
    -- We fire ParryAttempt:FireServer() once the ball targets us and is within
    -- range. Distance is generous (default 80 studs) to beat network latency on
    -- a fast-moving ball. The server validates proximity and cooldown server-side.

    local _autoParry = false
    local _lastParry = 0
    local _parryCount = 0
    local COOLDOWN   = 0.3   -- min gap between attempts (server enforces its own)
    local PARRY_DIST = 80    -- studs; fire this far out to beat latency

    local _heartbeat

    local function startAutoParry()
        if _heartbeat then return end
        _heartbeat = RunSvc.Heartbeat:Connect(function()
            if not _autoParry then return end

            local char = player.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            -- accept both workspace.Alive and workspace.Dead (training mode)
            local parent = char.Parent
            if parent ~= workspace.Alive and parent ~= workspace:FindFirstChild("Dead") then return end

            local now = os.clock()
            if now - _lastParry < COOLDOWN then return end

            for _, ball in workspace.Balls:GetChildren() do
                -- skip visual clones the client creates (realBall == false)
                if ball:GetAttribute("realBall") == false then continue end

                if ball:GetAttribute("target") == player.Name then
                    local ok, pos = pcall(function() return ball.Position end)
                    if not ok then continue end

                    local dist = (pos - hrp.Position).Magnitude
                    if dist <= PARRY_DIST then
                        _lastParry = now
                        _parryCount += 1
                        ParryAttempt:FireServer()
                        break
                    end
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

    -- confirm server accepted parries
    local _successCount = 0
    local _successConn = ParrySuccess.OnClientEvent:Connect(function()
        if _autoParry then
            _successCount += 1
        end
    end)

    -- ── UI ────────────────────────────────────────────────────────────────────
    elements:Toggle("Auto Parry", section, function(state)
        _autoParry = state
        if state then
            _parryCount  = 0
            _successCount = 0
            startAutoParry()
        else
            stopAutoParry()
        end
    end)

    elements:Slider("Parry Distance (studs)", section, 10, 150, PARRY_DIST, function(val)
        PARRY_DIST = val
    end)

    -- debug button so you can confirm it's alive
    elements:Button("Print Parry Stats", section, function()
        print(("[BladeBall] attempts=%d  server_accepts=%d"):format(_parryCount, _successCount))
    end)
end

-- Blade Ball (PlaceId 16281300371)

return function(section)
    local elements  = getgenv()._astroElements
    local Players   = game:GetService("Players")
    local RS        = game:GetService("ReplicatedStorage")
    local RunSvc    = game:GetService("RunService")
    local player    = Players.LocalPlayer

    local Remotes      = RS:WaitForChild("Remotes")
    local ParryAttempt = Remotes:WaitForChild("ParryAttempt")

    -- ── Auto Parry ────────────────────────────────────────────────────────────
    -- Balls targeting the local player live in workspace.Balls.
    -- Each ball has a "target" attribute (player name string).
    -- Firing ParryAttempt:FireServer() is all the server needs; it validates
    -- range server-side, so we just need to fire when the ball is close.
    -- Cooldown mirrors the server-side parry window (~1.5s).

    local _autoParry  = false
    local _lastParry  = 0
    local COOLDOWN    = 1.5   -- seconds between parry attempts
    local PARRY_DIST  = 25    -- stud distance threshold to trigger parry

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

            for _, ball in workspace.Balls:GetChildren() do
                if ball:GetAttribute("target") == player.Name then
                    local dist = (ball.Position - hrp.Position).Magnitude
                    if dist <= PARRY_DIST then
                        _lastParry = now
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

    -- ── UI ────────────────────────────────────────────────────────────────────
    elements:Toggle("Auto Parry", section, function(state)
        _autoParry = state
        if state then
            startAutoParry()
        else
            stopAutoParry()
        end
    end)

    local distSlider = elements:Slider("Parry Distance", section, 5, 60, PARRY_DIST, function(val)
        PARRY_DIST = val
    end)

    local coolSlider = elements:Slider("Parry Cooldown (s x10)", section, 5, 30, COOLDOWN * 10, function(val)
        COOLDOWN = val / 10
    end)
end

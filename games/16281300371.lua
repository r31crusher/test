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
    -- PRY (the obfuscated anti-cheat VM) stores the server validation hash in
    -- _G.BAC_HASH on load. We fire ParryAttempt with that hash directly —
    -- no __namecall hooks (BAC detects those), no firesignal on GUI elements
    -- (triggers PluginManager check inside the game's parry function).

    local _autoParry = false
    local _lastParry = 0
    local COOLDOWN   = 0.4
    local PARRY_DIST = 15

    local _heartbeat

    local function doParry()
        local hash = _G.BAC_HASH
        if hash then
            ParryAttempt:FireServer(hash)
        else
            ParryAttempt:FireServer()
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

            for _, ball in workspace.Balls:GetChildren() do
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

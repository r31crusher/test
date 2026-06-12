-- Blade Ball (PlaceId 16281300371)

return function(section)
    local elements  = getgenv()._astroElements
    local Players   = game:GetService("Players")
    local RS        = game:GetService("ReplicatedStorage")
    local RunSvc    = game:GetService("RunService")
    local CS        = game:GetService("CollectionService")
    local player    = Players.LocalPlayer

    local Remotes      = RS:WaitForChild("Remotes")
    local ParrySuccess = Remotes:WaitForChild("ParrySuccess")

    -- ── Auto Parry ────────────────────────────────────────────────────────────
    -- ParryAttempt:FireServer() with no args is rejected by the server.
    -- The PRY module (obfuscated VM) sends a BAC_HASH and camera/player data
    -- that the server validates. The in-game BlockButton GUI uses the same PRY
    -- path (SwordsController u90 → PRY). We trigger it via firesignal so the
    -- game's own code fires the remote with proper args.

    local _autoParry  = false
    local _lastParry  = 0
    local _parryCount = 0
    local _successCount = 0
    local COOLDOWN    = 0.35   -- seconds between trigger calls
    local PARRY_DIST  = 13     -- studs; close enough to pass server range check

    local _heartbeat

    local function doParry()
        -- use the game's own BlockButton so PRY runs with correct hash/args
        local btns = CS:GetTagged("BlockButton")
        if btns[1] then
            firesignal(btns[1].Activated)
            _parryCount += 1
            return true
        end
        return false
    end

    local function startAutoParry()
        if _heartbeat then return end
        _heartbeat = RunSvc.Heartbeat:Connect(function()
            if not _autoParry then return end

            local char = player.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

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

    local _successConn = ParrySuccess.OnClientEvent:Connect(function()
        if _autoParry then _successCount += 1 end
    end)

    -- ── UI ────────────────────────────────────────────────────────────────────
    elements:Toggle("Auto Parry", section, function(state)
        _autoParry = state
        if state then
            _parryCount   = 0
            _successCount = 0
            startAutoParry()
        else
            stopAutoParry()
        end
    end)

    elements:Slider("Parry Distance (studs)", section, 5, 30, PARRY_DIST, function(val)
        PARRY_DIST = val
    end)

    elements:Button("Print Parry Stats", section, function()
        print(("[BladeBall] BlockButton found: %s | attempts: %d | accepts: %d"):format(
            tostring(CS:GetTagged("BlockButton")[1] ~= nil),
            _parryCount, _successCount
        ))
    end)
end

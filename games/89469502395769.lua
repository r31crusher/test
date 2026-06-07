-- Brainrot Kick Simulator (PlaceId 89469502395769)

return function(section)
    local elements = getgenv()._astroElements
    local player   = game:GetService("Players").LocalPlayer
    local RS       = game:GetService("ReplicatedStorage")

    local Network        = RS:WaitForChild("Shared"):WaitForChild("Packages"):WaitForChild("Network")
    local revKickEvent   = Network:WaitForChild("rev_KickEvent")
    local revKickCollect = Network:WaitForChild("rev_KickCollect")
    local revKickEnded   = Network:WaitForChild("rev_KickEventEnded")
    local revBUpgrade    = Network:WaitForChild("rev_B_Upgrade")
    local revRebirth     = Network:WaitForChild("rev_RebirthRequest")
    local refSellAll     = Network:WaitForChild("ref_B_SellAll")

    local rng = Random.new()

    local function j(base, jitter)
        jitter = jitter or 0.25
        return base * (1 + (rng:NextNumber() * 2 - 1) * jitter)
    end

    local function getHRP()
        local char = player.Character
        return char and char:FindFirstChild("HumanoidRootPart")
    end

    local function getMyPlot()
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return end
        for _, plot in ipairs(plots:GetChildren()) do
            if plot:GetAttribute("Owner") == player.Name then
                return plot
            end
        end
    end

-- ── Thread tracking — all task.spawn calls register here so unload can
    -- cancel them immediately rather than waiting for flags to be checked. ──────
    local _threads = {}
    local function spawn(fn)
        local t = task.spawn(fn)
        table.insert(_threads, t)
        return t
    end

    -- ── Round-end tracking ─────────────────────────────────────────────────────
    local _kickRoundActive = false
    local _kickEndedConn = revKickEnded.OnClientEvent:Connect(function()
        _kickRoundActive = false
    end)

    local function waitForRoundEnd(timeout)
        local deadline = tick() + (timeout or 25)
        while _kickRoundActive and tick() < deadline do
            task.wait(0.25)
        end
    end

    -- ── Auto Collect ──────────────────────────────────────────────────────────────
    getgenv()._brk_collect = false
    elements:Toggle("Auto Collect", section, function(v)
        getgenv()._brk_collect = v
        if v then
            spawn(function()
                while getgenv()._brk_collect do
                    local hrp  = getHRP()
                    local plot = getMyPlot()
                    if hrp and plot then
                        local buttons = plot:FindFirstChild("Buttons")
                        if buttons then
                            for _, slot in ipairs(buttons:GetChildren()) do
                                if not getgenv()._brk_collect then break end
                                if slot:IsA("BasePart") and slot.Name:match("^Slot%d+$") then
                                    pcall(firetouchinterest, slot, hrp, 0)
                                    task.wait(0.05)
                                    pcall(firetouchinterest, slot, hrp, 1)
                                    task.wait(j(0.45, 0.2))
                                end
                            end
                        end
                    end
                    task.wait(j(1.5, 0.3))
                end
            end)
        end
    end)

    -- ── Auto Sell ─────────────────────────────────────────────────────────────────
    getgenv()._brk_sell = false
    elements:Toggle("Auto Sell", section, function(v)
        getgenv()._brk_sell = v
        if v then
            spawn(function()
                while getgenv()._brk_sell do
                    pcall(function() refSellAll:InvokeServer() end)
                    task.wait(j(4, 0.3))
                end
            end)
        end
    end)

    -- ── Auto Kick ─────────────────────────────────────────────────────────────────
    -- Uses Humanoid:MoveTo for all navigation — no hard CFrame assignment, so
    -- the anti-cheat's teleport/speed checks never fire.
    -- Timeline:
    --   1. Walk to KickReady zone
    --   2. Fire KickEvent — OnStartKick anchors character
    --   3. Poll hrp.Anchored until false (GameHandler line 667, tsunami spawn)
    --   4. Walk to CollectZone; game's own v130 PreRender fires KickCollect on arrival
    -- MoveTo has a built-in 8s timeout; we retry every 7s so the character
    -- keeps heading toward the target until it arrives or the deadline passes.
    local function walkTo(target, timeoutSecs, speed)
        local char = player.Character
        local hum  = char and char:FindFirstChild("Humanoid")
        if not hum or not getHRP() then return end
        local prev = hum.WalkSpeed
        if speed then hum.WalkSpeed = speed end
        local deadline = tick() + (timeoutSecs or 20)
        while tick() < deadline do
            hum:MoveTo(target.Position)
            local done = false
            local conn = hum.MoveToFinished:Connect(function(reached)
                done = true
                if reached then deadline = 0 end  -- arrived — exit outer loop too
            end)
            local inner = tick() + 7  -- re-issue before Roblox's 8s timeout
            while not done and tick() < inner and tick() < deadline do
                task.wait(0.1)
            end
            conn:Disconnect()
            if deadline == 0 then break end
        end
        if speed then hum.WalkSpeed = prev end
    end

    getgenv()._brk_kick = false
    elements:Toggle("Auto Kick", section, function(v)
        getgenv()._brk_kick = v
        if v then
            spawn(function()
                local kickArea    = workspace:WaitForChild("Areas"):WaitForChild("KickReady")
                local collectZone = workspace:WaitForChild("Zones"):WaitForChild("CollectZone")

                while getgenv()._brk_kick do
                    if _kickRoundActive
                        or player:GetAttribute("RoundDebounce")
                        or player:GetAttribute("KickDebounced") then
                        task.wait(1)
                        continue
                    end

                    if not getHRP() then task.wait(2) continue end

                    -- Walk into kick zone (legitimate movement, not a CFrame jump)
                    walkTo(kickArea, 15)
                    task.wait(j(0.6, 0.2))

                    if player:GetAttribute("RoundDebounce") or player:GetAttribute("KickDebounced") then
                        task.wait(1)
                        continue
                    end

                    -- Perfect kick every time (scale=1 is max timing accuracy)
                    local scale = 1
                    _kickRoundActive = true
                    pcall(function() revKickEvent:FireServer(scale, 1) end)

                    -- Wait for OnStartKick to unanchor (GameHandler line 667, ~4-5s after fire)
                    local hrp = getHRP()
                    local unanchorDeadline = tick() + 12
                    while hrp and hrp.Parent and hrp.Anchored and tick() < unanchorDeadline do
                        task.wait(0.1)
                        hrp = getHRP()
                    end

                    -- Character is free — sprint to collect zone and spam KickCollect
                    -- in parallel (game fires it every PreRender frame when in zone;
                    -- we do the same so we don't miss the window).
                    if getHRP() and not getHRP().Anchored then
                        local collectSpam = spawn(function()
                            while _kickRoundActive do
                                pcall(function() revKickCollect:FireServer() end)
                                task.wait(0.05)
                            end
                        end)
                        walkTo(collectZone, 15, 80)
                        -- stop the spam once we've arrived and the round ends naturally
                    end

                    waitForRoundEnd(25)
                    task.wait(j(2, 0.25))
                end
            end)
        end
    end)

    -- ── Auto Upgrade ─────────────────────────────────────────────────────────────
    getgenv()._brk_upgrade = false
    elements:Toggle("Auto Upgrade", section, function(v)
        getgenv()._brk_upgrade = v
        if v then
            spawn(function()
                while getgenv()._brk_upgrade do
                    local plot = getMyPlot()
                    if plot then
                        local buttons = plot:FindFirstChild("Buttons")
                        if buttons then
                            for _, slot in ipairs(buttons:GetChildren()) do
                                if not getgenv()._brk_upgrade then break end
                                local slotId = tonumber(slot.Name:gsub("Slot", ""))
                                if slotId then
                                    pcall(function() revBUpgrade:FireServer(slotId) end)
                                    task.wait(j(0.35, 0.3))
                                end
                            end
                        end
                    end
                    task.wait(j(5, 0.25))
                end
            end)
        end
    end)

    -- ── Auto Lift ─────────────────────────────────────────────────────────────────
    getgenv()._brk_lift = false
    elements:Toggle("Auto Lift", section, function(v)
        getgenv()._brk_lift = v
        if v then
            spawn(function()
                while getgenv()._brk_lift do
                    local char = player.Character
                    local hum  = char and char:FindFirstChild("Humanoid")
                    if hum then
                        local inKick = player:GetAttribute("RoundDebounce") or player:GetAttribute("KickDebounced")
                        if not inKick then
                            local equipped = char:FindFirstChildOfClass("Tool")
                            if not (equipped and equipped:HasTag("SquatTool")) then
                                for _, t in ipairs(player.Backpack:GetChildren()) do
                                    if t:IsA("Tool") and t:HasTag("SquatTool") then
                                        hum:EquipTool(t)
                                        break
                                    end
                                end
                            end
                        end
                    end
                    task.wait(j(1.5, 0.35))
                end
            end)
        end
    end)

    -- ── Auto Rebirth ──────────────────────────────────────────────────────────────
    getgenv()._brk_rebirth = false
    elements:Toggle("Auto Rebirth", section, function(v)
        getgenv()._brk_rebirth = v
        if v then
            spawn(function()
                while getgenv()._brk_rebirth do
                    pcall(function() revRebirth:FireServer() end)
                    task.wait(j(12, 0.2))
                end
            end)
        end
    end)

    -- ── Unload ────────────────────────────────────────────────────────────────────
    section.AncestorRemoving:Connect(function()
        -- Stop all flags so loops exit on their next check
        getgenv()._brk_collect = false
        getgenv()._brk_sell    = false
        getgenv()._brk_kick    = false
        getgenv()._brk_upgrade = false
        getgenv()._brk_lift    = false
        getgenv()._brk_rebirth = false

        -- Cancel every tracked thread immediately (catches threads blocked in
        -- waitForRoundEnd or long task.wait calls that haven't checked the flag)
        for _, t in ipairs(_threads) do
            pcall(task.cancel, t)
        end
        table.clear(_threads)

        -- Disconnect the persistent remote connection
        _kickEndedConn:Disconnect()

        -- Unequip squat tool so lifting stops right away
        local char = player.Character
        local hum  = char and char:FindFirstChild("Humanoid")
        if hum then pcall(function() hum:UnequipTools() end) end
    end)
end

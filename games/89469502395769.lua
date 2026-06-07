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

    local function teleportInto(hrp, part)
        local sz = part.Size
        local ox = (rng:NextNumber() * 2 - 1) * math.min(sz.X * 0.3, 3)
        local oz = (rng:NextNumber() * 2 - 1) * math.min(sz.Z * 0.3, 3)
        hrp.CFrame = part.CFrame * CFrame.new(ox, 3, oz)
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
    -- Timeline:
    --   1. Teleport into KickReady zone, wait for server position check to settle
    --   2. Fire KickEvent — server fires back → OnStartKick anchors character
    --   3. Poll hrp.Anchored until it goes false (GameHandler line 667, ~4-5s)
    --   4. Character is now free; teleport to CollectZone and fire KickCollect
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

                    local hrp = getHRP()
                    if not hrp then task.wait(2) continue end

                    -- Move into kick zone and let the server-side position check settle
                    teleportInto(hrp, kickArea)
                    task.wait(j(2, 0.2))

                    if player:GetAttribute("RoundDebounce") or player:GetAttribute("KickDebounced") then
                        task.wait(1)
                        continue
                    end

                    -- Fire with randomised power; percent=1 is normal (player left it at MAX)
                    local scale = 0.65 + rng:NextNumber() * 0.35
                    _kickRoundActive = true
                    pcall(function() revKickEvent:FireServer(scale, 1) end)

                    -- Wait for OnStartKick to unanchor the character (line 667 of GameHandler).
                    -- The server anchors on receipt, runs the animation (~3.5s of task.waits),
                    -- then unanchors right before the tsunami spawns. Only move after that.
                    hrp = getHRP()
                    local unanchorDeadline = tick() + 12
                    while hrp and hrp.Parent and hrp.Anchored and tick() < unanchorDeadline do
                        task.wait(0.1)
                        hrp = getHRP()
                    end

                    -- Character is now free — run to collect zone and claim the brainrots
                    hrp = getHRP()
                    if hrp and not hrp.Anchored then
                        teleportInto(hrp, collectZone)
                        task.wait(j(0.5, 0.2))
                        pcall(function() revKickCollect:FireServer() end)
                    end

                    waitForRoundEnd(25)
                    task.wait(j(2.5, 0.25))
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

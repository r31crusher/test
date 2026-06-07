-- Brainrot Kick Simulator (PlaceId 89469502395769)

return function(section)
    local elements = getgenv()._astroElements
    local player   = game:GetService("Players").LocalPlayer
    local RS       = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")

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

    -- Drop player into a zone part with a small random XZ spread
    local function teleportInto(hrp, part)
        local sz = part.Size
        local ox = (rng:NextNumber() * 2 - 1) * math.min(sz.X * 0.3, 3)
        local oz = (rng:NextNumber() * 2 - 1) * math.min(sz.Z * 0.3, 3)
        hrp.CFrame = part.CFrame * CFrame.new(ox, 3, oz)
    end

    -- Wait for KickEventEnded with a safety timeout (returns true if it fired)
    local _kickRoundActive = false
    revKickEnded.OnClientEvent:Connect(function()
        _kickRoundActive = false
    end)

    local function waitForRoundEnd(timeout)
        timeout = timeout or 25
        local deadline = tick() + timeout
        while _kickRoundActive and tick() < deadline do
            task.wait(0.25)
        end
    end

    -- ── Auto Collect ──────────────────────────────────────────────────────────────
    getgenv()._brk_collect = false
    elements:Toggle("Auto Collect", section, function(v)
        getgenv()._brk_collect = v
        if v then
            task.spawn(function()
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
            task.spawn(function()
                while getgenv()._brk_sell do
                    pcall(function() refSellAll:InvokeServer() end)
                    task.wait(j(4, 0.3))
                end
            end)
        end
    end)

    -- ── Auto Kick ─────────────────────────────────────────────────────────────────
    -- Full round-aware cycle:
    --   1. Teleport into kick zone, wait for server to register position (~2s)
    --   2. Fire kick with random scale
    --   3. Wait for tsunami window (~4s), then move to CollectZone & fire KickCollect
    --   4. Wait for KickEventEnded before starting the next round (prevents double-fire)
    getgenv()._brk_kick = false
    elements:Toggle("Auto Kick", section, function(v)
        getgenv()._brk_kick = v
        if v then
            task.spawn(function()
                local kickArea    = workspace:WaitForChild("Areas"):WaitForChild("KickReady")
                local collectZone = workspace:WaitForChild("Zones"):WaitForChild("CollectZone")

                while getgenv()._brk_kick do
                    -- Skip if still in an active round or debounced
                    if _kickRoundActive
                        or player:GetAttribute("RoundDebounce")
                        or player:GetAttribute("KickDebounced") then
                        task.wait(1)
                        continue
                    end

                    local hrp = getHRP()
                    if not hrp then task.wait(2) continue end

                    -- Step 1: enter kick zone, let server-side position check settle
                    teleportInto(hrp, kickArea)
                    task.wait(j(2, 0.2))

                    -- Double-check debounces after the wait
                    if player:GetAttribute("RoundDebounce") or player:GetAttribute("KickDebounced") then
                        task.wait(1)
                        continue
                    end

                    -- Step 2: kick with varied power (0.65–1.0)
                    local scale = 0.65 + rng:NextNumber() * 0.35
                    _kickRoundActive = true
                    pcall(function() revKickEvent:FireServer(scale, 1) end)

                    -- Step 3: wait for the tsunami to start (~4s into the animation),
                    -- then be in the CollectZone when it arrives
                    task.wait(j(4, 0.15))

                    hrp = getHRP()
                    if hrp then
                        teleportInto(hrp, collectZone)
                        task.wait(j(0.6, 0.25))
                        pcall(function() revKickCollect:FireServer() end)
                    end

                    -- Step 4: wait for the server to close the round
                    waitForRoundEnd(25)

                    -- Short break before next round
                    task.wait(j(3, 0.25))
                end
            end)
        end
    end)

    -- ── Auto Upgrade ─────────────────────────────────────────────────────────────
    getgenv()._brk_upgrade = false
    elements:Toggle("Auto Upgrade", section, function(v)
        getgenv()._brk_upgrade = v
        if v then
            task.spawn(function()
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
            task.spawn(function()
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
            task.spawn(function()
                while getgenv()._brk_rebirth do
                    pcall(function() revRebirth:FireServer() end)
                    task.wait(j(12, 0.2))
                end
            end)
        end
    end)

    -- ── Unload ────────────────────────────────────────────────────────────────────
    section.AncestorRemoving:Connect(function()
        getgenv()._brk_collect = false
        getgenv()._brk_sell    = false
        getgenv()._brk_kick    = false
        getgenv()._brk_upgrade = false
        getgenv()._brk_lift    = false
        getgenv()._brk_rebirth = false
    end)
end

-- Brainrot Kick Simulator (PlaceId 89469502395769)

return function(section)
    local elements = getgenv()._astroElements
    local player   = game:GetService("Players").LocalPlayer
    local RS       = game:GetService("ReplicatedStorage")

    local Network        = RS:WaitForChild("Shared"):WaitForChild("Packages"):WaitForChild("Network")
    local revKickEvent   = Network:WaitForChild("rev_KickEvent")
    local revKickCollect = Network:WaitForChild("rev_KickCollect")
    local revBUpgrade    = Network:WaitForChild("rev_B_Upgrade")
    local revRebirth     = Network:WaitForChild("rev_RebirthRequest")
    local refSellAll     = Network:WaitForChild("ref_B_SellAll")

    local rng = Random.new()

    -- Returns a value in [base*(1-jitter), base*(1+jitter)]
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

    -- Teleport inside a part with a small random XZ offset so it looks natural
    local function teleportInto(hrp, part)
        local sz  = part.Size
        local ox  = (rng:NextNumber() * 2 - 1) * math.min(sz.X * 0.3, 3)
        local oz  = (rng:NextNumber() * 2 - 1) * math.min(sz.Z * 0.3, 3)
        hrp.CFrame = part.CFrame * CFrame.new(ox, 3, oz)
    end

    -- ── Auto Collect ──────────────────────────────────────────────────────────────
    -- Uses firetouchinterest to go through the game's Touched handler; the handler
    -- checks coins > 0 and applies its own 0.4 s debounce before firing B_Collect.
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
                                    -- Slightly faster than the 0.4 s debounce; feels like
                                    -- a player walking quickly past each button
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
    -- Randomises kick scale (0.75–1.0) and delays to mimic imperfect human timing.
    -- Teleports into the zone with a small random offset before firing.
    getgenv()._brk_kick = false
    elements:Toggle("Auto Kick", section, function(v)
        getgenv()._brk_kick = v
        if v then
            task.spawn(function()
                local kickArea    = workspace:WaitForChild("Areas"):WaitForChild("KickReady")
                local collectZone = workspace:WaitForChild("Zones"):WaitForChild("CollectZone")
                while getgenv()._brk_kick do
                    if player:GetAttribute("RoundDebounce") or player:GetAttribute("KickDebounced") then
                        task.wait(1)
                        continue
                    end
                    local hrp = getHRP()
                    if not hrp then task.wait(2) continue end

                    -- Move into kick zone then wait a beat before swinging
                    teleportInto(hrp, kickArea)
                    task.wait(j(0.8, 0.3))

                    -- Scale varies 0.75–1.0; percent stays at 1 (player left it at MAX)
                    local scale = 0.75 + rng:NextNumber() * 0.25
                    pcall(function() revKickEvent:FireServer(scale, 1) end)

                    -- Wait for the kick sequence + tsunami to resolve
                    task.wait(j(5.5, 0.15))

                    -- Move into collect zone
                    hrp = getHRP()
                    if hrp then
                        teleportInto(hrp, collectZone)
                        task.wait(j(0.5, 0.3))
                        pcall(function() revKickCollect:FireServer() end)
                    end

                    -- Brief pause before next round
                    task.wait(j(2.5, 0.2))
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
    -- Keeps the SquatTool equipped. The server runs its own lift loop while it's
    -- held; the game unequips it during kicks so we re-equip after each round.
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
    -- Server rejects silently if requirements aren't met yet
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

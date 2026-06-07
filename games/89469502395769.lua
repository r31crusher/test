-- Brainrot Kick Simulator (PlaceId 89469502395769)

return function(section)
    local elements = getgenv()._astroElements
    local player   = game:GetService("Players").LocalPlayer
    local RS       = game:GetService("ReplicatedStorage")

    local Network        = RS:WaitForChild("Shared"):WaitForChild("Packages"):WaitForChild("Network")
    local revBCollect    = Network:WaitForChild("rev_B_Collect")
    local revBUpgrade    = Network:WaitForChild("rev_B_Upgrade")
    local revKickEvent   = Network:WaitForChild("rev_KickEvent")
    local revKickCollect = Network:WaitForChild("rev_KickCollect")
    local revRebirth     = Network:WaitForChild("rev_RebirthRequest")
    local refSellAll     = Network:WaitForChild("ref_B_SellAll")

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

    -- ── Auto Collect ──────────────────────────────────────────────────────────────
    -- Fires B_Collect for every brainrot slot button on the player's own plot
    getgenv()._brk_collect = false
    elements:Toggle("Auto Collect", section, function(v)
        getgenv()._brk_collect = v
        if v then
            task.spawn(function()
                while getgenv()._brk_collect do
                    local plot = getMyPlot()
                    if plot then
                        local buttons = plot:FindFirstChild("Buttons")
                        if buttons then
                            for _, slot in ipairs(buttons:GetChildren()) do
                                if not getgenv()._brk_collect then break end
                                local slotId = tonumber(slot.Name:gsub("Slot", ""))
                                if slotId then
                                    pcall(function() revBCollect:FireServer(slotId) end)
                                    task.wait(0.05)
                                end
                            end
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    end)

    -- ── Auto Sell ─────────────────────────────────────────────────────────────────
    -- Sells all brainrots from the player's inventory every 3 seconds
    getgenv()._brk_sell = false
    elements:Toggle("Auto Sell", section, function(v)
        getgenv()._brk_sell = v
        if v then
            task.spawn(function()
                while getgenv()._brk_sell do
                    pcall(function() refSellAll:InvokeServer() end)
                    task.wait(3)
                end
            end)
        end
    end)

    -- ── Auto Kick ─────────────────────────────────────────────────────────────────
    -- Teleports to the KickReady area, fires at max power, then collects
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
                    if hrp then
                        hrp.CFrame = kickArea.CFrame * CFrame.new(0, 3, 0)
                        task.wait(0.3)
                        pcall(function() revKickEvent:FireServer(1, 1) end)
                        task.wait(5)
                        hrp = getHRP()
                        if hrp then
                            hrp.CFrame = collectZone.CFrame * CFrame.new(0, 3, 0)
                            task.wait(0.3)
                            pcall(function() revKickCollect:FireServer() end)
                        end
                        task.wait(2)
                    else
                        task.wait(2)
                    end
                end
            end)
        end
    end)

    -- ── Auto Upgrade ─────────────────────────────────────────────────────────────
    -- Fires B_Upgrade for every brainrot slot on the player's plot
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
                                    task.wait(0.05)
                                end
                            end
                        end
                    end
                    task.wait(3)
                end
            end)
        end
    end)

    -- ── Auto Lift ─────────────────────────────────────────────────────────────────
    -- Keeps the SquatTool equipped so the server-side lift loop keeps running.
    -- Re-equips whenever the game unequips it (kick zone entry, kick start, etc.)
    getgenv()._brk_lift = false
    elements:Toggle("Auto Lift", section, function(v)
        getgenv()._brk_lift = v
        if v then
            task.spawn(function()
                while getgenv()._brk_lift do
                    local char = player.Character
                    local hum  = char and char:FindFirstChild("Humanoid")
                    if hum then
                        -- Skip if in kick zone or mid-kick (tool auto-unequips there)
                        local inKickZone = char:GetAttribute("RoundDebounce") or player:GetAttribute("KickDebounced")
                        if not inKickZone then
                            -- Check if already equipped
                            local equipped = char:FindFirstChildOfClass("Tool")
                            if not (equipped and equipped:HasTag("SquatTool")) then
                                -- Find it in backpack
                                for _, t in ipairs(player.Backpack:GetChildren()) do
                                    if t:IsA("Tool") and t:HasTag("SquatTool") then
                                        hum:EquipTool(t)
                                        break
                                    end
                                end
                            end
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    end)

    -- ── Auto Rebirth ──────────────────────────────────────────────────────────────
    -- Fires RebirthRequest every 10 seconds; server rejects if requirements unmet
    getgenv()._brk_rebirth = false
    elements:Toggle("Auto Rebirth", section, function(v)
        getgenv()._brk_rebirth = v
        if v then
            task.spawn(function()
                while getgenv()._brk_rebirth do
                    pcall(function() revRebirth:FireServer() end)
                    task.wait(10)
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

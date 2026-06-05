-- Brainrot Tycoon (UGC Carry)

return function(section)
    local elements = getgenv()._astroElements

    local player  = game:GetService("Players").LocalPlayer
    local RS       = game:GetService("ReplicatedStorage")
    local events   = RS:WaitForChild("Events")

    local evDrop      = events:WaitForChild("RequestDropItem")
    local evSell      = events:WaitForChild("RequestSell")
    local evBaseUp    = events:WaitForChild("RequestBaseUpgrade")
    local evSlotUp    = events:WaitForChild("RequestSlotUpgrade")
    local evRebirth   = events:WaitForChild("RequestRebirth")
    local evDaily     = events:WaitForChild("ClaimDailyReward")
    local fnDailyInfo = events:WaitForChild("GetDailyInfo")

    local function getPlot()
        return workspace:FindFirstChild("Plot_" .. player.Name)
    end

    local function getHRP()
        local char = player.Character
        return char and char:FindFirstChild("HumanoidRootPart")
    end

    -- ── Auto Farm ─────────────────────────────────────────────────────────────
    -- Carry limit is 1: approach the Emerald Galaxy spawn area to stream it in,
    -- pick up one SpawnedItem, return to safe zone (CollectionZone) to drop, repeat.
    getgenv()._brain_farm = false
    elements:Toggle("Auto Farm", section, function(v)
        getgenv()._brain_farm = v
        if v then
            task.spawn(function()
                local itemSpawns = workspace:WaitForChild("ItemSpawns", 15)
                local zones      = workspace:WaitForChild("CollectionZones", 15)
                if not itemSpawns or not zones then
                    warn("[Astro] ItemSpawns or CollectionZones not found")
                    return
                end

                -- Block until the CollectionZone part streams in
                local zone = zones:WaitForChild("CollectionZone", 15)
                if not zone then
                    warn("[Astro] CollectionZone part not found")
                    return
                end

                -- Collect all spawn area parts (one per zone tier, including Emerald Galaxy)
                local function getSpawnAreas()
                    local areas = {}
                    for _, child in ipairs(itemSpawns:GetChildren()) do
                        if child:IsA("BasePart") then
                            table.insert(areas, child)
                        end
                    end
                    return areas
                end

                -- Check if the character is currently holding an item
                local function hasItem()
                    local char = player.Character
                    return char and char:FindFirstChild("HeadStackItem") ~= nil
                end

                while getgenv()._brain_farm do
                    local hrp = getHRP()
                    if not hrp then task.wait(1) continue end

                    local spawnAreas = getSpawnAreas()
                    if #spawnAreas == 0 then
                        warn("[Astro] No spawn areas loaded yet, waiting...")
                        task.wait(2)
                        continue
                    end

                    -- Step 1: approach each spawn area to stream it in, then grab an item
                    local picked = false
                    for _, area in ipairs(spawnAreas) do
                        if not getgenv()._brain_farm then break end
                        hrp = getHRP()
                        if not hrp then break end

                        -- Teleport near the area to load it
                        hrp.CFrame = CFrame.new(area.Position + Vector3.new(0, 5, 15))
                        task.wait(1)

                        -- Now look for SpawnedItems inside this area
                        for _, item in ipairs(area:GetChildren()) do
                            if not getgenv()._brain_farm then break end
                            if item.Name == "SpawnedItem" then
                                local part = item:FindFirstChildOfClass("MeshPart")
                                    or item:FindFirstChildOfClass("BasePart")
                                if part then
                                    local prompt = part:FindFirstChildOfClass("ProximityPrompt")
                                    if not prompt then continue end
                                    prompt.HoldDuration = 0
                                    hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 2, 0))
                                    task.wait(0.2)
                                    pcall(fireproximityprompt, prompt)
                                    task.wait(0.5)
                                    if hasItem() then
                                        picked = true
                                        break
                                    end
                                end
                            end
                        end
                        if picked then break end
                    end

                    if not picked then
                        task.wait(1)
                        continue
                    end

                    -- Step 2: teleport back to safe zone
                    hrp = getHRP()
                    if hrp then
                        hrp.CFrame = CFrame.new(zone.Position + Vector3.new(0, 3, 0))
                        task.wait(0.5)
                    end
                end
            end)
        end
    end)

    -- ── Auto Sell ─────────────────────────────────────────────────────────────
    -- Teleports to SellNPC and sells the full inventory every few seconds.
    getgenv()._brain_sell = false
    elements:Toggle("Auto Sell", section, function(v)
        getgenv()._brain_sell = v
        if v then
            task.spawn(function()
                while getgenv()._brain_sell do
                    local hrp = getHRP()
                    local npc = workspace:FindFirstChild("SellNPC")
                    local proxPart = npc and npc:FindFirstChild("ProxPart")
                    if hrp and proxPart then
                        hrp.CFrame = CFrame.new(proxPart.Position + Vector3.new(0, 3, 0))
                        task.wait(0.1)
                    end
                    pcall(function() evSell:FireServer("Inventory") end)
                    task.wait(3)
                end
            end)
        end
    end)

    -- ── Auto Upgrade Slots ────────────────────────────────────────────────────
    getgenv()._brain_slotUp = false
    elements:Toggle("Auto Upgrade Slots", section, function(v)
        getgenv()._brain_slotUp = v
        if v then
            task.spawn(function()
                while getgenv()._brain_slotUp do
                    local plot = getPlot()
                    if plot then
                        for _, gui in ipairs(plot:GetDescendants()) do
                            if not getgenv()._brain_slotUp then break end
                            if gui:IsA("SurfaceGui") and gui.Name == "UpgradeGUI" then
                                local floorName = gui:GetAttribute("FloorName")
                                local slotName  = gui:GetAttribute("SlotName")
                                if floorName and slotName then
                                    pcall(function() evSlotUp:FireServer(floorName, slotName) end)
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

    -- ── Auto Upgrade Base (Floors) ────────────────────────────────────────────
    getgenv()._brain_baseUp = false
    elements:Toggle("Auto Upgrade Base", section, function(v)
        getgenv()._brain_baseUp = v
        if v then
            task.spawn(function()
                while getgenv()._brain_baseUp do
                    local plot = getPlot()
                    local hrp  = getHRP()
                    if plot and hrp then
                        for _, desc in ipairs(plot:GetDescendants()) do
                            if not getgenv()._brain_baseUp then break end
                            if desc:IsA("BasePart") and desc.Name == "Touch" then
                                hrp.CFrame = CFrame.new(desc.Position + Vector3.new(0, 3, 0))
                                task.wait(0.1)
                                pcall(function() evBaseUp:FireServer() end)
                                task.wait(0.1)
                            end
                        end
                    end
                    task.wait(5)
                end
            end)
        end
    end)

    -- ── Auto Rebirth ──────────────────────────────────────────────────────────
    getgenv()._brain_rebirth = false
    elements:Toggle("Auto Rebirth", section, function(v)
        getgenv()._brain_rebirth = v
        if v then
            task.spawn(function()
                while getgenv()._brain_rebirth do
                    local ls = player:FindFirstChild("leaderstats")
                    if ls then
                        local spd = ls:FindFirstChild("WalkSpeed")
                        local reb = ls:FindFirstChild("Rebirths")
                        if spd and reb then
                            if spd.Value >= reb.Value * 5 + 40 then
                                pcall(function() evRebirth:FireServer() end)
                            end
                        end
                    end
                    task.wait(3)
                end
            end)
        end
    end)

    -- ── Auto Daily Reward ─────────────────────────────────────────────────────
    getgenv()._brain_daily = false
    elements:Toggle("Auto Daily Reward", section, function(v)
        getgenv()._brain_daily = v
        if v then
            task.spawn(function()
                while getgenv()._brain_daily do
                    local ok, info = pcall(function() return fnDailyInfo:InvokeServer() end)
                    if ok and info and info.CanClaim then
                        pcall(function() evDaily:FireServer() end)
                    end
                    task.wait(60)
                end
            end)
        end
    end)

    -- ── Unload hook ───────────────────────────────────────────────────────────
    -- When ui.lua calls gui:Destroy(), the section ancestor is removed.
    -- This kills all running loops so nothing keeps running after unload.
    section.AncestorRemoving:Connect(function()
        getgenv()._brain_farm    = false
        getgenv()._brain_sell    = false
        getgenv()._brain_slotUp  = false
        getgenv()._brain_baseUp  = false
        getgenv()._brain_rebirth = false
        getgenv()._brain_daily   = false
    end)
end

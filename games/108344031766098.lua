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

    -- Block all Robux purchase prompts while this game script is loaded
    local _mpsHook = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "PromptProductPurchase" or method == "PromptGamePassPurchase" then
            return
        end
        return _mpsHook(self, ...)
    end))

    -- ── Auto Farm ─────────────────────────────────────────────────────────────
    -- Carry limit is 1: approach the Emerald Galaxy spawn area to stream it in,
    -- pick up one SpawnedItem, return to safe zone (CollectionZone) to drop, repeat.
    getgenv()._brain_farm = false
    elements:Toggle("Auto Farm", section, function(v)
        getgenv()._brain_farm = v
        if v then
            task.spawn(function()
                local itemSpawns = workspace:WaitForChild("ItemSpawns", 15)
                if not itemSpawns then
                    warn("[Astro] ItemSpawns not found")
                    return
                end

                local WAYPOINT      = Vector3.new(-171.97, 35.87, 2286.70)
                local SAFE_ZONE_POS = Vector3.new(-163.88, 37.33, 4564.50)

                -- Teleport through waypoint then safe zone to stream Part 11 in
                local hrp = getHRP()
                if hrp then
                    hrp.CFrame = CFrame.new(WAYPOINT)
                    task.wait(1.5)
                    hrp.CFrame = CFrame.new(SAFE_ZONE_POS)
                    task.wait(2)
                end

                local emeraldPart = itemSpawns:WaitForChild("11", 15)
                if not emeraldPart then
                    warn("[Astro] Emerald Galaxy (Part 11) still not loaded after approach")
                    return
                end

                while getgenv()._brain_farm do
                    local hrp = getHRP()
                    if not hrp then task.wait(1) continue end

                    -- Find first SpawnedItem in Part 11 (Emerald Galaxy only)
                    local prompt, itemPart
                    for _, item in ipairs(emeraldPart:GetChildren()) do
                        if item.Name == "SpawnedItem" then
                            local part = item:FindFirstChildOfClass("MeshPart")
                            if part then
                                local p = part:FindFirstChildOfClass("ProximityPrompt")
                                if p then
                                    prompt   = p
                                    itemPart = part
                                    break
                                end
                            end
                        end
                    end

                    if not prompt then
                        -- No items spawned yet, wait at safe zone
                        task.wait(2)
                        continue
                    end

                    -- Step 1: teleport to item and pick it up
                    hrp.CFrame = CFrame.new(itemPart.Position + Vector3.new(0, 3, 0))
                    task.wait(0.3)
                    prompt.HoldDuration = 0
                    pcall(fireproximityprompt, prompt)
                    task.wait(0.5)

                    -- Step 2: return to safe zone
                    hrp = getHRP()
                    if hrp then
                        hrp.CFrame = CFrame.new(SAFE_ZONE_POS)
                        task.wait(0.5)
                    end
                end
            end)
        end
    end)

    -- ── Auto Sell ─────────────────────────────────────────────────────────────
    -- Fires RequestSell without teleporting so it doesn't interfere with Auto Farm.
    getgenv()._brain_sell = false
    elements:Toggle("Auto Sell", section, function(v)
        getgenv()._brain_sell = v
        if v then
            task.spawn(function()
                while getgenv()._brain_sell do
                    pcall(function() evSell:FireServer("Inventory") end)
                    task.wait(3)
                end
            end)
        end
    end)

    -- ── Auto Collect ─────────────────────────────────────────────────────────
    getgenv()._brain_collect = false
    elements:Toggle("Auto Collect", section, function(v)
        getgenv()._brain_collect = v
        if v then
            task.spawn(function()
                -- Cache CollectTouch parts once; refresh if plot reloads
                local cachedParts = {}
                local function refreshParts()
                    cachedParts = {}
                    local plot = getPlot()
                    if not plot then return end
                    for _, part in ipairs(plot:GetDescendants()) do
                        if part:IsA("BasePart") and part.Name == "CollectTouch" then
                            table.insert(cachedParts, part)
                        end
                    end
                end

                refreshParts()

                while getgenv()._brain_collect do
                    local hrp = getHRP()
                    if hrp then
                        if #cachedParts == 0 then refreshParts() end
                        for _, part in ipairs(cachedParts) do
                            if not getgenv()._brain_collect then break end
                            if part and part.Parent then
                                pcall(firetouchinterest, part, hrp, 0)
                                task.wait(0.05)
                                pcall(firetouchinterest, part, hrp, 1)
                                task.wait(0.05)
                            end
                        end
                    end
                    task.wait(0.5)
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

    -- ── Teleport to Safe Zone ────────────────────────────────────────────────
    elements:Button("Teleport to Safe Zone", section, function()
        local hrp = getHRP()
        if hrp then
            hrp.CFrame = CFrame.new(16.45, 58.63, -10.71)
        end
    end)

    -- ── Unload hook ───────────────────────────────────────────────────────────
    -- When ui.lua calls gui:Destroy(), the section ancestor is removed.
    -- This kills all running loops so nothing keeps running after unload.
    section.AncestorRemoving:Connect(function()
        getgenv()._brain_farm    = false
        getgenv()._brain_sell    = false
        getgenv()._brain_collect = false
        getgenv()._brain_slotUp  = false
        getgenv()._brain_baseUp  = false
        getgenv()._brain_rebirth = false
        getgenv()._brain_daily   = false
    end)
end

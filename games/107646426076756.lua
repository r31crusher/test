-- Build A Ring Farm (PlaceId 107646426076756)

return function(section)
    local elements = getgenv()._astroElements

    local rs      = game:GetService("ReplicatedStorage")
    local remotes = rs.Remotes

    local rCompostFolder    = remotes:WaitForChild("Composter")
    local rCompostState     = rCompostFolder:WaitForChild("RequestState")
    local rCompostInsert    = rCompostFolder:WaitForChild("InsertSeed")
    local rCompostLever     = rCompostFolder:WaitForChild("PullLever")

    local rPlantSeed        = remotes:WaitForChild("PlantSeed")
    local rRemovePlant      = remotes:WaitForChild("RemovePlant")
    local rSellCrates       = remotes:WaitForChild("SellCrates")
    local rUpgrade          = remotes:WaitForChild("UpgradePlant")
    local rUnlock           = remotes:WaitForChild("UnlockPlot")
    local rRollSeeds        = remotes:WaitForChild("RollSeeds")
    local rBuySeed          = remotes:WaitForChild("BuySeed")
    local rPlotUpgrade      = remotes:WaitForChild("PlotUpgradeTransaction")
    local rUpgradeSeedRolls = remotes:WaitForChild("UpgradeSeedRolls")
    local rUpgradeSeedLuck  = remotes:WaitForChild("UpgradeSeedLuck")
    local rUpgradeFarm      = remotes:WaitForChild("UpgradeFarm")
    local rDaily            = remotes:WaitForChild("ClaimDailyReward")
    local rCode             = remotes:WaitForChild("SubmitCode")

    local PLOT_UPGRADE_TYPES = {
        "ExtraYield", "ExtraPower", "ExtraSawRange",
        "ExtraSprinklerRange", "SoilQuality",
    }

    -- Plant data: load from Registry (has Rarity, Price, Cost, RollChance)
    local Plants = {}
    task.spawn(function()
        local ok, reg = pcall(require, rs:WaitForChild("Shared"):WaitForChild("Registry"))
        if ok and reg and reg.Plants then
            Plants = reg.Plants
        end
    end)

    local RARITY_RANK = {
        Common=1, Uncommon=2, Rare=3, Epic=4,
        Legendary=5, Secret=6, Divine=7, Exotic=8, Prismatic=9, Transcended=10,
    }
    local RANK_LABEL = {"Common","Uncommon","Rare","Epic","Legendary","Secret","Divine","Exotic","Prismatic","Transcended"}

    -- Fetch the player's farm plot once on load
    local myPlot = nil
    task.spawn(function()
        local rf = remotes:WaitForChild("Plot"):WaitForChild("GetPlot")
        local ok, result = pcall(rf.InvokeServer, rf)
        if ok and result then myPlot = result end
    end)

    -- Returns all Dirt parts in the player's farm (emptyOnly = no PlantName)
    local function getDirtParts(emptyOnly)
        if not myPlot then return {} end
        local farmPlot = myPlot:FindFirstChild("FarmPlot")
        if not farmPlot then return {} end
        local dirts = {}
        for _, plotModel in farmPlot:GetChildren() do
            if plotModel:IsA("Model") and plotModel.Name:match("^Plot%d+$") then
                local dirt = plotModel:FindFirstChild("Dirt")
                if dirt then
                    if not emptyOnly or not dirt:GetAttribute("PlantName") then
                        table.insert(dirts, dirt)
                    end
                end
            end
        end
        return dirts
    end

    -- Returns (dirt, currentPrice) of the lowest-value occupied plot
    local function getWorstPlot()
        local worst, worstPrice = nil, math.huge
        for _, dirt in getDirtParts(false) do
            local name = dirt:GetAttribute("PlantName")
            if name then
                local data = Plants[name]
                local price = data and data.Price or 0
                if price < worstPrice then
                    worst, worstPrice = dirt, price
                end
            end
        end
        return worst, worstPrice
    end

    local loops = {}
    local function cancelLoop(name)
        if loops[name] then task.cancel(loops[name]); loops[name] = nil end
    end

    -- Track roll results from the server
    local lastRollSeeds = {}
    local rollSignal    = Instance.new("BindableEvent")
    local rollConn = rRollSeeds.OnClientEvent:Connect(function(names)
        if not names or #names == 0 then return end
        lastRollSeeds = {}
        for i, name in ipairs(names) do lastRollSeeds[i] = name end
        rollSignal:Fire()
    end)

    -- Minimum rarity rank for auto-buy (default 5 = Legendary)
    local minRank = 5

    -- Attempt to buy + plant/swap a rolled seed
    local function tryBuyAndPlant(slotIdx, plantName)
        local data = Plants[plantName]
        if not data then return false end
        local rank = RARITY_RANK[data.Rarity] or 0
        if rank < minRank then return false end

        local emptyDirts = getDirtParts(true)
        if #emptyDirts > 0 then
            -- Empty plot available — buy and plant
            pcall(rBuySeed.FireServer, rBuySeed, slotIdx)
            task.wait(0.4)
            pcall(rPlantSeed.FireServer, rPlantSeed, emptyDirts[1])
            return true
        else
            -- All plots full — swap if new seed earns more than the worst current plant
            local worstDirt, worstPrice = getWorstPlot()
            if worstDirt and data.Price > worstPrice then
                pcall(rBuySeed.FireServer, rBuySeed, slotIdx)
                task.wait(0.4)
                pcall(rRemovePlant.FireServer, rRemovePlant, worstDirt)
                task.wait(0.3)
                pcall(rPlantSeed.FireServer, rPlantSeed, worstDirt)
                return true
            end
        end
        return false
    end

    -- ─── Auto Roll Seeds ──────────────────────────────────────────────────────

    elements:Label("Min rarity: Legendary", section)  -- label updated by slider
    -- We need a reference to update it; create it manually
    local minRarityLabel = Instance.new("TextLabel")
    minRarityLabel.Name           = "LabelElement"
    minRarityLabel.Size           = UDim2.new(1, 0, 0, 24)
    minRarityLabel.BackgroundTransparency = 1
    minRarityLabel.Font           = Enum.Font.Gotham
    minRarityLabel.TextSize       = 13
    minRarityLabel.TextColor3     = Color3.fromRGB(200, 190, 255)
    minRarityLabel.TextXAlignment = Enum.TextXAlignment.Left
    minRarityLabel.Text           = "Min Rarity:  Legendary"
    minRarityLabel.Parent         = section

    elements:Slider("Rarity Threshold", section, 1, 6, 5, function(v)
        minRank = v
        minRarityLabel.Text = "Min Rarity:  " .. (RANK_LABEL[v] or tostring(v))
    end)

    elements:Toggle("Auto Roll Seeds", section, function(state)
        cancelLoop("roll")
        if not state then return end
        loops.roll = task.spawn(function()
            while true do
                rRollSeeds:FireServer()
                -- Wait up to 6s for the server to send results back
                local t = tick()
                local received = false
                local conn = rollSignal.Event:Connect(function() received = true end)
                repeat task.wait(0.1) until received or tick() - t > 6
                conn:Disconnect()

                task.wait(0.5)  -- let animation settle

                -- Try to buy every qualifying seed in this roll
                for slotIdx, plantName in pairs(lastRollSeeds) do
                    tryBuyAndPlant(slotIdx, plantName)
                    task.wait(0.2)
                end

                task.wait(3)  -- roll cooldown
            end
        end)
    end)

    -- ─── Farm features ────────────────────────────────────────────────────────

    elements:Toggle("Auto Sell Crates", section, function(state)
        cancelLoop("sell")
        if state then
            loops.sell = task.spawn(function()
                while task.wait(3) do rSellCrates:FireServer() end
            end)
        end
    end)

    -- Returns all unlocked floor names ("Floor1", "Floor2", ...) from the player's plot.
    -- Floor1 is the plot itself (never a named child); Floor2+ are child models.
    local function getFloors()
        local floors = {"Floor1"}
        if not myPlot then return floors end
        for _, child in myPlot:GetChildren() do
            if child.Name:match("^Floor%d+$") then
                table.insert(floors, child.Name)
            end
        end
        return floors
    end

    -- Composter floor indices: 2 = basic, 3 = tier2, 4 = tier3 (unlocked with Farm floors)
    local COMPOSTER_FLOORS = {2, 3, 4}

    local function getDataSnapshot()
        local ok, DR = pcall(require, rs:WaitForChild("Packages"):WaitForChild("DataReplicator"))
        if ok and DR then
            local rep = pcall(DR.GetReplicator) and DR.GetReplicator()
            if rep then return rep:GetSnapshot() end
        end
        return nil
    end

    -- Auto Upgrade — fires all plot upgrade types on every floor, plus seed rolls/luck/farm
    elements:Toggle("Auto Upgrade All", section, function(state)
        cancelLoop("plotUpgrade")
        if state then
            loops.plotUpgrade = task.spawn(function()
                while task.wait(4) do
                    -- Farm-wide upgrades
                    pcall(rUpgradeSeedRolls.InvokeServer, rUpgradeSeedRolls)
                    task.wait(0.2)
                    pcall(rUpgradeSeedLuck.InvokeServer, rUpgradeSeedLuck)
                    task.wait(0.2)
                    pcall(rUpgradeFarm.InvokeServer, rUpgradeFarm)
                    task.wait(0.2)
                    -- Per-floor upgrades
                    for _, floor in getFloors() do
                        for _, upgradeType in PLOT_UPGRADE_TYPES do
                            pcall(rPlotUpgrade.InvokeServer, rPlotUpgrade, upgradeType, floor)
                            task.wait(0.15)
                        end
                    end
                end
            end)
        end
    end)

    -- Auto Composter — pulls ready composters and feeds them the cheapest seeds first
    elements:Toggle("Auto Composter", section, function(state)
        cancelLoop("compost")
        if not state then return end
        loops.compost = task.spawn(function()
            while task.wait(10) do
                for _, floor in COMPOSTER_FLOORS do
                    -- Pull lever if a tier has been reached
                    local ok, st = pcall(rCompostState.InvokeServer, rCompostState, floor)
                    if ok and type(st) == "table" and st.Tier then
                        pcall(rCompostLever.InvokeServer, rCompostLever, floor)
                        task.wait(0.5)
                    end

                    -- Feed cheapest seeds from inventory into this composter
                    local snapshot = getDataSnapshot()
                    if snapshot and snapshot.SeedsInventory then
                        -- Build sorted list: cheapest (lowest Price) first
                        local seeds = {}
                        for key, entry in pairs(snapshot.SeedsInventory) do
                            local data = Plants[entry.Name]
                            if data and (entry.Count or 0) > 0 then
                                table.insert(seeds, {key=key, entry=entry, price=data.Price or 0})
                            end
                        end
                        table.sort(seeds, function(a, b) return a.price < b.price end)
                        local fed = 0
                        for _, seed in seeds do
                            if fed >= 3 then break end
                            pcall(rCompostInsert.InvokeServer, rCompostInsert, floor, seed.key, 1)
                            task.wait(0.15)
                            fed = fed + 1
                        end
                    end
                    task.wait(0.5)
                end
            end
        end)
    end)

    elements:Toggle("Auto Upgrade Plants", section, function(state)
        cancelLoop("upgrade")
        if state then
            loops.upgrade = task.spawn(function()
                while task.wait(5) do
                    for _, dirt in getDirtParts(false) do
                        if dirt:GetAttribute("PlantName") then
                            pcall(rUpgrade.InvokeServer, rUpgrade, dirt)
                            task.wait(0.1)
                        end
                    end
                end
            end)
        end
    end)

    elements:Button("Plant All (equipped seed)", section, function()
        for _, dirt in getDirtParts(true) do
            pcall(rPlantSeed.FireServer, rPlantSeed, dirt)
            task.wait(0.1)
        end
    end)

    elements:Button("Unlock All Plots", section, function()
        for _, dirt in getDirtParts(false) do
            if dirt.Parent:GetAttribute("Unlocked") == false then
                pcall(rUnlock.FireServer, rUnlock, dirt)
                task.wait(0.15)
            end
        end
    end)

    -- ─── Misc ─────────────────────────────────────────────────────────────────

    elements:Button("Claim Daily Reward", section, function()
        pcall(rDaily.InvokeServer, rDaily)
    end)

    local pendingCode = ""
    elements:Textbox("Redeem Code", section, function(text) pendingCode = text end)
    elements:Button("Submit Code", section, function()
        if pendingCode ~= "" then
            pcall(rCode.InvokeServer, rCode, pendingCode)
        end
    end)

    -- ─── Unload ───────────────────────────────────────────────────────────────

    section.AncestorRemoving:Connect(function()
        for name in loops do cancelLoop(name) end
        rollConn:Disconnect()
        rollSignal:Destroy()
        if minRarityLabel and minRarityLabel.Parent then
            minRarityLabel:Destroy()
        end
    end)
end

-- Grow a Garden (PlaceId 107646426076756)

return function(section)
    local elements = getgenv()._astroElements

    local rs      = game:GetService("ReplicatedStorage")
    local remotes = rs.Remotes

    local rPlantSeed  = remotes:WaitForChild("PlantSeed")
    local rSellCrates = remotes:WaitForChild("SellCrates")
    local rUpgrade    = remotes:WaitForChild("UpgradePlant")
    local rUnlock     = remotes:WaitForChild("UnlockPlot")
    local rDaily      = remotes:WaitForChild("ClaimDailyReward")
    local rCode       = remotes:WaitForChild("SubmitCode")

    -- Fetch the player's farm plot once on load
    local myPlot = nil
    task.spawn(function()
        local rf = remotes:WaitForChild("Plot"):WaitForChild("GetPlot")
        local ok, result = pcall(rf.InvokeServer, rf)
        if ok and result then
            myPlot = result
        end
    end)

    -- Returns all Dirt parts in the player's farm (emptyOnly = no PlantName attribute)
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

    local loops = {}

    local function cancelLoop(name)
        if loops[name] then
            task.cancel(loops[name])
            loops[name] = nil
        end
    end

    -- Auto Sell Crates — server doesn't require physical crate pickup
    elements:Toggle("Auto Sell Crates", section, function(state)
        cancelLoop("sell")
        if state then
            loops.sell = task.spawn(function()
                while task.wait(3) do
                    rSellCrates:FireServer()
                end
            end)
        end
    end)

    -- Auto Upgrade Plants — upgrades every occupied dirt plot
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

    -- Plant All — plants equipped seed on every empty dirt (equip seed first)
    elements:Button("Plant All (equipped seed)", section, function()
        for _, dirt in getDirtParts(true) do
            pcall(rPlantSeed.FireServer, rPlantSeed, dirt)
            task.wait(0.1)
        end
    end)

    -- Unlock All Plots — unlocks every locked dirt plot
    elements:Button("Unlock All Plots", section, function()
        for _, dirt in getDirtParts(false) do
            if dirt.Parent:GetAttribute("Unlocked") == false then
                pcall(rUnlock.FireServer, rUnlock, dirt)
                task.wait(0.15)
            end
        end
    end)

    -- Claim Daily Reward
    elements:Button("Claim Daily Reward", section, function()
        pcall(rDaily.InvokeServer, rDaily)
    end)

    -- Redeem Code
    local pendingCode = ""
    elements:Textbox("Redeem Code", section, function(text)
        pendingCode = text
    end)
    elements:Button("Submit Code", section, function()
        if pendingCode ~= "" then
            local ok, result = pcall(rCode.InvokeServer, rCode, pendingCode)
            if ok then
                print("[Astro] Code result:", result)
            end
        end
    end)

    -- Unload
    section.AncestorRemoving:Connect(function()
        for name in loops do
            cancelLoop(name)
        end
    end)
end

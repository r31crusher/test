-- Pet game (PlaceId 96645548064314)

return function(section)
    local elements = getgenv()._astroElements

    local players = game:GetService("Players")
    local rs      = game:GetService("ReplicatedStorage")
    local remotes = rs:WaitForChild("Remotes")
    local player  = players.LocalPlayer

    local collectAllCash   = remotes:WaitForChild("collectAllPetCash")
    local sellPetRF        = remotes:WaitForChild("sellPet")
    local sellEggRF        = remotes:WaitForChild("sellEgg")
    local minigameRequest  = remotes:WaitForChild("minigameRequest")
    local updateProgress   = remotes:WaitForChild("UpdateProgress")
    local throwLasso       = remotes:WaitForChild("ThrowLasso")

    local PET_FOLDERS = {
        "RoamingPets", "SkyIslandPets", "WaterIslandPets", "BeeIslandPets",
        "GalaxyIslandPets", "NewEventIslandPets", "SafariIslandPets",
        "CaveIslandPets", "DeepCavePets", "VolcanoIslandPets",
        "LavaIslandPets", "AbyssIslandPets",
    }

    local RARITY_RANK = {
        Common=1, Rare=2, Epic=3, Legendary=4,
        Mythical=5, Boss=6, Divine=7, Exclusive=8, Secret=9,
    }

    -- Returns the highest-rarity (then highest-strength) available pet across all folders.
    -- We teleport to it anyway so distance is only a tiebreaker.
    local function findBestPet()
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        local best, bestRank, bestStr, bestDist = nil, -1, -1, math.huge
        for _, folderName in PET_FOLDERS do
            local folder = workspace:FindFirstChild(folderName)
            local pets   = folder and folder:FindFirstChild("Pets")
            if pets then
                for _, pet in pets:GetChildren() do
                    if pet:IsA("Model") and not pet:GetAttribute("Captured") then
                        local rank = RARITY_RANK[pet:GetAttribute("Rarity") or "Common"] or 1
                        local str  = pet:GetAttribute("Strength") or 0
                        local dist = (hrp.Position - pet:GetPivot().Position).Magnitude
                        if rank > bestRank
                            or (rank == bestRank and str > bestStr)
                            or (rank == bestRank and str == bestStr and dist < bestDist)
                        then
                            best, bestRank, bestStr, bestDist = pet, rank, str, dist
                        end
                    end
                end
            end
        end
        return best
    end

    -- Locate ClaimLoginReward under the versioned Knit package
    local function findKnitRE(serviceName, reName)
        local idx = rs:FindFirstChild("Packages") and rs.Packages:FindFirstChild("_Index")
        if not idx then return end
        for _, pkg in idx:GetChildren() do
            local knit = pkg:FindFirstChild("knit")
            if knit then
                local svc = knit:FindFirstChild("Services") and knit.Services:FindFirstChild(serviceName)
                if svc then
                    local re = svc:FindFirstChild("RE") and svc.RE:FindFirstChild(reName)
                    if re then return re end
                end
            end
        end
    end

    local loops = {}

    local function cancelLoop(name)
        if loops[name] then
            task.cancel(loops[name])
            loops[name] = nil
        end
    end

    -- Auto Collect Cash
    elements:Toggle("Auto Collect Cash", section, function(state)
        cancelLoop("cash")
        if state then
            loops.cash = task.spawn(function()
                while task.wait(2) do
                    collectAllCash:FireServer()
                end
            end)
        end
    end)

    local SELL_FILTERS = { typeFilter="All", mutationFilter="All", rarityFilter="All" }

    -- Auto Sell Pets (server skips Exclusive/Secret; task.spawn avoids blocking on the 4s server confirm)
    elements:Toggle("Auto Sell Pets", section, function(state)
        cancelLoop("sellPets")
        if state then
            loops.sellPets = task.spawn(function()
                while task.wait(6) do
                    task.spawn(function()
                        pcall(sellPetRF.InvokeServer, sellPetRF, nil, true, SELL_FILTERS)
                    end)
                end
            end)
        end
    end)

    -- Auto Sell Eggs
    elements:Toggle("Auto Sell Eggs", section, function(state)
        cancelLoop("sellEggs")
        if state then
            loops.sellEggs = task.spawn(function()
                while task.wait(6) do
                    task.spawn(function()
                        pcall(sellEggRF.InvokeServer, sellEggRF, nil, true, SELL_FILTERS)
                    end)
                end
            end)
        end
    end)

    -- Auto Lasso
    elements:Toggle("Auto Lasso", section, function(state)
        cancelLoop("lasso")
        if state then
            loops.lasso = task.spawn(function()
                while task.wait(0.5) do
                    local char = player.Character
                    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then continue end

                    local pet = findBestPet()
                    if not pet or not pet.Parent then continue end

                    -- Teleport within lasso range if too far
                    if (hrp.Position - pet:GetPivot().Position).Magnitude > 25 then
                        hrp.CFrame = pet:GetPivot() * CFrame.new(0, 3, 6)
                        task.wait(0.25)
                    end

                    if not pet.Parent then continue end

                    -- Fire ThrowLasso first (server gates minigameRequest on this)
                    local petPos = pet:GetPivot().Position
                    local rawDir = petPos - hrp.Position
                    local dir    = Vector3.new(rawDir.X, 0, rawDir.Z).Unit
                    throwLasso:FireServer(0.9, dir)
                    task.wait(0.1)

                    if not pet.Parent then continue end

                    local ok, result = pcall(function()
                        return minigameRequest:InvokeServer(pet, pet:GetPivot())
                    end)

                    if ok and result == true then
                        -- StartProgressReporter fires every ~1s; OnClick fires when progress hits 100.
                        -- Server validates realistic timing, so space out updates accordingly.
                        task.wait(0.4)
                        for _, v in {20, 45, 70, 90, 100, 100} do
                            updateProgress:FireServer(v)
                            task.wait(0.8)
                        end
                        task.wait(1)
                    end
                end
            end)
        end
    end)

    -- Claim Daily Reward
    elements:Button("Claim Daily Reward", section, function()
        local re = findKnitRE("DailyRewardsService", "ClaimLoginReward")
        if re then
            re:FireServer()
        end
    end)

    -- Unload
    section.AncestorRemoving:Connect(function()
        for name in loops do
            cancelLoop(name)
        end
    end)
end

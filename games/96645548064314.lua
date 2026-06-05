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

    local RARITY_RANK = {
        Common=1, Rare=2, Epic=3, Legendary=4,
        Mythical=5, Boss=6, Divine=7, Exclusive=8, Secret=9,
    }

    -- All roaming pet folders the lasso can target
    local PET_FOLDERS = {
        "RoamingPets", "SkyIslandPets", "WaterIslandPets", "BeeIslandPets",
        "GalaxyIslandPets", "NewEventIslandPets", "SafariIslandPets",
        "CaveIslandPets", "DeepCavePets", "VolcanoIslandPets",
        "LavaIslandPets", "AbyssIslandPets",
    }

    -- workspace.QuickTravel islands in rough rarity order (weakest → strongest)
    local ISLANDS = {
        "BeeIsland", "SafariIsland", "CaveIsland",
        "VolcanoIsland", "DragonIsland", "ForgottenDepths",
    }

    local function teleportToIsland(name)
        local qt     = workspace:FindFirstChild("QuickTravel")
        local island = qt and qt:FindFirstChild(name)
        local marker = island and island:FindFirstChild("Marker")
        local hrp    = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if marker and hrp then
            hrp.CFrame = marker.CFrame + Vector3.new(0, 8, 0)
            return true
        end
        return false
    end

    -- Returns the nearest uncaptured Boss (or higher) pet across all folders.
    local function findBossPet()
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        local best, bestDist = nil, math.huge
        for _, folderName in PET_FOLDERS do
            local folder = workspace:FindFirstChild(folderName)
            local pets   = folder and folder:FindFirstChild("Pets")
            if pets then
                for _, pet in pets:GetChildren() do
                    if pet:IsA("Model") and not pet:GetAttribute("Captured") then
                        local rank = RARITY_RANK[pet:GetAttribute("Rarity") or "Common"] or 1
                        if rank >= RARITY_RANK.Boss then
                            local dist = (hrp.Position - pet:GetPivot().Position).Magnitude
                            if dist < bestDist then
                                best, bestDist = pet, dist
                            end
                        end
                    end
                end
            end
        end
        return best
    end

    -- Returns the best uncaptured pet across all folders.
    -- Priority: highest rarity → highest strength → closest.
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

    -- Auto Sell Pets (server skips Exclusive/Secret; task.spawn avoids the 4s server confirm block)
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

    -- Pen income display
    -- Pens carry an Owner attribute matching the player's name — no Knit call needed.
    local function getMyPen()
        local pens = workspace:FindFirstChild("PlayerPens")
        if not pens then return nil end
        for _, pen in pens:GetChildren() do
            if pen:GetAttribute("Owner") == player.Name then
                return pen
            end
        end
        return nil
    end

    local function getTotalRPS()
        local pen  = getMyPen()
        local pets = pen and pen:FindFirstChild("Pets")
        if not pets then return 0 end
        local total = 0
        for _, pet in pets:GetChildren() do
            if pet:IsA("Model") then
                total = total + (pet:GetAttribute("RPS") or 0)
            end
        end
        return total
    end

    local function fmtNumber(n)
        if n >= 1e9 then return string.format("%.1fB", n / 1e9)
        elseif n >= 1e6 then return string.format("%.1fM", n / 1e6)
        elseif n >= 1e3 then return string.format("%.1fK", n / 1e3)
        else return string.format("%.0f", n) end
    end

    local rpsLabel = Instance.new("TextLabel")
    rpsLabel.Name               = "LabelElement"
    rpsLabel.Size               = UDim2.new(1, 0, 0, 24)
    rpsLabel.BackgroundTransparency = 1
    rpsLabel.Font               = Enum.Font.Gotham
    rpsLabel.TextSize           = 13
    rpsLabel.TextColor3         = Color3.fromRGB(200, 190, 255)
    rpsLabel.TextXAlignment     = Enum.TextXAlignment.Left
    rpsLabel.Text               = "Pen Income:  $--/s"
    rpsLabel.Parent             = section

    loops.rpsUpdate = task.spawn(function()
        while task.wait(2) do
            if rpsLabel and rpsLabel.Parent then
                rpsLabel.Text = "Pen Income:  $" .. fmtNumber(getTotalRPS()) .. "/s"
            end
        end
    end)

    -- Shared lasso routine used by both Auto Lasso and Boss Hunt.
    -- finder: function() → pet model | nil
    -- loopKey: key in loops table
    -- startIsland: index into ISLANDS to teleport to on enable
    local function startLassoLoop(loopKey, finder, startIsland)
        cancelLoop(loopKey)
        local islandIdx = startIsland
        loops[loopKey] = task.spawn(function()
            teleportToIsland(ISLANDS[islandIdx])
            task.wait(3)
            while task.wait(0.5) do
                local char = player.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then continue end

                local pet = finder()

                if not pet then
                    islandIdx = (islandIdx % #ISLANDS) + 1
                    teleportToIsland(ISLANDS[islandIdx])
                    task.wait(3)
                    continue
                end

                if not pet.Parent then continue end

                if (hrp.Position - pet:GetPivot().Position).Magnitude > 25 then
                    hrp.CFrame = pet:GetPivot() * CFrame.new(0, 3, 6)
                    task.wait(0.25)
                end

                if not pet.Parent then continue end

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

    -- Auto Lasso — targets best available pet, starts at ForgottenDepths
    elements:Toggle("Auto Lasso", section, function(state)
        if state then
            startLassoLoop("lasso", findBestPet, #ISLANDS)
        else
            cancelLoop("lasso")
        end
    end)

    -- Boss Hunt — targets Boss+ rarity only, cycles all islands looking for them
    elements:Toggle("Boss Hunt", section, function(state)
        if state then
            startLassoLoop("bossHunt", findBossPet, #ISLANDS)
        else
            cancelLoop("bossHunt")
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
        if rpsLabel and rpsLabel.Parent then
            rpsLabel:Destroy()
        end
    end)
end

-- Survival Game (PlaceId 126509999114328)

return function(section)
    local elements = getgenv()._astroElements
    local rs  = game:GetService("RunService")
    local lp  = game.Players.LocalPlayer
    local re  = game:GetService("ReplicatedStorage").RemoteEvents

    -- Remotes
    local rfToolDmg  = re:WaitForChild("ToolDamageObject")    -- RF: (model, tool, dmg, hrpCF[, lethal])
    local rfTorch    = re:WaitForChild("MonsterHitByTorch")   -- RF: (enemyModel)
    local rfScrap    = re:WaitForChild("RequestScrapItem")    -- RF: (scrapper, item)
    local evBurn     = re:WaitForChild("RequestBurnItem")     -- RE: (fire, item)
    local evCook     = re:WaitForChild("RequestCookItem")     -- RE: (fire, item)
    local evTameN    = re:WaitForChild("RequestTame_Neutral") -- RE: (animal, tool)
    local evTameH    = re:WaitForChild("RequestTame_Hungry")  -- RE: (animal, tool)
    local evUpgDef   = re:WaitForChild("RequestUpgradeDefense")

    -- ── Helpers ──────────────────────────────────────────────────────────────
    local function getHRP()
        local c = lp.Character
        return c and c:FindFirstChild("HumanoidRootPart")
    end
    local function getHum()
        local c = lp.Character
        return c and c:FindFirstChildOfClass("Humanoid")
    end
    -- Only returns equipped tool — server rejects backpack tools
    local function getEquippedTool()
        local c = lp.Character
        return c and c:FindFirstChildOfClass("Tool")
    end

    local function getCampground()
        local map = workspace:FindFirstChild("Map")
        return map and map:FindFirstChild("Campground")
    end
    local function getFire()
        local cg = getCampground()
        return cg and cg:FindFirstChild("MainFire")
    end
    local function getCrafter()
        local cg = getCampground()
        return cg and cg:FindFirstChild("CraftingBench")
    end
    local function getScrapper()
        local cg = getCampground()
        return cg and cg:FindFirstChild("Scrapper")
    end

    -- Returns CFrame above the fire's InnerTouchZone (where items need to land)
    local function getFireAboveCF()
        local f = getFire()
        if not f then return nil end
        local zone = f:FindFirstChild("InnerTouchZone")
            or f:FindFirstChild("OuterTouchZone")
            or f:FindFirstChildWhichIsA("BasePart")
        return zone and (zone.CFrame + Vector3.new(0, 3, 0))
    end

    -- Moves a Model to a CFrame using PivotTo (works even without PrimaryPart set)
    local function moveModel(model, cf)
        pcall(function() model:PivotTo(cf) end)
    end

    local function ownedItems()
        local result = {}
        local folder = workspace:FindFirstChild("Items")
        if not folder then return result end
        for _, item in pairs(folder:GetChildren()) do
            local owner = item:GetAttribute("Owner")
            if owner == nil or owner == lp.UserId then
                table.insert(result, item)
            end
        end
        return result
    end

    -- ── Cleanup ───────────────────────────────────────────────────────────────
    local conns  = {}
    local active = {}

    local function cleanup()
        for _, c in pairs(conns) do pcall(function() c:Disconnect() end) end
        conns = {}
        for k in pairs(active) do active[k] = false end
    end
    local function addConn(c) table.insert(conns, c) end

    -- ════════════════════════════════════════════════════════════════════════
    --  COMBAT
    -- ════════════════════════════════════════════════════════════════════════
    elements:Label("━━━━  COMBAT  ━━━━", section)

    -- Kill Aura — passes the enemy MODEL (has HitRegisters + Health on model)
    local killLast = 0
    elements:Toggle("Kill Aura", section, function(v)
        active.kill = v
        if not v then return end
        addConn(rs.Heartbeat:Connect(function()
            if not active.kill then return end
            if time() - killLast < 0.25 then return end
            killLast = time()
            local hrp  = getHRP()
            local tool = getEquippedTool()
            if not hrp or not tool then return end
            local chars = workspace:FindFirstChild("Characters")
            if not chars then return end
            for _, enemy in pairs(chars:GetChildren()) do
                local hp = enemy:GetAttribute("Health")
                if hp and hp > 0 and not enemy:GetAttribute("Dead") then
                    local root = enemy:FindFirstChild("HumanoidRootPart")
                        or enemy.PrimaryPart
                        or enemy:FindFirstChildWhichIsA("BasePart")
                    if root and (root.Position - hrp.Position).Magnitude <= 20 then
                        task.spawn(function()
                            rfToolDmg:InvokeServer(enemy, tool, 9999, hrp.CFrame)
                        end)
                    end
                end
            end
        end))
    end)

    -- Chop Aura — passes the tree MODEL (has HitRegisters + Health on model)
    local chopAuraLast = 0
    elements:Toggle("Chop Aura", section, function(v)
        active.chopAura = v
        if not v then return end
        addConn(rs.Heartbeat:Connect(function()
            if not active.chopAura then return end
            if time() - chopAuraLast < 0.5 then return end
            chopAuraLast = time()
            local hrp  = getHRP()
            local tool = getEquippedTool()
            if not hrp or not tool then return end
            local foliage = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Foliage")
            if not foliage then return end
            for _, tree in pairs(foliage:GetChildren()) do
                local hp = tree:GetAttribute("Health") or 0
                if tree:FindFirstChild("HitRegisters") and hp > 0 then
                    local pivot = tree:GetPivot()
                    if (pivot.Position - hrp.Position).Magnitude <= 30 then
                        local dmg    = tool:GetAttribute("WeaponResourceDamage") or 10
                        local lethal = hp <= dmg
                        task.spawn(function()
                            rfToolDmg:InvokeServer(tree, tool, dmg, hrp.CFrame, lethal)
                        end)
                    end
                end
            end
        end))
    end)

    -- Auto Chop Trees — teleports to each tree and passes the tree MODEL
    elements:Toggle("Auto Chop Trees", section, function(v)
        active.chopAll = v
        if not v then return end
        task.spawn(function()
            while active.chopAll do
                local hrp  = getHRP()
                local tool = getEquippedTool()
                if hrp and tool then
                    local foliage = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Foliage")
                    if foliage then
                        for _, tree in pairs(foliage:GetChildren()) do
                            if not active.chopAll then break end
                            local hp = tree:GetAttribute("Health") or 0
                            if tree:FindFirstChild("HitRegisters") and hp > 0 then
                                local pivot = tree:GetPivot()
                                hrp.CFrame = CFrame.new(pivot.Position + Vector3.new(3, 0, 0))
                                task.wait(0.1)
                                local dmg    = tool:GetAttribute("WeaponResourceDamage") or 10
                                local lethal = hp <= dmg
                                task.spawn(function()
                                    rfToolDmg:InvokeServer(tree, tool, dmg, hrp.CFrame, lethal)
                                end)
                                task.wait(0.35)
                            end
                        end
                    end
                end
                task.wait(0.5)
            end
        end)
    end)

    -- Auto Stun Deer / Owl
    local stunLast = 0
    elements:Toggle("Auto Stun (Deer / Owl)", section, function(v)
        active.stun = v
        if not v then return end
        addConn(rs.Heartbeat:Connect(function()
            if not active.stun then return end
            if time() - stunLast < 0.5 then return end
            stunLast = time()
            local hrp = getHRP()
            if not hrp then return end
            local chars = workspace:FindFirstChild("Characters")
            if not chars then return end
            for _, enemy in pairs(chars:GetChildren()) do
                local name = enemy.Name
                if (name:find("Deer") or name:find("Owl") or name:find("Ram")) and
                    not enemy:GetAttribute("Dead") then
                    local root = enemy:FindFirstChild("HumanoidRootPart")
                        or enemy.PrimaryPart
                        or enemy:FindFirstChildWhichIsA("BasePart")
                    if root and (root.Position - hrp.Position).Magnitude <= 30 then
                        task.spawn(function() rfTorch:InvokeServer(enemy) end)
                    end
                end
            end
        end))
    end)

    -- God Mode — health setter + auto-revive on death (server health is authoritative,
    -- so the revive remote is the reliable part; health setting helps against client-checked damage)
    local evRevive = re:WaitForChild("RequestSelfRevive")
    local function bindGodMode()
        if not active.god then return end
        local char = lp.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        -- try to keep health maxed locally (catches client-side damage checks)
        addConn(hum.HealthChanged:Connect(function()
            if active.god then
                pcall(function() hum.Health = hum.MaxHealth end)
            end
        end))
        -- when we actually die, revive instantly
        addConn(hum.Died:Connect(function()
            if active.god then
                task.wait(0.1)
                pcall(function() evRevive:FireServer() end)
            end
        end))
    end
    elements:Toggle("God Mode", section, function(v)
        active.god = v
        if not v then return end
        bindGodMode()
        -- re-bind on respawn
        addConn(lp.CharacterAdded:Connect(function()
            task.wait(1)
            bindGodMode()
        end))
    end)

    -- Auto Tame Animals
    local tameLast = 0
    elements:Toggle("Auto Tame Animals", section, function(v)
        active.tame = v
        if not v then return end
        addConn(rs.Heartbeat:Connect(function()
            if not active.tame then return end
            if time() - tameLast < 1 then return end
            tameLast = time()
            local hrp  = getHRP()
            local tool = getEquippedTool()
            if not hrp or not tool then return end
            local chars = workspace:FindFirstChild("Characters")
            if not chars then return end
            for _, animal in pairs(chars:GetChildren()) do
                local state = animal:GetAttribute("CurrentTamingState")
                if (state == "Neutral" or state == "Hungry") and not animal:GetAttribute("TamedBy") then
                    local root = animal:FindFirstChild("HumanoidRootPart")
                        or animal.PrimaryPart
                        or animal:FindFirstChildWhichIsA("BasePart")
                    if root and (root.Position - hrp.Position).Magnitude <= 25 then
                        if state == "Neutral" then
                            evTameN:FireServer(animal, tool)
                        else
                            evTameH:FireServer(animal, tool)
                        end
                    end
                end
            end
        end))
    end)

    -- ════════════════════════════════════════════════════════════════════════
    --  FARMING / ITEMS
    -- ════════════════════════════════════════════════════════════════════════
    elements:Label("━━━━  FARMING  ━━━━", section)

    -- Bring Items to Camp
    elements:Button("Bring Items to Camp", section, function()
        local hrp = getHRP()
        if not hrp then return end
        local dest = hrp.CFrame + Vector3.new(0, 2, 0)
        for _, item in pairs(ownedItems()) do
            moveModel(item, dest)
            dest = dest + Vector3.new(2, 0, 0)
        end
    end)

    -- TP Wood to Fire — moves each wood item above InnerTouchZone then fires remote
    elements:Button("TP Wood to Fire", section, function()
        local fire = getFire()
        local aboveCF = getFireAboveCF()
        if not fire or not aboveCF then warn("[Astro] MainFire not found") return end
        for _, item in pairs(ownedItems()) do
            if item:GetAttribute("BurnFuel") then
                moveModel(item, aboveCF)
                task.wait(0.05)
                evBurn:FireServer(fire, item)
            end
        end
    end)

    -- TP Wood to Crafter — stacks wood items on top of CraftingBench
    elements:Button("TP Wood to Crafter", section, function()
        local crafter = getCrafter()
        if not crafter then warn("[Astro] CraftingBench not found") return end
        local baseCF = crafter:GetPivot() + Vector3.new(0, 3, 0)
        local offset = 0
        for _, item in pairs(ownedItems()) do
            if item:GetAttribute("BurnFuel") then
                moveModel(item, baseCF + Vector3.new(offset, 0, 0))
                offset = offset + 1.5
            end
        end
    end)

    -- TP Meat to Fire — moves each cookable item above InnerTouchZone then fires remote
    elements:Button("TP Meat to Fire", section, function()
        local fire = getFire()
        local aboveCF = getFireAboveCF()
        if not fire or not aboveCF then warn("[Astro] MainFire not found") return end
        for _, item in pairs(ownedItems()) do
            if item:GetAttribute("Cookable") then
                moveModel(item, aboveCF)
                task.wait(0.05)
                evCook:FireServer(fire, item)
            end
        end
    end)

    -- Auto Scrap Junk
    elements:Toggle("Auto Scrap Junk", section, function(v)
        active.scrap = v
        if not v then return end
        task.spawn(function()
            while active.scrap do
                local scrapper = getScrapper()
                if scrapper then
                    local scrapCF = scrapper:GetPivot() + Vector3.new(0, 2, 0)
                    for _, item in pairs(ownedItems()) do
                        if not active.scrap then break end
                        if item:GetAttribute("Scrappable") or
                           item:HasTag("CanBeGrinded") or
                           item:HasTag("Gem") or
                           item:HasTag("GreenGem") then
                            moveModel(item, scrapCF)
                            task.wait(0.1)
                            task.spawn(function()
                                rfScrap:InvokeServer(scrapper, item)
                            end)
                            task.wait(0.3)
                        end
                    end
                end
                task.wait(1)
            end
        end)
    end)

    -- ════════════════════════════════════════════════════════════════════════
    --  BASE / UPGRADES
    -- ════════════════════════════════════════════════════════════════════════
    elements:Label("━━━━  BASE  ━━━━", section)

    elements:Button("Upgrade Defenses", section, function()
        local structs = workspace:FindFirstChild("Structures")
        if not structs then warn("[Astro] Structures not found") return end
        for _, s in pairs(structs:GetDescendants()) do
            if s:IsA("BasePart") and s:GetAttribute("Owner") == lp.UserId then
                task.spawn(function() evUpgDef:FireServer(s) end)
                task.wait(0.1)
            end
        end
    end)

    -- ════════════════════════════════════════════════════════════════════════
    --  CLEANUP
    -- ════════════════════════════════════════════════════════════════════════
    section.AncestorRemoving:Connect(cleanup)
end

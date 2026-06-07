-- Survival Game (PlaceId 126509999114328)

return function(section)
    local elements = getgenv()._astroElements
    local rs  = game:GetService("RunService")
    local lp  = game.Players.LocalPlayer
    local re  = game:GetService("ReplicatedStorage").RemoteEvents

    -- Remotes
    local rfToolDmg    = re:WaitForChild("ToolDamageObject")     -- RF
    local rfTorch      = re:WaitForChild("MonsterHitByTorch")    -- RF
    local rfScrap      = re:WaitForChild("RequestScrapItem")     -- RF: (scrapper, item)
    local evBurnItem   = re:WaitForChild("RequestBurnItem")      -- RE: (fire, item)
    local evCookItem   = re:WaitForChild("RequestCookItem")      -- RE: (fire, item)
    local evTameN      = re:WaitForChild("RequestTame_Neutral")  -- RE: (animal, fluteModel)
    local evTameH      = re:WaitForChild("RequestTame_Hungry")   -- RE: (animal, fluteModel)

    -- ── Helpers ──────────────────────────────────────────────────────────────
    local function getHRP()
        local c = lp.Character
        return c and c:FindFirstChild("HumanoidRootPart")
    end
    local function getHum()
        local c = lp.Character
        return c and c:FindFirstChildOfClass("Humanoid")
    end
    local function getTool()
        local c = lp.Character
        if c then
            local t = c:FindFirstChildOfClass("Tool")
            if t then return t end
        end
        return lp.Backpack:FindFirstChildOfClass("Tool")
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
    local function getFirePos()
        local f = getFire()
        if not f then return nil end
        local pp = f.PrimaryPart or f:FindFirstChildWhichIsA("BasePart")
        return pp and pp.CFrame
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

    -- ── Cleanup tracking ─────────────────────────────────────────────────────
    local conns  = {}
    local active = {}   -- boolean flags keyed by name

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

    -- Kill Aura
    local killLast = 0
    elements:Toggle("Kill Aura", section, function(v)
        active.kill = v
        if not v then return end
        addConn(rs.Heartbeat:Connect(function()
            if not active.kill then return end
            if time() - killLast < 0.25 then return end
            killLast = time()
            local hrp  = getHRP()
            local tool = getTool()
            if not hrp or not tool then return end
            local chars = workspace:FindFirstChild("Characters")
            if not chars then return end
            for _, enemy in pairs(chars:GetChildren()) do
                if enemy:GetAttribute("Health") and
                   enemy:GetAttribute("Health") > 0 and
                   not enemy:GetAttribute("Dead") then
                    local root = enemy:FindFirstChild("HumanoidRootPart")
                        or enemy.PrimaryPart
                        or enemy:FindFirstChildWhichIsA("BasePart")
                    if root and (root.Position - hrp.Position).Magnitude <= 20 then
                        task.spawn(function()
                            rfToolDmg:InvokeServer(root, tool, 9999, hrp.CFrame)
                        end)
                    end
                end
            end
        end))
    end)

    -- Chop Aura  (damages nearby trees without teleporting)
    local chopLast = 0
    elements:Toggle("Chop Aura", section, function(v)
        active.chop = v
        if not v then return end
        addConn(rs.Heartbeat:Connect(function()
            if not active.chop then return end
            if time() - chopLast < 0.5 then return end
            chopLast = time()
            local hrp  = getHRP()
            local tool = getTool()
            if not hrp or not tool then return end
            local foliage = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Foliage")
            if not foliage then return end
            for _, tree in pairs(foliage:GetChildren()) do
                local hp = tree:GetAttribute("Health") or 0
                if tree:FindFirstChild("HitRegisters") and hp > 0 then
                    local trunk = tree:FindFirstChild("Trunk")
                        or tree.PrimaryPart
                        or tree:FindFirstChildWhichIsA("BasePart")
                    if trunk and (trunk.Position - hrp.Position).Magnitude <= 30 then
                        local dmg    = tool:GetAttribute("WeaponResourceDamage") or 10
                        local lethal = hp <= dmg
                        task.spawn(function()
                            rfToolDmg:InvokeServer(trunk, tool, dmg, hrp.CFrame, lethal)
                        end)
                    end
                end
            end
        end))
    end)

    -- Auto Chop Trees  (teleports to each tree, no radius limit)
    elements:Toggle("Auto Chop Trees", section, function(v)
        active.chopAll = v
        if not v then return end
        task.spawn(function()
            while active.chopAll do
                local hrp  = getHRP()
                local tool = getTool()
                if hrp and tool then
                    local foliage = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Foliage")
                    if foliage then
                        for _, tree in pairs(foliage:GetChildren()) do
                            if not active.chopAll then break end
                            local hp = tree:GetAttribute("Health") or 0
                            if tree:FindFirstChild("HitRegisters") and hp > 0 then
                                local trunk = tree:FindFirstChild("Trunk")
                                    or tree.PrimaryPart
                                    or tree:FindFirstChildWhichIsA("BasePart")
                                if trunk then
                                    hrp.CFrame = CFrame.new(trunk.Position + Vector3.new(3, 0, 0))
                                    task.wait(0.1)
                                    local dmg    = tool:GetAttribute("WeaponResourceDamage") or 10
                                    local lethal = hp <= dmg
                                    task.spawn(function()
                                        rfToolDmg:InvokeServer(trunk, tool, dmg, hrp.CFrame, lethal)
                                    end)
                                    task.wait(0.35)
                                end
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
                        task.spawn(function()
                            rfTorch:InvokeServer(enemy)
                        end)
                    end
                end
            end
        end))
    end)

    -- God Mode
    elements:Toggle("God Mode", section, function(v)
        active.god = v
        if not v then return end
        addConn(rs.Heartbeat:Connect(function()
            if not active.god then return end
            local hum = getHum()
            if hum and hum.Health < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
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
            local tool = getTool()
            if not hrp or not tool then return end
            local chars = workspace:FindFirstChild("Characters")
            if not chars then return end
            for _, animal in pairs(chars:GetChildren()) do
                local state = animal:GetAttribute("CurrentTamingState")
                if (state == "Neutral" or state == "Hungry") and
                    not animal:GetAttribute("TamedBy") then
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

    -- Bring Items to Camp (teleport all owned workspace items to player)
    elements:Button("Bring Items to Camp", section, function()
        local hrp = getHRP()
        if not hrp then return end
        local dest = hrp.CFrame + Vector3.new(0, 2, 0)
        for _, item in pairs(ownedItems()) do
            local pp = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
            if pp then
                item:SetPrimaryPartCFrame(dest)
                dest = dest + Vector3.new(2, 0, 0)
            end
        end
    end)

    -- TP Wood to Fire
    elements:Button("TP Wood to Fire", section, function()
        local fire = getFire()
        local fp   = getFirePos()
        if not fire or not fp then warn("[Astro] MainFire not found") return end
        for _, item in pairs(ownedItems()) do
            if item:GetAttribute("BurnFuel") then
                local pp = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
                if pp then item:SetPrimaryPartCFrame(fp + Vector3.new(0, 1, 0)) task.wait(0.05) end
                evBurnItem:FireServer(fire, item)
            end
        end
    end)

    -- TP Wood to Crafter
    elements:Button("TP Wood to Crafter", section, function()
        local crafter = getCrafter()
        if not crafter then warn("[Astro] CraftingBench not found") return end
        local cp = crafter.PrimaryPart or crafter:FindFirstChildWhichIsA("BasePart")
        if not cp then return end
        local dest = cp.CFrame + Vector3.new(0, 2, 0)
        for _, item in pairs(ownedItems()) do
            if item:GetAttribute("BurnFuel") then
                local pp = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
                if pp then
                    item:SetPrimaryPartCFrame(dest)
                    dest = dest + Vector3.new(1.5, 0, 0)
                end
            end
        end
    end)

    -- TP Meat to Fire
    elements:Button("TP Meat to Fire", section, function()
        local fire = getFire()
        local fp   = getFirePos()
        if not fire or not fp then warn("[Astro] MainFire not found") return end
        for _, item in pairs(ownedItems()) do
            if item:GetAttribute("Cookable") then
                local pp = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
                if pp then item:SetPrimaryPartCFrame(fp + Vector3.new(0, 1, 0)) task.wait(0.05) end
                evCookItem:FireServer(fire, item)
            end
        end
    end)

    -- Auto Scrap Junk  (teleports scrappable items into the Scrapper)
    elements:Toggle("Auto Scrap Junk", section, function(v)
        active.scrap = v
        if not v then return end
        task.spawn(function()
            while active.scrap do
                local scrapper = getScrapper()
                if scrapper then
                    local sp = scrapper.PrimaryPart or scrapper:FindFirstChildWhichIsA("BasePart")
                    if sp then
                        for _, item in pairs(ownedItems()) do
                            if not active.scrap then break end
                            if item:GetAttribute("Scrappable") or
                               item:HasTag("CanBeGrinded") or
                               item:HasTag("Gem") or
                               item:HasTag("GreenGem") then
                                local pp = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
                                if pp then
                                    item:SetPrimaryPartCFrame(sp.CFrame + Vector3.new(0, 2, 0))
                                    task.wait(0.1)
                                end
                                task.spawn(function()
                                    rfScrap:InvokeServer(scrapper, item)
                                end)
                                task.wait(0.3)
                            end
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

    -- Auto Upgrade Defenses  (fires upgrade remote for each owned defense part)
    local evUpgDef = re:WaitForChild("RequestUpgradeDefense")
    elements:Button("Upgrade Defenses", section, function()
        local structs = workspace:FindFirstChild("Structures")
        if not structs then warn("[Astro] Structures folder not found") return end
        for _, s in pairs(structs:GetDescendants()) do
            if s:IsA("BasePart") and s:GetAttribute("Owner") == lp.UserId then
                task.spawn(function()
                    evUpgDef:FireServer(s)
                end)
                task.wait(0.1)
            end
        end
    end)

    -- ════════════════════════════════════════════════════════════════════════
    --  CLEANUP
    -- ════════════════════════════════════════════════════════════════════════
    section.AncestorRemoving:Connect(cleanup)
end

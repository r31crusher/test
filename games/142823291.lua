-- Murder Mystery 2 (PlaceId 142823291)

return function(section)
    local elements = getgenv()._astroElements
    local Players  = game:GetService("Players")
    local RS       = game:GetService("ReplicatedStorage")
    local RunSvc   = game:GetService("RunService")
    local player   = Players.LocalPlayer

    local Remotes      = RS:WaitForChild("Remotes")
    local GameplayR    = Remotes:WaitForChild("Gameplay")
    local GiveWeapon   = GameplayR:WaitForChild("GiveWeapon")
    local ShowTeammates= GameplayR:WaitForChild("ShowTeammates")
    local CoinsStarted = GameplayR:WaitForChild("CoinsStarted")
    local GetCoin      = GameplayR:WaitForChild("GetCoin")

    -- WeaponService module (provides GetMouseTargetCFrame used by gun tools)
    local WeaponService = require(RS:WaitForChild("ClientServices"):WaitForChild("WeaponService"))

    local rng = Random.new()
    local function j(base, jitter)
        jitter = jitter or 0.2
        return base * (1 + (rng:NextNumber() * 2 - 1) * jitter)
    end

    local _threads = {}
    local function spawn(fn)
        local t = task.spawn(fn)
        table.insert(_threads, t)
        return t
    end

    -- ── Role detection ────────────────────────────────────────────────────────
    -- GiveWeapon only fires to the local player for their own role, so we cannot
    -- use remote events to learn other players' roles. Instead we read the
    -- CollectionService tags that the game applies to weapon tools — "Weapon_Knife"
    -- = murderer, "Weapon_Gun" = sheriff. These tags replicate to all clients, so
    -- checking any player's character (or backpack) is reliable.
    local function getRole(p)
        for _, container in { p.Character, p.Backpack } do
            if container then
                for _, obj in container:GetChildren() do
                    if obj:IsA("Tool") then
                        if obj:HasTag("Weapon_Knife") then return "Murderer" end
                        if obj:HasTag("Weapon_Gun")   then return "Sheriff"  end
                    end
                end
            end
        end
        return "Innocent"
    end

    local _roleConns = {}

    -- Still listen to ShowTeammates for modes where multiple murderers exist and
    -- one may not have their knife visible yet. Store as a supplement.
    local _knownMurderers = {}
    table.insert(_roleConns, ShowTeammates.OnClientEvent:Connect(function(names)
        for _, name in ipairs(names) do
            _knownMurderers[name] = true
        end
    end))
    table.insert(_roleConns, GameplayR:WaitForChild("RoundStart").OnClientEvent:Connect(function()
        _knownMurderers = {}
    end))

    -- Wrap getRole so ShowTeammates data acts as a fallback
    local function getPlayerRole(p)
        local r = getRole(p)
        if r ~= "Innocent" then return r end
        if _knownMurderers[p.Name] then return "Murderer" end
        return "Innocent"
    end

    -- ── Silent Aim ────────────────────────────────────────────────────────────
    -- Hook WeaponService:GetMouseTargetCFrame so the gun always points at the
    -- nearest enemy player's HumanoidRootPart.
    getgenv()._mm2_silentaim = false
    local origGetTarget = WeaponService.GetMouseTargetCFrame

    -- When true, silent aim only locks onto known murderers (sheriff use-case)
    getgenv()._mm2_sheriffonly = false

    local function nearestEnemy()
        local myChar = player.Character
        if not myChar then return nil end
        local myHRP = myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return nil end
        local best, bestDist = nil, math.huge
        for _, p in Players:GetPlayers() do
            if p ~= player and p.Character then
                -- If sheriff-only flag is set, skip anyone not the murderer
                if getgenv()._mm2_sheriffonly and getPlayerRole(p) ~= "Murderer" then
                    continue
                end
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local d = (hrp.Position - myHRP.Position).Magnitude
                    if d < bestDist then
                        best, bestDist = hrp, d
                    end
                end
            end
        end
        return best
    end

    WeaponService.GetMouseTargetCFrame = function(self)
        if getgenv()._mm2_silentaim then
            local hrp = nearestEnemy()
            if hrp then
                return CFrame.new(hrp.Position)
            end
        end
        return origGetTarget(self)
    end

    elements:Toggle("Silent Aim", section, function(v)
        getgenv()._mm2_silentaim = v
    end)

    -- Sheriff Only: silent aim targets only known murderers instead of nearest player
    elements:Toggle("Sheriff Only (aim murderer)", section, function(v)
        getgenv()._mm2_sheriffonly = v
    end)

    -- ── Player ESP ────────────────────────────────────────────────────────────
    -- BillboardGui above each player's head showing their role and distance.
    getgenv()._mm2_esp = false
    local espBills = {}

    local ROLE_COLOR = {
        Murderer = Color3.fromRGB(255, 60, 60),
        Sheriff  = Color3.fromRGB(80, 180, 255),
        Innocent = Color3.fromRGB(200, 200, 200),
    }

    local function makeESPFor(p)
        if p == player then return end
        local function attach()
            local char = p.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local bb = Instance.new("BillboardGui")
            bb.Name = "_mm2esp"
            bb.Size = UDim2.new(0, 120, 0, 40)
            bb.StudsOffset = Vector3.new(0, 3, 0)
            bb.AlwaysOnTop = true
            bb.Adornee = hrp
            bb.Parent = game.CoreGui

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 13
            lbl.TextStrokeTransparency = 0
            lbl.Parent = bb

            espBills[p] = { bb = bb, lbl = lbl, hrp = hrp }
        end

        attach()
        p.CharacterAdded:Connect(function()
            task.wait(0.5)
            if espBills[p] then
                espBills[p].bb:Destroy()
                espBills[p] = nil
            end
            if getgenv()._mm2_esp then attach() end
        end)
    end

    local function removeESPFor(p)
        if espBills[p] then
            espBills[p].bb:Destroy()
            espBills[p] = nil
        end
    end

    local _espRender
    local _espPlayerAdded, _espPlayerRemoving

    local function startESP()
        for _, p in Players:GetPlayers() do
            makeESPFor(p)
        end
        _espPlayerAdded = Players.PlayerAdded:Connect(makeESPFor)
        _espPlayerRemoving = Players.PlayerRemoving:Connect(removeESPFor)

        _espRender = RunSvc.RenderStepped:Connect(function()
            local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            for p, data in pairs(espBills) do
                if not data.bb.Parent then
                    espBills[p] = nil
                    continue
                end
                local role = getPlayerRole(p)
                local dist = myHRP and math.floor((data.hrp.Position - myHRP.Position).Magnitude) or 0
                data.lbl.Text = string.format("[%s] %s\n%dm", role, p.Name, dist)
                data.lbl.TextColor3 = ROLE_COLOR[role] or ROLE_COLOR.Innocent
            end
        end)
    end

    local function stopESP()
        if _espRender then _espRender:Disconnect() _espRender = nil end
        if _espPlayerAdded then _espPlayerAdded:Disconnect() _espPlayerAdded = nil end
        if _espPlayerRemoving then _espPlayerRemoving:Disconnect() _espPlayerRemoving = nil end
        for p, data in pairs(espBills) do
            data.bb:Destroy()
            espBills[p] = nil
        end
    end

    elements:Toggle("Player ESP", section, function(v)
        getgenv()._mm2_esp = v
        if v then startESP() else stopESP() end
    end)

    -- ── Role Reveal (console) ─────────────────────────────────────────────────
    -- Prints murderer names to dev console when ShowTeammates fires.
    getgenv()._mm2_rolereveal = false
    table.insert(_roleConns, ShowTeammates.OnClientEvent:Connect(function(names)
        if not getgenv()._mm2_rolereveal then return end
        for _, name in ipairs(names) do
            print("[MM2] Murderer detected:", name)
        end
    end))
    -- Also scan all players by weapon tag on demand each second
    table.insert(_roleConns, RunSvc.Heartbeat:Connect(function()
        if not getgenv()._mm2_rolereveal then return end
        for _, p in Players:GetPlayers() do
            if p ~= player then
                local role = getPlayerRole(p)
                if role ~= "Innocent" then
                    -- only print once per role assignment (stored in _knownMurderers for murderers)
                    if role == "Murderer" and not _knownMurderers[p.Name .. "_printed"] then
                        _knownMurderers[p.Name .. "_printed"] = true
                        print("[MM2]", role, "->", p.Name)
                    end
                end
            end
        end
    end))

    elements:Toggle("Role Reveal (console)", section, function(v)
        getgenv()._mm2_rolereveal = v
    end)

    -- ── Auto Coin Collect ─────────────────────────────────────────────────────
    -- When CoinsStarted fires the server spawns coin parts in workspace.
    -- The client fires GetCoin with the coin's CFrame to collect it.
    getgenv()._mm2_coins = false
    local _coinConn

    local function collectCoins()
        -- Coins are typically parented under workspace or a "Coins" folder
        local function tryCollect(obj)
            if obj:IsA("BasePart") and obj.Name == "Coin" then
                pcall(function() GetCoin:FireServer(obj.CFrame) end)
            end
        end

        -- Collect any already-spawned coins
        local coinsFolder = workspace:FindFirstChild("Coins") or workspace
        for _, obj in ipairs(coinsFolder:GetDescendants()) do
            if not getgenv()._mm2_coins then break end
            tryCollect(obj)
            task.wait(j(0.08, 0.3))
        end

        -- Watch for new ones
        _coinConn = workspace.DescendantAdded:Connect(function(obj)
            if not getgenv()._mm2_coins then
                if _coinConn then _coinConn:Disconnect() _coinConn = nil end
                return
            end
            task.wait(0.05)
            tryCollect(obj)
        end)
    end

    elements:Toggle("Auto Coin Collect", section, function(v)
        getgenv()._mm2_coins = v
        if v then
            spawn(collectCoins)
        else
            if _coinConn then _coinConn:Disconnect() _coinConn = nil end
        end
    end)

    -- ── Speed ─────────────────────────────────────────────────────────────────
    getgenv()._mm2_speed = false
    local DEFAULT_SPEED = 16
    local FAST_SPEED    = 32

    local _speedConn

    elements:Toggle("Speed Hack", section, function(v)
        getgenv()._mm2_speed = v
        if v then
            _speedConn = RunSvc.Heartbeat:Connect(function()
                local char = player.Character
                local hum  = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = FAST_SPEED end
            end)
        else
            if _speedConn then _speedConn:Disconnect() _speedConn = nil end
            local char = player.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = DEFAULT_SPEED end
        end
    end)

    -- ── Unload ────────────────────────────────────────────────────────────────
    section.AncestorRemoving:Connect(function()
        getgenv()._mm2_silentaim   = false
        getgenv()._mm2_sheriffonly = false
        getgenv()._mm2_esp         = false
        getgenv()._mm2_rolereveal = false
        getgenv()._mm2_coins      = false
        getgenv()._mm2_speed      = false

        -- Restore original aim function
        WeaponService.GetMouseTargetCFrame = origGetTarget

        stopESP()

        if _coinConn then _coinConn:Disconnect() _coinConn = nil end
        if _speedConn then _speedConn:Disconnect() _speedConn = nil end

        for _, conn in ipairs(_roleConns) do conn:Disconnect() end
        table.clear(_roleConns)

        for _, t in ipairs(_threads) do pcall(task.cancel, t) end
        table.clear(_threads)

        local char = player.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = DEFAULT_SPEED end
    end)
end

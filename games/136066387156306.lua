-- Be Flash for Brainrots (PlaceId 136066387156306)

return function(section)
    local elements = getgenv()._astroElements

    local rs     = game:GetService("ReplicatedStorage")
    local player = game:GetService("Players").LocalPlayer

    local evDash     = rs:WaitForChild("DashEvent")
    local evTrain    = rs.Events:WaitForChild("TrainTreadmillEvent")
    local evSell     = rs.Remotes:WaitForChild("SellEvent")
    local evRebirth  = rs.RemoteGUI:WaitForChild("URebirth")
    local fnStorm    = rs.Events:WaitForChild("StormBreakerChargeFunction")
    local evBonus    = rs:WaitForChild("BonusClaimRemote")

    local loops = {}
    local function cancelLoop(name)
        if loops[name] then task.cancel(loops[name]); loops[name] = nil end
    end

    -- ── Auto Train ────────────────────────────────────────────────────────────
    -- TrainTreadmillEvent:FireServer(qteHit) fires every second while on treadmill.
    -- The qteHit bool is fully client-controlled — server applies 2x multiplier on true.
    -- Always sending true gives permanent 2x income without clicking any QTE buttons.
    elements:Toggle("Auto Train (2x QTE)", section, function(state)
        cancelLoop("train")
        if not state then return end
        loops.train = task.spawn(function()
            while task.wait(1) do
                pcall(evTrain.FireServer, evTrain, true)
            end
        end)
    end)

    -- ── Auto Charge ───────────────────────────────────────────────────────────
    -- Server validates player is inside ChargeZoneTrigger before accepting StartCharge.
    -- Teleport into the zone first, then run the charge sequence.
    local chargeZone = workspace:WaitForChild("Map"):WaitForChild("Plot")
        :WaitForChild("ChargeZoneGroup"):WaitForChild("ChargeZoneTrigger")

    elements:Toggle("Auto Charge", section, function(state)
        cancelLoop("charge")
        if not state then return end
        loops.charge = task.spawn(function()
            while task.wait(4) do
                local char = player.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and chargeZone then
                    hrp.CFrame = CFrame.new(chargeZone.Position + Vector3.new(0, 3, 0))
                    task.wait(0.3)
                end
                pcall(evDash.FireServer, evDash, "StartCharge")
                task.wait(0.2)
                pcall(evDash.FireServer, evDash, 3)
                task.wait(0.2)
                pcall(evDash.FireServer, evDash, "EndWarp")
            end
        end)
    end)

    -- ── Auto Sell ─────────────────────────────────────────────────────────────
    -- Hitbox uses TouchTransmitter so the server validates via touch events.
    -- firetouchinterest registers the player as inside the zone before selling.
    local sellHitbox = workspace:WaitForChild("Map"):WaitForChild("Shops")
        :WaitForChild("Sell"):WaitForChild("Hitbox")

    elements:Toggle("Auto Sell", section, function(state)
        cancelLoop("sell")
        if not state then return end
        loops.sell = task.spawn(function()
            while task.wait(3) do
                local char = player.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and sellHitbox then
                    hrp.CFrame = CFrame.new(sellHitbox.Position + Vector3.new(0, 3, 0))
                    task.wait(0.2)
                    pcall(firetouchinterest, sellHitbox, hrp, 0)
                    task.wait(0.2)
                    pcall(evSell.FireServer, evSell, "All")
                    task.wait(0.1)
                    pcall(firetouchinterest, sellHitbox, hrp, 1)
                end
            end
        end)
    end)

    -- ── Auto Rebirth ──────────────────────────────────────────────────────────
    elements:Toggle("Auto Rebirth", section, function(state)
        cancelLoop("rebirth")
        if not state then return end
        loops.rebirth = task.spawn(function()
            while task.wait(5) do
                pcall(evRebirth.FireServer, evRebirth)
            end
        end)
    end)

    -- ── Auto StormBreaker ─────────────────────────────────────────────────────
    -- Offer currency to charge the Storm Breaker.
    -- Amount selector: 100Qi < 100Sx < 100Sp (use highest you can afford).
    local stormAmount = "100Qi"

    local stormLabel = Instance.new("TextLabel")
    stormLabel.Name               = "LabelElement"
    stormLabel.Size               = UDim2.new(1, 0, 0, 24)
    stormLabel.BackgroundTransparency = 1
    stormLabel.Font               = Enum.Font.Gotham
    stormLabel.TextSize           = 13
    stormLabel.TextColor3         = Color3.fromRGB(200, 190, 255)
    stormLabel.TextXAlignment     = Enum.TextXAlignment.Left
    stormLabel.Text               = "Storm offer:  100Qi"
    stormLabel.Parent             = section

    elements:Button("Offer 100Qi", section, function()
        stormAmount = "100Qi"
        stormLabel.Text = "Storm offer:  100Qi"
    end)
    elements:Button("Offer 100Sx", section, function()
        stormAmount = "100Sx"
        stormLabel.Text = "Storm offer:  100Sx"
    end)
    elements:Button("Offer 100Sp", section, function()
        stormAmount = "100Sp"
        stormLabel.Text = "Storm offer:  100Sp"
    end)

    elements:Toggle("Auto StormBreaker", section, function(state)
        cancelLoop("storm")
        if not state then return end
        loops.storm = task.spawn(function()
            while task.wait(2) do
                pcall(fnStorm.InvokeServer, fnStorm, "Pay", stormAmount)
            end
        end)
    end)

    elements:Button("Claim Bonus", section, function()
        pcall(evBonus.FireServer, evBonus)
    end)

    -- ── Unload ────────────────────────────────────────────────────────────────
    section.AncestorRemoving:Connect(function()
        for name in loops do cancelLoop(name) end
        if stormLabel and stormLabel.Parent then
            stormLabel:Destroy()
        end
    end)
end

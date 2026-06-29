-- +1 Speed Keyboard Escape (PlaceId 95082159892680)

return function(section)
    local elements = getgenv()._astroElements
    local RS       = game:GetService("ReplicatedStorage")
    local plr      = game:GetService("Players").LocalPlayer

    local _farming  = false
    local _winStage = 1

    local part = Instance.new("Part")
    part.Anchored = true
    part.Size = Vector3.new(10, 1, 546)
    part.Position = Vector3.new(1, 75, 1090)
    part.Parent = workspace

    local _stage9Bridges = {}

    local BRIDGE_PAIRS = {
        { Vector3.new(-1248, 302, 1468), Vector3.new(-1342, 281, 1466) },
        { Vector3.new(-1510, 334, 1466), Vector3.new(-1563, 320, 1466) },
        { Vector3.new(-1627, 319, 1464), Vector3.new(-1740, 289, 1464) },
        { Vector3.new(-1864, 315, 1465), Vector3.new(-1934, 306, 1465) },
        { Vector3.new(-2046, 304, 1465), Vector3.new(-2127, 306, 1466) },
        { Vector3.new(-2183, 323, 1466), Vector3.new(-2244, 313, 1466) },
        { Vector3.new(-2345, 323, 1466), Vector3.new(-2409, 321, 1466) },
        { Vector3.new(-2530, 318, 1466), Vector3.new(-2594, 293, 1479) },
        { Vector3.new(-2788, 306, 1464), Vector3.new(-2853, 282, 1464) },
        { Vector3.new(-3994, 295, 1466), Vector3.new(-4328, 471, 1514) },
    }

    local function spawnBridges()
        for _, p in _stage9Bridges do p:Destroy() end
        table.clear(_stage9Bridges)
        for _, pair in BRIDGE_PAIRS do
            local a, b = pair[1], pair[2]
            local bridge = Instance.new("Part")
            bridge.Anchored   = true
            bridge.CanCollide = true
            bridge.Size       = Vector3.new(10, 1, (b - a).Magnitude)
            bridge.CFrame     = CFrame.lookAt((a + b) / 2, b)
            bridge.Transparency = 0.5
            bridge.Parent     = workspace
            table.insert(_stage9Bridges, bridge)
        end
    end

    local function waitForTsunamiWindow()
        local npcPiege = workspace:FindFirstChild("NPC & Piege")
        if not npcPiege then return end
        local tsunami = npcPiege:FindFirstChild("Tsunami1")
        if not tsunami then return end

        local travelTime = tsunami:GetAttribute("TravelTime") or 5.02326
        local waveStartedAt = nil

        local conn = tsunami:GetAttributeChangedSignal("TsunamiStartTime"):Connect(function()
            waveStartedAt = tick()
        end)

        while _farming do
            if waveStartedAt then
                local remaining = travelTime - (tick() - waveStartedAt)
                if remaining <= 3.2 then break end
            end
            task.wait(0.05)
        end

        conn:Disconnect()
    end

    elements:Label("Currently supports up to 11 stages.", section)

    elements:Slider("Win Stage", section, 1, 11, 1, function(v)
        _winStage = math.floor(v)
    end)

    elements:Toggle("Autofarm", section, function(v)
        _farming = v
        if not v then return end

        spawnBridges()

        task.spawn(function()
            while _farming do
                RS:WaitForChild("Remotes"):WaitForChild("UpdateSpeed"):FireServer("Walking")
                task.wait()
            end
        end)

        task.spawn(function()
            local CS        = game:GetService("CollectionService")
            local lavaTower = workspace["NPC & Piege"] and workspace["NPC & Piege"]:FindFirstChild("LavaTower")
            local npc10     = workspace:FindFirstChild("NPC10")
            while _farming do
                for _, w in CS:GetTagged("CrushWallL") do
                    w.CanCollide = false
                    w.CanTouch   = false
                end
                for _, w in CS:GetTagged("CrushWallR") do
                    w.CanCollide = false
                    w.CanTouch   = false
                end
                for _, w in CS:GetTagged("LavaPart") do
                    w.CanTouch = false
                end
                if lavaTower then
                    local lc = lavaTower:FindFirstChild("LavaCollide")
                    if lc then lc.CanTouch = false end
                end
                if npc10 then
                    for _, p in npc10:GetDescendants() do
                        if p:IsA("BasePart") then
                            p.CanCollide = false
                            p.CanTouch   = false
                        end
                    end
                end
                task.wait()
            end
        end)

        task.spawn(function()
            while _farming do
                pcall(function()
                    plr.Character.Humanoid:MoveTo(Vector3.new(2, 9, 282))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    if _winStage == 1 then
                        plr.Character.Humanoid:MoveTo(workspace.Structure.Stage2.WinBlock1.Position)
                        plr.Character.Humanoid.MoveToFinished:Wait()
                        task.wait(1)
                        return
                    end
                    plr.Character.Humanoid:MoveTo(Vector3.new(70, 9, 398))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(1, 9, 505))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    if _winStage == 2 then
                        plr.Character.Humanoid:MoveTo(workspace.Structure.Stage3.WinBlock2.Position)
                        plr.Character.Humanoid.MoveToFinished:Wait()
                        task.wait(1)
                        return
                    end
                    plr.Character.Humanoid:MoveTo(Vector3.new(1, 8, 503))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(19, 8, 524))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(18, 8, 556))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(18, 19, 593))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(19, 52, 683))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(18, 77, 751))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-1, 77, 776))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    if _winStage == 3 then
                        plr.Character.Humanoid:MoveTo(workspace.Structure.Stage4.WinBlock3.Position)
                        plr.Character.Humanoid.MoveToFinished:Wait()
                        task.wait(1)
                        return
                    end
                    plr.Character.Humanoid:MoveTo(Vector3.new(1, 77, 817))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(1, 77, 1042))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    if _winStage == 4 then
                        plr.Character.Humanoid:MoveTo(workspace.Structure.Stage5.WinBlock4.Position)
                        plr.Character.Humanoid.MoveToFinished:Wait()
                        task.wait(1)
                        return
                    end
                    plr.Character.Humanoid:MoveTo(Vector3.new(2, 77, 1363))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    if _winStage == 5 then
                        plr.Character.Humanoid:MoveTo(workspace.Structure.Stage6.WinBlock5.Position)
                        plr.Character.Humanoid.MoveToFinished:Wait()
                        task.wait(1)
                        return
                    end
                    waitForTsunamiWindow()
                    plr.Character.Humanoid:MoveTo(Vector3.new(1, 77, 1416))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-21, 54, 1481))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-322, 54, 1465))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-539, 54, 1462))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    if _winStage == 6 then
                        plr.Character.Humanoid:MoveTo(workspace.Structure.Stage7.WinBlock6.Position)
                        plr.Character.Humanoid.MoveToFinished:Wait()
                        task.wait(1)
                        return
                    end
                    plr.Character.Humanoid:MoveTo(Vector3.new(-563, 54, 1464))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-775, 54, 1460))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-1008, 54, 1462))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    if _winStage == 7 then
                        plr.Character.Humanoid:MoveTo(workspace.Structure.Stage8.WinBlock7.Position)
                        plr.Character.Humanoid.MoveToFinished:Wait()
                        task.wait(1)
                        return
                    end
                    plr.Character.Humanoid:MoveTo(Vector3.new(-1022, 54, 1465))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-1058, 54, 1464))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-1088, 54, 1465))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-1088, 117, 1465))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-1088, 282, 1465))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-1119, 296, 1465))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    if _winStage == 8 then
                        plr.Character.Humanoid:MoveTo(workspace.Structure.Stage9.WinBlock8.Position)
                        plr.Character.Humanoid.MoveToFinished:Wait()
                        task.wait(1)
                        return
                    end
                    plr.Character.Humanoid:MoveTo(Vector3.new(-1137, 296, 1464))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-1216, 296, 1466))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-1247, 304, 1468))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-1339, 285, 1466))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-1427, 336, 1465))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-1512, 337, 1465))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-1574, 321, 1467))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-1623, 321, 1464))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-1751, 290, 1463))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-1860, 316, 1465))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-1933, 309, 1464))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-2042, 307, 1464))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-2138, 311, 1466))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-2190, 325, 1465))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-2252, 314, 1465))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-2346, 326, 1466))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-2414, 322, 1465))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-2520, 322, 1466))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-2563, 308, 1474))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-2610, 294, 1485))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-2710, 294, 1481))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-2790, 309, 1466))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-2880, 283, 1464))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-2968, 296, 1463))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    if _winStage == 9 then
                        plr.Character.Humanoid:MoveTo(workspace.Structure.Stage10.WinBlock9.Position)
                        plr.Character.Humanoid.MoveToFinished:Wait()
                        task.wait(1)
                        return
                    end
                    plr.Character.Humanoid:MoveTo(Vector3.new(-2972, 296, 1465))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-3179, 296, 1335))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-3513, 296, 1338))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-3932, 296, 1464))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    if _winStage == 10 then
                        plr.Character.Humanoid:MoveTo(workspace.Structure.Stage11.WinBlock10.Position)
                        plr.Character.Humanoid.MoveToFinished:Wait()
                        task.wait(1)
                        return
                    end
                    plr.Character.Humanoid:MoveTo(Vector3.new(-3957, 296, 1465))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-3993, 296, 1465))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-3997, 299, 1466))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-4145, 377, 1487))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-4317, 468, 1511))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    plr.Character.Humanoid:MoveTo(Vector3.new(-4367, 471, 1525))
                    plr.Character.Humanoid.MoveToFinished:Wait()
                    if _winStage == 11 then
                        plr.Character.Humanoid:MoveTo(workspace.Structure.Stage12.WinBlock11.Position)
                        plr.Character.Humanoid.MoveToFinished:Wait()
                        task.wait(1)
                        return
                    end
                end)
            end
        end)
    end)

    section.AncestorRemoving:Connect(function()
        _farming = false
        part:Destroy()
        for _, p in _stage9Bridges do p:Destroy() end
        table.clear(_stage9Bridges)
    end)
end

-- +1 Speed Keyboard Escape (PlaceId 95082159892680)

return function(section)
    local elements = getgenv()._astroElements
    local RS       = game:GetService("ReplicatedStorage")
    local plr      = game:GetService("Players").LocalPlayer

    local _farming  = false
    local _winStage = 1




    local function flyTo(pos)
        local speed = plr.Character.Humanoid.WalkSpeed
        while _farming and (plr.Character.HumanoidRootPart.Position - pos).Magnitude > 2 do
            local dir = (pos - plr.Character.HumanoidRootPart.Position).Unit
            plr.Character.HumanoidRootPart.AssemblyLinearVelocity = dir * speed
            task.wait()
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

        local hum   = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
        local speed = hum and hum.WalkSpeed or 16

        if speed > 140 then
            -- faster than tsunami: go the moment wave spawns
            while _farming and not waveStartedAt do
                task.wait(0.05)
            end
        else
            -- slower than tsunami: follow behind, wait until 3.2s remain
            while _farming do
                if waveStartedAt then
                    local remaining = travelTime - (tick() - waveStartedAt)
                    if remaining <= 3.2 then break end
                end
                task.wait(0.05)
            end
        end

        conn:Disconnect()
    end

    elements:Label("Currently supports up to 12 stages.", section)

    elements:Slider("Win Stage", section, 1, 12, 1, function(v)
        _winStage = math.floor(v)
    end)

    elements:Toggle("Autofarm", section, function(v)
        _farming = v
        if not v then return end

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
                    flyTo(Vector3.new(2, 9, 282))
                    if _winStage == 1 then
                        plr.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        plr.Character.Humanoid:MoveTo(workspace.Structure.Stage2.WinBlock1.Position)
                        plr.Character.Humanoid.MoveToFinished:Wait()
                        task.wait(1)
                        return
                    end
                    flyTo(Vector3.new(70, 9, 398))
                    flyTo(Vector3.new(1, 9, 505))
                    if _winStage == 2 then
                        plr.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        plr.Character.Humanoid:MoveTo(workspace.Structure.Stage3.WinBlock2.Position)
                        plr.Character.Humanoid.MoveToFinished:Wait()
                        task.wait(1)
                        return
                    end
                    flyTo(Vector3.new(1, 8, 503))
                    flyTo(Vector3.new(19, 8, 524))
                    flyTo(Vector3.new(18, 8, 556))
                    flyTo(Vector3.new(18, 19, 593))
                    flyTo(Vector3.new(19, 52, 683))
                    flyTo(Vector3.new(18, 77, 751))
                    flyTo(Vector3.new(-1, 77, 776))
                    if _winStage == 3 then
                        plr.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        plr.Character.Humanoid:MoveTo(workspace.Structure.Stage4.WinBlock3.Position)
                        plr.Character.Humanoid.MoveToFinished:Wait()
                        task.wait(1)
                        return
                    end
                    flyTo(Vector3.new(1, 77, 817))
                    flyTo(Vector3.new(1, 77, 1042))
                    if _winStage == 4 then
                        plr.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        plr.Character.Humanoid:MoveTo(workspace.Structure.Stage5.WinBlock4.Position)
                        plr.Character.Humanoid.MoveToFinished:Wait()
                        task.wait(1)
                        return
                    end
                    flyTo(Vector3.new(2, 77, 1363))
                    if _winStage == 5 then
                        plr.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        plr.Character.Humanoid:MoveTo(workspace.Structure.Stage6.WinBlock5.Position)
                        plr.Character.Humanoid.MoveToFinished:Wait()
                        task.wait(1)
                        return
                    end
                    waitForTsunamiWindow()
                    flyTo(Vector3.new(1, 77, 1416))
                    flyTo(Vector3.new(-21, 54, 1481))
                    flyTo(Vector3.new(-322, 54, 1465))
                    flyTo(Vector3.new(-539, 54, 1462))
                    if _winStage == 6 then
                        plr.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        plr.Character.Humanoid:MoveTo(workspace.Structure.Stage7.WinBlock6.Position)
                        plr.Character.Humanoid.MoveToFinished:Wait()
                        task.wait(1)
                        return
                    end
                    flyTo(Vector3.new(-563, 54, 1464))
                    flyTo(Vector3.new(-775, 54, 1460))
                    flyTo(Vector3.new(-1008, 54, 1462))
                    if _winStage == 7 then
                        plr.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        plr.Character.Humanoid:MoveTo(workspace.Structure.Stage8.WinBlock7.Position)
                        plr.Character.Humanoid.MoveToFinished:Wait()
                        task.wait(1)
                        return
                    end
                    flyTo(Vector3.new(-1028, 54, 1466))
                    flyTo(Vector3.new(-1086, 54, 1466))
                    flyTo(Vector3.new(-1086, 291, 1466))
                    flyTo(Vector3.new(-1086, 299, 1466))
                    flyTo(Vector3.new(-1097, 298, 1465))
                    flyTo(Vector3.new(-1120, 296, 1466))
                    if _winStage == 8 then
                        plr.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        plr.Character.Humanoid:MoveTo(workspace.Structure.Stage9.WinBlock8.Position)
                        plr.Character.Humanoid.MoveToFinished:Wait()
                        task.wait(1)
                        return
                    end
                    flyTo(Vector3.new(-1137, 296, 1464))
                    flyTo(Vector3.new(-1216, 296, 1466))
                    flyTo(Vector3.new(-1247, 304, 1468))
                    flyTo(Vector3.new(-1339, 285, 1466))
                    flyTo(Vector3.new(-1427, 336, 1465))
                    flyTo(Vector3.new(-1512, 337, 1465))
                    flyTo(Vector3.new(-1574, 321, 1467))
                    flyTo(Vector3.new(-1623, 321, 1464))
                    flyTo(Vector3.new(-1751, 290, 1463))
                    flyTo(Vector3.new(-1860, 316, 1465))
                    flyTo(Vector3.new(-1933, 309, 1464))
                    flyTo(Vector3.new(-2042, 307, 1464))
                    flyTo(Vector3.new(-2138, 311, 1466))
                    flyTo(Vector3.new(-2190, 325, 1465))
                    flyTo(Vector3.new(-2252, 314, 1465))
                    flyTo(Vector3.new(-2346, 326, 1466))
                    flyTo(Vector3.new(-2414, 322, 1465))
                    flyTo(Vector3.new(-2520, 322, 1466))
                    flyTo(Vector3.new(-2563, 308, 1474))
                    flyTo(Vector3.new(-2610, 294, 1485))
                    flyTo(Vector3.new(-2710, 294, 1481))
                    flyTo(Vector3.new(-2790, 309, 1466))
                    flyTo(Vector3.new(-2880, 283, 1464))
                    flyTo(Vector3.new(-2968, 296, 1463))
                    plr.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    if _winStage == 9 then
                        plr.Character.Humanoid:MoveTo(workspace.Structure.Stage10.WinBlock9.Position)
                        plr.Character.Humanoid.MoveToFinished:Wait()
                        task.wait(1)
                        return
                    end
                    flyTo(Vector3.new(-2972, 296, 1465))
                    flyTo(Vector3.new(-3179, 296, 1335))
                    flyTo(Vector3.new(-3513, 296, 1338))
                    flyTo(Vector3.new(-3932, 296, 1464))
                    if _winStage == 10 then
                        plr.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        plr.Character.Humanoid:MoveTo(workspace.Structure.Stage11.WinBlock10.Position)
                        plr.Character.Humanoid.MoveToFinished:Wait()
                        task.wait(1)
                        return
                    end
                    flyTo(Vector3.new(-3949, 296, 1465))
                    flyTo(Vector3.new(-4293, 299, 1455))
                    flyTo(Vector3.new(-4299, 345, 1448))
                    flyTo(Vector3.new(-4316, 345, 1448))
                    flyTo(Vector3.new(-4314, 348, 1330))
                    flyTo(Vector3.new(-4303, 371, 1305))
                    flyTo(Vector3.new(-4183, 370, 1305))
                    flyTo(Vector3.new(-4049, 371, 1305))
                    flyTo(Vector3.new(-4027, 395, 1314))
                    flyTo(Vector3.new(-4017, 395, 1314))
                    flyTo(Vector3.new(-4042, 451, 1463))
                    flyTo(Vector3.new(-4062, 458, 1497))
                    flyTo(Vector3.new(-4166, 455, 1543))
                    flyTo(Vector3.new(-4264, 461, 1533))
                    flyTo(Vector3.new(-4314, 476, 1528))
                    flyTo(Vector3.new(-4357, 472, 1528))
                    plr.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    if _winStage == 11 then
                        plr.Character.Humanoid:MoveTo(workspace.Structure.Stage12.WinBlock11.Position)
                        plr.Character.Humanoid.MoveToFinished:Wait()
                        task.wait(1)
                        return
                    end
                    flyTo(Vector3.new(-4384, 471, 1532))
                    flyTo(Vector3.new(-4439, 470, 1534))
                    flyTo(Vector3.new(-4597, 470, 1505))
                    flyTo(Vector3.new(-4568, 470, 1349))
                    flyTo(Vector3.new(-4533, 470, 1391))
                    flyTo(Vector3.new(-4455, 470, 1448))
                    flyTo(Vector3.new(-4479, 470, 1245))
                    flyTo(Vector3.new(-4587, 470, 1130))
                    flyTo(Vector3.new(-4720, 470, 1197))
                    flyTo(Vector3.new(-4723, 470, 1372))
                    flyTo(Vector3.new(-4867, 470, 1396))
                    flyTo(Vector3.new(-4918, 470, 1508))
                    flyTo(Vector3.new(-4983, 470, 1630))
                    flyTo(Vector3.new(-5065, 470, 1566))
                    flyTo(Vector3.new(-5058, 470, 1342))
                    flyTo(Vector3.new(-5112, 470, 1161))
                    flyTo(Vector3.new(-5225, 470, 1203))
                    flyTo(Vector3.new(-5174, 470, 1307))
                    flyTo(Vector3.new(-5182, 470, 1398))
                    flyTo(Vector3.new(-5322, 470, 1469))
                    plr.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    if _winStage == 12 then
                        plr.Character.Humanoid:MoveTo(workspace.Structure.Stage13.WinBlock12.Position)
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
    end)
end

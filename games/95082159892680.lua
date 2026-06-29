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

    local function waitForTsunamiClear()
        local npcPiege = workspace:FindFirstChild("NPC & Piege")
        if not npcPiege then return end
        while _farming do
            local tsunami = npcPiege:FindFirstChild("Tsunami1")
            if not tsunami then break end
            local x = tsunami:GetPivot().Position.X
            if x < -600 then break end
            task.wait(0.25)
        end
    end

    elements:Label("Currently supports up to 6 stages.", section)

    elements:Slider("Win Stage", section, 1, 6, 1, function(v)
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
            while _farming do
                pcall(function()
                    local hum = plr.Character.Humanoid
                    hum:MoveTo(Vector3.new(2, 9, 282))
                    hum.MoveToFinished:Wait()
                    if _winStage == 1 then
                        hum:MoveTo(workspace.Structure.Stage2.WinBlock1.Position)
                        hum.MoveToFinished:Wait()
                        task.wait(1)
                        return
                    end
                    hum:MoveTo(Vector3.new(70, 9, 398))
                    hum.MoveToFinished:Wait()
                    hum:MoveTo(Vector3.new(1, 9, 505))
                    hum.MoveToFinished:Wait()
                    if _winStage == 2 then
                        hum:MoveTo(workspace.Structure.Stage3.WinBlock2.Position)
                        hum.MoveToFinished:Wait()
                        task.wait(1)
                        return
                    end
                    hum:MoveTo(Vector3.new(19, 9, 541))
                    hum.MoveToFinished:Wait()
                    hum:MoveTo(Vector3.new(20, 77, 754))
                    hum.MoveToFinished:Wait()
                    if _winStage == 3 then
                        hum:MoveTo(workspace.Structure.Stage4.WinBlock3.Position)
                        hum.MoveToFinished:Wait()
                        task.wait(1)
                        return
                    end
                    hum:MoveTo(Vector3.new(1, 77, 817))
                    hum.MoveToFinished:Wait()
                    hum:MoveTo(Vector3.new(1, 77, 1042))
                    hum.MoveToFinished:Wait()
                    if _winStage == 4 then
                        hum:MoveTo(workspace.Structure.Stage5.WinBlock4.Position)
                        hum.MoveToFinished:Wait()
                        task.wait(1)
                        return
                    end
                    hum:MoveTo(Vector3.new(2, 77, 1363))
                    hum.MoveToFinished:Wait()
                    if _winStage == 5 then
                        hum:MoveTo(workspace.Structure.Stage6.WinBlock5.Position)
                        hum.MoveToFinished:Wait()
                        task.wait(1)
                        return
                    end
                    waitForTsunamiClear()
                    hum:MoveTo(Vector3.new(0, 77, 1401))
                    hum.MoveToFinished:Wait()
                    hum:MoveTo(Vector3.new(-56, 54, 1473))
                    hum.MoveToFinished:Wait()
                    hum:MoveTo(Vector3.new(-541, 54, 1470))
                    hum.MoveToFinished:Wait()
                    if _winStage == 6 then
                        hum:MoveTo(workspace.Structure.Stage7.WinBlock6.Position)
                        hum.MoveToFinished:Wait()
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
    end)
end

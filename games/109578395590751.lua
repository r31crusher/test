-- +1 Speed Brick Escape (PlaceId 109578395590751)

return function(section)
    local elements = getgenv()._astroElements
    local RS = game:GetService("RunService")
    local plr = game:GetService("Players").LocalPlayer

    local _farming = false

    local _speed = 400

    local function flyTo(pos)
        while (_farming or _farming2) and (plr.Character.HumanoidRootPart.Position - pos).Magnitude > 2 do
            local dir = (pos - plr.Character.HumanoidRootPart.Position).Unit
            plr.Character.HumanoidRootPart.AssemblyLinearVelocity = dir * _speed
            task.wait()
        end
        plr.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end

    elements:Toggle("World 1 Autofarm", section, function(v)
        _farming = v
        if not v then return end

        local speedConn
        local function hookSpeed()
            if speedConn then speedConn:Disconnect() end
            if plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") then
                plr.Character.Humanoid.WalkSpeed = 400
                speedConn = plr.Character.Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                    plr.Character.Humanoid.WalkSpeed = 400
                end)
            end
        end
        hookSpeed()
        plr.CharacterAdded:Connect(hookSpeed)

        local noclip = RS.Heartbeat:Connect(function()
            if plr.Character then
                for _, p in plr.Character:GetDescendants() do
                    if p:IsA("BasePart") then
                        p.CanCollide = false
                    end
                end
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:Move(Vector3.new(0, 0, -1))
                end
            end
        end)

        local swingRemote = game:GetService("ReplicatedStorage"):WaitForChild("HammerSimSwing")
        task.spawn(function()
            while _farming do
                swingRemote:FireServer()
                task.wait(0.6)
            end
        end)

        task.spawn(function()
            while _farming do
                flyTo(Vector3.new(5129, 699, -2559))
                flyTo(Vector3.new(90, 13, 65))
                task.wait(15)
            end
            noclip:Disconnect()
        end)
    end)

    local _farming2 = false
    elements:Toggle("World 2 Autofarm", section, function(v)
        _farming2 = v
        if not v then return end

        local speedConn2
        local function hookSpeed2()
            if speedConn2 then speedConn2:Disconnect() end
            if plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") then
                plr.Character.Humanoid.WalkSpeed = 400
                speedConn2 = plr.Character.Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                    plr.Character.Humanoid.WalkSpeed = 400
                end)
            end
        end
        hookSpeed2()
        plr.CharacterAdded:Connect(hookSpeed2)

        local noclip2 = RS.Heartbeat:Connect(function()
            if plr.Character then
                for _, p in plr.Character:GetDescendants() do
                    if p:IsA("BasePart") then
                        p.CanCollide = false
                    end
                end
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:Move(Vector3.new(0, 0, -1))
                end
            end
        end)

        local swingRemote2 = game:GetService("ReplicatedStorage"):WaitForChild("HammerSimSwing")
        task.spawn(function()
            while _farming2 do
                swingRemote2:FireServer()
                task.wait(0.6)
            end
        end)

        task.spawn(function()
            while _farming2 do
                flyTo(Vector3.new(1239, 904, 25249))
                flyTo(Vector3.new(91, 864, 26849))
                flyTo(Vector3.new(-168.218, 817.925, 26801.1))
                task.wait(15)
            end
            noclip2:Disconnect()
        end)
    end)

    local _autoRebirth = false
    elements:Toggle("Auto Rebirth", section, function(v)
        _autoRebirth = v
        if not v then return end
        task.spawn(function()
            local RS2 = game:GetService("ReplicatedStorage")
            local rebirthRemote = RS2:WaitForChild("BrickRebirthRequest")
            local victoryRemote = RS2:WaitForChild("VictoryUpdate")
            local currentWins = 0
            local conn = victoryRemote.OnClientEvent:Connect(function(wins)
                if typeof(wins) == "number" then
                    currentWins = wins
                end
            end)
            while _autoRebirth do
                if currentWins >= 1000 then
                    rebirthRemote:FireServer()
                    task.wait(1)
                end
                task.wait(0.5)
            end
            conn:Disconnect()
        end)
    end)

    section.AncestorRemoving:Connect(function()
        _farming = false
        _farming2 = false
        _autoRebirth = false
    end)
end

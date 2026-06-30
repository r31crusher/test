-- +1 Speed Brick Escape (PlaceId 109578395590751)

return function(section)
    local elements = getgenv()._astroElements
    local RS = game:GetService("RunService")
    local plr = game:GetService("Players").LocalPlayer

    local _farming = false

    local _speed = 400

    local function flyTo(pos)
        while _farming and (plr.Character.HumanoidRootPart.Position - pos).Magnitude > 2 do
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
                -- wait for teleport back (large position jump)
                local lastPos = plr.Character.HumanoidRootPart.Position
                while _farming do
                    task.wait()
                    local newPos = plr.Character.HumanoidRootPart.Position
                    if (newPos - lastPos).Magnitude > 50 then
                        break
                    end
                    lastPos = newPos
                end
                local deadline = os.clock() + 10
                local brickPts = {Vector3.new(5109, 699, -2559), Vector3.new(5119, 699, -2559)}
                local bi = 1
                while _farming and os.clock() < deadline do
                    flyTo(brickPts[bi])
                    bi = bi % 2 + 1
                end
            end
            noclip:Disconnect()
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
        _autoRebirth = false
    end)
end

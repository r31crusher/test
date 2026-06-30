-- +1 Speed Brick Escape (PlaceId 109578395590751)

return function(section)
    local elements = getgenv()._astroElements
    local RS = game:GetService("RunService")
    local plr = game:GetService("Players").LocalPlayer

    local _farming = false

    local _speed = 250

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
                plr.Character.Humanoid.WalkSpeed = 250
                speedConn = plr.Character.Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                    plr.Character.Humanoid.WalkSpeed = 250
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
                task.wait(5)
            end
            noclip:Disconnect()
        end)
    end)

    section.AncestorRemoving:Connect(function()
        _farming = false
    end)
end

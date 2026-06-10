-- Bike Obby for Brainrots (PlaceId 136919941417380)

return function(section)
    local elements = getgenv()._astroElements
    local plr      = game:GetService("Players").LocalPlayer
    local RS       = game:GetService("ReplicatedStorage")

    getgenv()._bike_farm  = false
    getgenv()._bike_equip = false

    local _bestEvent
    pcall(function() _bestEvent = RS.Events.PlaceBestBrainrots end)

    -- ── Auto Farm ────────────────────────────────────────────────────────────
    elements:Toggle("Farm Brainrots", section, function(v)
        getgenv()._bike_farm = v
        if not v then return end
        task.spawn(function()
            while getgenv()._bike_farm do
                pcall(function()
                    local char = plr.Character
                    if not char then return end

                    local tiers = {
                        {pos = Vector3.new(-3394, 1450, 7887), folder = "10"},
                        {pos = Vector3.new(-3394, 1450, 6269), folder = "9"},
                        {pos = Vector3.new(-3394, 1450, 4732), folder = "8"},
                    }

                    for _, tier in ipairs(tiers) do
                        if not getgenv()._bike_farm then break end
                        char:MoveTo(tier.pos)
                        local folder = workspace.ItemSpawns:WaitForChild(tier.folder, 5)
                        if not folder then continue end

                        for _, item in pairs(folder:GetChildren()) do
                            if not getgenv()._bike_farm then break end
                            if not item:IsA("Model") then continue end
                            local prp = item.PrimaryPart
                            if not prp or not prp:FindFirstChild("ProximityPrompt") then continue end

                            char:MoveTo(prp.Position)

                            local pickDeadline = tick() + 20
                            repeat
                                fireproximityprompt(prp.ProximityPrompt)
                                task.wait()
                            until not item or item.Parent ~= folder or tick() > pickDeadline

                            local br = char:WaitForChild("StackItem", 5)
                            if br then
                                char:MoveTo(workspace.Zones.BikeSpawn.Position)
                                local dropDeadline = tick() + 20
                                repeat task.wait() until not br or br.Parent ~= char or tick() > dropDeadline
                            end

                            task.wait(0.1)
                        end
                    end
                end)

                task.wait(0.1)
            end
        end)
    end)

    -- ── Auto Equip Best ───────────────────────────────────────────────────────
    elements:Toggle("Auto Equip Best", section, function(v)
        getgenv()._bike_equip = v
        if not v then return end
        task.spawn(function()
            while getgenv()._bike_equip do
                pcall(function()
                    if not _bestEvent then
                        _bestEvent = RS.Events.PlaceBestBrainrots
                    end
                    _bestEvent:FireServer()
                end)
                task.wait(5)
            end
        end)
    end)

    -- ── Unload ────────────────────────────────────────────────────────────────
    section.AncestorRemoving:Connect(function()
        getgenv()._bike_farm  = false
        getgenv()._bike_equip = false
    end)
end

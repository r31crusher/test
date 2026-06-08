-- pole obby for brainrots

return function(section)
    local elements = getgenv()._astroElements

    getgenv().farming = false
    local plr = game:GetService("Players").LocalPlayer

    local _safeZoneEvent = game:GetService("ReplicatedStorage").Packages.Net["RE/SafeZoneEvent"]
    elements:Toggle("Farm Brainrots", section, function(v)
        getgenv().farming = v
        if v then
            task.spawn(function()
                while getgenv().farming do
                    pcall(function()
                        for _, mob in pairs(workspace.Mobs:GetChildren()) do
                            if not mob.PrimaryPart then continue end
                            local Rarity = mob.PrimaryPart.OverheadAttach.AnimalOverhead.Rarity.Text
                            if Rarity == "OG" or Rarity == "Admin" then
                                plr.Character:MoveTo(mob.PrimaryPart.Position)
                                repeat fireproximityprompt(mob.PrimaryPart.ProximityPrompt) task.wait() until not mob or not mob.PrimaryPart or mob.PrimaryPart:FindFirstChild("MobCarryWeld")
                                _safeZoneEvent:FireServer()
                                task.wait(0.1)
                            end
                        end
                    end)
                    task.wait(0.1)
                end
            end)
        end
    end)
end

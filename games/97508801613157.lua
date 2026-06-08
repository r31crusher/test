-- parkour run for brainrots

return function(section)
    local elements = getgenv()._astroElements
    getgenv().farming = false

    local plr = game:GetService("Players").LocalPlayer

    local _returnEvent = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RE/BG_ReturnToBase"]
    elements:Toggle("Farming", section, function(v)
        getgenv().farming = v
        if v then
            task.spawn(function()
                while getgenv().farming do
                    plr.Character:MoveTo(Vector3.new(12738, 1490, 231))
                    for _, spawner in pairs(workspace.BG_BrainrotSpawner:GetChildren()) do
                        local br = spawner:FindFirstChildOfClass("Model")
                        if spawner.Name == "Mythical" and br then
                            if not br.PrimaryPart:FindFirstChildOfClass("ProximityPrompt") then continue end
                            repeat fireproximityprompt(br.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")) task.wait() until br.Parent ~= spawner
                            _returnEvent:FireServer()
                            task.wait(1)
                        end
                    end
                    task.wait(0.1)
                end
            end)
        end
    end)
end

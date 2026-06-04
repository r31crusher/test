-- parkour run for brainrots

return function(section)
    local elements = loadstring(game:HttpGet(getgitpath("src").."elements.lua"))()
    getgenv().farming = false

    local plr = game:GetService("Players").LocalPlayer

    elements:Toggle("Farming", section, function(v)
        if v then
            getgenv().farming = true

            while getgenv().farming do

                plr.Character:MoveTo(Vector3.new(12738, 1490, 231))

                for _, v in pairs(workspace.BG_BrainrotSpawner:GetChildren()) do
                    local br = v:FindFirstChildOfClass("Model")
                    if v.Name == "Mythical" and br then
                        if not br.PrimaryPart:FindFirstChildOfClass("ProximityPrompt") then continue end
                        repeat fireproximityprompt(br.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")) task.wait() until br.Parent ~= v
                        local Event = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RE/BG_ReturnToBase"]
                        Event:FireServer()
                        task.wait(1)
                    end
                end

                task.wait(0.1)
            end
        else
            getgenv().farming = false
        end
    end)
end

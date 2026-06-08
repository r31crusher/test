-- hack vault for brainrots

return function(section)
    local elements = getgenv()._astroElements

    local plr = game:GetService("Players").LocalPlayer
    getgenv().FarmRots = false

    elements:Toggle("Farm Brainrots", section, function(v)
        getgenv().FarmRots = v
        if v then
            task.spawn(function()
                while getgenv().FarmRots do
                    for _, br in pairs(workspace.EntitiesFolder:GetChildren()) do
                        plr.Character:MoveTo(Vector3.new(-2494, 4, -726))
                        task.wait(0.5)
                        if not br:GetAttribute("SpawnZone") == 22 then continue end
                        if not br.PrimaryPart then continue end
                        plr.Character:MoveTo(br.PrimaryPart.Position)
                        task.wait()
                        repeat fireproximityprompt(br.PrimaryPart.TakeBrainrotPrompt) task.wait() until not br.PrimaryPart or br.PrimaryPart:FindFirstChild("Attachment")
                        plr.Character:MoveTo(Vector3.new(77, 4, -729))
                        task.wait(1)
                    end
                    task.wait()
                end
            end)
        end
    end)
end

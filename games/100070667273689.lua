-- Survive flood for brainrots

return function(section)
    local elements = getgenv()._astroElements

    local repStorage = game:GetService("ReplicatedStorage")
    local plr = game:GetService("Players").LocalPlayer
    local brainrotFold = workspace.GameFolder.Brainrots

    getgenv().Farming = false

    local function grabem(where)
        local char = plr.Character
        for _, br in pairs(where:GetChildren()) do
            if not br.PrimaryPart then continue end
            char:MoveTo(br.PrimaryPart.Position)
            task.wait(0.5)
            fireproximityprompt(br.PrimaryPart.ProximityPrompt)
            task.wait(0.25)
            char:MoveTo(Vector3.new(-2, 4, 13))
            task.wait(0.5)
        end
    end

    elements:Toggle("Farming", section, function(isOn)
        getgenv().Farming = isOn
        if isOn then
            task.spawn(function()
                while getgenv().Farming do
                    grabem(brainrotFold.Infinity)
                    grabem(brainrotFold.Godly)
                    grabem(brainrotFold.Secret)
                    grabem(brainrotFold.Celestial)
                    task.wait(1)
                end
            end)
        end
    end)
end

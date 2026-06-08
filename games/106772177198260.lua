-- Reel for brainrots

return function(section)
    local elements = getgenv()._astroElements

    local repStorage = game:GetService("ReplicatedStorage")
    local plr = game:GetService("Players").LocalPlayer

    local placeEv = game:GetService("ReplicatedStorage").RemoteHandler.Plot

    getgenv().Farming = false

    elements:Toggle("Farming", section, function(isOn)
        getgenv().Farming = isOn
        if isOn then
            task.spawn(function()
                while getgenv().Farming do
                    repStorage.RemoteHandler.Fishing:FireServer("Caught", 3)
                    task.wait(0.1)
                end
            end)
        end
    end)

    elements:Button("Dupe Brainrot InHand", section, function()
        local char = plr.Character
        local br = char:FindFirstChildOfClass("Tool")
        if br and br:GetAttribute("brainrot") then
            for plotNum = 1, 30 do
                placeEv:FireServer("Add", "Plot" .. plotNum, br.Name)
                task.wait(0.5)
            end
        end
    end)
end

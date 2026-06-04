-- Reel for brainrots

return function(section)
    local elements = loadstring(game:HttpGet(getgitpath("src").."elements.lua"))()

    local repStorage = game:GetService("ReplicatedStorage")
    local plr = game:GetService("Players").LocalPlayer

    local placeEv = game:GetService("ReplicatedStorage").RemoteHandler.Plot

    getgenv().Farming = false

    elements:Toggle("Farming", section, function(isOn)
        if isOn then
            getgenv().Farming = true
            while getgenv().Farming do
                repStorage.RemoteHandler.Fishing:FireServer(
                    "Caught",
                    3
                )
                task.wait(0.1)
            end
        else
            getgenv().Farming = false
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

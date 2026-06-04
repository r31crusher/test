-- scream for brainrots

return function(section, elements)
    elements = elements or loadstring(game:HttpGet(getgitpath("src").."elements.lua"))()
    getgenv().AddingSpins = false
    getgenv().AutoSleepy = false
    getgenv().AutoOg = false

    elements:Toggle("Add Inf Spins", section, function(v)
        if v then
            getgenv().AddingSpins = true

            while getgenv().AddingSpins do
                local Event = game:GetService("ReplicatedStorage").Remotes.AddSpin
                Event:FireServer()
                task.wait()
            end
        else
            getgenv().AddingSpins = false
        end
    end)

    elements:Toggle("Auto Spin Sleepy Mutation", section, function(v)
        if v then
            getgenv().AutoSleepy = true

            while getgenv().AutoSleepy do
                local Event = game:GetService("ReplicatedStorage").Remotes.SpinEventWheel
                Event:FireServer(
                    5
                )
                task.wait(0.5)
            end
        else
            getgenv().AutoSleepy = false
        end
    end)

    elements:Toggle("Auto Spin OG", section, function(v)
        if v then
            getgenv().AutoOg = true

            while getgenv().AutoOg do
                local Event = game:GetService("ReplicatedStorage").Remotes.SpinEventWheel
                Event:FireServer(
                    4
                )
                task.wait(0.5)
            end
        else
            getgenv().AutoOg = false
        end
    end)
end

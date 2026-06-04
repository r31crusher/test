-- dream for brainrots

return function(section)
    local elements = loadstring(game:HttpGet(getgitpath("src").."elements.lua"))()
    getgenv().farming = false

    elements:Toggle("Farming", section, function(v)
        if v then
            getgenv().farming = true

            while getgenv().farming do
                local Event = game:GetService("ReplicatedStorage").Remotes.DreamStateChanged
                Event:FireServer(
                    true
                )

                local Event = game:GetService("ReplicatedStorage").Remotes.RequestDreamBrainrots
                Event:FireServer()

                local Event = game:GetService("ReplicatedStorage").Remotes.PickupDreamBrainrot
                Event:FireServer(
                    "60"
                )

                task.wait()
                local Event = game:GetService("ReplicatedStorage").Remotes.RequestDreamWallExit
                Event:FireServer()
                task.wait()
            end
        else
            getgenv().farming = false
        end
    end)
end

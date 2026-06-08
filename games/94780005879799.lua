-- scream for brainrots

return function(section)
    local elements = getgenv()._astroElements
    getgenv().AddingSpins = false
    getgenv().AutoSleepy = false
    getgenv().AutoOg = false

    local _remotes       = game:GetService("ReplicatedStorage").Remotes
    local _evAddSpin     = _remotes.AddSpin
    local _evSpinWheel   = _remotes.SpinEventWheel

    elements:Toggle("Add Inf Spins", section, function(v)
        getgenv().AddingSpins = v
        if v then
            task.spawn(function()
                while getgenv().AddingSpins do
                    _evAddSpin:FireServer()
                    task.wait()
                end
            end)
        end
    end)

    elements:Toggle("Auto Spin Sleepy Mutation", section, function(v)
        getgenv().AutoSleepy = v
        if v then
            task.spawn(function()
                while getgenv().AutoSleepy do
                    _evSpinWheel:FireServer(5)
                    task.wait(0.5)
                end
            end)
        end
    end)

    elements:Toggle("Auto Spin OG", section, function(v)
        getgenv().AutoOg = v
        if v then
            task.spawn(function()
                while getgenv().AutoOg do
                    _evSpinWheel:FireServer(4)
                    task.wait(0.5)
                end
            end)
        end
    end)
end

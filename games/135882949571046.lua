-- dream for brainrots

return function(section)
    local elements = getgenv()._astroElements
    getgenv().farming = false

    local _remotes       = game:GetService("ReplicatedStorage").Remotes
    local _evDreamState  = _remotes.DreamStateChanged
    local _evReqDream    = _remotes.RequestDreamBrainrots
    local _evPickup      = _remotes.PickupDreamBrainrot
    local _evWallExit    = _remotes.RequestDreamWallExit

    elements:Toggle("Farming", section, function(v)
        getgenv().farming = v
        if v then
            task.spawn(function()
                while getgenv().farming do
                    _evDreamState:FireServer(true)
                    _evReqDream:FireServer()
                    _evPickup:FireServer("60")
                    task.wait()
                    _evWallExit:FireServer()
                    task.wait()
                end
            end)
        end
    end)
end

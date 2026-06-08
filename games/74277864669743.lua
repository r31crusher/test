-- fly for brainrots

return function(section)
    local elements = getgenv()._astroElements

    local plr = game:GetService("Players").LocalPlayer
    getgenv().Farming = false
    getgenv().FarmWings = false
    getgenv().AutoBest = false
    getgenv().AutoCollect = false

    elements:Label("Auto rejoin on kick recommended. (Settings tab)", section)

    local _packetRemote = game:GetService("ReplicatedStorage").Libraries.Packet.RemoteEvent

    local _WANTED_RARITIES = { ADMIN=true, Lucky=true, Ascendant=true, Transcendent=true, OG=true }

    elements:Toggle("Farm Brainrots", section, function(v)
        getgenv().Farming = v
        if v then
            task.spawn(function()
                while getgenv().Farming do
                    for _, br in pairs(workspace.Brainrots:GetChildren()) do
                        if not _WANTED_RARITIES[br:GetAttribute("Rarity")] then continue end
                        if not br.PrimaryPart then continue end
                        local prompt = br:FindFirstChildOfClass("Model") and
                            br:FindFirstChildOfClass("Model"):FindFirstChildOfClass("MeshPart") and
                            br:FindFirstChildOfClass("Model"):FindFirstChildOfClass("MeshPart"):FindFirstChildOfClass("ProximityPrompt")
                        if prompt then
                            plr.Character:MoveTo(br.PrimaryPart.Position)
                            repeat fireproximityprompt(prompt) task.wait() until not br or br.Parent ~= workspace.Brainrots
                            task.wait()
                            plr.Character:MoveTo(Vector3.new(7, 10, 44))
                            task.wait(0.25)
                        end
                    end
                    task.wait(0.1)
                end
            end)
        end
    end)

    elements:Toggle("Auto Buy Speed", section, function(v)
        getgenv().FarmWings = v
        if v then
            task.spawn(function()
                while getgenv().FarmWings do
                    _packetRemote:FireServer(buffer.fromstring("\x15\x01"))
                    task.wait()
                end
            end)
        end
    end)

    elements:Toggle("Auto Equip Best", section, function(v)
        getgenv().AutoBest = v
        if v then
            task.spawn(function()
                while getgenv().AutoBest do
                    _packetRemote:FireServer(buffer.fromstring("\x0E"))
                    task.wait(1)
                end
            end)
        end
    end)

    elements:Toggle("Auto Collect", section, function(v)
        getgenv().AutoCollect = v
        if v then
            task.spawn(function()
                while getgenv().AutoCollect do
                    for _, plot in pairs(workspace.Plots:GetChildren()) do
                        if plot:GetAttribute("Owner") == plr.UserId then
                            for _, pod in pairs(plot.Podiums:GetChildren()) do
                                firetouchinterest(plr.Character.Head, pod.Collect, true)
                                task.wait()
                                firetouchinterest(plr.Character.Head, pod.Collect, false)
                            end
                        end
                    end
                    task.wait(2)
                end
            end)
        end
    end)
end

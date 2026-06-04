-- nuke for brainrots

return function(section)
    local elements = loadstring(game:HttpGet(getgitpath("src").."elements.lua"))()

    local brainrotFold = workspace.Camera.BrainrotContainer
    local wallDurabilities = require(game:GetService("ReplicatedStorage").Modules.Constants.WallDurabilities)
    local plr = game:GetService("Players").LocalPlayer

    local powerAmt = plr.PlayerGui.HUD.BottomRight.Stats.Container.Power.CollectedText

    getgenv().AutoMoney = false
    getgenv().AutoRebirth = false

    elements:Toggle("Auto Money", section, function(v)
        if v then
            getgenv().AutoMoney = true

            while getgenv().AutoMoney do
                task.spawn(function()
                    local Event = game:GetService("ReplicatedStorage").ModifiedPackages.Packet.RemoteEvent
                    Event:FireServer(
                        buffer.fromstring("\x0E")
                    )
                end)
                task.wait()
            end
        else
            getgenv().AutoMoney = false
        end
    end)

    elements:Toggle("Auto Rebirth", section, function(v)
        if v then
            getgenv().AutoRebirth = true

            while getgenv().AutoRebirth do
                local Event = game:GetService("ReplicatedStorage").ModifiedPackages.Packet.RemoteEvent
                Event:FireServer(
                    buffer.fromstring("\x93")
                )
                task.wait(1)
            end
        else
            getgenv().AutoRebirth = false
        end
    end)
end

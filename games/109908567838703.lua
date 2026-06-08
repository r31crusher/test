-- nuke for brainrots

return function(section)
    local elements = getgenv()._astroElements

    local brainrotFold = workspace.Camera.BrainrotContainer
    local wallDurabilities = require(game:GetService("ReplicatedStorage").Modules.Constants.WallDurabilities)
    local plr = game:GetService("Players").LocalPlayer

    local powerAmt = plr.PlayerGui.HUD.BottomRight.Stats.Container.Power.CollectedText

    local _packetRemote = game:GetService("ReplicatedStorage").ModifiedPackages.Packet.RemoteEvent

    getgenv().AutoMoney   = false
    getgenv().AutoRebirth = false

    elements:Toggle("Auto Money", section, function(v)
        getgenv().AutoMoney = v
        if v then
            task.spawn(function()
                while getgenv().AutoMoney do
                    _packetRemote:FireServer(buffer.fromstring("\x0E"))
                    task.wait()
                end
            end)
        end
    end)

    elements:Toggle("Auto Rebirth", section, function(v)
        getgenv().AutoRebirth = v
        if v then
            task.spawn(function()
                while getgenv().AutoRebirth do
                    _packetRemote:FireServer(buffer.fromstring("\x93"))
                    task.wait(1)
                end
            end)
        end
    end)
end

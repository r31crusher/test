-- "Rizz Tower" because it was the first result

return function(section)
    local elements = getgenv()._astroElements

    getgenv().WinFarm = false

    local plr = game:GetService("Players").LocalPlayer

    elements:Toggle("Win Farm", section, function(bool)
        getgenv().WinFarm = bool
        if bool then
            task.spawn(function()
                while getgenv().WinFarm do
                    pcall(function()
                        plr.Character:MoveTo(Vector3.new(1, 477, -315))
                        task.wait()
                        firetouchinterest(plr.Character.Head, workspace.TeleportWin.Reward, true)
                        task.wait()
                        firetouchinterest(plr.Character.Head, workspace.TeleportWin.Reward, false)
                        task.wait()
                    end)
                end
            end)
        end
    end)
end

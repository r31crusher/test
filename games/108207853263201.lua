-- "Rizz Tower" because it was the first result

return function(section)
    local elements = loadstring(game:HttpGet(getgitpath("src").."elements.lua"))()

    getgenv().WinFarm = false

    local plr = game:GetService("Players").LocalPlayer

    elements:Toggle("Win Farm", section, function(bool)
        if bool then
            getgenv().WinFarm = true

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
        else
            getgenv().WinFarm = false
        end
    end)
end

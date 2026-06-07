-- lumber tycoon simulator (130442872556222)

return function(section)
    local elements = getgenv()._astroElements

    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local lp = Players.LocalPlayer

    local Remotes = ReplicatedStorage:WaitForChild("Remotes")
    local purchaseUpgrade = Remotes:WaitForChild("PurchaseUpgrade")
    local prestigeRemote  = Remotes:WaitForChild("Prestige")

    local UPGRADES = {
        "Radius", "Damage", "Coins", "Wood", "Trees",
        "WalkSpeed", "SpawnRate", "LuckMultiplier", "AutoDamage"
    }
    local ZONE = "Zone1"

    local loops = {}

    local function cancelLoop(name)
        if loops[name] then
            task.cancel(loops[name])
            loops[name] = nil
        end
    end

    -- Auto Upgrade: spam all upgrades every 0.5s
    elements:Toggle("Auto Upgrade", section, function(state)
        cancelLoop("upgrade")
        if state then
            loops.upgrade = task.spawn(function()
                while true do
                    for _, id in ipairs(UPGRADES) do
                        purchaseUpgrade:FireServer(id, ZONE)
                        task.wait(0.1)
                    end
                    task.wait(0.3)
                end
            end)
        end
    end)

    -- Auto Prestige: fire prestige remote every second
    elements:Toggle("Auto Prestige", section, function(state)
        cancelLoop("prestige")
        if state then
            loops.prestige = task.spawn(function()
                while task.wait(1) do
                    prestigeRemote:FireServer()
                end
            end)
        end
    end)

    -- One-shot: buy every upgrade once immediately
    elements:Button("Max Upgrades Now", section, function()
        task.spawn(function()
            for i = 1, 50 do
                for _, id in ipairs(UPGRADES) do
                    purchaseUpgrade:FireServer(id, ZONE)
                    task.wait(0.05)
                end
            end
        end)
    end)

    section.AncestorRemoving:Connect(function()
        for name in loops do
            cancelLoop(name)
        end
    end)
end

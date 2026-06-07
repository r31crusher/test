-- lumber tycoon simulator 130442872556222
-- remotes: PurchaseUpgrade(upgradeId, zoneName), Prestige(), UnlockZone(zoneName)
-- no server validation on any of these

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local purchaseUpgrade = Remotes:WaitForChild("PurchaseUpgrade")
local prestige = Remotes:WaitForChild("Prestige")

-- all upgrade IDs from UpgradeConfig
local UPGRADES = {
    "Radius", "Damage", "Coins", "Wood", "Trees",
    "WalkSpeed", "SpawnRate", "LuckMultiplier", "AutoDamage"
}

-- only Zone1 exists in this game currently
local ZONE = "Zone1"

local function maxUpgrades()
    for i = 1, 50 do
        for _, id in ipairs(UPGRADES) do
            purchaseUpgrade:FireServer(id, ZONE)
            task.wait(0.1)
        end
    end
end

local function autoPrestige()
    for i = 1, 20 do
        prestige:FireServer()
        task.wait(0.2)
    end
end

-- main
task.spawn(maxUpgrades)
task.delay(6, autoPrestige)
task.delay(12, maxUpgrades)

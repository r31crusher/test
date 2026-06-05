-- Lemon Empire Tycoon

return function(section)
    local elements = loadstring(game:HttpGet(getgitpath("src").."elements.lua"))()

    local player = game:GetService("Players").LocalPlayer
    local RS     = game:GetService("ReplicatedStorage")

    local clickFruitRemote = RS.Core.RemoteSignal.ClickFruitService.Clicked
    local cashDropNew      = RS.Core.RemoteSignal.CashDropService.New
    local cashDropRedeem   = RS.Core.RemoteRequest.CashDropService.Redeem

    -- Find the tycoon owned by the local player.
    -- Tries both a StringValue named "Owner" and the "Owner" instance attribute.
    local function getMyTycoon()
        for i = 1, 10 do
            local t = workspace:FindFirstChild("Tycoon" .. i)
            if t then
                local ownerVal = t:FindFirstChild("Owner")
                if ownerVal and ownerVal.Value == player.Name then return t end
                if t:GetAttribute("Owner") == player.Name      then return t end
            end
        end
        return nil
    end

    -- Walk every descendant of `parent` and invoke RemoteFunctions whose name
    -- matches `remoteName`.  Skips remotes already attempted this cycle.
    local function invokeAll(parent, remoteName, delay)
        for _, desc in ipairs(parent:GetDescendants()) do
            if desc:IsA("RemoteFunction") and desc.Name == remoteName then
                pcall(function() desc:InvokeServer() end)
                task.wait(delay)
            end
        end
    end

    -- Same but only collects remotes inside folders named "Multiplier" or "Hills"
    -- (income-boosting upgrades, skipping pure cosmetic Decor items).
    local function invokeIncomeOnly(parent, delay)
        for _, desc in ipairs(parent:GetDescendants()) do
            if desc:IsA("Folder") then
                local n = desc.Name
                if n == "Multiplier" or n == "Multipliers" or n == "Hills" or n == "Other" then
                    for _, btn in ipairs(desc:GetChildren()) do
                        local rf = btn:FindFirstChildOfClass("RemoteFunction")
                        if rf and rf.Name == "Purchase" then
                            pcall(function() rf:InvokeServer() end)
                            task.wait(delay)
                        end
                    end
                end
            end
        end
    end

    -- ── Auto Buy Multipliers ──────────────────────────────────────────────────
    -- Only purchases income-multiplying upgrades (Multiplier / Hills categories).
    -- Skips expensive cosmetic Decor/Structure items so cash goes further.
    getgenv()._lemon_buyMult = false
    elements:Toggle("Auto Buy Multipliers", section, function(v)
        getgenv()._lemon_buyMult = v
        if v then
            task.spawn(function()
                while getgenv()._lemon_buyMult do
                    local tycoon = getMyTycoon()
                    if tycoon then
                        local purchases = tycoon:FindFirstChild("Purchases")
                        if purchases then
                            invokeIncomeOnly(purchases, 0.05)
                            -- Also upgrade each building
                            invokeAll(purchases, "Upgrade", 0.05)
                        end
                    end
                    task.wait(5)
                end
            end)
        end
    end)

    -- ── Auto Buy Everything ───────────────────────────────────────────────────
    -- Purchases all buttons in the tycoon including Decor and Structure.
    getgenv()._lemon_buyAll = false
    elements:Toggle("Auto Buy Everything", section, function(v)
        getgenv()._lemon_buyAll = v
        if v then
            task.spawn(function()
                while getgenv()._lemon_buyAll do
                    local tycoon = getMyTycoon()
                    if tycoon then
                        local purchases = tycoon:FindFirstChild("Purchases")
                        if purchases then
                            invokeAll(purchases, "Purchase", 0.05)
                            invokeAll(purchases, "Upgrade",  0.05)
                        end
                    end
                    task.wait(5)
                end
            end)
        end
    end)

    -- ── Auto Click Fruits ─────────────────────────────────────────────────────
    -- Fires ClickFruitService to earn passive income from fruit clicks.
    getgenv()._lemon_autoClick = false
    elements:Toggle("Auto Click Fruits", section, function(v)
        getgenv()._lemon_autoClick = v
        if v then
            task.spawn(function()
                while getgenv()._lemon_autoClick do
                    pcall(function() clickFruitRemote:FireServer() end)
                    task.wait(0.05)
                end
            end)
        end
    end)

    -- ── Auto Cash Drops ───────────────────────────────────────────────────────
    -- Listens for the server's CashDrop.New event and immediately redeems
    -- each drop by invoking CashDropService.Redeem with the received data.
    getgenv()._lemon_cashDrops = false
    local _dropConn
    elements:Toggle("Auto Cash Drops", section, function(v)
        getgenv()._lemon_cashDrops = v
        if v then
            _dropConn = cashDropNew.OnClientEvent:Connect(function(...)
                local args = {...}
                task.wait(0.1)
                pcall(function() cashDropRedeem:InvokeServer(table.unpack(args)) end)
            end)
        else
            if _dropConn then _dropConn:Disconnect(); _dropConn = nil end
        end
    end)
end

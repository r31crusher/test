-- Lemon Empire Tycoon

return function(section)
    local elements = getgenv()._astroElements

    local player = game:GetService("Players").LocalPlayer
    local RS     = game:GetService("ReplicatedStorage")

    -- Find the tycoon owned by the local player.
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

    -- Invoke every RemoteFunction named `remoteName` under `parent`.
    -- Spy confirmed args: Purchase expects (false), Upgrade expects (1).
    local function invokeAll(parent, remoteName, delay, arg)
        for _, desc in ipairs(parent:GetDescendants()) do
            if desc:IsA("RemoteFunction") and desc.Name == remoteName then
                pcall(function() desc:InvokeServer(arg) end)
                task.wait(delay)
            end
        end
    end

    -- Only invoke Purchase remotes inside Multiplier / Hills / Other folders.
    local function invokeIncomeOnly(parent, delay)
        for _, desc in ipairs(parent:GetDescendants()) do
            if desc:IsA("Folder") then
                local n = desc.Name
                if n == "Multiplier" or n == "Multipliers" or n == "Hills" or n == "Other" then
                    for _, btn in ipairs(desc:GetChildren()) do
                        local rf = btn:FindFirstChildOfClass("RemoteFunction")
                        if rf and rf.Name == "Purchase" then
                            pcall(function() rf:InvokeServer(false) end)
                            task.wait(delay)
                        end
                    end
                end
            end
        end
    end

    -- ── Auto Buy Multipliers ──────────────────────────────────────────────────
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
                            invokeAll(purchases, "Upgrade", 0.05, 1)
                        end
                    end
                    task.wait(5)
                end
            end)
        end
    end)

    -- ── Auto Buy Everything ───────────────────────────────────────────────────
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
                            invokeAll(purchases, "Purchase", 0.05, false)
                            invokeAll(purchases, "Upgrade",  0.05, 1)
                        end
                    end
                    task.wait(5)
                end
            end)
        end
    end)

    -- ── Auto Wake Income (all buildings) ─────────────────────────────────────
    -- Spy confirmed: clicking a building fires TycoonX.Remotes.WakeIncomeStream
    -- with the building name stripped of spaces, e.g. "LemonDepot".
    -- We iterate every building in Purchases and wake them all on a tight loop.
    getgenv()._lemon_autoClick = false
    elements:Toggle("Auto Wake Income", section, function(v)
        getgenv()._lemon_autoClick = v
        if v then
            task.spawn(function()
                while getgenv()._lemon_autoClick do
                    local tycoon = getMyTycoon()
                    if tycoon then
                        local remotes   = tycoon:FindFirstChild("Remotes")
                        local wakeRemote = remotes and remotes:FindFirstChild("WakeIncomeStream")
                        local purchases  = tycoon:FindFirstChild("Purchases")
                        if wakeRemote and purchases then
                            for _, building in ipairs(purchases:GetChildren()) do
                                if not getgenv()._lemon_autoClick then break end
                                local key = building.Name:gsub("%s+", "")
                                pcall(function() wakeRemote:InvokeServer(key) end)
                                task.wait(0.05)
                            end
                        end
                    end
                    task.wait(0.1)
                end
            end)
        end
    end)

    -- ── Auto Cash Drops ───────────────────────────────────────────────────────
    getgenv()._lemon_cashDrops = false
    local _dropConn
    elements:Toggle("Auto Cash Drops", section, function(v)
        getgenv()._lemon_cashDrops = v
        if v then
            local newRemote = RS:FindFirstChild("Core")
                and RS.Core:FindFirstChild("RemoteSignal")
                and RS.Core.RemoteSignal:FindFirstChild("CashDropService")
                and RS.Core.RemoteSignal.CashDropService:FindFirstChild("New")
            local redeemRemote = RS:FindFirstChild("Core")
                and RS.Core:FindFirstChild("RemoteRequest")
                and RS.Core.RemoteRequest:FindFirstChild("CashDropService")
                and RS.Core.RemoteRequest.CashDropService:FindFirstChild("Redeem")
            if not newRemote or not redeemRemote then return end
            _dropConn = newRemote.OnClientEvent:Connect(function(...)
                local args = {...}
                task.wait(0.1)
                pcall(function() redeemRemote:InvokeServer(table.unpack(args)) end)
            end)
        else
            if _dropConn then _dropConn:Disconnect(); _dropConn = nil end
        end
    end)
end

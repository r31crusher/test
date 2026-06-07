-- Bedwars (PlaceId 6872265039)

return function(section)
    local elements = getgenv()._astroElements
    local Players  = game:GetService("Players")
    local RunSvc   = game:GetService("RunService")
    local player   = Players.LocalPlayer

    local function isEnemy(p)
        return p ~= player and not (p.Team and p.Team == player.Team)
    end

    -- ── ESP ───────────────────────────────────────────────────────────────────
    getgenv()._bdESP = false
    local _espBills = {}

    local function _makeESP(p)
        if not isEnemy(p) then return end
        local function attach()
            local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local bb = Instance.new("BillboardGui")
            bb.Name = "_bdESP"; bb.Size = UDim2.new(0, 140, 0, 44)
            bb.StudsOffset = Vector3.new(0, 3.5, 0); bb.AlwaysOnTop = true
            bb.Adornee = hrp; bb.Parent = game.CoreGui
            local nameLbl = Instance.new("TextLabel", bb)
            nameLbl.Size = UDim2.new(1, 0, 0.55, 0); nameLbl.BackgroundTransparency = 1
            nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize = 13
            nameLbl.TextStrokeTransparency = 0
            nameLbl.TextColor3 = p.Team and p.Team.TeamColor.Color or Color3.fromRGB(255, 80, 80)
            nameLbl.Text = p.Name
            local healthLbl = Instance.new("TextLabel", bb)
            healthLbl.Size = UDim2.new(1, 0, 0.45, 0); healthLbl.Position = UDim2.new(0, 0, 0.55, 0)
            healthLbl.BackgroundTransparency = 1; healthLbl.Font = Enum.Font.Gotham
            healthLbl.TextSize = 11; healthLbl.TextStrokeTransparency = 0
            healthLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
            _espBills[p] = { bb = bb, nameLbl = nameLbl, healthLbl = healthLbl, hrp = hrp }
        end
        attach()
        p.CharacterAdded:Connect(function()
            task.wait(0.5)
            if _espBills[p] then _espBills[p].bb:Destroy(); _espBills[p] = nil end
            if getgenv()._bdESP then attach() end
        end)
    end

    local function _removeESP(p)
        if _espBills[p] then _espBills[p].bb:Destroy(); _espBills[p] = nil end
    end

    local _espRender, _espAdded, _espRemoving

    local function _startESP()
        for _, p in Players:GetPlayers() do _makeESP(p) end
        _espAdded    = Players.PlayerAdded:Connect(_makeESP)
        _espRemoving = Players.PlayerRemoving:Connect(_removeESP)
        _espRender   = RunSvc.RenderStepped:Connect(function()
            local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            for p, data in pairs(_espBills) do
                if not data.bb.Parent then _espBills[p] = nil; continue end
                local hum  = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
                local dist = myHRP and math.floor((data.hrp.Position - myHRP.Position).Magnitude) or 0
                data.nameLbl.TextColor3 = p.Team and p.Team.TeamColor.Color or Color3.fromRGB(255, 80, 80)
                data.nameLbl.Text = p.Name
                data.healthLbl.Text = hum and string.format("HP: %d  [%dm]", math.floor(hum.Health), dist) or ""
            end
        end)
    end

    local function _stopESP()
        if _espRender   then _espRender:Disconnect()   _espRender   = nil end
        if _espAdded    then _espAdded:Disconnect()    _espAdded    = nil end
        if _espRemoving then _espRemoving:Disconnect() _espRemoving = nil end
        for _, data in pairs(_espBills) do data.bb:Destroy() end
        table.clear(_espBills)
    end

    elements:Toggle("ESP", section, function(v)
        getgenv()._bdESP = v
        if v then _startESP() else _stopESP() end
    end)

    -- ── Unload ────────────────────────────────────────────────────────────────
    section.AncestorRemoving:Connect(function()
        getgenv()._bdESP = false
        _stopESP()
    end)
end

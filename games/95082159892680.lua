return function(section)
    local elements   = getgenv()._astroElements
    local Players    = game:GetService("Players")
    local RunSvc     = game:GetService("RunService")
    local RS         = game:GetService("ReplicatedStorage")
    local lp         = Players.LocalPlayer

    local _conns = {}

    local function notify(text)
        local sg = Instance.new("ScreenGui")
        sg.Name = "_astroAcNotif"
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        sg.Parent = game.CoreGui

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 300, 0, 50)
        frame.Position = UDim2.new(0.5, -150, 0, 80)
        frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        frame.BackgroundTransparency = 0.2
        frame.BorderSizePixel = 0
        frame.Parent = sg
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(255, 70, 70)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 14
        lbl.Parent = frame

        task.delay(5, function() sg:Destroy() end)
    end

    table.insert(_conns, RS:WaitForChild("CheatWarningEvent").OnClientEvent:Connect(function()
        notify("Anticheat triggered!")
    end))

    local _speedActive = false
    local _speedVal    = 1000

    local function zeroVelocity()
        local char = lp.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.AssemblyLinearVelocity = Vector3.zero end
    end

    elements:Toggle("Speed Override", section, function(v)
        _speedActive = v
        if not v then
            local char = lp.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
            zeroVelocity()
        end
    end)

    elements:Slider("Speed", section, 100, 50000, 1000, function(v)
        _speedVal = v
    end)

    table.insert(_conns, RunSvc.Heartbeat:Connect(function()
        if not _speedActive then return end
        local char = lp.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hum and hrp and hum.Health > 0 then
            hum.WalkSpeed = _speedVal
            if hum.MoveDirection.Magnitude == 0 then
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end))

    local _autoWinActive = false

    local function applyNoclip()
        local char = lp.Character
        if not char then return end
        for _, p in char:GetDescendants() do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end

    local function collectWinBlocks()
        local found = {}
        for _, d in workspace:GetDescendants() do
            if d:IsA("BasePart") and d.Name:match("^WinBlock%d") then
                local n = tonumber(d.Name:match("%d+$")) or 0
                table.insert(found, { part = d, num = n })
            end
        end
        table.sort(found, function(a, b) return a.num < b.num end)
        return found
    end

    elements:Toggle("Auto Win", section, function(v)
        _autoWinActive = v
        if not v then return end
        task.spawn(function()
            local blocks = collectWinBlocks()
            if #blocks == 0 then _autoWinActive = false return end

            local idx = 1
            while _autoWinActive and idx <= #blocks do
                local char = lp.Character
                local hum  = char and char:FindFirstChildOfClass("Humanoid")
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if not (hum and hrp and hum.Health > 0) then task.wait(0.1) continue end

                local entry = blocks[idx]
                if not entry.part.Parent then idx += 1 continue end

                applyNoclip()
                hum.WalkSpeed = _speedVal

                local dist = (entry.part.Position - hrp.Position).Magnitude
                if dist < 3 then
                    idx += 1
                    task.wait(1.5)
                elseif dist <= 10 then
                    hum.WalkSpeed = 16
                    hum:MoveTo(entry.part.Position)
                else
                    hum:MoveTo(entry.part.Position)
                end

                task.wait(0.1)
            end

            _autoWinActive = false
        end)
    end)

    table.insert(_conns, RunSvc.Heartbeat:Connect(function()
        if not _autoWinActive then return end
        applyNoclip()
    end))

    section.AncestorRemoving:Connect(function()
        _speedActive   = false
        _autoWinActive = false
        for _, c in _conns do c:Disconnect() end
        table.clear(_conns)
    end)
end

return function(section)
    local elements = getgenv()._astroElements
    local Players  = game:GetService("Players")
    local RunSvc   = game:GetService("RunService")
    local lp       = Players.LocalPlayer

    local _conns = {}

    local _speedActive = false
    local _speedVal    = 1000

    elements:Toggle("Speed Override", section, function(v)
        _speedActive = v
    end)

    elements:Slider("Speed", section, 100, 50000, 1000, function(v)
        _speedVal = v
    end)

    table.insert(_conns, RunSvc.Heartbeat:Connect(function()
        if not _speedActive then return end
        local char = lp.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            hum.WalkSpeed = _speedVal
        end
    end))

    local _autoWinActive = false
    local _autoWinSpeed  = 5000

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
            if #blocks == 0 then
                _autoWinActive = false
                return
            end
            local idx = 1
            while _autoWinActive and idx <= #blocks do
                local char = lp.Character
                local hum  = char and char:FindFirstChildOfClass("Humanoid")
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 then
                    applyNoclip()
                    hum.WalkSpeed = _autoWinSpeed
                    local entry = blocks[idx]
                    if not entry.part.Parent then
                        idx += 1
                    else
                        local dist = (entry.part.Position - hrp.Position).Magnitude
                        if dist < 5 then
                            idx += 1
                            task.wait(1.5)
                        else
                            hum:MoveTo(entry.part.Position)
                        end
                    end
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

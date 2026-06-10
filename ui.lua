
local TeleportService  = game:GetService("TeleportService")
local HttpService      = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local plr              = game:GetService("Players").LocalPlayer

local Library = loadstring(game:HttpGet(getgitpath("src") .. "Library.lua"))()

Library.Scheme.BackgroundColor = Color3.fromRGB(9,  11, 17)
Library.Scheme.MainColor       = Color3.fromRGB(16, 19, 26)
Library.Scheme.AccentColor     = Color3.fromRGB(210, 215, 240)
Library.Scheme.OutlineColor    = Color3.fromRGB(26, 31, 48)
Library.Scheme.FontColor       = Color3.new(1, 1, 1)

local Window = Library:CreateWindow({
    Title         = "Astro",
    Footer        = "v2.0  |  Insert to toggle",
    ToggleKeybind = Enum.KeyCode.Insert,
    AutoShow      = true,
    Size          = UDim2.fromOffset(820, 640),
    GlobalSearch  = true,
})

local Tabs = {
    Home      = Window:AddTab("Home",      "home"),
    Universal = Window:AddTab("Universal", "shield"),
    Game      = Window:AddTab("Game",      "gamepad-2"),
    Players   = Window:AddTab("Players",   "users"),
    Gameslist = Window:AddTab("Gameslist", "list"),
    Settings  = Window:AddTab("Settings",  "settings"),
    Credits   = Window:AddTab("Credits",   "heart"),
}

task.defer(function()
    local _tabOrder = {
        Tabs.Home, Tabs.Universal, Tabs.Game,
        Tabs.Players, Tabs.Gameslist, Tabs.Settings, Tabs.Credits,
    }
    local _accentMap = {}
    for i, tabObj in ipairs(_tabOrder) do
        local info = Library.TabButtons and Library.TabButtons[i]
        if not info or not info.Label then continue end
        local btn = info.Label.Parent
        if not btn then continue end

        local glow = Instance.new("Frame")
        glow.Size                 = UDim2.new(0, 6, 0.55, 0)
        glow.AnchorPoint          = Vector2.new(0, 0.5)
        glow.Position             = UDim2.new(0, 0, 0.5, 0)
        glow.BackgroundColor3     = Color3.fromRGB(210, 215, 240)
        glow.BackgroundTransparency = 0.82
        glow.BorderSizePixel      = 0
        glow.ZIndex               = (btn.ZIndex or 1) + 1
        glow.Visible              = false
        glow.Parent               = btn
        local gc = Instance.new("UICorner")
        gc.CornerRadius           = UDim.new(0, 3)
        gc.Parent                 = glow

        local line = Instance.new("Frame")
        line.Size                 = UDim2.new(0, 2, 0.55, 0)
        line.AnchorPoint          = Vector2.new(0, 0.5)
        line.Position             = UDim2.new(0, 0, 0.5, 0)
        line.BackgroundColor3     = Color3.fromRGB(210, 215, 240)
        line.BorderSizePixel      = 0
        line.ZIndex               = (btn.ZIndex or 1) + 2
        line.Visible              = false
        line.Parent               = btn
        local lc = Instance.new("UICorner")
        lc.CornerRadius           = UDim.new(0, 1)
        lc.Parent                 = line

        _accentMap[tabObj] = {line = line, glow = glow}
    end

    local function _refreshAccents()
        for t, parts in pairs(_accentMap) do
            local on = (Library.ActiveTab == t)
            parts.line.Visible = on
            parts.glow.Visible = on
        end
    end

    for tabObj in pairs(_accentMap) do
        local orig = tabObj.Show
        tabObj.Show = function(...)
            orig(...)
            _refreshAccents()
        end
    end

    _refreshAccents()
end)

local _uidCtr = 0
local function uid(p) _uidCtr += 1; return p .. tostring(_uidCtr) end

local _kbRegistry = {}
local _kbPosX, _kbPosY = 10, nil
local function _kbRegister(label, kp, getActive, mode)
    table.insert(_kbRegistry, {label=label, kp=kp, getActive=getActive, mode=mode})
end

local _setSpeedBoost_obj, _flyTog, _noclipTog, _aimbotTog, _setBoxEsp_obj

local GameGB       = Tabs.Game:AddLeftGroupbox("Game")
local GameRGB      = Tabs.Game:AddRightGroupbox("Info")
local _makeAdapter = loadstring(game:HttpGet(getgitpath("src") .. "elements.lua"))()
getgenv()._astroElements = _makeAdapter(GameGB)
local _gameSection = GameGB.Container or GameGB.Content or GameGB[1] or GameGB

local _sessionStart  = tick()
local _featuresUsed  = 0
local _playersJoined = 0
game:GetService("Players").PlayerAdded:Connect(function() _playersJoined += 1 end)

local HomeLogoGB  = Tabs.Home:AddLeftGroupbox("Astro")
local HomeQAGB    = Tabs.Home:AddRightGroupbox("Quick Actions")
local HomeStatsGB = Tabs.Home:AddRightGroupbox("Session")

HomeLogoGB:AddLabel("  ___   ___  ____  ____  ___  ")
HomeLogoGB:AddLabel(" / _ | / __||_  / |  _ \\/ _ \\ ")
HomeLogoGB:AddLabel("| (_| |\\__ \\ / /  | |_) | (_) |")
HomeLogoGB:AddLabel(" \\__,_||___//_/   |____/ \\___/ ")
HomeLogoGB:AddLabel(" ")
HomeLogoGB:AddLabel("universal exploit tools")
HomeLogoGB:AddLabel("press Insert to show / hide")
HomeLogoGB:AddLabel(" ")
HomeLogoGB:AddLabel("Game:  " .. tostring(game.PlaceId))

HomeQAGB:AddButton({Text = "Toggle Speed",  Func = function()
    if _setSpeedBoost_obj then _setSpeedBoost_obj:SetValue(not _setSpeedBoost_obj.Value) end
end})
HomeQAGB:AddButton({Text = "Toggle Fly",    Func = function()
    if _flyTog    then _flyTog:SetValue(not _flyTog.Value)       end
end})
HomeQAGB:AddButton({Text = "Toggle Noclip", Func = function()
    if _noclipTog then _noclipTog:SetValue(not _noclipTog.Value) end
end})
HomeQAGB:AddButton({Text = "Toggle Aimbot", Func = function()
    if _aimbotTog then _aimbotTog:SetValue(not _aimbotTog.Value) end
end})
HomeQAGB:AddButton({Text = "Toggle Box ESP", Func = function()
    if _setBoxEsp_obj then _setBoxEsp_obj:SetValue(not _setBoxEsp_obj.Value) end
end})

local _sessionElapsedLbl  = HomeStatsGB:AddLabel("Uptime:  0:00")
local _sessionFeaturesLbl = HomeStatsGB:AddLabel("Features used:  0")
local _sessionPlayersLbl  = HomeStatsGB:AddLabel("Players joined:  0")

task.spawn(function()
    while true do
        task.wait(1)
        local e    = math.floor(tick() - _sessionStart)
        local mins = math.floor(e / 60)
        local secs = e % 60
        pcall(function()
            _sessionElapsedLbl:SetText(string.format("Uptime:  %d:%02d", mins, secs))
            _sessionFeaturesLbl:SetText("Features used:  " .. _featuresUsed)
            _sessionPlayersLbl:SetText("Players joined:  " .. _playersJoined)
        end)
    end
end)

local UnivL = Tabs.Universal:AddLeftGroupbox("Movement & Combat")
local UnivR = Tabs.Universal:AddRightGroupbox("ESP & Visual")

local movL  = UnivL
local movR  = UnivL
local cmbL  = UnivL
local cmbR  = UnivL
local espL  = UnivR
local espR  = UnivR
local visL  = UnivR

UnivL:AddLabel("── Speed ─────────────────────────────────")
local _walkSpeed   = 50
local _walkEnabled = false

_setSpeedBoost_obj = movL:AddToggle(uid("tog"), {
    Text     = "Speed Boost",
    Default  = false,
    Callback = function(v)
        _walkEnabled = v
        if v then _featuresUsed += 1 end
        if plr.Character then
            local h = plr.Character:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = v and _walkSpeed or 16 end
        end
    end,
})
local _setSpeedBoost = function(v) _setSpeedBoost_obj:SetValue(v) end

local _setWalkSpeed_obj = movL:AddSlider(uid("sld"), {
    Text     = "Walk Speed",
    Min      = 8,
    Max      = 250,
    Default  = 50,
    Rounding = 0,
    Callback = function(v)
        _walkSpeed = v
        if _walkEnabled and plr.Character then
            local h = plr.Character:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = v end
        end
    end,
})
local _setWalkSpeed = function(v) _setWalkSpeed_obj:SetValue(v) end

plr.CharacterAdded:Connect(function(char)
    local h = char:WaitForChild("Humanoid", 5)
    if h then h.WalkSpeed = _walkEnabled and _walkSpeed or 16 end
end)

UnivL:AddLabel("── Fly ───────────────────────────────────")

local _flyBV, _flyBG
local _flySpeed = 50
getgenv()._astroFlying = false

_flyTog = movL:AddToggle(uid("tog"), {
    Text     = "Fly  (WASD · Space=up · Shift=down)",
    Default  = false,
    Callback = function(on)
        getgenv()._astroFlying = on
        if on then _featuresUsed += 1 end
        local char = plr.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if on then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = true end
            _flyBV = Instance.new("BodyVelocity", hrp)
            _flyBV.Velocity = Vector3.zero
            _flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            _flyBG = Instance.new("BodyGyro", hrp)
            _flyBG.MaxTorque = Vector3.new(9e4, 9e4, 9e4)
            _flyBG.P = 9e4
            _flyBG.D = 1e3
            RunService:BindToRenderStep("AstroFly", Enum.RenderPriority.Character.Value + 1, function()
                if not getgenv()._astroFlying then
                    RunService:UnbindFromRenderStep("AstroFly")
                    return
                end
                local cam = workspace.CurrentCamera
                local dir = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector  end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector  end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then dir += Vector3.yAxis end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis end
                _flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * _flySpeed or Vector3.zero
                _flyBG.CFrame   = cam.CFrame
            end)
        else
            RunService:UnbindFromRenderStep("AstroFly")
            if _flyBV then _flyBV:Destroy(); _flyBV = nil end
            if _flyBG then _flyBG:Destroy(); _flyBG = nil end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
        end
    end,
})
local setFly = function(v) _flyTog:SetValue(v) end

local _flyKPIdx = uid("kp")
_flyTog:AddKeyPicker(_flyKPIdx, {
    Text            = "Fly Key",
    Default         = "F",
    Mode            = "Toggle",
    SyncToggleState = false,
    Callback = function(v)
        if v ~= nil then setFly(v) end
    end,
})
local _flyKP = Library.Options and Library.Options[_flyKPIdx]
_kbRegister("Fly", _flyKP, function() return _flyTog.Value end, "Toggle")

local _setFlySpeed_obj = movL:AddSlider(uid("sld"), {
    Text     = "Fly Speed",
    Min      = 10,
    Max      = 300,
    Default  = 50,
    Rounding = 0,
    Callback = function(v) _flySpeed = v end,
})
local _setFlySpeed = function(v) _setFlySpeed_obj:SetValue(v) end

UnivL:AddLabel("── Misc ──────────────────────────────────")

getgenv()._astroWalkFling = false
movL:AddToggle(uid("tog"), {
    Text     = "Walk Fling",
    Default  = false,
    Callback = function(v)
        getgenv()._astroWalkFling = v
        if not v then return end
        task.spawn(function()
            local movel = 0.1
            while getgenv()._astroWalkFling do
                RunService.Heartbeat:Wait()
                local char = plr.Character
                local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
                if char and char.Parent and root and root.Parent then
                    local vel = root.Velocity
                    root.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
                    RunService.RenderStepped:Wait()
                    if root and root.Parent then root.Velocity = vel end
                    RunService.Stepped:Wait()
                    if root and root.Parent then
                        root.Velocity = vel + Vector3.new(0, movel, 0)
                        movel = movel * -1
                    end
                else
                    RunService.Heartbeat:Wait()
                end
            end
        end)
    end,
})

getgenv()._astroNoclip = false
local _noclipParts = {}

local function _cacheNoclipParts()
    _noclipParts = {}
    local char = plr.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then table.insert(_noclipParts, p) end
    end
end

_noclipTog = movR:AddToggle(uid("tog"), {
    Text     = "Noclip",
    Default  = false,
    Callback = function(v)
        getgenv()._astroNoclip = v
        if v then _featuresUsed += 1; _cacheNoclipParts() end
    end,
})
local setNoclip = function(v) _noclipTog:SetValue(v) end

local _noclipKPIdx = uid("kp")
_noclipTog:AddKeyPicker(_noclipKPIdx, {
    Text            = "Noclip Key",
    Default         = "V",
    Mode            = "Toggle",
    SyncToggleState = false,
    Callback = function(v)
        if v ~= nil then
            getgenv()._astroNoclip = v
            _noclipTog:SetValue(v)
            if v then _cacheNoclipParts() end
        end
    end,
})
local _noclipKP = Library.Options and Library.Options[_noclipKPIdx]
_kbRegister("Noclip", _noclipKP, function() return _noclipTog.Value end, "Toggle")

plr.CharacterAdded:Connect(function()
    _noclipParts = {}
    if getgenv()._astroNoclip then
        task.wait(0.5)
        _cacheNoclipParts()
    end
end)

RunService.Stepped:Connect(function()
    if not getgenv()._astroNoclip then return end
    for _, p in ipairs(_noclipParts) do
        if p.Parent then p.CanCollide = false end
    end
end)

getgenv()._astroInfJump = false
local _setInfJump_obj = movR:AddToggle(uid("tog"), {
    Text     = "Infinite Jump",
    Default  = false,
    Callback = function(v) getgenv()._astroInfJump = v end,
})
local _setInfJump = function(v) _setInfJump_obj:SetValue(v) end

UserInputService.JumpRequest:Connect(function()
    if not getgenv()._astroInfJump then return end
    local char = plr.Character
    if not char then return end
    local h = char:FindFirstChildOfClass("Humanoid")
    if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

getgenv()._astroAntiFall = false
local _afLastSafe = nil

local _setAntiFall_obj = movR:AddToggle(uid("tog"), {
    Text     = "Anti-Fall",
    Default  = false,
    Callback = function(v)
        getgenv()._astroAntiFall = v
        if not v then _afLastSafe = nil end
    end,
})
local _setAntiFall = function(v) _setAntiFall_obj:SetValue(v) end

RunService.Heartbeat:Connect(function()
    if not getgenv()._astroAntiFall then return end
    local char = plr.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    if hum.FloorMaterial ~= Enum.Material.Air then
        _afLastSafe = hrp.CFrame
    end
    if _afLastSafe and hrp.Position.Y < _afLastSafe.Position.Y - 60 then
        hrp.CFrame = _afLastSafe
    end
end)

getgenv()._astroAntiAfk = false
local _setAntiAfk_obj = movR:AddToggle(uid("tog"), {
    Text     = "Anti-AFK",
    Default  = false,
    Callback = function(v)
        getgenv()._astroAntiAfk = v
        if v then
            task.spawn(function()
                while getgenv()._astroAntiAfk do
                    task.wait(60)
                    if getgenv()._astroAntiAfk then
                        pcall(function()
                            local vim = game:GetService("VirtualInputManager")
                            vim:SendKeyEvent(true,  "Q", false, game)
                            vim:SendKeyEvent(false, "Q", false, game)
                        end)
                    end
                end
            end)
        end
    end,
})
local _setAntiAfk = function(v) _setAntiAfk_obj:SetValue(v) end

local _fbOrig
local _fullbrightOn = false
local _setFullbright_obj = movR:AddToggle(uid("tog"), {
    Text     = "Fullbright",
    Default  = false,
    Callback = function(v)
        _fullbrightOn = v
        local L = game:GetService("Lighting")
        if v then
            _fbOrig = {L.Brightness, L.Ambient, L.OutdoorAmbient, L.FogEnd}
            L.Brightness     = 2
            L.Ambient        = Color3.fromRGB(178, 178, 178)
            L.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
            L.FogEnd         = 1e6
        elseif _fbOrig then
            L.Brightness     = _fbOrig[1]
            L.Ambient        = _fbOrig[2]
            L.OutdoorAmbient = _fbOrig[3]
            L.FogEnd         = _fbOrig[4]
        end
    end,
})
local _setFullbright = function(v) _setFullbright_obj:SetValue(v) end

UnivL:AddLabel("── Aimbot ────────────────────────────────")
local _aimFOV   = 200
local _aimSpeed = 8
local _aimMode  = "Legacy"

local _rayParams = RaycastParams.new()
_rayParams.FilterType = Enum.RaycastFilterType.Exclude

local _rayFilter = {nil, nil}
local function _isVisible(targetPart)
    local origin = workspace.CurrentCamera.CFrame.Position
    _rayFilter[1] = targetPart.Parent
    _rayFilter[2] = plr.Character
    _rayParams.FilterDescendantsInstances = _rayFilter
    return workspace:Raycast(origin, targetPart.Position - origin, _rayParams) == nil
end

local function getAimTarget()
    local cam    = workspace.CurrentCamera
    local lp     = game:GetService("Players").LocalPlayer
    local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    local best, bestDist = nil, _aimFOV
    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        if p == lp then continue end
        if getgenv()._astroAimTeamCheck and lp.Team and p.Team == lp.Team then continue end
        local char = p.Character or workspace:FindFirstChild(p.Name)
        if not char then continue end
        local head = char:FindFirstChild("Head")
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if not head or not hum or hum.Health <= 0 then continue end
        local sp, onScreen = cam:WorldToViewportPoint(head.Position)
        if not onScreen then continue end
        if getgenv()._astroAimVisCheck and not _isVisible(head) then continue end
        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d < bestDist then bestDist = d; best = head end
    end
    return best
end

local _silentHookOrig = nil

local function _installSilentHook()
    if _silentHookOrig then return end
    local ok, orig = pcall(hookmetamethod, game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local saActive = _aimMode == "Silent" and getgenv()._aimEnabled
        if self == workspace and saActive
                and (method == "Raycast" or method == "Spherecast" or method == "Blockcast") then
            local origin, direction = ...
            if method == "Blockcast" and typeof(origin) == "CFrame" then
                origin = origin.Position
            end
            if origin and direction then
                local camPos = workspace.CurrentCamera.CFrame.Position
                if (origin - camPos).Magnitude < 100 then
                    local tgt = getAimTarget()
                    if tgt then
                        local args = {...}
                        args[2] = (tgt.Position - origin).Unit * direction.Magnitude
                        return _silentHookOrig(self, table.unpack(args))
                    end
                end
            end
        end
        return _silentHookOrig(self, ...)
    end)
    if ok then _silentHookOrig = orig end
end

getgenv()._aimEnabled  = false
getgenv()._astroAiming = false
_aimbotTog = cmbL:AddToggle(uid("tog"), {
    Text     = "Aimbot",
    Default  = false,
    Callback = function(v)
        getgenv()._aimEnabled = v
        if v then _featuresUsed += 1 end
        if not v then getgenv()._astroAiming = false end
    end,
})
local _setAimbot = function(v) _aimbotTog:SetValue(v) end

local _aimbotKPIdx = uid("kp")
_aimbotTog:AddKeyPicker(_aimbotKPIdx, {
    Text            = "Aimbot Key",
    Default         = "E",
    Mode            = "Hold",
    SyncToggleState = false,
    Callback = function(v)
        if getgenv()._aimEnabled then
            getgenv()._astroAiming = v
        end
    end,
})
local _aimbotKP = Library.Options and Library.Options[_aimbotKPIdx]
_kbRegister("Aimbot", _aimbotKP, function() return _aimbotTog.Value end, "Hold")

cmbL:AddDropdown(uid("dd"), {
    Text     = "Aim Mode",
    Values   = {"Legacy", "Silent"},
    Default  = "Legacy",
    Callback = function(v)
        _aimMode = v
        if v == "Silent" then _installSilentHook() end
    end,
})

local _setAimFOV_obj = cmbL:AddSlider(uid("sld"), {
    Text     = "Aim FOV",
    Min      = 50,
    Max      = 600,
    Default  = 200,
    Rounding = 0,
    Callback = function(v) _aimFOV = v end,
})
local _setAimFOV = function(v) _setAimFOV_obj:SetValue(v) end

local _setAimSmooth_obj = cmbL:AddSlider(uid("sld"), {
    Text     = "Aim Smoothness",
    Min      = 1,
    Max      = 20,
    Default  = 8,
    Rounding = 0,
    Callback = function(v) _aimSpeed = v end,
})
local _setAimSmooth = function(v) _setAimSmooth_obj:SetValue(v) end

getgenv()._astroAimTeamCheck = false
local _setTeamCheck_obj = cmbL:AddToggle(uid("tog"), {
    Text     = "Team Check",
    Default  = false,
    Callback = function(v) getgenv()._astroAimTeamCheck = v end,
})
local _setTeamCheck = function(v) _setTeamCheck_obj:SetValue(v) end

getgenv()._astroAimVisCheck = false
local _setAimVisCheck_obj = cmbL:AddToggle(uid("tog"), {
    Text     = "Vis Check",
    Default  = false,
    Callback = function(v) getgenv()._astroAimVisCheck = v end,
})
local _setAimVisCheck = function(v) _setAimVisCheck_obj:SetValue(v) end

RunService:BindToRenderStep("AstroAim", Enum.RenderPriority.Last.Value, function()
    if not getgenv()._astroAiming then return end
    local target = getAimTarget()
    if not target then return end
    if _aimMode == "Legacy" then
        local cam = workspace.CurrentCamera
        local t = math.clamp(_aimSpeed / 20, 0.05, 1)
        cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, target.Position), t)
    end
end)

UnivL:AddLabel("── Utilities ─────────────────────────────")

getgenv()._astroSpinbot = false
cmbR:AddToggle(uid("tog"), {
    Text     = "Spinbot",
    Default  = false,
    Callback = function(v)
        getgenv()._astroSpinbot = v
        if v then
            RunService:BindToRenderStep("AstroSpinBot", Enum.RenderPriority.Character.Value + 1, function()
                if not getgenv()._astroSpinbot then
                    RunService:UnbindFromRenderStep("AstroSpinBot")
                    return
                end
                local char = plr.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, tick() * 15, 0)
                end
            end)
        else
            RunService:UnbindFromRenderStep("AstroSpinBot")
        end
    end,
})

getgenv()._astroDesync = false
cmbR:AddToggle(uid("tog"), {
    Text     = "Desync",
    Default  = false,
    Callback = function(v)
        getgenv()._astroDesync = v
        if v then
            task.spawn(function()
                while getgenv()._astroDesync do
                    local char = plr.Character
                    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local real = hrp.CFrame
                        hrp.CFrame = real * CFrame.new(0, 1e4, 0)
                        RunService.Heartbeat:Wait()
                        hrp.CFrame = real
                    end
                    task.wait(0.1)
                end
            end)
        end
    end,
})

getgenv()._astroHitboxes = false
local _hitboxSize      = 8
local _hitboxOrigSizes = {}

local function _applyHitbox(p)
    if p == plr then return end
    local char = p.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and not _hitboxOrigSizes[p.UserId] then
        _hitboxOrigSizes[p.UserId] = hrp.Size
        hrp.Size = Vector3.new(_hitboxSize, _hitboxSize, _hitboxSize)
    end
end

local function _clearHitbox(p)
    if p.Character then
        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
        if hrp and _hitboxOrigSizes[p.UserId] then
            hrp.Size = _hitboxOrigSizes[p.UserId]
        end
    end
    _hitboxOrigSizes[p.UserId] = nil
end

local _setHitboxes_obj = cmbR:AddToggle(uid("tog"), {
    Text     = "Hitboxes",
    Default  = false,
    Callback = function(v)
        getgenv()._astroHitboxes = v
        if v then
            for _, p in game:GetService("Players"):GetPlayers() do _applyHitbox(p) end
        else
            for _, p in game:GetService("Players"):GetPlayers() do _clearHitbox(p) end
            _hitboxOrigSizes = {}
        end
    end,
})
local _setHitboxes = function(v) _setHitboxes_obj:SetValue(v) end

cmbR:AddSlider(uid("sld"), {
    Text     = "Hitbox Size",
    Min      = 2,
    Max      = 20,
    Default  = 8,
    Rounding = 0,
    Callback = function(v)
        _hitboxSize = v
        if getgenv()._astroHitboxes then
            _hitboxOrigSizes = {}
            for _, p in game:GetService("Players"):GetPlayers() do _applyHitbox(p) end
        end
    end,
})

for _, _hbp in game:GetService("Players"):GetPlayers() do
    _hbp.CharacterAdded:Connect(function()
        task.wait(0.2)
        if getgenv()._astroHitboxes then _applyHitbox(_hbp) end
    end)
end
game:GetService("Players").PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.2)
        if getgenv()._astroHitboxes then _applyHitbox(p) end
    end)
end)

getgenv()._astroTracers = false

local function _drawTracer(origin, hitPos)
    local cam = workspace.CurrentCamera
    local ln  = Drawing.new("Line")
    ln.Color     = Color3.fromRGB(255, 210, 50)
    ln.Thickness = 1.5
    local t, dur = 0, 0.35
    while t < dur do
        t += RunService.RenderStepped:Wait()
        local oSP       = cam:WorldToViewportPoint(origin)
        local hSP, onSc = cam:WorldToViewportPoint(hitPos)
        ln.Visible = onSc and oSP.Z > 0
        if ln.Visible then
            ln.From         = Vector2.new(oSP.X, oSP.Y)
            ln.To           = Vector2.new(hSP.X, hSP.Y)
            ln.Transparency = t / dur
        end
    end
    ln:Remove()
end

local _tracerHookOrig = nil
local function _installTracerHook()
    if _tracerHookOrig then return end
    local ok, orig = pcall(hookmetamethod, game, "__namecall", function(self, ...)
        local result = _tracerHookOrig(self, ...)
        if getnamecallmethod() == "Raycast" and self == workspace
                and getgenv()._astroTracers then
            local origin, direction = ...
            if origin and direction then
                local camPos = workspace.CurrentCamera.CFrame.Position
                if (origin - camPos).Magnitude < 15 then
                    local hit = result and result.Position or (origin + direction)
                    task.spawn(_drawTracer, origin, hit)
                end
            end
        end
        return result
    end)
    if ok then _tracerHookOrig = orig end
end

cmbR:AddToggle(uid("tog"), {
    Text     = "Bullet Tracers",
    Default  = false,
    Callback = function(v)
        getgenv()._astroTracers = v
        if v then _installTracerHook() end
    end,
})

UnivR:AddLabel("── ESP Overlays ──────────────────────────")
local _esp = {box=false, skeleton=false, name=false, distance=false, weapon=false, health=false}
local _espD = {}

_setBoxEsp_obj  = espL:AddToggle(uid("tog"), {Text = "Box",        Default = false, Callback = function(v) _esp.box      = v; if v then _featuresUsed+=1 end end})
local _setSkelEsp_obj = espL:AddToggle(uid("tog"), {Text = "Skeleton",   Default = false, Callback = function(v) _esp.skeleton = v end})
local _setNameEsp_obj = espL:AddToggle(uid("tog"), {Text = "Name",       Default = false, Callback = function(v) _esp.name     = v end})
local _setDistEsp_obj = espL:AddToggle(uid("tog"), {Text = "Distance",   Default = false, Callback = function(v) _esp.distance = v end})
local _setWeapEsp_obj = espL:AddToggle(uid("tog"), {Text = "Weapon",     Default = false, Callback = function(v) _esp.weapon   = v end})
local _setHpEsp_obj   = espL:AddToggle(uid("tog"), {Text = "Health Bar", Default = false, Callback = function(v) _esp.health   = v end})

local _setBoxEsp  = function(v) _setBoxEsp_obj:SetValue(v)  end
local _setSkelEsp = function(v) _setSkelEsp_obj:SetValue(v) end
local _setNameEsp = function(v) _setNameEsp_obj:SetValue(v) end
local _setDistEsp = function(v) _setDistEsp_obj:SetValue(v) end
local _setWeapEsp = function(v) _setWeapEsp_obj:SetValue(v) end
local _setHpEsp   = function(v) _setHpEsp_obj:SetValue(v)   end

UnivR:AddLabel("── ESP Filters ───────────────────────────")
local _espTeamCheck = false
local _setEspTeamCheck_obj = espL:AddToggle(uid("tog"), {
    Text     = "Team Check",
    Default  = false,
    Callback = function(v) _espTeamCheck = v end,
})
local _setEspTeamCheck = function(v) _setEspTeamCheck_obj:SetValue(v) end

local _espVisCheck = false
local _setEspVisCheck_obj = espL:AddToggle(uid("tog"), {
    Text     = "Vis Check",
    Default  = false,
    Callback = function(v) _espVisCheck = v end,
})
local _setEspVisCheck = function(v) _setEspVisCheck_obj:SetValue(v) end

local _espColorMap = {
    Red    = Color3.fromRGB(255, 50,  50),
    Orange = Color3.fromRGB(255, 145,  0),
    Yellow = Color3.fromRGB(255, 235, 40),
    Green  = Color3.fromRGB(50,  255, 80),
    Cyan   = Color3.fromRGB(40,  215, 255),
    Blue   = Color3.fromRGB(60,  110, 255),
    Purple = Color3.fromRGB(180, 60,  255),
    White  = Color3.fromRGB(255, 255, 255),
}
local _espColorNames     = {"Red","Orange","Yellow","Green","Cyan","Blue","Purple","White"}
local _espVisColor       = _espColorMap.Red
local _espNoVisColor     = _espColorMap.Orange
local _espVisColorName   = "Red"
local _espNoVisColorName = "Orange"

UnivR:AddLabel("── ESP Colors ────────────────────────────")
espR:AddDropdown(uid("dd"), {
    Text     = "Visible Color",
    Values   = _espColorNames,
    Default  = "Red",
    Callback = function(v) _espVisColorName = v; _espVisColor = _espColorMap[v] end,
})
espR:AddDropdown(uid("dd"), {
    Text     = "Hidden Color",
    Values   = _espColorNames,
    Default  = "Orange",
    Callback = function(v) _espNoVisColorName = v; _espNoVisColor = _espColorMap[v] end,
})

UnivR:AddLabel("── Visual ────────────────────────────────")
local _hitSoundObj = Instance.new("Sound")
_hitSoundObj.SoundId = "rbxassetid://2766953031"
_hitSoundObj.Volume  = 0.5
_hitSoundObj.RollOffMaxDistance = 0
_hitSoundObj.Parent = game.CoreGui
getgenv()._astroHitSound = false

local function _showDmgNum(worldPos, amount)
    local txt   = Drawing.new("Text")
    txt.Text    = "-" .. math.round(amount)
    txt.Size    = 18
    txt.Color   = Color3.fromRGB(255, 60, 60)
    txt.Outline = true
    txt.Center  = true
    local t, dur = 0, 1.0
    local baseY = worldPos.Y
    while t < dur do
        t += RunService.RenderStepped:Wait()
        local sp, onSc = workspace.CurrentCamera:WorldToViewportPoint(
            Vector3.new(worldPos.X, baseY + t * 3, worldPos.Z))
        txt.Visible = onSc and sp.Z > 0
        if txt.Visible then
            txt.Position     = Vector2.new(sp.X, sp.Y)
            txt.Transparency = t / dur
        end
    end
    txt:Remove()
end

getgenv()._astroDmgInd = false
local _dmgWatchers = {}

local function _watchDmg(p)
    if p == plr or _dmgWatchers[p.UserId] then return end
    local conns = {}
    _dmgWatchers[p.UserId] = conns
    local function attachChar(char)
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local prev = hum.Health
        table.insert(conns, hum.HealthChanged:Connect(function(hp)
            local dmg = prev - hp
            if dmg > 0 then
                if getgenv()._astroDmgInd then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then task.spawn(_showDmgNum, hrp.Position, dmg) end
                end
                if getgenv()._astroHitSound then _hitSoundObj:Play() end
            end
            prev = hp
        end))
    end
    if p.Character then attachChar(p.Character) end
    table.insert(conns, p.CharacterAdded:Connect(function(c)
        task.wait(0.2); attachChar(c)
    end))
end

local function _unwatchDmg(p)
    local conns = _dmgWatchers[p.UserId]
    if conns then
        for _, c in conns do pcall(function() c:Disconnect() end) end
        _dmgWatchers[p.UserId] = nil
    end
end

local function _startDmgWatch()
    for _, p in game:GetService("Players"):GetPlayers() do _watchDmg(p) end
end
local function _stopDmgWatchIfNone()
    if not getgenv()._astroDmgInd and not getgenv()._astroHitSound then
        for _, p in game:GetService("Players"):GetPlayers() do _unwatchDmg(p) end
    end
end

game:GetService("Players").PlayerAdded:Connect(function(p)
    if getgenv()._astroDmgInd or getgenv()._astroHitSound then _watchDmg(p) end
end)
game:GetService("Players").PlayerRemoving:Connect(function(p) _unwatchDmg(p) end)

getgenv()._astroCrosshair = false
local _chLines  = {}
local _chRender = nil

local function _buildCrosshair()
    if #_chLines > 0 then return end
    local function mkLine()
        local l = Drawing.new("Line")
        l.Color = Color3.fromRGB(255, 255, 255); l.Thickness = 1.5; l.Visible = true
        return l
    end
    local dot = Drawing.new("Circle")
    dot.Radius = 1.5; dot.Color = Color3.fromRGB(255, 255, 255)
    dot.Filled = true; dot.Visible = true
    _chLines = {mkLine(), mkLine(), mkLine(), mkLine(), dot}

    _chRender = RunService.RenderStepped:Connect(function()
        if not getgenv()._astroCrosshair then return end
        local vp = workspace.CurrentCamera.ViewportSize
        local cx, cy, g, l = vp.X/2, vp.Y/2, 4, 8
        _chLines[1].From = Vector2.new(cx,     cy-g-l); _chLines[1].To = Vector2.new(cx,     cy-g)
        _chLines[2].From = Vector2.new(cx,     cy+g  ); _chLines[2].To = Vector2.new(cx,     cy+g+l)
        _chLines[3].From = Vector2.new(cx-g-l, cy    ); _chLines[3].To = Vector2.new(cx-g,   cy)
        _chLines[4].From = Vector2.new(cx+g,   cy    ); _chLines[4].To = Vector2.new(cx+g+l, cy)
        _chLines[5].Position = Vector2.new(cx, cy)
    end)
end

local function _destroyCrosshair()
    if _chRender then _chRender:Disconnect(); _chRender = nil end
    for _, d in _chLines do pcall(function() d:Remove() end) end
    _chLines = {}
end

getgenv()._astroViewmodel = false
local _vmGui, _vmRender, _vmLastCF, _vmPrevTool
local _vmSpringX = {pos = 0, vel = 0}
local _vmSpringY = {pos = 0, vel = 0}

local function _vmSpringStep(s, target, dt)
    local acc = (target - s.pos) * 12 - s.vel * 5
    s.vel += acc * dt; s.pos += s.vel * dt
    return s.pos
end

local function _enableViewmodel()
    if _vmGui then return end
    _vmLastCF = workspace.CurrentCamera.CFrame

    _vmGui = Instance.new("ScreenGui")
    _vmGui.Name = "_astroVM"; _vmGui.ResetOnSpawn = false
    _vmGui.DisplayOrder = 5; _vmGui.Parent = game.CoreGui

    local vf = Instance.new("ViewportFrame", _vmGui)
    vf.Size           = UDim2.new(0.42, 0, 0.38, 0)
    vf.Position       = UDim2.new(1, -8, 1, -8)
    vf.AnchorPoint    = Vector2.new(1, 1)
    vf.BackgroundTransparency = 1
    vf.LightDirection = Vector3.new(-1, -1, -1)
    vf.LightColor     = Color3.new(1, 1, 1)
    vf.AmbientColor   = Color3.fromRGB(180, 180, 180)

    local vmCam = Instance.new("Camera", vf)
    vmCam.FieldOfView = 55
    vf.CurrentCamera  = vmCam

    _vmRender = RunService.RenderStepped:Connect(function(dt)
        if not getgenv()._astroViewmodel then return end
        local cam   = workspace.CurrentCamera
        local delta = _vmLastCF:ToObjectSpace(cam.CFrame)
        _vmLastCF   = cam.CFrame
        local sx = _vmSpringStep(_vmSpringX, math.clamp(delta.Position.X, -1, 1) * 0.05, dt)
        local sy = _vmSpringStep(_vmSpringY, math.clamp(delta.Position.Y, -1, 1) * 0.05, dt)

        local char   = plr.Character
        local tool   = char and char:FindFirstChildOfClass("Tool")
        local handle = tool and tool:FindFirstChild("Handle")
        vf.Visible   = handle ~= nil
        if not handle then _vmPrevTool = nil; return end

        if tool ~= _vmPrevTool then
            _vmPrevTool = tool
            for _, c in vf:GetChildren() do
                if c:IsA("BasePart") then c:Destroy() end
            end
            local h2 = handle:Clone()
            h2.Anchored = true; h2.CanCollide = false
            h2.CastShadow = false; h2.Name = "VMHandle"
            h2.Parent = vf
        end

        local vmh = vf:FindFirstChild("VMHandle")
        if not vmh then return end
        vmh.CFrame = CFrame.new(0.38 + sx, -0.26 + sy, -0.6)
            * CFrame.Angles(math.rad(-8) + sy * 0.4, sx * 0.4, 0)
        vmCam.CFrame = CFrame.new(Vector3.zero)
    end)
end

local function _disableViewmodel()
    if _vmRender then _vmRender:Disconnect(); _vmRender = nil end
    if _vmGui    then _vmGui:Destroy();       _vmGui    = nil end
    _vmPrevTool = nil
end

visL:AddToggle(uid("tog"), {
    Text     = "Damage Indicators",
    Default  = false,
    Callback = function(v)
        getgenv()._astroDmgInd = v
        if v then _startDmgWatch() else _stopDmgWatchIfNone() end
    end,
})
visL:AddToggle(uid("tog"), {
    Text     = "Hit Sound",
    Default  = false,
    Callback = function(v)
        getgenv()._astroHitSound = v
        if v then _startDmgWatch() else _stopDmgWatchIfNone() end
    end,
})
visL:AddToggle(uid("tog"), {
    Text     = "Crosshair",
    Default  = false,
    Callback = function(v)
        getgenv()._astroCrosshair = v
        if v then _buildCrosshair() else _destroyCrosshair() end
    end,
})
visL:AddToggle(uid("tog"), {
    Text     = "Viewmodel",
    Default  = false,
    Callback = function(v)
        getgenv()._astroViewmodel = v
        if v then _enableViewmodel() else _disableViewmodel() end
    end,
})

local SettingsGB  = Tabs.Settings:AddLeftGroupbox("Config")
local SettingsRGB = Tabs.Settings:AddRightGroupbox("Actions")

local CFG_FILE  = "astro/universal/config.json"
local META_FILE = "astro/universal/meta.json"

local function _cfgEnsureDirs()
    if not isfolder("astro")           then makefolder("astro")           end
    if not isfolder("astro/universal") then makefolder("astro/universal") end
end

local function _readMeta()
    if not isfile(META_FILE) then return {} end
    local ok, d = pcall(function() return HttpService:JSONDecode(readfile(META_FILE)) end)
    return (ok and type(d) == "table") and d or {}
end

local function _writeMeta(tbl)
    _cfgEnsureDirs()
    writefile(META_FILE, HttpService:JSONEncode(tbl))
end

local _kbGui = Instance.new("ScreenGui")
_kbGui.Name           = "._astroKB"
_kbGui.ResetOnSpawn   = false
_kbGui.IgnoreGuiInset = true
_kbGui.DisplayOrder   = 2
_kbGui.Parent         = game.CoreGui

local _kbFrame = Instance.new("Frame")
_kbFrame.BackgroundColor3       = Color3.fromRGB(6, 6, 10)
_kbFrame.BackgroundTransparency = 0.15
_kbFrame.BorderSizePixel        = 0
_kbFrame.Size                   = UDim2.fromOffset(175, 20)
_kbFrame.Parent                 = _kbGui
Instance.new("UICorner", _kbFrame).CornerRadius = UDim.new(0, 5)

local _kbPad = Instance.new("UIPadding", _kbFrame)
_kbPad.PaddingLeft   = UDim.new(0, 7)
_kbPad.PaddingRight  = UDim.new(0, 7)
_kbPad.PaddingTop    = UDim.new(0, 4)
_kbPad.PaddingBottom = UDim.new(0, 4)

local _kbLayout = Instance.new("UIListLayout", _kbFrame)
_kbLayout.FillDirection = Enum.FillDirection.Vertical
_kbLayout.SortOrder     = Enum.SortOrder.LayoutOrder
_kbLayout.Padding       = UDim.new(0, 2)

local _kbTitle = Instance.new("TextLabel", _kbFrame)
_kbTitle.Size                 = UDim2.new(1, 0, 0, 13)
_kbTitle.BackgroundTransparency = 1
_kbTitle.Text                 = "KEYBINDS"
_kbTitle.TextColor3           = Color3.fromRGB(180, 180, 200)
_kbTitle.TextSize             = 10
_kbTitle.Font                 = Enum.Font.GothamBold
_kbTitle.TextXAlignment       = Enum.TextXAlignment.Left
_kbTitle.LayoutOrder          = 0

local _kbRows = {}

local function _getKeyName(kp)

    local ok, v = pcall(function() return kp.Value end)
    return (ok and v and tostring(v)) or "?"
end

task.spawn(function()
    RunService.RenderStepped:Wait()

    local vp = workspace.CurrentCamera.ViewportSize
    _kbFrame.Position = UDim2.fromOffset(_kbPosX, _kbPosY or math.floor(vp.Y * 0.5 - 40))

    while _kbGui.Parent do

        while #_kbRows < #_kbRegistry do
            local r = Instance.new("TextLabel", _kbFrame)
            r.Size                  = UDim2.new(1, 0, 0, 14)
            r.BackgroundTransparency = 1
            r.TextSize              = 11
            r.Font                  = Enum.Font.Gotham
            r.TextXAlignment        = Enum.TextXAlignment.Left
            r.TextTruncate          = Enum.TextTruncate.AtEnd
            r.LayoutOrder           = #_kbRows + 1
            table.insert(_kbRows, r)
        end

        for i, entry in ipairs(_kbRegistry) do
            local key  = _getKeyName(entry.kp)

            local modeOk, modeVal = pcall(function() return entry.kp.Mode end)
            local mode = "(" .. (modeOk and modeVal or entry.mode) .. ")"
            local activeOk, active = pcall(entry.getActive)
            active = activeOk and active or false
            local row = _kbRows[i]
            row.Text       = "[" .. key .. "]  " .. entry.label .. "  " .. mode
            row.TextColor3 = active
                and Color3.fromRGB(220, 220, 240)
                or  Color3.fromRGB(80, 80, 100)
            row.Visible = true
        end
        for i = #_kbRegistry + 1, #_kbRows do _kbRows[i].Visible = false end

        local rCount = #_kbRegistry
        _kbFrame.Size = UDim2.fromOffset(175, 4 + 13 + (rCount > 0 and 2 + rCount * 16 or 0) + 4)

        task.wait(0.15)
    end
end)

do
    local UIS = game:GetService("UserInputService")
    local dragging, dragStart, frameStart = false, nil, nil

    _kbFrame.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging   = true
            dragStart  = inp.Position
            frameStart = _kbFrame.AbsolutePosition
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if not dragging or inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local d  = inp.Position - dragStart
        local vp = workspace.CurrentCamera.ViewportSize
        local nx = math.clamp(frameStart.X + d.X, 0, vp.X - _kbFrame.AbsoluteSize.X)
        local ny = math.clamp(frameStart.Y + d.Y, 0, vp.Y - _kbFrame.AbsoluteSize.Y)
        _kbFrame.Position = UDim2.fromOffset(nx, ny)
        _kbPosX, _kbPosY = nx, ny
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
            dragging = false
            pcall(saveConfig)
        end
    end)
end


local function saveConfig()
    _cfgEnsureDirs()
    local data = {
        walkSpeed         = _walkSpeed,
        walkEnabled       = _walkEnabled,
        flySpeed          = _flySpeed,
        noclipEnabled     = getgenv()._astroNoclip,
        infJump           = getgenv()._astroInfJump,
        fullbright        = _fullbrightOn,
        antiAfk           = getgenv()._astroAntiAfk,
        aimEnabled        = getgenv()._aimEnabled,
        aimFOV            = _aimFOV,
        aimSpeed          = _aimSpeed,
        aimTeamCheck      = getgenv()._astroAimTeamCheck,
        aimVisCheck       = getgenv()._astroAimVisCheck,
        aimMode           = _aimMode,
        espBox            = _esp.box,
        espSkeleton       = _esp.skeleton,
        espName           = _esp.name,
        espDistance       = _esp.distance,
        espWeapon         = _esp.weapon,
        espHealth         = _esp.health,
        espTeamCheck      = _espTeamCheck,
        espVisCheck       = _espVisCheck,
        espVisColorName   = _espVisColorName,
        espNoVisColorName = _espNoVisColorName,
        kbPosX            = _kbPosX,
        kbPosY            = _kbPosY,
    }
    writefile(CFG_FILE, HttpService:JSONEncode(data))
end

local function loadConfig()
    if not isfile(CFG_FILE) then return false end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CFG_FILE)) end)
    if not ok or type(data) ~= "table" then return false end

    if data.walkSpeed then _setWalkSpeed(data.walkSpeed) end
    if data.flySpeed  then _setFlySpeed(data.flySpeed)   end
    if data.aimFOV    then _setAimFOV(data.aimFOV)       end
    if data.aimSpeed  then _setAimSmooth(data.aimSpeed)  end

    if data.walkEnabled   ~= nil then _setSpeedBoost(data.walkEnabled)  end
    if data.noclipEnabled ~= nil then setNoclip(data.noclipEnabled)     end
    if data.infJump       ~= nil then _setInfJump(data.infJump)         end
    if data.fullbright    ~= nil then _setFullbright(data.fullbright)   end
    if data.antiAfk       ~= nil then _setAntiAfk(data.antiAfk)        end
    if data.aimEnabled    ~= nil then _setAimbot(data.aimEnabled)       end
    if data.aimTeamCheck  ~= nil then _setTeamCheck(data.aimTeamCheck)  end
    if data.aimVisCheck   ~= nil then _setAimVisCheck(data.aimVisCheck) end
    if data.aimMode then
        _aimMode = data.aimMode
        if _aimMode == "Silent" then _installSilentHook() end
    end

    if data.espBox      ~= nil then _setBoxEsp(data.espBox)       end
    if data.espSkeleton ~= nil then _setSkelEsp(data.espSkeleton) end
    if data.espName     ~= nil then _setNameEsp(data.espName)     end
    if data.espDistance ~= nil then _setDistEsp(data.espDistance) end
    if data.espWeapon   ~= nil then _setWeapEsp(data.espWeapon)   end
    if data.espHealth   ~= nil then _setHpEsp(data.espHealth)     end
    if data.espTeamCheck ~= nil then _setEspTeamCheck(data.espTeamCheck) end
    if data.espVisCheck  ~= nil then _setEspVisCheck(data.espVisCheck)   end
    if data.espVisColorName then
        _espVisColorName = data.espVisColorName
        _espVisColor = _espColorMap[data.espVisColorName] or _espVisColor
    end
    if data.espNoVisColorName then
        _espNoVisColorName = data.espNoVisColorName
        _espNoVisColor = _espColorMap[data.espNoVisColorName] or _espNoVisColor
    end

    if data.kbPosX then _kbPosX = data.kbPosX end
    if data.kbPosY then _kbPosY = data.kbPosY end
    pcall(function() _kbFrame.Position = UDim2.fromOffset(_kbPosX, _kbPosY) end)

    return true
end

local function silentLoadConfig()
    if not isfile(CFG_FILE) then return false end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CFG_FILE)) end)
    if not ok or type(data) ~= "table" then return false end

    if data.walkSpeed then _walkSpeed = data.walkSpeed end
    if data.flySpeed  then _flySpeed  = data.flySpeed  end
    if data.aimFOV    then _aimFOV    = data.aimFOV    end
    if data.aimSpeed  then _aimSpeed  = data.aimSpeed  end
    if data.aimMode then
        _aimMode = data.aimMode
        if _aimMode == "Silent" then _installSilentHook() end
    end
    if data.espVisColorName then
        _espVisColorName = data.espVisColorName
        _espVisColor = _espColorMap[data.espVisColorName] or _espVisColor
    end
    if data.espNoVisColorName then
        _espNoVisColorName = data.espNoVisColorName
        _espNoVisColor = _espColorMap[data.espNoVisColorName] or _espNoVisColor
    end

    return true
end

local _autoLoad = _readMeta().autoLoad == true

SettingsGB:AddButton({Text = "Save Config",  Func = function() pcall(saveConfig)       end})
SettingsGB:AddButton({Text = "Load Config",  Func = function() pcall(loadConfig)       end})
SettingsGB:AddButton({Text = "Silent Load",  Func = function() pcall(silentLoadConfig) end})

local _autoLoadTog = SettingsGB:AddToggle(uid("tog"), {
    Text     = "Auto Load on Start",
    Default  = false,
    Callback = function(v)
        _autoLoad = v
        local m = _readMeta(); m.autoLoad = v
        pcall(_writeMeta, m)
    end,
})
local _setAutoLoad = function(v) _autoLoadTog:SetValue(v) end
_setAutoLoad(_autoLoad)

SettingsGB:AddToggle(uid("tog"), {
    Text     = "Disable 3D Rendering",
    Default  = false,
    Callback = function(v) RunService:Set3dRenderingEnabled(not v) end,
})
SettingsGB:AddToggle(uid("tog"), {
    Text     = "Auto Rejoin on kick",
    Default  = false,
    Callback = function(v) getgenv().autorjjjj = v end,
})

SettingsRGB:AddButton({
    Text = "Unload",
    Func = function()
        if getgenv()._astroUnload then getgenv()._astroUnload() end
    end,
})

if _autoLoad then pcall(loadConfig) end

local _espGui = Instance.new("ScreenGui")
_espGui.Name           = "_astroESP"
_espGui.ResetOnSpawn   = false
_espGui.IgnoreGuiInset = true
_espGui.DisplayOrder   = 1
_espGui.Parent         = game.CoreGui

local SKL_R15 = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}
local SKL_R6 = {
    {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},
    {"Torso","Left Leg"},{"Torso","Right Leg"},
}

local PROBE_NAMES = {
    "Head","HumanoidRootPart","LeftFoot","RightFoot","LeftHand","RightHand",
    "LeftLowerLeg","RightLowerLeg","LeftLowerArm","RightLowerArm",
    "Left Leg","Right Leg","Left Arm","Right Arm","Torso",
}

local function _newContainer()
    local f = Instance.new("Frame")
    f.Size = UDim2.fromScale(1, 1)
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.Parent = _espGui
    return f
end

local function _newBoxFrames(parent)
    local t = {}
    for i = 1, 4 do
        local f = Instance.new("Frame")
        f.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        f.BorderSizePixel  = 0
        f.Visible          = false
        f.Parent           = parent
        t[i] = f
    end
    return t
end

local function _applyBox(t, x0, y0, x1, y1, col)
    local w, h, tk = x1-x0, y1-y0, 2
    for _, f in ipairs(t) do f.BackgroundColor3 = col; f.Visible = true end
    t[1].Position=UDim2.new(0,x0,    0,y0   ); t[1].Size=UDim2.new(0,w, 0,tk)
    t[2].Position=UDim2.new(0,x0,    0,y1-tk); t[2].Size=UDim2.new(0,w, 0,tk)
    t[3].Position=UDim2.new(0,x0,    0,y0   ); t[3].Size=UDim2.new(0,tk,0,h )
    t[4].Position=UDim2.new(0,x1-tk, 0,y0   ); t[4].Size=UDim2.new(0,tk,0,h )
end

local function _newLineFrame(parent)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    f.BorderSizePixel  = 0
    f.AnchorPoint      = Vector2.new(0.5, 0.5)
    f.Visible          = false
    f.Parent           = parent
    return f
end

local function _applyLine(f, ax, ay, bx, by, col)
    local dx, dy = bx-ax, by-ay
    local len = math.sqrt(dx*dx + dy*dy)
    if len < 1 then f.Visible = false; return end
    f.BackgroundColor3 = col
    f.Size     = UDim2.new(0, len, 0, 1)
    f.Position = UDim2.new(0, (ax+bx)*0.5, 0, (ay+by)*0.5)
    f.Rotation = math.deg(math.atan2(dy, dx))
    f.Visible  = true
end

local function _newLbl(parent, sz, col)
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Font                   = Enum.Font.GothamBold
    t.TextSize               = sz  or 13
    t.TextColor3             = col or Color3.fromRGB(255, 255, 255)
    t.TextStrokeTransparency = 0.5
    t.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
    t.AnchorPoint            = Vector2.new(0.5, 0.5)
    t.Size                   = UDim2.new(0, 300, 0, 20)
    t.Visible                = false
    t.Parent                 = parent
    return t
end

local function _newHpBar(parent)
    local bg = Instance.new("Frame")
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BorderSizePixel  = 0
    bg.ClipsDescendants = true
    bg.Visible          = false
    bg.Parent           = parent
    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    fill.BorderSizePixel  = 0
    fill.AnchorPoint      = Vector2.new(0, 1)
    fill.Position         = UDim2.new(0, 0, 1, 0)
    fill.Size             = UDim2.new(1, 0, 1, 0)
    fill.Parent           = bg
    return bg, fill
end

local _espPartCache = {}

local function _buildPartCache(userId, char)
    local pts = {}
    local needed = {}
    for _, n in ipairs(PROBE_NAMES)   do needed[n] = true end
    for _, c in ipairs(SKL_R15)       do needed[c[1]] = true; needed[c[2]] = true end
    for _, c in ipairs(SKL_R6)        do needed[c[1]] = true; needed[c[2]] = true end
    for n in pairs(needed) do
        local p = char:FindFirstChild(n)
        if p then pts[n] = p end
    end
    _espPartCache[userId] = {char = char, parts = pts}
end

local function _connectPartCache(p)
    if p.Character then _buildPartCache(p.UserId, p.Character) end
    p.CharacterAdded:Connect(function(char)
        task.wait(0.1)
        _buildPartCache(p.UserId, char)
    end)
end
for _, p in ipairs(game:GetService("Players"):GetPlayers()) do _connectPartCache(p) end
game:GetService("Players").PlayerAdded:Connect(_connectPartCache)

local function getESPData(uid)
    if not _espD[uid] then
        local c = _newContainer()
        local hpBg, hpFill = _newHpBar(c)
        _espD[uid] = {
            container = c,
            boxF      = _newBoxFrames(c),
            hpBg      = hpBg,
            hpFill    = hpFill,
            nameT     = _newLbl(c, 13, Color3.fromRGB(255, 255, 255)),
            distT     = _newLbl(c, 11, Color3.fromRGB(160, 210, 255)),
            weapT     = _newLbl(c, 11, Color3.fromRGB(255, 210, 80)),
            sklLines  = {},
        }
    end
    return _espD[uid]
end

local function hideAll(d)
    for _, f in ipairs(d.boxF) do f.Visible = false end
    d.hpBg.Visible  = false
    d.nameT.Visible = false
    d.distT.Visible = false
    d.weapT.Visible = false
    for _, f in ipairs(d.sklLines) do f.Visible = false end
end

local function cleanESP(uid)
    local d = _espD[uid]
    if not d then return end
    pcall(function() d.container:Destroy() end)
    _espD[uid]          = nil
    _espPartCache[uid]  = nil
end

local function updateESP(p)
    local d      = getESPData(p.UserId)
    local cached = _espPartCache[p.UserId]
    local char   = p.Character or workspace:FindFirstChild(p.Name)
    if not char then hideAll(d); return end
    if not cached or cached.char ~= char then
        _buildPartCache(p.UserId, char)
        cached = _espPartCache[p.UserId]
    end
    local pts = cached.parts

    local hrp = pts["HumanoidRootPart"]
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then hideAll(d); return end
    if _espTeamCheck and plr.Team and p.Team and p.Team == plr.Team then hideAll(d); return end

    local cam      = workspace.CurrentCamera
    local vis      = not _espVisCheck or _isVisible(hrp)
    local espColor = vis and _espVisColor or _espNoVisColor

    local head = pts["Head"]
    if not head or not head.Parent then
        head = char:FindFirstChild("Head")
        if head then pts["Head"] = head else hideAll(d); return end
    end

    local footPart = pts["LeftFoot"] or pts["RightFoot"] or pts["Left Leg"] or pts["Right Leg"]
    local headTop  = head.Position + Vector3.new(0, head.Size.Y * 0.5, 0)
    local feetPos
    if footPart and footPart.Parent then
        feetPos = footPart.Position - Vector3.new(0, footPart.Size.Y * 0.5, 0)
    else
        feetPos = hrp.Position - Vector3.new(0, hum.HipHeight + 0.5, 0)
    end

    local spHead, onHead = cam:WorldToViewportPoint(headTop)
    local spFeet, onFeet = cam:WorldToViewportPoint(feetPos)
    local spHrp,  onHrp  = cam:WorldToViewportPoint(hrp.Position)
    if not onHead and not onFeet and not onHrp then hideAll(d); return end

    local cx    = spHrp.X
    local minY  = math.min(spHead.Y, spFeet.Y) - 4
    local maxY  = math.max(spHead.Y, spFeet.Y) + 4
    local halfW = (maxY - minY) * 0.28
    local minX  = cx - halfW
    local maxX  = cx + halfW

    if _esp.box then
        _applyBox(d.boxF, minX, minY, maxX, maxY, espColor)
    else
        for _, f in ipairs(d.boxF) do f.Visible = false end
    end

    if _esp.health then
        local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
        local r = math.clamp(math.floor(255*(1-ratio)*2), 0, 255)
        local g = math.clamp(math.floor(255*ratio*2),     0, 255)
        d.hpBg.Position = UDim2.new(0, minX-7, 0, minY)
        d.hpBg.Size     = UDim2.new(0, 4, 0, maxY-minY)
        d.hpBg.Visible  = true
        d.hpFill.BackgroundColor3 = Color3.fromRGB(r, g, 0)
        d.hpFill.Size     = UDim2.new(1, 0, ratio, 0)
        d.hpFill.Position = UDim2.new(0, 0, 1, 0)
    else
        d.hpBg.Visible = false
    end

    local textY = minY - 10
    if _esp.name then
        d.nameT.Position = UDim2.new(0, cx, 0, textY)
        d.nameT.Text     = p.DisplayName
        d.nameT.Visible  = true
        textY -= 14
    else
        d.nameT.Visible = false
    end

    if _esp.distance then
        local myHRP = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        if myHRP then
            d.distT.Text     = math.floor((myHRP.Position - hrp.Position).Magnitude) .. "m"
            d.distT.Position = UDim2.new(0, cx, 0, textY)
            d.distT.Visible  = true
        else
            d.distT.Visible = false
        end
    else
        d.distT.Visible = false
    end

    if _esp.weapon then
        local tool = char:FindFirstChildOfClass("Tool")
        d.weapT.Text     = tool and tool.Name or ""
        d.weapT.Position = UDim2.new(0, cx, 0, maxY + 10)
        d.weapT.Visible  = d.weapT.Text ~= ""
    else
        d.weapT.Visible = false
    end

    if _esp.skeleton then

        local isR15  = char:FindFirstChild("UpperTorso") ~= nil
        local camPos = cam.CFrame.Position
        local camLook= cam.CFrame.LookVector

        local segs
        if isR15 then
            segs = {}
            for _, c in ipairs(SKL_R15) do
                local p0 = pts[c[1]] or char:FindFirstChild(c[1])
                local p1 = pts[c[2]] or char:FindFirstChild(c[2])
                if p0 and p1 and p0.Parent and p1.Parent then
                    table.insert(segs, {p0.Position, p1.Position})
                else
                    table.insert(segs, false)
                end
            end
        else

            local torso    = pts["Torso"] or char:FindFirstChild("Torso")
            local headPt   = pts["Head"]  or char:FindFirstChild("Head")
            local leftArm  = pts["Left Arm"]  or char:FindFirstChild("Left Arm")
            local rightArm = pts["Right Arm"] or char:FindFirstChild("Right Arm")
            local leftLeg  = pts["Left Leg"]  or char:FindFirstChild("Left Leg")
            local rightLeg = pts["Right Leg"] or char:FindFirstChild("Right Leg")

            local spineRef = torso or hrp
            local shoulder, hip
            if spineRef and spineRef.Parent then
                local h = (torso and torso.Size.Y or 2) * 0.5 - 0.1
                shoulder = spineRef.Position + Vector3.new(0,  h, 0)
                hip      = spineRef.Position + Vector3.new(0, -h, 0)
            end
            segs = {
                headPt   and shoulder and {headPt.Position,   shoulder} or false,
                shoulder and hip      and {shoulder,           hip}      or false,
                leftArm  and shoulder and {shoulder,  leftArm.Position}  or false,
                rightArm and shoulder and {shoulder, rightArm.Position}  or false,
                leftLeg  and hip      and {hip,       leftLeg.Position}  or false,
                rightLeg and hip      and {hip,      rightLeg.Position}  or false,
            }
        end

        while #d.sklLines < #segs do
            table.insert(d.sklLines, _newLineFrame(d.container))
        end
        for i, seg in ipairs(segs) do
            local lf = d.sklLines[i]
            if seg and (seg[1]-camPos):Dot(camLook) > 0 and (seg[2]-camPos):Dot(camLook) > 0 then
                local s0 = cam:WorldToViewportPoint(seg[1])
                local s1 = cam:WorldToViewportPoint(seg[2])
                _applyLine(lf, s0.X, s0.Y, s1.X, s1.Y, espColor)
            else
                lf.Visible = false
            end
        end
        for i = #segs+1, #d.sklLines do d.sklLines[i].Visible = false end
    else
        for _, f in ipairs(d.sklLines) do f.Visible = false end
    end
end

RunService.RenderStepped:Connect(function()
    if not (_esp.box or _esp.skeleton or _esp.name or _esp.distance or _esp.weapon or _esp.health) then return end
    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        if p ~= plr then updateESP(p) end
    end
end)

game:GetService("Players").PlayerRemoving:Connect(function(p)
    cleanESP(p.UserId)
end)

local CreditsGB = Tabs.Credits:AddLeftGroupbox("Credits")
local ok3, credSrc = pcall(game.HttpGet, game, getgitpath("src") .. "credits.json")
if ok3 and credSrc then
    local credits = HttpService:JSONDecode(credSrc)
    for sect, people in pairs(credits) do
        CreditsGB:AddLabel("> " .. sect)
        for _, person in ipairs(people) do
            CreditsGB:AddLabel("  + " .. person)
        end
    end
end

do
    local Players = game:GetService("Players")

    local PlayersLeft  = Tabs.Players:AddLeftGroupbox("Players")
    local PlayersRight = Tabs.Players:AddRightGroupbox("Selected Player")

    local _countLbl = PlayersLeft:AddLabel("0 players online")

    local _selectedPlayer = nil
    local _trollId        = 0

    local function getOtherNames()
        local names = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= plr then table.insert(names, p.DisplayName) end
        end
        table.sort(names)
        return names
    end

    local _playerDD = PlayersLeft:AddDropdown(uid("dd"), {
        Text       = "Select Player",
        Values     = getOtherNames(),
        Default    = nil,
        AllowNull  = true,
        Searchable = true,
        Callback   = function(v)
            if not v then _selectedPlayer = nil; return end
            for _, p in ipairs(Players:GetPlayers()) do
                if p.DisplayName == v then _selectedPlayer = p; return end
            end
            _selectedPlayer = nil
        end,
    })

    local _nameLbl  = PlayersRight:AddLabel("No player selected")
    local _statsLbl = PlayersRight:AddLabel("")

    PlayersRight:AddButton({Text = "Teleport To", Func = function()
        local p = _selectedPlayer; if not p then return end
        local myHRP  = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        local tgtHRP = p.Character   and p.Character:FindFirstChild("HumanoidRootPart")
        if myHRP and tgtHRP then myHRP.CFrame = tgtHRP.CFrame + Vector3.new(3, 0, 0) end
    end})

    PlayersRight:AddButton({Text = "Spectate", Func = function()
        local p = _selectedPlayer; if not p then return end
        local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            workspace.CurrentCamera.CameraSubject = hum
            workspace.CurrentCamera.CameraType    = Enum.CameraType.Follow
        end
    end})

    PlayersRight:AddButton({Text = "Fling", Func = function()
        local p = _selectedPlayer; if not p then return end
        local myChar = plr.Character
        local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
        local myHRP  = myHum and myHum.RootPart
        local tgtChar = p.Character
        local tgtHum  = tgtChar and tgtChar:FindFirstChildOfClass("Humanoid")
        local tgtHRP  = tgtHum and tgtHum.RootPart
        local tgtHead = tgtChar and (tgtChar:FindFirstChild("Head") or tgtChar:FindFirstChild("UpperTorso"))
        if not myChar or not myHum or not myHRP then return end
        if not tgtChar or (not tgtHRP and not tgtHead) then return end

        local savedCF        = myHRP.CFrame
        local orgFallHeight  = workspace.FallenPartsDestroyHeight

        local function fpos(base, pos, ang)
            local cf = CFrame.new(base.Position) * pos * ang
            myHRP.CFrame = cf
            myChar:SetPrimaryPartCFrame(cf)
            myHRP.Velocity    = Vector3.new(9e7, 9e7 * 10, 9e7)
            myHRP.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        end

        local function sfbase(base)
            local deadline = tick() + 2
            local angle    = 0
            repeat
                if not myHRP or not tgtHum then break end
                if base.Velocity.Magnitude < 50 then
                    angle += 100
                    local md = tgtHum.MoveDirection * (base.Velocity.Magnitude / 1.25)
                    fpos(base, CFrame.new( 0,     1.5,  0   ) + md, CFrame.Angles(math.rad(angle), 0, 0)) task.wait()
                    fpos(base, CFrame.new( 0,    -1.5,  0   ) + md, CFrame.Angles(math.rad(angle), 0, 0)) task.wait()
                    fpos(base, CFrame.new( 2.25,  1.5, -2.25) + md, CFrame.Angles(math.rad(angle), 0, 0)) task.wait()
                    fpos(base, CFrame.new(-2.25, -1.5,  2.25) + md, CFrame.Angles(math.rad(angle), 0, 0)) task.wait()
                    fpos(base, CFrame.new( 0,     1.5,  0   ) + tgtHum.MoveDirection, CFrame.Angles(math.rad(angle), 0, 0)) task.wait()
                    fpos(base, CFrame.new( 0,    -1.5,  0   ) + tgtHum.MoveDirection, CFrame.Angles(math.rad(angle), 0, 0)) task.wait()
                else
                    local ws = tgtHum.WalkSpeed
                    local rv = tgtHRP and (tgtHRP.Velocity.Magnitude / 1.25) or ws
                    fpos(base, CFrame.new(0,  1.5,  ws), CFrame.Angles(math.rad(90),  0, 0)) task.wait()
                    fpos(base, CFrame.new(0, -1.5, -ws), CFrame.Angles(0, 0, 0))             task.wait()
                    fpos(base, CFrame.new(0,  1.5,  ws), CFrame.Angles(math.rad(90),  0, 0)) task.wait()
                    fpos(base, CFrame.new(0,  1.5,  rv), CFrame.Angles(math.rad(90),  0, 0)) task.wait()
                    fpos(base, CFrame.new(0, -1.5, -rv), CFrame.Angles(0, 0, 0))             task.wait()
                    fpos(base, CFrame.new(0,  1.5,  rv), CFrame.Angles(math.rad(90),  0, 0)) task.wait()
                    fpos(base, CFrame.new(0, -1.5,  0 ), CFrame.Angles(math.rad(90),  0, 0)) task.wait()
                    fpos(base, CFrame.new(0, -1.5,  0 ), CFrame.Angles(0, 0, 0))             task.wait()
                    fpos(base, CFrame.new(0, -1.5,  0 ), CFrame.Angles(math.rad(-90), 0, 0)) task.wait()
                    fpos(base, CFrame.new(0, -1.5,  0 ), CFrame.Angles(0, 0, 0))             task.wait()
                end
            until base.Velocity.Magnitude > 500
                or base.Parent ~= tgtChar
                or p.Parent ~= game:GetService("Players")
                or tgtHum.Sit
                or myHum.Health <= 0
                or tick() > deadline
        end

        workspace.FallenPartsDestroyHeight = 0 / 0

        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.new(9e8, 9e8, 9e8)
        bv.MaxForce = Vector3.new(1/0, 1/0, 1/0)
        bv.Parent   = myHRP

        myHum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

        local base = tgtHRP or tgtHead
        if tgtHRP and tgtHead then
            base = ((tgtHRP.Position - tgtHead.Position).Magnitude > 5) and tgtHead or tgtHRP
        end
        if base then sfbase(base) end

        bv:Destroy()
        myHum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        workspace.CurrentCamera.CameraSubject = myHum

        repeat
            local restoreCF = savedCF * CFrame.new(0, 0.5, 0)
            myHRP.CFrame = restoreCF
            myChar:SetPrimaryPartCFrame(restoreCF)
            myHum:ChangeState("GettingUp")
            for _, part in myChar:GetChildren() do
                if part:IsA("BasePart") then
                    part.Velocity    = Vector3.zero
                    part.RotVelocity = Vector3.zero
                end
            end
            task.wait()
        until (myHRP.Position - savedCF.p).Magnitude < 25

        workspace.FallenPartsDestroyHeight = orgFallHeight
    end})

    PlayersRight:AddLabel("─────────────────────────")

    for _, action in ipairs({"Standon", "Orbit", "Merge", "Fan", "Stop"}) do
        local _action = action
        PlayersRight:AddButton({
            Text = _action,
            Func = function()
                _trollId += 1
                if _action == "Stop" then return end
                local id = _trollId
                task.spawn(function()
                    while _trollId == id do
                        local p    = _selectedPlayer
                        local myHRP = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                        local tChar = p and p.Character
                        local tHRP  = tChar and tChar:FindFirstChild("HumanoidRootPart")
                        local tHead = tChar and tChar:FindFirstChild("Head")
                        if myHRP then
                            if _action == "Standon" and tHead then
                                myHRP.CFrame = CFrame.new(tHead.Position + Vector3.new(0, 3.5, 0))
                            elseif _action == "Orbit" and tHRP then
                                local spin = (os.clock() * 270) % 360
                                myHRP.CFrame = tHRP.CFrame * CFrame.Angles(0, math.rad(spin), 0) * CFrame.new(0, 0, 5)
                            elseif _action == "Merge" and tHRP then
                                myHRP.CFrame = tHRP.CFrame
                            elseif _action == "Fan" and tHRP then
                                myHRP.CFrame = tHRP.CFrame * CFrame.new(0, 3, 0)
                                    * CFrame.Angles(-math.pi/2, 0, 0)
                                    * CFrame.Angles(0, 0, os.clock() * math.pi * 3)
                            end
                        end
                        RunService.Heartbeat:Wait()
                    end
                end)
            end,
        })
    end

    task.spawn(function()
        while true do
            local p = _selectedPlayer
            if p and p.Parent then

                local dname = p.DisplayName
                if #dname > 20 then dname = dname:sub(1, 18) .. ".." end
                local nameStr = dname .. (p.DisplayName ~= p.Name and ("  (@" .. p.Name .. ")") or "")
                pcall(function() _nameLbl:SetText(nameStr) end)

                local char  = p.Character
                local hum   = char and char:FindFirstChildOfClass("Humanoid")
                local hrp   = char and char:FindFirstChild("HumanoidRootPart")
                local myHrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                if hum and hrp and myHrp then
                    local hp   = math.floor(hum.Health)
                    local dist = math.floor((hrp.Position - myHrp.Position).Magnitude)
                    pcall(function() _statsLbl:SetText("HP: " .. hp .. "  |  Dist: " .. dist .. "m") end)
                else
                    pcall(function() _statsLbl:SetText("(not spawned)") end)
                end
            else
                if p and not p.Parent then
                    _selectedPlayer = nil
                    pcall(function() _playerDD:SetValue(nil) end)
                end
                pcall(function() _nameLbl:SetText("No player selected") end)
                pcall(function() _statsLbl:SetText("") end)
            end
            task.wait(0.5)
        end
    end)

    local function updateList()
        local names = getOtherNames()
        local count = #names
        _countLbl:SetText(count .. " player" .. (count == 1 and "" or "s") .. " online")
        _playerDD:SetValues(names)
    end

    Players.PlayerAdded:Connect(function() task.wait(0.1); updateList() end)
    Players.PlayerRemoving:Connect(function(p)
        if _selectedPlayer == p then
            _selectedPlayer = nil
            pcall(function() _playerDD:SetValue(nil) end)
        end
        task.wait(); updateList()
    end)

    updateList()

end

GameRGB:AddLabel("PlaceId:  " .. tostring(game.PlaceId))
GameRGB:AddButton({Text = "Copy PlaceId", Func = function()
    pcall(function() setclipboard(tostring(game.PlaceId)) end)
    Library:Notify("Astro", "PlaceId copied.", 2)
end})

local ok, gameSrc = pcall(game.HttpGet, game, getgitpath("games") .. tostring(game.PlaceId) .. ".lua")
if ok and gameSrc and #gameSrc > 0 and gameSrc ~= "404: Not Found" then
    local gameModule = loadstring(gameSrc)
    if gameModule then
        pcall(function() gameModule()(_gameSection) end)
    end
else
    GameGB:AddLabel("No module for this game.")
    GameGB:AddButton({Text = "Go to Games List", Func = function()
        Library:Notify("Astro", "Switch to the Gameslist tab.", 3)
    end})
end

local GameslistGB  = Tabs.Gameslist:AddLeftGroupbox("Teleport")
local GameslistRGB = Tabs.Gameslist:AddRightGroupbox("Info")

local ok2, listSrc = pcall(game.HttpGet, game, getgitpath("src") .. "gameslist.json")
if ok2 and listSrc then
    local gameList  = HttpService:JSONDecode(listSrc)
    local _glNames  = {}
    local _glIdMap  = {}
    for _, g in ipairs(gameList) do
        local name = (g.status or "●") .. " " .. tostring(g["game"])
        table.insert(_glNames, name)
        _glIdMap[name] = tonumber(g.id)
    end

    if #_glNames > 0 then
        local _selectedGl = _glNames[1]
        GameslistGB:AddDropdown(uid("dd"), {
            Text       = "Select Game",
            Values     = _glNames,
            Default    = _glNames[1],
            Searchable = true,
            Callback   = function(v) _selectedGl = v end,
        })
        GameslistGB:AddButton({Text = "Teleport", Func = function()
            local id = _selectedGl and _glIdMap[_selectedGl]
            if id then TeleportService:Teleport(id) end
        end})
        GameslistRGB:AddLabel(tostring(#_glNames) .. " games supported")
    end
end

getgenv()._astroUnload = function()
    getgenv()._astroFlying       = false
    getgenv()._astroNoclip       = false
    getgenv()._astroAiming       = false
    getgenv()._aimEnabled        = false
    getgenv()._astroInfJump      = false
    getgenv()._astroAntiAfk      = false
    getgenv()._astroAimTeamCheck = false
    getgenv()._astroAimVisCheck  = false
    getgenv().autorjjjj          = false

    RunService:UnbindFromRenderStep("AstroFly")
    RunService:UnbindFromRenderStep("AstroAim")
    RunService:UnbindFromRenderStep("AstroSpinBot")
    RunService:Set3dRenderingEnabled(true)

    if _flyBV then _flyBV:Destroy(); _flyBV = nil end
    if _flyBG then _flyBG:Destroy(); _flyBG = nil end

    if _fullbrightOn and _fbOrig then
        local L = game:GetService("Lighting")
        L.Brightness     = _fbOrig[1]
        L.Ambient        = _fbOrig[2]
        L.OutdoorAmbient = _fbOrig[3]
        L.FogEnd         = _fbOrig[4]
    end
    _fullbrightOn = false

    _walkEnabled = false
    if plr.Character then
        local h = plr.Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = 16; h.PlatformStand = false end
    end

    getgenv()._astroDesync   = false
    getgenv()._astroHitboxes = false
    getgenv()._astroAntiFall = false
    getgenv()._astroSpinbot  = false
    for _, p in game:GetService("Players"):GetPlayers() do _clearHitbox(p) end
    _hitboxOrigSizes = {}

    getgenv()._astroTracers   = false
    getgenv()._astroDmgInd    = false
    getgenv()._astroHitSound  = false
    getgenv()._astroCrosshair = false
    getgenv()._astroViewmodel = false
    for _, p in game:GetService("Players"):GetPlayers() do _unwatchDmg(p) end
    pcall(function() _hitSoundObj:Destroy() end)
    _destroyCrosshair()
    _disableViewmodel()

    if _tracerHookOrig then
        pcall(hookmetamethod, game, "__namecall", _tracerHookOrig)
        _tracerHookOrig = nil
    end
    if _silentHookOrig then
        pcall(hookmetamethod, game, "__namecall", _silentHookOrig)
        _silentHookOrig = nil
    end

    _esp.box      = false
    _esp.skeleton = false
    _esp.name     = false
    _esp.distance = false
    _esp.weapon   = false
    _esp.health   = false
    for uid in pairs(_espD) do cleanESP(uid) end
    pcall(function() _espGui:Destroy() end)
    pcall(function() _kbGui:Destroy()    end)

    pcall(function() Library:Unload() end)
end

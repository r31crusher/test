-- ── Astro – ui.lua (Obsidian edition) ────────────────────────────────────────
local TeleportService  = game:GetService("TeleportService")
local HttpService      = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local plr              = game:GetService("Players").LocalPlayer

-- ── Obsidian library ──────────────────────────────────────────────────────────
local repo    = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()

-- ── Window ────────────────────────────────────────────────────────────────────
local Window = Library:CreateWindow({
    Title          = "Astro",
    Footer         = "universal tools",
    ToggleKeybind  = Enum.KeyCode.Insert,
    AutoShow       = true,
})

-- ── Tabs ──────────────────────────────────────────────────────────────────────
local Tabs = {
    Home      = Window:AddTab("Home"),
    Universal = Window:AddTab("Universal"),
    Game      = Window:AddTab("Game"),
    Players   = Window:AddTab("Players"),
    Gameslist = Window:AddTab("Gameslist"),
    Settings  = Window:AddTab("Settings"),
    Credits   = Window:AddTab("Credits"),
}

-- ── Groupboxes ────────────────────────────────────────────────────────────────
local HomeGB      = Tabs.Home:AddLeftGroupbox("Home")
local GameGB      = Tabs.Game:AddLeftGroupbox("Game")
local GameslistGB = Tabs.Gameslist:AddLeftGroupbox("Games List")
local SettingsGB  = Tabs.Settings:AddLeftGroupbox("Settings")
local CreditsGB   = Tabs.Credits:AddLeftGroupbox("Credits")

-- ── Universal – Tabbox (replaces hand-rolled sub-tab system) ─────────────────
local UniTabBox  = Tabs.Universal:AddLeftTabbox()
local movTab     = UniTabBox:AddTab("Movement")
local combatTab  = UniTabBox:AddTab("Combat")
local espTab     = UniTabBox:AddTab("ESP")
local visualTab  = UniTabBox:AddTab("Visual")

-- ── UID helper ────────────────────────────────────────────────────────────────
local _uidCtr = 0
local function uid(p) _uidCtr += 1; return p .. tostring(_uidCtr) end

-- ── elements adapter (keeps game scripts working) ─────────────────────────────
-- elements.lua now exports a factory function; bind it to GameGB so game
-- scripts calling getgenv()._astroElements:Toggle(...) get real Obsidian elements.
local _makeAdapter = loadstring(game:HttpGet(getgitpath("src") .. "elements.lua"))()
getgenv()._astroElements = _makeAdapter(GameGB)

-- ── Home tab ──────────────────────────────────────────────────────────────────
HomeGB:AddLabel("Welcome to Astro!  Press Insert to toggle.")
HomeGB:AddLabel("Select a tab on the left to get started.")

-- ── Game tab ──────────────────────────────────────────────────────────────────
-- Game scripts receive the GameGB groupbox's underlying content Frame as `section`
-- so they can parent raw Instances (sub-tab bars, etc.) into it.
-- GameGB.Container is Obsidian's inner ScrollingFrame; fall back through common names.
local _gameSection = GameGB.Container or GameGB.Content or GameGB[1] or GameGB

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

-- ── Games List tab ────────────────────────────────────────────────────────────
local ok2, listSrc = pcall(game.HttpGet, game, getgitpath("src") .. "gameslist.json")
if ok2 and listSrc then
    local gameList = HttpService:JSONDecode(listSrc)
    for _, g in ipairs(gameList) do
        GameslistGB:AddButton({
            Text     = (g.status or "●") .. " " .. tostring(g["game"]),
            Func = function() TeleportService:Teleport(tonumber(g.id)) end,
        })
    end
end

-- ═════════════════════════════════════════════════════════════════════════════
--  MOVEMENT
-- ═════════════════════════════════════════════════════════════════════════════
local _walkSpeed   = 50
local _walkEnabled = false

local _setWalkSpeed_obj = movTab:AddSlider(uid("sld"), {
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

local _setSpeedBoost_obj = movTab:AddToggle(uid("tog"), {
    Text     = "Speed Boost",
    Default  = false,
    Callback = function(v)
        _walkEnabled = v
        if plr.Character then
            local h = plr.Character:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = v and _walkSpeed or 16 end
        end
    end,
})
local _setSpeedBoost = function(v) _setSpeedBoost_obj:SetValue(v) end

plr.CharacterAdded:Connect(function(char)
    local h = char:WaitForChild("Humanoid", 5)
    if h then h.WalkSpeed = _walkEnabled and _walkSpeed or 16 end
end)

-- ── Noclip ────────────────────────────────────────────────────────────────────
getgenv()._astroNoclip = false
local _noclipTog = movTab:AddToggle(uid("tog"), {
    Text     = "Noclip",
    Default  = false,
    Callback = function(v)
        getgenv()._astroNoclip = v
    end,
})
local setNoclip = function(v) _noclipTog:SetValue(v) end

local _noclipKB = _noclipTog:AddKeyPicker({
    Text    = "Noclip Key",
    Default = "V",
    Mode    = "Toggle",
    SyncToggleState = false,
    Callback = function(v)
        if v ~= nil then
            getgenv()._astroNoclip = v
            _noclipTog:SetValue(v)
        end
    end,
})

RunService.Stepped:Connect(function()
    if not getgenv()._astroNoclip then return end
    local char = plr.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end)

-- ── Fly Speed ─────────────────────────────────────────────────────────────────
local _flySpeed = 50

local _setFlySpeed_obj = movTab:AddSlider(uid("sld"), {
    Text     = "Fly Speed",
    Min      = 10,
    Max      = 300,
    Default  = 50,
    Rounding = 0,
    Callback = function(v) _flySpeed = v end,
})
local _setFlySpeed = function(v) _setFlySpeed_obj:SetValue(v) end

-- ── Fly ───────────────────────────────────────────────────────────────────────
local _flyBV, _flyBG

getgenv()._astroFlying = false
local _flyTog = movTab:AddToggle(uid("tog"), {
    Text     = "Fly  (WASD · Space=up · Shift=down)",
    Default  = false,
    Callback = function(on)
        getgenv()._astroFlying = on
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

local _flyKB = _flyTog:AddKeyPicker({
    Text    = "Fly Key",
    Default = "F",
    Mode    = "Toggle",
    SyncToggleState = false,
    Callback = function(v)
        if v ~= nil then
            setFly(v)
        end
    end,
})

-- ── Infinite Jump ─────────────────────────────────────────────────────────────
getgenv()._astroInfJump = false
local _setInfJump_obj = movTab:AddToggle(uid("tog"), {
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

-- ── Fullbright ────────────────────────────────────────────────────────────────
local _fbOrig
local _fullbrightOn = false
local _setFullbright_obj = movTab:AddToggle(uid("tog"), {
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

-- ── Anti-AFK ─────────────────────────────────────────────────────────────────
getgenv()._astroAntiAfk = false
local _setAntiAfk_obj = movTab:AddToggle(uid("tog"), {
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

-- ── Anti-Fall ─────────────────────────────────────────────────────────────────
-- Saves your last grounded CFrame and teleports you back if you fall 60+ studs
-- below it (e.g. walking off the map into the void).
getgenv()._astroAntiFall = false
local _afLastSafe = nil

local _setAntiFall_obj = movTab:AddToggle(uid("tog"), {
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

-- ═════════════════════════════════════════════════════════════════════════════
--  COMBAT
-- ═════════════════════════════════════════════════════════════════════════════
local _aimFOV   = 200
local _aimSpeed = 8

local _setAimFOV_obj = combatTab:AddSlider(uid("sld"), {
    Text     = "Aim FOV",
    Min      = 50,
    Max      = 600,
    Default  = 200,
    Rounding = 0,
    Callback = function(v) _aimFOV = v end,
})
local _setAimFOV = function(v) _setAimFOV_obj:SetValue(v) end

local _setAimSmooth_obj = combatTab:AddSlider(uid("sld"), {
    Text     = "Aim Smoothness",
    Min      = 1,
    Max      = 20,
    Default  = 8,
    Rounding = 0,
    Callback = function(v) _aimSpeed = v end,
})
local _setAimSmooth = function(v) _setAimSmooth_obj:SetValue(v) end

getgenv()._astroAimTeamCheck = false
local _setTeamCheck_obj = combatTab:AddToggle(uid("tog"), {
    Text     = "Team Check",
    Default  = false,
    Callback = function(v) getgenv()._astroAimTeamCheck = v end,
})
local _setTeamCheck = function(v) _setTeamCheck_obj:SetValue(v) end

local _aimMode = "Legacy"
combatTab:AddDropdown(uid("dd"), {
    Text     = "Aim Mode",
    Values   = {"Legacy", "Silent"},
    Default  = "Legacy",
    Callback = function(v)
        _aimMode = v
        if v == "Silent" then _installSilentHook() end
    end,
})

getgenv()._astroAimVisCheck = false
local _setAimVisCheck_obj = combatTab:AddToggle(uid("tog"), {
    Text     = "Vis Check",
    Default  = false,
    Callback = function(v) getgenv()._astroAimVisCheck = v end,
})
local _setAimVisCheck = function(v) _setAimVisCheck_obj:SetValue(v) end

-- Shared raycast params reused each frame to avoid GC pressure
local _rayParams = RaycastParams.new()
_rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function _isVisible(targetPart)
    local origin = workspace.CurrentCamera.CFrame.Position
    local filter = {targetPart.Parent}
    if plr.Character then table.insert(filter, plr.Character) end
    _rayParams.FilterDescendantsInstances = filter
    return workspace:Raycast(origin, targetPart.Position - origin, _rayParams) == nil
end

local function getAimTarget()
    local cam      = workspace.CurrentCamera
    local lp       = game:GetService("Players").LocalPlayer
    local center   = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
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

-- Installs a __namecall hook that intercepts workspace:Raycast / Spherecast
-- calls that look like weapon fire and redirects them toward the aim target.
-- Called lazily the first time Silent mode is activated.
local function _installSilentHook()
    if _silentHookOrig then return end
    local ok, orig = pcall(hookmetamethod, game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        -- Silent mode: redirect whenever aimbot is enabled (no keybind hold needed).
        -- Legacy mode: keybind hold (_astroAiming) moves the camera instead.
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

-- ── Aimbot ────────────────────────────────────────────────────────────────────
getgenv()._aimEnabled  = false
getgenv()._astroAiming = false
local _aimbotTog = combatTab:AddToggle(uid("tog"), {
    Text     = "Aimbot",
    Default  = false,
    Callback = function(v)
        getgenv()._aimEnabled = v
        if not v then getgenv()._astroAiming = false end
    end,
})
local _setAimbot = function(v) _aimbotTog:SetValue(v) end

local _aimbotKB = _aimbotTog:AddKeyPicker({
    Text    = "Aimbot Key",
    Default = "E",
    Mode    = "Hold",
    SyncToggleState = false,
    Callback = function(v)
        if getgenv()._aimEnabled then
            getgenv()._astroAiming = v
        end
    end,
})

RunService:BindToRenderStep("AstroAim", Enum.RenderPriority.Last.Value, function()
    if not getgenv()._astroAiming then return end
    local target = getAimTarget()
    if not target then return end
    if _aimMode == "Legacy" then
        local cam = workspace.CurrentCamera
        local t = math.clamp(_aimSpeed / 20, 0.05, 1)
        cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, target.Position), t)
    end
    -- Silent: the __namecall hook handles ray redirection; no camera movement needed.
end)

-- ── SpinBot ───────────────────────────────────────────────────────────────────
getgenv()._astroSpinbot = false
local _setSpinbot_obj = combatTab:AddToggle(uid("tog"), {
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
local _setSpinbot = function(v) _setSpinbot_obj:SetValue(v) end

-- ── Desync ────────────────────────────────────────────────────────────────────
-- Rapidly sends a bogus position to the server then snaps back so the
-- server-side hitbox drifts away from your actual client position.
getgenv()._astroDesync = false
local _setDesync_obj = combatTab:AddToggle(uid("tog"), {
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
local _setDesync = function(v) _setDesync_obj:SetValue(v) end

-- ── HitBoxes ──────────────────────────────────────────────────────────────────
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

local _setHitboxes_obj = combatTab:AddToggle(uid("tog"), {
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

combatTab:AddSlider(uid("sld"), {
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

-- ═════════════════════════════════════════════════════════════════════════════
--  ESP
-- ═════════════════════════════════════════════════════════════════════════════
local _esp = {box=false, skeleton=false, name=false, distance=false, weapon=false, health=false}
local _espD = {}

local _setBoxEsp_obj  = espTab:AddToggle(uid("tog"), {Text="Box",        Default=false, Callback=function(v) _esp.box      = v end})
local _setSkelEsp_obj = espTab:AddToggle(uid("tog"), {Text="Skeleton",   Default=false, Callback=function(v) _esp.skeleton = v end})
local _setNameEsp_obj = espTab:AddToggle(uid("tog"), {Text="Name",       Default=false, Callback=function(v) _esp.name     = v end})
local _setDistEsp_obj = espTab:AddToggle(uid("tog"), {Text="Distance",   Default=false, Callback=function(v) _esp.distance = v end})
local _setWeapEsp_obj = espTab:AddToggle(uid("tog"), {Text="Weapon",     Default=false, Callback=function(v) _esp.weapon   = v end})
local _setHpEsp_obj   = espTab:AddToggle(uid("tog"), {Text="Health Bar", Default=false, Callback=function(v) _esp.health   = v end})

local _setBoxEsp      = function(v) _setBoxEsp_obj:SetValue(v)  end
local _setSkelEsp     = function(v) _setSkelEsp_obj:SetValue(v) end
local _setNameEsp     = function(v) _setNameEsp_obj:SetValue(v) end
local _setDistEsp     = function(v) _setDistEsp_obj:SetValue(v) end
local _setWeapEsp     = function(v) _setWeapEsp_obj:SetValue(v) end
local _setHpEsp       = function(v) _setHpEsp_obj:SetValue(v)   end

local _espTeamCheck = false
local _setEspTeamCheck_obj = espTab:AddToggle(uid("tog"), {
    Text     = "Team Check",
    Default  = false,
    Callback = function(v) _espTeamCheck = v end,
})
local _setEspTeamCheck = function(v) _setEspTeamCheck_obj:SetValue(v) end

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
local _espColorNames = {"Red","Orange","Yellow","Green","Cyan","Blue","Purple","White"}

local _espVisColor     = _espColorMap.Red
local _espNoVisColor   = _espColorMap.Orange
local _espVisColorName   = "Red"
local _espNoVisColorName = "Orange"
local _espVisCheck = false

local _setEspVisCheck_obj = espTab:AddToggle(uid("tog"), {
    Text     = "Vis Check",
    Default  = false,
    Callback = function(v) _espVisCheck = v end,
})
local _setEspVisCheck = function(v) _setEspVisCheck_obj:SetValue(v) end

espTab:AddDropdown(uid("dd"), {
    Text     = "Visible Color",
    Values   = _espColorNames,
    Default  = "Red",
    Callback = function(v)
        _espVisColorName = v; _espVisColor = _espColorMap[v]
    end,
})
espTab:AddDropdown(uid("dd"), {
    Text     = "Hidden Color",
    Values   = _espColorNames,
    Default  = "Orange",
    Callback = function(v)
        _espNoVisColorName = v; _espNoVisColor = _espColorMap[v]
    end,
})

-- ═════════════════════════════════════════════════════════════════════════════
--  VISUAL
-- ═════════════════════════════════════════════════════════════════════════════

-- Hit Sound (shared by both Hit Sound and Damage Indicators toggles)
local _hitSoundObj = Instance.new("Sound")
_hitSoundObj.SoundId = "rbxassetid://2766953031"
_hitSoundObj.Volume  = 0.5
_hitSoundObj.RollOffMaxDistance = 0
_hitSoundObj.Parent = game.CoreGui
getgenv()._astroHitSound = false

-- Floating damage numbers via Drawing API
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
    txt.Remove()
end

-- Damage / hit-sound watchers — shared by both toggles
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

-- Bullet Tracers — draws a fading line from shot origin to hit point each frame
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
    ln.Remove()
end

-- Chains off whatever __namecall hook is already installed (silent aim or original)
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

-- Crosshair — persistent + viewport-size aware
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
    _chLines = {mkLine(), mkLine(), mkLine(), mkLine(), dot}  -- top/bot/left/right/dot

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

-- Viewmodel — ViewportFrame in the bottom-right corner showing the held tool
-- with spring-physics sway tied to camera movement.
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

-- Visual section UI elements
visualTab:AddToggle(uid("tog"), {
    Text     = "Bullet Tracers",
    Default  = false,
    Callback = function(v)
        getgenv()._astroTracers = v
        if v then _installTracerHook() end
    end,
})
visualTab:AddToggle(uid("tog"), {
    Text     = "Damage Indicators",
    Default  = false,
    Callback = function(v)
        getgenv()._astroDmgInd = v
        if v then _startDmgWatch() else _stopDmgWatchIfNone() end
    end,
})
visualTab:AddToggle(uid("tog"), {
    Text     = "Hit Sound",
    Default  = false,
    Callback = function(v)
        getgenv()._astroHitSound = v
        if v then _startDmgWatch() else _stopDmgWatchIfNone() end
    end,
})
visualTab:AddToggle(uid("tog"), {
    Text     = "Crosshair",
    Default  = false,
    Callback = function(v)
        getgenv()._astroCrosshair = v
        if v then _buildCrosshair() else _destroyCrosshair() end
    end,
})
visualTab:AddToggle(uid("tog"), {
    Text     = "Viewmodel",
    Default  = false,
    Callback = function(v)
        getgenv()._astroViewmodel = v
        if v then _enableViewmodel() else _disableViewmodel() end
    end,
})

-- ═════════════════════════════════════════════════════════════════════════════
--  SETTINGS tab / Config system
-- ═════════════════════════════════════════════════════════════════════════════
SettingsGB:AddToggle(uid("tog"), {
    Text     = "Disable 3D Rendering",
    Default  = false,
    Callback = function(v)
        RunService:Set3dRenderingEnabled(not v)
    end,
})
SettingsGB:AddToggle(uid("tog"), {
    Text     = "Auto Rejoin on kick",
    Default  = false,
    Callback = function(v)
        getgenv().autorjjjj = v
    end,
})
SettingsGB:AddButton({
    Text     = "Unload",
    Func = function()
        if getgenv()._astroUnload then getgenv()._astroUnload() end
    end,
})

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

local function saveConfig()
    _cfgEnsureDirs()
    local data = {
        walkSpeed     = _walkSpeed,
        walkEnabled   = _walkEnabled,
        flySpeed      = _flySpeed,
        noclipEnabled = getgenv()._astroNoclip,
        infJump       = getgenv()._astroInfJump,
        fullbright    = _fullbrightOn,
        antiAfk       = getgenv()._astroAntiAfk,
        aimEnabled    = getgenv()._aimEnabled,
        aimFOV        = _aimFOV,
        aimSpeed      = _aimSpeed,
        aimTeamCheck  = getgenv()._astroAimTeamCheck,
        aimVisCheck   = getgenv()._astroAimVisCheck,
        aimMode       = _aimMode,
        espBox        = _esp.box,
        espSkeleton   = _esp.skeleton,
        espName       = _esp.name,
        espDistance   = _esp.distance,
        espWeapon     = _esp.weapon,
        espHealth     = _esp.health,
        espTeamCheck      = _espTeamCheck,
        espVisCheck       = _espVisCheck,
        espVisColorName   = _espVisColorName,
        espNoVisColorName = _espNoVisColorName,
    }
    writefile(CFG_FILE, HttpService:JSONEncode(data))
end

local function loadConfig()
    if not isfile(CFG_FILE) then return false end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CFG_FILE)) end)
    if not ok or type(data) ~= "table" then return false end

    if data.walkSpeed  then _setWalkSpeed(data.walkSpeed)  end
    if data.flySpeed   then _setFlySpeed(data.flySpeed)    end
    if data.aimFOV     then _setAimFOV(data.aimFOV)       end
    if data.aimSpeed   then _setAimSmooth(data.aimSpeed)   end

    if data.walkEnabled   ~= nil then _setSpeedBoost(data.walkEnabled)  end
    if data.noclipEnabled ~= nil then setNoclip(data.noclipEnabled)     end
    if data.infJump       ~= nil then _setInfJump(data.infJump)         end
    if data.fullbright    ~= nil then _setFullbright(data.fullbright)   end
    if data.antiAfk       ~= nil then _setAntiAfk(data.antiAfk)        end
    if data.aimEnabled    ~= nil then _setAimbot(data.aimEnabled)       end
    if data.aimTeamCheck  ~= nil then _setTeamCheck(data.aimTeamCheck)  end
    if data.aimVisCheck   ~= nil then _setAimVisCheck(data.aimVisCheck) end
    if data.aimMode             then _aimMode = data.aimMode; if _aimMode == "Silent" then _installSilentHook() end end

    if data.espBox      ~= nil then _setBoxEsp(data.espBox)       end
    if data.espSkeleton ~= nil then _setSkelEsp(data.espSkeleton) end
    if data.espName     ~= nil then _setNameEsp(data.espName)     end
    if data.espDistance ~= nil then _setDistEsp(data.espDistance) end
    if data.espWeapon   ~= nil then _setWeapEsp(data.espWeapon)   end
    if data.espHealth   ~= nil then _setHpEsp(data.espHealth)     end
    if data.espTeamCheck ~= nil then _setEspTeamCheck(data.espTeamCheck) end
    if data.espVisCheck  ~= nil then _setEspVisCheck(data.espVisCheck)  end
    if data.espVisColorName   then
        _espVisColorName = data.espVisColorName
        _espVisColor = _espColorMap[data.espVisColorName] or _espVisColor
    end
    if data.espNoVisColorName then
        _espNoVisColorName = data.espNoVisColorName
        _espNoVisColor = _espColorMap[data.espNoVisColorName] or _espNoVisColor
    end

    return true
end

-- Silent load: restores preference values only (speeds, FOV, aim mode).
-- Intentionally skips feature toggles so no hacks activate automatically.
local function silentLoadConfig()
    if not isfile(CFG_FILE) then return false end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CFG_FILE)) end)
    if not ok or type(data) ~= "table" then return false end

    if data.walkSpeed then _walkSpeed = data.walkSpeed end
    if data.flySpeed  then _flySpeed  = data.flySpeed  end
    if data.aimFOV    then _aimFOV    = data.aimFOV    end
    if data.aimSpeed  then _aimSpeed  = data.aimSpeed  end
    if data.aimMode   then _aimMode = data.aimMode; if _aimMode == "Silent" then _installSilentHook() end end
    if data.espVisColorName   then
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

SettingsGB:AddLabel("— Universal Config —")
SettingsGB:AddButton({Text = "Save Config",  Func = function() pcall(saveConfig)       end})
SettingsGB:AddButton({Text = "Load Config",  Func = function() pcall(loadConfig)       end})
SettingsGB:AddButton({Text = "Silent Load",  Func = function() pcall(silentLoadConfig) end})

local _autoLoadTog = SettingsGB:AddToggle(uid("tog"), {
    Text     = "Auto Load on Start",
    Default  = false,
    Callback = function(v)
        _autoLoad = v
        local m = _readMeta()
        m.autoLoad = v
        pcall(_writeMeta, m)
    end,
})
local _setAutoLoad = function(v) _autoLoadTog:SetValue(v) end
_setAutoLoad(_autoLoad)

if _autoLoad then pcall(loadConfig) end

-- ═════════════════════════════════════════════════════════════════════════════
--  ESP RENDERING LOOP
-- ═════════════════════════════════════════════════════════════════════════════
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

local function newLine(color, thick)
    local l = Drawing.new("Line")
    l.Color = color or Color3.fromRGB(255,50,50)
    l.Thickness = thick or 1.5
    l.Visible = false
    return l
end
local function newText(size, color)
    local t = Drawing.new("Text")
    t.Size = size or 13
    t.Color = color or Color3.fromRGB(255,255,255)
    t.Outline = true
    t.Center = true
    t.Visible = false
    return t
end

local function getESPData(espUid)
    if not _espD[espUid] then
        _espD[espUid] = {
            box      = Drawing.new("Square"),
            hpBg     = newLine(Color3.fromRGB(0,0,0), 3),
            hpBar    = newLine(Color3.fromRGB(0,255,0), 3),
            nameT    = newText(13, Color3.fromRGB(255,255,255)),
            distT    = newText(11, Color3.fromRGB(160,210,255)),
            weapT    = newText(11, Color3.fromRGB(255,210,80)),
            sklLines = {},
        }
        local b = _espD[espUid].box
        b.Filled = false
        b.Thickness = 1.5
        b.Color = Color3.fromRGB(255,50,50)
        b.Visible = false
    end
    return _espD[espUid]
end

local function hideAll(d)
    d.box.Visible = false
    d.hpBg.Visible = false
    d.hpBar.Visible = false
    d.nameT.Visible = false
    d.distT.Visible = false
    d.weapT.Visible = false
    for _, l in ipairs(d.sklLines) do l.Visible = false end
end

local function cleanESP(espUid)
    local d = _espD[espUid]
    if not d then return end
    pcall(function() d.box:Remove() end)
    pcall(function() d.hpBg:Remove() end)
    pcall(function() d.hpBar:Remove() end)
    pcall(function() d.nameT:Remove() end)
    pcall(function() d.distT:Remove() end)
    pcall(function() d.weapT:Remove() end)
    for _, l in ipairs(d.sklLines) do pcall(function() l:Remove() end) end
    _espD[espUid] = nil
end

local function updateESP(p)
    local char = p.Character or workspace:FindFirstChild(p.Name)
    local d = getESPData(p.UserId)
    if not char then hideAll(d); return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then hideAll(d); return end
    if _espTeamCheck and plr.Team and p.Team and p.Team == plr.Team then hideAll(d); return end

    local cam = workspace.CurrentCamera
    local vis = not _espVisCheck or _isVisible(hrp)
    local espColor = vis and _espVisColor or _espNoVisColor

    local probeNames = {"Head","HumanoidRootPart","LeftFoot","RightFoot","LeftHand","RightHand",
                        "LeftLowerLeg","RightLowerLeg","LeftLowerArm","RightLowerArm",
                        "Left Leg","Right Leg","Left Arm","Right Arm","Torso"}
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local hit = false
    for _, pn in ipairs(probeNames) do
        local part = char:FindFirstChild(pn)
        if part then
            local sp, on = cam:WorldToViewportPoint(part.Position)
            if on then
                hit = true
                if sp.X < minX then minX = sp.X end
                if sp.Y < minY then minY = sp.Y end
                if sp.X > maxX then maxX = sp.X end
                if sp.Y > maxY then maxY = sp.Y end
            end
        end
    end
    if not hit then hideAll(d); return end

    local pad = 4
    minX, minY, maxX, maxY = minX-pad, minY-pad, maxX+pad, maxY+pad
    local cx = (minX+maxX)/2

    if _esp.box then
        d.box.Position = Vector2.new(minX, minY)
        d.box.Size     = Vector2.new(maxX-minX, maxY-minY)
        d.box.Color    = espColor
        d.box.Visible  = true
    else
        d.box.Visible = false
    end

    if _esp.health then
        local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
        local r = math.clamp(math.floor(255*(1-ratio)*2), 0, 255)
        local g = math.clamp(math.floor(255*ratio*2),     0, 255)
        local barX = minX - 5
        d.hpBg.From = Vector2.new(barX, minY)
        d.hpBg.To   = Vector2.new(barX, maxY)
        d.hpBg.Visible = true
        d.hpBar.Color = Color3.fromRGB(r, g, 0)
        d.hpBar.From  = Vector2.new(barX, maxY)
        d.hpBar.To    = Vector2.new(barX, maxY - (maxY-minY)*ratio)
        d.hpBar.Visible = true
    else
        d.hpBg.Visible = false
        d.hpBar.Visible = false
    end

    local textY = minY - 15
    if _esp.name then
        d.nameT.Text     = p.DisplayName
        d.nameT.Position = Vector2.new(cx, textY)
        d.nameT.Visible  = true
        textY = textY - 13
    else
        d.nameT.Visible = false
    end
    if _esp.distance and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        local dist = math.floor((plr.Character.HumanoidRootPart.Position - hrp.Position).Magnitude)
        d.distT.Text     = dist .. "m"
        d.distT.Position = Vector2.new(cx, textY)
        d.distT.Visible  = true
    else
        d.distT.Visible = false
    end
    if _esp.weapon then
        local tool = char:FindFirstChildOfClass("Tool")
        d.weapT.Text    = tool and tool.Name or ""
        d.weapT.Position = Vector2.new(cx, maxY + 2)
        d.weapT.Visible  = d.weapT.Text ~= ""
    else
        d.weapT.Visible = false
    end

    if _esp.skeleton then
        local isR15 = char:FindFirstChild("UpperTorso") ~= nil
        local conns = isR15 and SKL_R15 or SKL_R6
        while #d.sklLines < #conns do
            table.insert(d.sklLines, newLine(Color3.fromRGB(255,255,255), 1))
        end
        local camPos  = cam.CFrame.Position
        local camLook = cam.CFrame.LookVector
        for i, c in ipairs(conns) do
            local p0 = char:FindFirstChild(c[1])
            local p1 = char:FindFirstChild(c[2])
            local ln = d.sklLines[i]
            if p0 and p1 then
                -- dot product check: both endpoints must be in front of the camera plane.
                -- WorldToViewportPoint Z is always positive (absolute distance), so it
                -- cannot detect behind-camera points; the dot product is the correct test.
                local inFront0 = (p0.Position - camPos):Dot(camLook) > 0
                local inFront1 = (p1.Position - camPos):Dot(camLook) > 0
                if inFront0 and inFront1 then
                    local s0 = cam:WorldToViewportPoint(p0.Position)
                    local s1 = cam:WorldToViewportPoint(p1.Position)
                    ln.From  = Vector2.new(s0.X, s0.Y)
                    ln.To    = Vector2.new(s1.X, s1.Y)
                    ln.Color = espColor
                    ln.Visible = true
                else
                    ln.Visible = false
                end
            else
                ln.Visible = false
            end
        end
        for i = #conns+1, #d.sklLines do d.sklLines[i].Visible = false end
    else
        for _, l in ipairs(d.sklLines) do l.Visible = false end
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

-- ═════════════════════════════════════════════════════════════════════════════
--  CREDITS tab
-- ═════════════════════════════════════════════════════════════════════════════
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

-- ═════════════════════════════════════════════════════════════════════════════
--  PLAYERS tab — raw Instance code injected into Obsidian groupbox content
-- ═════════════════════════════════════════════════════════════════════════════
do
    local PlayersGB = Tabs.Players:AddLeftGroupbox("Players")
    -- Access Obsidian's inner content frame for raw Instance parenting.
    -- Obsidian groupboxes expose their inner scroll/list frame as .Container.
    local playersSection = PlayersGB.Container or PlayersGB.Content or PlayersGB[1]

    local Players = game:GetService("Players")

    local countLbl = Instance.new("TextLabel", playersSection)
    countLbl.Size = UDim2.new(1, 0, 0, 20)
    countLbl.BackgroundTransparency = 1
    countLbl.Font = Enum.Font.GothamSemibold
    countLbl.TextSize = 12
    countLbl.TextColor3 = Color3.fromRGB(130, 118, 175)
    countLbl.TextXAlignment = Enum.TextXAlignment.Left
    countLbl.Text = "0 players"

    local rowContainer = Instance.new("Frame", playersSection)
    rowContainer.Size = UDim2.new(1, 0, 0, 0)
    rowContainer.BackgroundTransparency = 1
    local rowLayout = Instance.new("UIListLayout", rowContainer)
    rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
    rowLayout.Padding = UDim.new(0, 4)
    rowLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        rowContainer.Size = UDim2.new(1, 0, 0, rowLayout.AbsoluteContentSize.Y)
    end)

    -- Incrementing stops any active troll loop across all rows
    local _trollId = 0

    local function makePlayerRow(p)
        local row = Instance.new("Frame", rowContainer)
        row.Name = tostring(p.UserId)
        row.Size = UDim2.new(1, 0, 0, 82)
        row.BackgroundColor3 = Color3.fromRGB(20, 17, 38)
        row.BorderSizePixel = 0
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
        local rs = Instance.new("UIStroke", row)
        rs.Color = Color3.fromRGB(100, 80, 190)
        rs.Transparency = 0.7

        -- Name + info (leave 184px on right for 3 top buttons)
        local nameLabel = Instance.new("TextLabel", row)
        nameLabel.Size = UDim2.new(1, -194, 0, 18)
        nameLabel.Position = UDim2.new(0, 10, 0, 6)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 13
        nameLabel.TextColor3 = Color3.fromRGB(210, 200, 255)
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Text = p.DisplayName .. (p.DisplayName ~= p.Name and ("  @" .. p.Name) or "")

        local infoLabel = Instance.new("TextLabel", row)
        infoLabel.Size = UDim2.new(1, -194, 0, 14)
        infoLabel.Position = UDim2.new(0, 10, 0, 26)
        infoLabel.BackgroundTransparency = 1
        infoLabel.Font = Enum.Font.Gotham
        infoLabel.TextSize = 11
        infoLabel.TextColor3 = Color3.fromRGB(130, 118, 175)
        infoLabel.TextXAlignment = Enum.TextXAlignment.Left
        local age = p.AccountAge
        local ageStr = age < 30 and "New (<30d)" or age < 365 and (math.floor(age/30) .. "mo") or (math.floor(age/365) .. "yr")
        infoLabel.Text = "ID: " .. p.UserId .. "  ·  Acct: " .. ageStr

        -- Top action buttons: TP / Spec / Fling (54px each, right-aligned, y=6)
        local function makeBtn(label, xOffset, color, cb)
            local btn = Instance.new("TextButton", row)
            btn.Size = UDim2.new(0, 54, 0, 26)
            btn.Position = UDim2.new(1, xOffset, 0, 6)
            btn.BackgroundColor3 = color
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = false
            btn.Font = Enum.Font.GothamSemibold
            btn.TextSize = 10
            btn.TextColor3 = Color3.fromRGB(210, 200, 255)
            btn.Text = label
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
            btn.MouseEnter:Connect(function()
                btn.BackgroundColor3 = Color3.fromRGB(
                    math.clamp(color.R * 255 + 20, 0, 255),
                    math.clamp(color.G * 255,      0, 255),
                    math.clamp(color.B * 255 + 30, 0, 255))
            end)
            btn.MouseLeave:Connect(function() btn.BackgroundColor3 = color end)
            btn.MouseButton1Click:Connect(cb)
        end

        makeBtn("TP", -184, Color3.fromRGB(38, 28, 75), function()
            local myHRP  = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            local tgtHRP = p.Character   and p.Character:FindFirstChild("HumanoidRootPart")
            if myHRP and tgtHRP then
                myHRP.CFrame = tgtHRP.CFrame + Vector3.new(3, 0, 0)
            end
        end)

        makeBtn("Spec", -124, Color3.fromRGB(30, 22, 60), function()
            local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                workspace.CurrentCamera.CameraSubject = hum
                workspace.CurrentCamera.CameraType    = Enum.CameraType.Follow
            end
        end)

        -- Fling: 16384 = Roblox network velocity cap; character flipped upside
        -- down matches the technique used in working fling scripts.
        makeBtn("Fling", -64, Color3.fromRGB(55, 10, 10), function()
            local myChar  = plr.Character
            local myHRP   = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local tgtChar = p.Character
            local tgtHRP  = tgtChar and tgtChar:FindFirstChild("HumanoidRootPart")
            local tgtHum  = tgtChar and tgtChar:FindFirstChildOfClass("Humanoid")
            if not myHRP or not tgtHRP or not tgtHum then return end

            local savedCF = myHRP.CFrame
            local myHum   = myChar:FindFirstChildOfClass("Humanoid")
            local angle   = 0
            local offIdx  = 1
            local offsets = {
                CFrame.new( 0,     1.5,  0   ),
                CFrame.new( 0,    -1.5,  0   ),
                CFrame.new( 2.25,  1.5, -2.25),
                CFrame.new(-2.25, -1.5,  2.25),
            }

            if myHum then
                myHum.Health = myHum.MaxHealth
                myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            end

            local bv = Instance.new("BodyVelocity")
            bv.Velocity = Vector3.new(16384, -16384, 16384)
            bv.MaxForce = Vector3.new(1/0, 1/0, 1/0)
            bv.P        = 9e8
            bv.Parent   = myHRP

            task.spawn(function()
                local iters = 0
                while iters < 120 and tgtHRP.Parent do
                    local vel = tgtHRP.AssemblyLinearVelocity.Magnitude
                    if vel > 500 then break end
                    if vel < 50 then angle = (angle + 100) % 360 end
                    offIdx = offIdx % #offsets + 1
                    local moveOff = tgtHum.MoveDirection
                        * (tgtHRP.AssemblyLinearVelocity.Magnitude / 1.25)
                    myHRP.CFrame = tgtHRP.CFrame
                        * CFrame.Angles(math.pi, 0, 0)
                        * offsets[offIdx]
                        * CFrame.Angles(math.rad(angle), 0, 0)
                        + moveOff
                    iters += 1
                    RunService.Heartbeat:Wait()
                end
                bv:Destroy()
                task.wait(0.1)
                if myHRP and myHRP.Parent then
                    myHRP.CFrame = savedCF
                    myHRP.AssemblyLinearVelocity  = Vector3.zero
                    myHRP.AssemblyAngularVelocity = Vector3.zero
                end
                if myHum then
                    myHum.Health = myHum.MaxHealth
                    myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                    myHum.PlatformStand = false
                end
            end)
        end)

        -- Troll buttons row — each loop anchors your character to the target.
        -- Pressing any troll button or Stop cancels the previous one.
        local trollBar = Instance.new("Frame", row)
        trollBar.Size = UDim2.new(1, -8, 0, 26)
        trollBar.Position = UDim2.new(0, 4, 0, 50)
        trollBar.BackgroundTransparency = 1
        local trollLayout = Instance.new("UIListLayout", trollBar)
        trollLayout.FillDirection = Enum.FillDirection.Horizontal
        trollLayout.Padding = UDim.new(0, 4)

        local trollDefs = {
            {"Standon", Color3.fromRGB(28, 22, 60)},
            {"Orbit",   Color3.fromRGB(22, 28, 55)},
            {"Merge",   Color3.fromRGB(30, 18, 55)},
            {"Fan",     Color3.fromRGB(22, 22, 58)},
            {"Stop",    Color3.fromRGB(60, 12, 12)},
        }

        for i, def in ipairs(trollDefs) do
            local tbtn = Instance.new("TextButton", trollBar)
            tbtn.Size = UDim2.new(0.2, -4, 1, 0)
            tbtn.BackgroundColor3 = def[2]
            tbtn.BorderSizePixel = 0
            tbtn.AutoButtonColor = false
            tbtn.Font = Enum.Font.GothamSemibold
            tbtn.TextSize = 10
            tbtn.TextColor3 = Color3.fromRGB(210, 200, 255)
            tbtn.Text = def[1]
            tbtn.LayoutOrder = i
            Instance.new("UICorner", tbtn).CornerRadius = UDim.new(0, 5)
            local col = def[2]
            tbtn.MouseEnter:Connect(function()
                tbtn.BackgroundColor3 = Color3.fromRGB(
                    math.clamp(col.R*255+20, 0, 255),
                    math.clamp(col.G*255,    0, 255),
                    math.clamp(col.B*255+30, 0, 255))
            end)
            tbtn.MouseLeave:Connect(function() tbtn.BackgroundColor3 = col end)

            local action = def[1]
            tbtn.MouseButton1Click:Connect(function()
                _trollId += 1
                if action == "Stop" then return end
                local id = _trollId
                task.spawn(function()
                    while _trollId == id do
                        local myHRP  = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                        local tChar  = p.Character
                        local tHRP   = tChar and tChar:FindFirstChild("HumanoidRootPart")
                        local tHead  = tChar and tChar:FindFirstChild("Head")
                        if myHRP then
                            if action == "Standon" and tHead then
                                myHRP.CFrame = CFrame.new(tHead.Position + Vector3.new(0, 3.5, 0))
                            elseif action == "Orbit" and tHRP then
                                local spin = (os.clock() * 270) % 360
                                myHRP.CFrame = tHRP.CFrame
                                    * CFrame.Angles(0, math.rad(spin), 0)
                                    * CFrame.new(0, 0, 5)
                            elseif action == "Merge" and tHRP then
                                myHRP.CFrame = tHRP.CFrame
                            elseif action == "Fan" and tHRP then
                                myHRP.CFrame = tHRP.CFrame
                                    * CFrame.new(0, 3, 0)
                                    * CFrame.Angles(-math.pi/2, 0, 0)
                                    * CFrame.Angles(0, 0, os.clock() * math.pi * 3)
                            end
                        end
                        RunService.Heartbeat:Wait()
                    end
                end)
            end)
        end

        return row
    end

    local function rebuild()
        for _, child in rowContainer:GetChildren() do
            if child:IsA("Frame") then child:Destroy() end
        end
        local all = Players:GetPlayers()
        countLbl.Text = #all .. " player" .. (#all == 1 and "" or "s") .. " online"
        table.sort(all, function(a, b) return a.Name < b.Name end)
        for _, p in all do
            makePlayerRow(p)
        end
    end

    rebuild()
    Players.PlayerAdded:Connect(rebuild)
    Players.PlayerRemoving:Connect(function()
        task.wait()
        rebuild()
    end)
end

-- ── Unload (defined here so all locals are captured correctly) ────────────────
getgenv()._astroUnload = function()
    -- flags
    getgenv()._astroFlying         = false
    getgenv()._astroNoclip         = false
    getgenv()._astroAiming         = false
    getgenv()._aimEnabled          = false
    getgenv()._astroInfJump        = false
    getgenv()._astroAntiAfk        = false
    getgenv()._astroAimTeamCheck   = false
    getgenv()._astroAimVisCheck    = false
    getgenv().autorjjjj            = false

    -- stop all render steps
    RunService:UnbindFromRenderStep("AstroFly")
    RunService:UnbindFromRenderStep("AstroAim")
    RunService:Set3dRenderingEnabled(true)

    -- fly cleanup
    if _flyBV then _flyBV:Destroy(); _flyBV = nil end
    if _flyBG then _flyBG:Destroy(); _flyBG = nil end

    -- fullbright restore
    if _fullbrightOn and _fbOrig then
        local L = game:GetService("Lighting")
        L.Brightness     = _fbOrig[1]
        L.Ambient        = _fbOrig[2]
        L.OutdoorAmbient = _fbOrig[3]
        L.FogEnd         = _fbOrig[4]
    end
    _fullbrightOn = false

    -- walk speed reset
    _walkEnabled = false
    if plr.Character then
        local h = plr.Character:FindFirstChildOfClass("Humanoid")
        if h then
            h.WalkSpeed     = 16
            h.PlatformStand = false
        end
    end

    -- combat extras
    getgenv()._astroSpinbot  = false
    getgenv()._astroDesync   = false
    getgenv()._astroHitboxes = false
    getgenv()._astroAntiFall = false
    RunService:UnbindFromRenderStep("AstroSpinBot")
    for _, p in game:GetService("Players"):GetPlayers() do _clearHitbox(p) end
    _hitboxOrigSizes = {}

    -- visual extras
    getgenv()._astroTracers   = false
    getgenv()._astroDmgInd    = false
    getgenv()._astroHitSound  = false
    getgenv()._astroCrosshair = false
    getgenv()._astroViewmodel = false
    for _, p in game:GetService("Players"):GetPlayers() do _unwatchDmg(p) end
    pcall(function() _hitSoundObj:Destroy() end)
    _destroyCrosshair()
    _disableViewmodel()

    -- restore __namecall hooks (tracer chains off silent aim, restore inner-first)
    if _tracerHookOrig then
        pcall(hookmetamethod, game, "__namecall", _tracerHookOrig)
        _tracerHookOrig = nil
    end
    if _silentHookOrig then
        pcall(hookmetamethod, game, "__namecall", _silentHookOrig)
        _silentHookOrig = nil
    end

    -- clear ESP state so the RenderStepped loop stops updating and recreating drawings
    _esp.box      = false
    _esp.skeleton = false
    _esp.name     = false
    _esp.distance = false
    _esp.weapon   = false
    _esp.health   = false

    -- clear all ESP drawings
    for espUid in pairs(_espD) do
        cleanESP(espUid)
    end

    -- unload Obsidian (destroys its ScreenGui)
    pcall(function() Library:Unload() end)
end

local CoreGui          = game:GetService("CoreGui")
local TeleportService  = game:GetService("TeleportService")
local HttpService      = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local container = (type(gethui) == "function" and gethui())
    or (type(get_hidden_gui) == "function" and get_hidden_gui())
    or CoreGui

local C = {
    bg      = Color3.fromRGB(10,  9,  18),
    topbar  = Color3.fromRGB( 8,  7,  15),
    sidebar = Color3.fromRGB(13, 11,  22),
    btnIdle = Color3.fromRGB(15, 13,  26),
    btnHov  = Color3.fromRGB(25, 20,  48),
    btnAct  = Color3.fromRGB(38, 28,  75),
    stroke  = Color3.fromRGB(110, 85, 210),
    tMain   = Color3.fromRGB(220,210, 255),
    tSub    = Color3.fromRGB(130,118, 175),
    tBtn    = Color3.fromRGB(170,160, 210),
    tAct    = Color3.fromRGB(210,195, 255),
}

local gui = Instance.new("ScreenGui")
gui.Name = "AstroUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = container

local MainFrame = Instance.new("Frame", gui)
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 760, 0, 520)
MainFrame.Position = UDim2.new(0.5, -380, 0.5, -260)
MainFrame.BackgroundColor3 = C.bg
MainFrame.BorderSizePixel = 0
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)
local mStroke = Instance.new("UIStroke", MainFrame)
mStroke.Color = C.stroke ; mStroke.Transparency = 0.6

local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 50)
TopBar.BackgroundColor3 = C.topbar
TopBar.BorderSizePixel = 0
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 14)

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(0, 200, 1, 0)
Title.Position = UDim2.new(0, 16, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Astro"
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 22
Title.TextColor3 = C.tMain
Title.TextXAlignment = Enum.TextXAlignment.Left

local Sub = Instance.new("TextLabel", TopBar)
Sub.Size = UDim2.new(0, 300, 0, 14)
Sub.Position = UDim2.new(0, 16, 0, 32)
Sub.BackgroundTransparency = 1
Sub.Text = "universal tools"
Sub.Font = Enum.Font.Gotham
Sub.TextSize = 11
Sub.TextColor3 = C.tSub
Sub.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Size = UDim2.new(0, 30, 0, 24)
CloseBtn.Position = UDim2.new(1, -42, 0.5, -12)
CloseBtn.BackgroundColor3 = C.btnIdle
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "×"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
CloseBtn.TextColor3 = C.tBtn
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseEnter:Connect(function()
    CloseBtn.BackgroundColor3 = Color3.fromRGB(50, 30, 80)
    CloseBtn.TextColor3 = Color3.fromRGB(255, 90, 90)
end)
CloseBtn.MouseLeave:Connect(function()
    CloseBtn.BackgroundColor3 = C.btnIdle
    CloseBtn.TextColor3 = C.tBtn
end)

local ShowBtn = Instance.new("TextButton", gui)
ShowBtn.Name = "ShowBtn"
ShowBtn.Size = UDim2.new(0, 80, 0, 28)
ShowBtn.Position = UDim2.new(0, 10, 0, 10)
ShowBtn.BackgroundColor3 = C.btnAct
ShowBtn.BorderSizePixel = 0
ShowBtn.Text = "Astro"
ShowBtn.Font = Enum.Font.GothamBold
ShowBtn.TextSize = 13
ShowBtn.TextColor3 = C.tMain
ShowBtn.Visible = false
Instance.new("UICorner", ShowBtn).CornerRadius = UDim.new(0, 8)

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    ShowBtn.Visible = true
end)
ShowBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    ShowBtn.Visible = false
end)
UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.Insert then
        MainFrame.Visible = not MainFrame.Visible
        ShowBtn.Visible = not MainFrame.Visible
    end
end)

do
    local dragging, dragStart, startPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local d = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                           startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 148, 1, -50)
Sidebar.Position = UDim2.new(0, 0, 0, 50)
Sidebar.BackgroundColor3 = C.sidebar
Sidebar.BorderSizePixel = 0
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 14)
local sbStroke = Instance.new("UIStroke", Sidebar)
sbStroke.Color = C.stroke ; sbStroke.Transparency = 0.7
local sbLayout = Instance.new("UIListLayout", Sidebar)
sbLayout.SortOrder = Enum.SortOrder.LayoutOrder
sbLayout.Padding = UDim.new(0, 6)
sbLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
local sbPad = Instance.new("UIPadding", Sidebar)
sbPad.PaddingTop = UDim.new(0, 10)

local SectionArea = Instance.new("Frame", MainFrame)
SectionArea.Size = UDim2.new(1, -158, 1, -60)
SectionArea.Position = UDim2.new(0, 153, 0, 55)
SectionArea.BackgroundTransparency = 1
SectionArea.ClipsDescendants = true

local function makeSection(name)
    local sf = Instance.new("ScrollingFrame", SectionArea)
    sf.Name = name
    sf.Size = UDim2.new(1, 0, 1, 0)
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.BackgroundTransparency = 1
    sf.ScrollBarThickness = 3
    sf.ScrollBarImageColor3 = C.stroke
    sf.BorderSizePixel = 0
    sf.Visible = false
    local layout = Instance.new("UIListLayout", sf)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    local pad = Instance.new("UIPadding", sf)
    pad.PaddingTop = UDim.new(0, 6)
    pad.PaddingLeft = UDim.new(0, 4)
    pad.PaddingRight = UDim.new(0, 6)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sf.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 14)
    end)
    return sf
end

local tabNames = {"Home", "Universal", "Game", "Gameslist", "Settings", "Credits"}
local Sections = {}
local CurSection

for i, name in ipairs(tabNames) do
    Sections[name] = {Container = makeSection(name)}
    local btn = Instance.new("TextButton", Sidebar)
    btn.Name = name .. "Tab"
    btn.Size = UDim2.new(1, -12, 0, 36)
    btn.BackgroundColor3 = C.btnIdle
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.TextColor3 = C.tBtn
    btn.AutoButtonColor = false
    btn.LayoutOrder = i
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    Sections[name].TabBtn = btn
end

local function setTab(name)
    if CurSection then
        CurSection.Container.Visible = false
        CurSection.TabBtn.BackgroundColor3 = C.btnIdle
        CurSection.TabBtn.TextColor3 = C.tBtn
    end
    CurSection = Sections[name]
    CurSection.Container.Visible = true
    CurSection.TabBtn.BackgroundColor3 = C.btnAct
    CurSection.TabBtn.TextColor3 = C.tAct
end

for _, name in ipairs(tabNames) do
    local btn = Sections[name].TabBtn
    btn.MouseEnter:Connect(function()
        if CurSection ~= Sections[name] then
            btn.BackgroundColor3 = C.btnHov
            btn.TextColor3 = C.tMain
        end
    end)
    btn.MouseLeave:Connect(function()
        if CurSection ~= Sections[name] then
            btn.BackgroundColor3 = C.btnIdle
            btn.TextColor3 = C.tBtn
        end
    end)
    btn.MouseButton1Click:Connect(function() setTab(name) end)
end

local elements = loadstring(game:HttpGet(getgitpath("src") .. "elements.lua"))()

local function makeSlider(str, parent, minVal, maxVal, default, cb)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 46)
    frame.BackgroundColor3 = Color3.fromRGB(20, 17, 38)
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke", frame)
    s.Color = Color3.fromRGB(100, 80, 190)
    s.Transparency = 0.6
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -12, 0, 18)
    lbl.Position = UDim2.new(0, 10, 0, 5)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 12
    lbl.TextColor3 = Color3.fromRGB(200, 190, 255)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = str .. ":  " .. tostring(default)
    local track = Instance.new("Frame", frame)
    track.Size = UDim2.new(1, -20, 0, 6)
    track.Position = UDim2.new(0, 10, 0, 32)
    track.BackgroundColor3 = Color3.fromRGB(35, 28, 65)
    track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local pct = (default - minVal) / (maxVal - minVal)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(110, 85, 210)
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("Frame", track)
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(pct, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(200, 185, 255)
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local dragging = false
    local function update(x)
        local t = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.round(minVal + t * (maxVal - minVal))
        fill.Size = UDim2.new(t, 0, 1, 0)
        knob.Position = UDim2.new(t, 0, 0.5, 0)
        lbl.Text = str .. ":  " .. tostring(val)
        cb(val)
    end
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(inp.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            update(inp.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

elements:Label("Welcome to Astro!  Press Insert to toggle.", Sections.Home.Container)
elements:Label("Select a tab on the left to get started.", Sections.Home.Container)

local ok, gameSrc = pcall(game.HttpGet, game, getgitpath("games") .. tostring(game.PlaceId) .. ".lua")
if ok and gameSrc and #gameSrc > 0 and gameSrc ~= "404: Not Found" then
    local gameModule = loadstring(gameSrc)()
    pcall(function() gameModule(Sections.Game.Container) end)
else
    elements:Unsupported(Sections.Game.Container, function()
        setTab("Gameslist")
    end)
end

local ok2, listSrc = pcall(game.HttpGet, game, getgitpath("src") .. "gameslist.json")
if ok2 and listSrc then
    local gameList = HttpService:JSONDecode(listSrc)
    for _, g in ipairs(gameList) do
        elements:Button((g.status or "●") .. " " .. tostring(g["game"]), Sections.Gameslist.Container, function()
            TeleportService:Teleport(tonumber(g.id))
        end)
    end
end

local RunService = game:GetService("RunService")
local plr        = game:GetService("Players").LocalPlayer

elements:Toggle("Disable 3D Rendering", Sections.Settings.Container, function(v)
    RunService:Set3dRenderingEnabled(not v)
end)
elements:Toggle("Auto Rejoin on kick", Sections.Settings.Container, function(v)
    getgenv().autorjjjj = v
end)

local _walkSpeed = 16
makeSlider("Walk Speed", Sections.Universal.Container, 8, 150, 16, function(v)
    _walkSpeed = v
    if plr.Character then
        local h = plr.Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = v end
    end
end)
plr.CharacterAdded:Connect(function(char)
    local h = char:WaitForChild("Humanoid", 5)
    if h then h.WalkSpeed = _walkSpeed end
end)

local _binds = {
    fly    = {key = Enum.KeyCode.F, hudLabel = nil},
    noclip = {key = Enum.KeyCode.V, hudLabel = nil},
}

local function makeLocalToggle(str, parent, bindRef, cb)
    local tog = Instance.new("TextButton", parent)
    tog.Size = UDim2.new(1, 0, 0, 32)
    tog.BackgroundColor3 = Color3.fromRGB(20, 17, 38)
    tog.BorderSizePixel = 0
    tog.AutoButtonColor = false
    tog.Text = ""
    Instance.new("UICorner", tog).CornerRadius = UDim.new(0, 6)
    local ts = Instance.new("UIStroke", tog)
    ts.Color = Color3.fromRGB(100, 80, 190) ; ts.Transparency = 0.6

    local lbl = Instance.new("TextLabel", tog)
    lbl.Size = UDim2.new(1, -98, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextColor3 = Color3.fromRGB(200, 190, 255)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = str

    local chip = Instance.new("TextButton", tog)
    chip.Size = UDim2.new(0, 38, 0, 20)
    chip.AnchorPoint = Vector2.new(1, 0.5)
    chip.Position = UDim2.new(1, -54, 0.5, 0)
    chip.BackgroundColor3 = Color3.fromRGB(35, 28, 65)
    chip.BorderSizePixel = 0
    chip.AutoButtonColor = false
    chip.Font = Enum.Font.GothamBold
    chip.TextSize = 10
    chip.TextColor3 = Color3.fromRGB(200, 185, 255)
    chip.Text = bindRef.key.Name
    chip.TextScaled = true
    Instance.new("UICorner", chip).CornerRadius = UDim.new(0, 4)

    local bg = Instance.new("Frame", tog)
    bg.Size = UDim2.new(0, 36, 0, 18)
    bg.AnchorPoint = Vector2.new(1, 0.5)
    bg.Position = UDim2.new(1, -8, 0.5, 0)
    bg.BackgroundColor3 = Color3.fromRGB(35, 28, 65)
    bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)
    local dot = Instance.new("Frame", bg)
    dot.Size = UDim2.new(0, 12, 0, 12)
    dot.AnchorPoint = Vector2.new(0, 0.5)
    dot.Position = UDim2.new(0, 3, 0.5, 0)
    dot.BackgroundColor3 = Color3.fromRGB(160, 150, 220)
    dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local on = false
    local function setState(v)
        on = v
        bg.BackgroundColor3 = v and Color3.fromRGB(80,55,180) or Color3.fromRGB(35,28,65)
        dot.AnchorPoint = v and Vector2.new(1,0.5) or Vector2.new(0,0.5)
        dot.Position = v and UDim2.new(1,-3,0.5,0) or UDim2.new(0,3,0.5,0)
        dot.BackgroundColor3 = v and Color3.fromRGB(210,200,255) or Color3.fromRGB(160,150,220)
        cb(v)
    end
    tog.MouseButton1Click:Connect(function() setState(not on) end)

    local rebinding = false
    chip.MouseButton1Click:Connect(function()
        if rebinding then return end
        rebinding = true
        chip.Text = "..."
        chip.BackgroundColor3 = Color3.fromRGB(80, 55, 180)
        local conn
        conn = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            conn:Disconnect()
            rebinding = false
            bindRef.key = input.KeyCode
            local name = input.KeyCode.Name
            chip.Text = name
            chip.BackgroundColor3 = Color3.fromRGB(35, 28, 65)
            if bindRef.hudLabel then bindRef.hudLabel.Text = name end
        end)
    end)

    return setState
end

local _flySpeed = 50
local _flyBV, _flyBG

getgenv()._astroNoclip = false
local setNoclip = makeLocalToggle("Noclip", Sections.Universal.Container, _binds.noclip, function(on)
    getgenv()._astroNoclip = on
end)
RunService.Stepped:Connect(function()
    if not getgenv()._astroNoclip then return end
    local char = plr.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end)

makeSlider("Fly Speed", Sections.Universal.Container, 10, 300, 50, function(v)
    _flySpeed = v
end)

getgenv()._astroFlying = false
local setFly = makeLocalToggle("Fly  (WASD · Space=up · Shift=down)", Sections.Universal.Container, _binds.fly, function(on)
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
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == _binds.fly.key    then setFly(not getgenv()._astroFlying)    end
    if input.KeyCode == _binds.noclip.key then setNoclip(not getgenv()._astroNoclip) end
end)

getgenv()._astroInfJump = false
elements:Toggle("Infinite Jump", Sections.Universal.Container, function(v)
    getgenv()._astroInfJump = v
end)
UserInputService.JumpRequest:Connect(function()
    if not getgenv()._astroInfJump then return end
    local char = plr.Character
    if not char then return end
    local h = char:FindFirstChildOfClass("Humanoid")
    if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

local _fbOrig
elements:Toggle("Fullbright", Sections.Universal.Container, function(v)
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
end)

getgenv()._astroAntiAfk = false
elements:Toggle("Anti-AFK", Sections.Universal.Container, function(v)
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
end)

local ok3, credSrc = pcall(game.HttpGet, game, getgitpath("src") .. "credits.json")
if ok3 and credSrc then
    local credits = HttpService:JSONDecode(credSrc)
    for sect, people in pairs(credits) do
        elements:CredHead(Sections.Credits.Container, sect)
        for _, person in ipairs(people) do
            elements:CredPerson(Sections.Credits.Container, person)
        end
    end
end

setTab("Home")

local hudRows = {
    {keyStr = "Insert",            desc = "Toggle Menu", bindRef = nil},
    {keyStr = _binds.fly.key.Name,    desc = "Fly",         bindRef = _binds.fly},
    {keyStr = _binds.noclip.key.Name, desc = "Noclip",      bindRef = _binds.noclip},
}

local kbFrame = Instance.new("Frame", gui)
kbFrame.Name = "KeybindHUD"
kbFrame.Size = UDim2.new(0, 160, 0, #hudRows * 22 + 28)
kbFrame.Position = UDim2.new(1, -170, 1, -(#hudRows * 22 + 38))
kbFrame.BackgroundColor3 = Color3.fromRGB(10, 9, 18)
kbFrame.BorderSizePixel = 0
kbFrame.Active = true
Instance.new("UICorner", kbFrame).CornerRadius = UDim.new(0, 8)
local kbStroke = Instance.new("UIStroke", kbFrame)
kbStroke.Color = Color3.fromRGB(110, 85, 210)
kbStroke.Transparency = 0.5

local kbTitle = Instance.new("TextLabel", kbFrame)
kbTitle.Size = UDim2.new(1, 0, 0, 20)
kbTitle.Position = UDim2.new(0, 0, 0, 4)
kbTitle.BackgroundTransparency = 1
kbTitle.Font = Enum.Font.GothamBold
kbTitle.TextSize = 11
kbTitle.TextColor3 = Color3.fromRGB(170, 160, 210)
kbTitle.Text = "KEYBINDS"

for i, row in ipairs(hudRows) do
    local r = Instance.new("Frame", kbFrame)
    r.Size = UDim2.new(1, -12, 0, 18)
    r.Position = UDim2.new(0, 6, 0, 22 + (i - 1) * 22)
    r.BackgroundTransparency = 1

    local keyLbl = Instance.new("TextLabel", r)
    keyLbl.Size = UDim2.new(0, 52, 1, 0)
    keyLbl.BackgroundColor3 = Color3.fromRGB(28, 24, 50)
    keyLbl.BorderSizePixel = 0
    keyLbl.Font = Enum.Font.GothamBold
    keyLbl.TextSize = 11
    keyLbl.TextColor3 = Color3.fromRGB(200, 185, 255)
    keyLbl.Text = row.keyStr
    keyLbl.TextScaled = true
    Instance.new("UICorner", keyLbl).CornerRadius = UDim.new(0, 4)

    if row.bindRef then
        row.bindRef.hudLabel = keyLbl
    end

    local desc = Instance.new("TextLabel", r)
    desc.Size = UDim2.new(1, -58, 1, 0)
    desc.Position = UDim2.new(0, 58, 0, 0)
    desc.BackgroundTransparency = 1
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 11
    desc.TextColor3 = Color3.fromRGB(160, 152, 200)
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.Text = row.desc
end

do
    local dragging, dragStart, startPos
    kbFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = kbFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local d = input.Position - dragStart
            kbFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                          startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

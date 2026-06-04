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
elements:Slider("Walk Speed", Sections.Universal.Container, 8, 150, 16, function(v)
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

getgenv()._astroNoclip = false
elements:Toggle("Noclip", Sections.Universal.Container, function(v)
    getgenv()._astroNoclip = v
end)
RunService.Stepped:Connect(function()
    if not getgenv()._astroNoclip then return end
    local char = plr.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end)

local _flySpeed = 50
local _flyBV, _flyBG

elements:Slider("Fly Speed", Sections.Universal.Container, 10, 300, 50, function(v)
    _flySpeed = v
end)

getgenv()._astroFlying = false
elements:Toggle("Fly  (WASD · Space=up · Shift=down)", Sections.Universal.Container, function(on)
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

local CoreGui          = game:GetService("CoreGui")
local TeleportService  = game:GetService("TeleportService")
local HttpService      = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

-- Use hidden GUI container if the executor provides one
local container = (type(gethui) == "function" and gethui())
    or (type(get_hidden_gui) == "function" and get_hidden_gui())
    or CoreGui

-- ── Astro palette ─────────────────────────────────────────────────────────────
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

-- ── Root GUI ──────────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "SolarisUI"
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

-- ── Top bar ───────────────────────────────────────────────────────────────────
local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 50)
TopBar.BackgroundColor3 = C.topbar
TopBar.BorderSizePixel = 0
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 14)

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(0, 200, 1, 0)
Title.Position = UDim2.new(0, 16, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Solaris"
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 22
Title.TextColor3 = C.tMain
Title.TextXAlignment = Enum.TextXAlignment.Left

local Sub = Instance.new("TextLabel", TopBar)
Sub.Size = UDim2.new(0, 300, 0, 14)
Sub.Position = UDim2.new(0, 16, 0, 32)
Sub.BackgroundTransparency = 1
Sub.Text = "brainrot tools"
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

-- Small re-open button shown when UI is closed
local ShowBtn = Instance.new("TextButton", gui)
ShowBtn.Name = "ShowBtn"
ShowBtn.Size = UDim2.new(0, 80, 0, 28)
ShowBtn.Position = UDim2.new(0, 10, 0, 10)
ShowBtn.BackgroundColor3 = C.btnAct
ShowBtn.BorderSizePixel = 0
ShowBtn.Text = "Solaris"
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

-- ── Dragging ──────────────────────────────────────────────────────────────────
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

-- ── Sidebar ───────────────────────────────────────────────────────────────────
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

-- ── Section area ──────────────────────────────────────────────────────────────
local SectionArea = Instance.new("Frame", MainFrame)
SectionArea.Size = UDim2.new(1, -158, 1, -60)
SectionArea.Position = UDim2.new(0, 153, 0, 55)
SectionArea.BackgroundTransparency = 1
SectionArea.ClipsDescendants = true

-- Build one scrolling section container
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

-- ── Tab system ────────────────────────────────────────────────────────────────
local tabNames = {"Home", "Game", "Gameslist", "Settings", "Credits"}
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

-- ── Load elements ─────────────────────────────────────────────────────────────
local elements = loadstring(game:HttpGet(getgitpath("src") .. "elements.lua"))()

-- ── Home ──────────────────────────────────────────────────────────────────────
elements:Label("Welcome to Solaris!  Press Insert to toggle.", Sections.Home.Container)
elements:Label("Select a tab on the left to get started.", Sections.Home.Container)

-- ── Game ──────────────────────────────────────────────────────────────────────
local ok, gameSrc = pcall(game.HttpGet, game, getgitpath("games") .. tostring(game.PlaceId) .. ".lua")
if ok and gameSrc and #gameSrc > 0 and gameSrc ~= "404: Not Found" then
    local gameModule = loadstring(gameSrc)()
    pcall(function() gameModule(Sections.Game.Container) end)
else
    elements:Unsupported(Sections.Game.Container, function()
        setTab("Gameslist")
    end)
end

-- ── Gameslist ─────────────────────────────────────────────────────────────────
local ok2, listSrc = pcall(game.HttpGet, game, getgitpath("src") .. "gameslist.json")
if ok2 and listSrc then
    local gameList = HttpService:JSONDecode(listSrc)
    for _, g in ipairs(gameList) do
        elements:Button((g.status or "●") .. " " .. tostring(g["game"]), Sections.Gameslist.Container, function()
            TeleportService:Teleport(tonumber(g.id))
        end)
    end
end

-- ── Settings ──────────────────────────────────────────────────────────────────
elements:Toggle("Disable 3D Rendering", Sections.Settings.Container, function(v)
    game:GetService("RunService"):Set3dRenderingEnabled(not v)
end)
elements:Toggle("Auto Rejoin on kick", Sections.Settings.Container, function(v)
    getgenv().autorjjjj = v
end)

-- ── Credits ───────────────────────────────────────────────────────────────────
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

-- ── Show Home by default ──────────────────────────────────────────────────────
setTab("Home")

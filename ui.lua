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

local tabNames = {"Home", "Universal", "Game", "Players", "Gameslist", "Settings", "Credits"}
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
getgenv()._astroElements = elements

local function makeDropdown(label, parent, options, default, cb)
    local itemH = 28
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundTransparency = 1
    frame.ClipsDescendants = false

    local header = Instance.new("TextButton", frame)
    header.Size = UDim2.new(1, 0, 1, 0)
    header.BackgroundColor3 = Color3.fromRGB(20, 17, 38)
    header.BorderSizePixel = 0
    header.AutoButtonColor = false
    header.Font = Enum.Font.GothamSemibold
    header.TextSize = 13
    header.TextColor3 = Color3.fromRGB(200, 190, 255)
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Text = "  " .. label .. ":  " .. default
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 6)
    local hStroke = Instance.new("UIStroke", header)
    hStroke.Color = Color3.fromRGB(100, 80, 190) ; hStroke.Transparency = 0.6

    local arrow = Instance.new("TextLabel", header)
    arrow.Size = UDim2.new(0, 22, 1, 0)
    arrow.Position = UDim2.new(1, -26, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 11
    arrow.TextColor3 = Color3.fromRGB(160, 150, 210)
    arrow.Text = "▼"

    local list = Instance.new("Frame", frame)
    list.Size = UDim2.new(1, 0, 0, #options * itemH)
    list.Position = UDim2.new(0, 0, 0, 34)
    list.BackgroundColor3 = Color3.fromRGB(16, 14, 28)
    list.BorderSizePixel = 0
    list.Visible = false
    list.ZIndex = 8
    Instance.new("UICorner", list).CornerRadius = UDim.new(0, 6)
    local lStroke = Instance.new("UIStroke", list)
    lStroke.Color = Color3.fromRGB(100, 80, 190) ; lStroke.Transparency = 0.5
    local lLayout = Instance.new("UIListLayout", list)
    lLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local isOpen = false

    for i, opt in ipairs(options) do
        local btn = Instance.new("TextButton", list)
        btn.Size = UDim2.new(1, 0, 0, itemH)
        btn.BackgroundTransparency = 1
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Font = Enum.Font.GothamSemibold
        btn.TextSize = 12
        btn.TextColor3 = opt == default
            and Color3.fromRGB(210, 195, 255)
            or  Color3.fromRGB(140, 130, 180)
        btn.Text = opt
        btn.LayoutOrder = i
        btn.ZIndex = 9
        btn.MouseEnter:Connect(function()
            btn.BackgroundTransparency = 0
            btn.BackgroundColor3 = Color3.fromRGB(30, 24, 55)
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundTransparency = 1
        end)
        btn.MouseButton1Click:Connect(function()
            isOpen = false
            list.Visible = false
            arrow.Text = "▼"
            frame.Size = UDim2.new(1, 0, 0, 32)
            header.Text = "  " .. label .. ":  " .. opt
            cb(opt)
        end)
    end

    header.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        list.Visible = isOpen
        arrow.Text = isOpen and "▲" or "▼"
        frame.Size = UDim2.new(1, 0, 0, isOpen and (32 + #options * itemH + 4) or 32)
    end)
end

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
    local function setValue(v)
        local t = math.clamp((v - minVal) / (maxVal - minVal), 0, 1)
        fill.Size = UDim2.new(t, 0, 1, 0)
        knob.Position = UDim2.new(t, 0, 0.5, 0)
        lbl.Text = str .. ":  " .. tostring(v)
        cb(v)
    end
    return setValue
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

-- Stub: real cleanup defined at end of file once all locals are in scope
elements:Button("Unload", Sections.Settings.Container, function()
    if getgenv()._astroUnload then getgenv()._astroUnload() end
end)

local _binds = {
    fly    = {key = Enum.KeyCode.F, mouseBtn = nil, displayName = "F", hudLabel = nil},
    noclip = {key = Enum.KeyCode.V, mouseBtn = nil, displayName = "V", hudLabel = nil},
    aim    = {key = Enum.KeyCode.E, mouseBtn = nil, displayName = "E", hudLabel = nil},
}

local _mouseBtnNames = {
    [Enum.UserInputType.MouseButton1] = "M1",
    [Enum.UserInputType.MouseButton2] = "M2",
    [Enum.UserInputType.MouseButton3] = "M3",
}

local function isBound(input, bind)
    if bind.mouseBtn and input.UserInputType == bind.mouseBtn then return true end
    if bind.key ~= Enum.KeyCode.Unknown and input.KeyCode == bind.key then return true end
    return false
end

local function makeSubSection(parent)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, 0, 0, 0)
    f.BackgroundTransparency = 1
    f.Visible = false
    local lay = Instance.new("UIListLayout", f)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Padding = UDim.new(0, 8)
    lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        f.Size = UDim2.new(1, 0, 0, lay.AbsoluteContentSize.Y)
    end)
    return f
end

local uniBar = Instance.new("Frame", Sections.Universal.Container)
uniBar.Size = UDim2.new(1, 0, 0, 32)
uniBar.BackgroundTransparency = 1
local uniBarLayout = Instance.new("UIListLayout", uniBar)
uniBarLayout.FillDirection = Enum.FillDirection.Horizontal
uniBarLayout.Padding = UDim.new(0, 6)

local movSection    = makeSubSection(Sections.Universal.Container)
local combatSection = makeSubSection(Sections.Universal.Container)
local espSection    = makeSubSection(Sections.Universal.Container)

local uniActiveSection, uniActiveBtn

local function makeSubTabBtn(label, section)
    local btn = Instance.new("TextButton", uniBar)
    btn.Size = UDim2.new(1/3, -4, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(15, 13, 26)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 12
    btn.TextColor3 = Color3.fromRGB(170, 160, 210)
    btn.Text = label
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function()
        if uniActiveSection then
            uniActiveSection.Visible = false
            uniActiveBtn.BackgroundColor3 = Color3.fromRGB(15, 13, 26)
            uniActiveBtn.TextColor3 = Color3.fromRGB(170, 160, 210)
        end
        section.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(38, 28, 75)
        btn.TextColor3 = Color3.fromRGB(210, 195, 255)
        uniActiveSection = section
        uniActiveBtn = btn
    end)
    return btn
end

local movBtn    = makeSubTabBtn("Movement", movSection)
local combatBtn = makeSubTabBtn("Combat",   combatSection)
local espBtn    = makeSubTabBtn("ESP",      espSection)

movSection.Visible = true
movBtn.BackgroundColor3 = Color3.fromRGB(38, 28, 75)
movBtn.TextColor3 = Color3.fromRGB(210, 195, 255)
uniActiveSection = movSection
uniActiveBtn = movBtn

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
    chip.Text = bindRef.displayName
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
            local isKey   = input.UserInputType == Enum.UserInputType.Keyboard
            local isMouse = _mouseBtnNames[input.UserInputType] ~= nil
            if not isKey and not isMouse then return end
            conn:Disconnect()
            rebinding = false
            if isKey then
                bindRef.key         = input.KeyCode
                bindRef.mouseBtn    = nil
                bindRef.displayName = input.KeyCode.Name
            else
                bindRef.key         = Enum.KeyCode.Unknown
                bindRef.mouseBtn    = input.UserInputType
                bindRef.displayName = _mouseBtnNames[input.UserInputType]
            end
            chip.Text = bindRef.displayName
            chip.BackgroundColor3 = Color3.fromRGB(35, 28, 65)
            if bindRef.hudLabel then bindRef.hudLabel.Text = bindRef.displayName end
        end)
    end)

    return setState
end

local _walkSpeed = 50
local _walkEnabled = false

local _setWalkSpeed = makeSlider("Walk Speed", movSection, 8, 250, 50, function(v)
    _walkSpeed = v
    if _walkEnabled and plr.Character then
        local h = plr.Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = v end
    end
end)
local _setSpeedBoost = elements:Toggle("Speed Boost", movSection, function(v)
    _walkEnabled = v
    if plr.Character then
        local h = plr.Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = v and _walkSpeed or 16 end
    end
end)
plr.CharacterAdded:Connect(function(char)
    local h = char:WaitForChild("Humanoid", 5)
    if h then h.WalkSpeed = _walkEnabled and _walkSpeed or 16 end
end)

local _flySpeed = 50
local _flyBV, _flyBG

getgenv()._astroNoclip = false
local setNoclip = makeLocalToggle("Noclip", movSection, _binds.noclip, function(on)
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

local _setFlySpeed = makeSlider("Fly Speed", movSection, 10, 300, 50, function(v)
    _flySpeed = v
end)

getgenv()._astroFlying = false
local setFly = makeLocalToggle("Fly  (WASD · Space=up · Shift=down)", movSection, _binds.fly, function(on)
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

local _aimFOV   = 200
local _aimSpeed = 8

local _setAimFOV   = makeSlider("Aim FOV",        combatSection, 50,  600, 200, function(v) _aimFOV   = v end)
local _setAimSmooth = makeSlider("Aim Smoothness", combatSection,  1,   20,   8, function(v) _aimSpeed = v end)

getgenv()._astroAimTeamCheck = false
local _setTeamCheck = elements:Toggle("Team Check", combatSection, function(v)
    getgenv()._astroAimTeamCheck = v
end)

local _aimMode = "Legacy"
makeDropdown("Aim Mode", combatSection, {"Legacy", "Silent"}, "Legacy", function(v)
    _aimMode = v
end)

getgenv()._astroAimVisCheck = false
local _setAimVisCheck = elements:Toggle("Vis Check", combatSection, function(v)
    getgenv()._astroAimVisCheck = v
end)

getgenv()._aimEnabled  = false
getgenv()._astroAiming = false
local _setAimbot = makeLocalToggle("Aimbot", combatSection, _binds.aim, function(on)
    getgenv()._aimEnabled = on
    if not on then getgenv()._astroAiming = false end
end)

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

local _silentOrig = nil

RunService:BindToRenderStep("AstroAim", Enum.RenderPriority.Last.Value, function()
    if not getgenv()._astroAiming then
        _silentOrig = nil
        return
    end
    local target = getAimTarget()
    if not target then return end
    local cam = workspace.CurrentCamera
    if _aimMode == "Legacy" then
        local t = math.clamp(_aimSpeed / 20, 0.05, 1)
        cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, target.Position), t)
    else
        _silentOrig = cam.CFrame
        cam.CFrame = CFrame.new(cam.CFrame.Position, target.Position)
    end
end)

RunService:BindToRenderStep("AstroAimRestore", Enum.RenderPriority.Last.Value + 1, function()
    if _silentOrig then
        workspace.CurrentCamera.CFrame = _silentOrig
        _silentOrig = nil
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if isBound(input, _binds.fly)    then setFly(not getgenv()._astroFlying)    end
    if isBound(input, _binds.noclip) then setNoclip(not getgenv()._astroNoclip) end
end)
-- Aim uses a separate connection with no gp guard so it fires in FPS games
-- that intercept the bound key (e.g. M2 for ADS, E for interact)
UserInputService.InputBegan:Connect(function(input)
    if isBound(input, _binds.aim) and getgenv()._aimEnabled then
        getgenv()._astroAiming = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if isBound(input, _binds.aim) then getgenv()._astroAiming = false end
end)

getgenv()._astroInfJump = false
local _setInfJump = elements:Toggle("Infinite Jump", movSection, function(v)
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
local _fullbrightOn = false
local _setFullbright = elements:Toggle("Fullbright", movSection, function(v)
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
end)

getgenv()._astroAntiAfk = false
local _setAntiAfk = elements:Toggle("Anti-AFK", movSection, function(v)
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

local _esp = {box=false, skeleton=false, name=false, distance=false, weapon=false, health=false}
local _espD = {}

local _setBoxEsp  = elements:Toggle("Box",        espSection, function(v) _esp.box      = v end)
local _setSkelEsp = elements:Toggle("Skeleton",   espSection, function(v) _esp.skeleton = v end)
local _setNameEsp = elements:Toggle("Name",       espSection, function(v) _esp.name     = v end)
local _setDistEsp = elements:Toggle("Distance",   espSection, function(v) _esp.distance = v end)
local _setWeapEsp = elements:Toggle("Weapon",     espSection, function(v) _esp.weapon   = v end)
local _setHpEsp   = elements:Toggle("Health Bar", espSection, function(v) _esp.health   = v end)

local _espTeamCheck = false
local _setEspTeamCheck = elements:Toggle("Team Check", espSection, function(v)
    _espTeamCheck = v
end)

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

local _espVisColor     = _espColorMap.Red     -- color when player is visible
local _espNoVisColor   = _espColorMap.Orange  -- color when player is behind a wall
local _espVisColorName   = "Red"
local _espNoVisColorName = "Orange"
local _espVisCheck = false

local _setEspVisCheck = elements:Toggle("Vis Check", espSection, function(v) _espVisCheck = v end)
makeDropdown("Visible Color", espSection, _espColorNames, "Red",    function(v)
    _espVisColorName = v ; _espVisColor = _espColorMap[v]
end)
makeDropdown("Hidden Color",  espSection, _espColorNames, "Orange", function(v)
    _espNoVisColorName = v ; _espNoVisColor = _espColorMap[v]
end)

-- ── Config system ──────────────────────────────────────────────────────────────
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

local function _serializeBind(b)
    return {
        displayName = b.displayName,
        keyName     = b.key.Name,
        mouseName   = b.mouseBtn and b.mouseBtn.Name or nil,
    }
end

local function _applyBind(b, s)
    if not s then return end
    b.displayName = s.displayName or b.displayName
    if s.mouseName then
        b.key      = Enum.KeyCode.Unknown
        b.mouseBtn = Enum.UserInputType[s.mouseName]
    else
        b.key      = Enum.KeyCode[s.keyName] or b.key
        b.mouseBtn = nil
    end
    if b.hudLabel then b.hudLabel.Text = b.displayName end
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
        bindFly       = _serializeBind(_binds.fly),
        bindNoclip    = _serializeBind(_binds.noclip),
        bindAim       = _serializeBind(_binds.aim),
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
    if data.aimTeamCheck  ~= nil then _setTeamCheck(data.aimTeamCheck)    end
    if data.aimVisCheck   ~= nil then _setAimVisCheck(data.aimVisCheck)  end
    if data.aimMode             then _aimMode = data.aimMode             end

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

    _applyBind(_binds.fly,    data.bindFly)
    _applyBind(_binds.noclip, data.bindNoclip)
    _applyBind(_binds.aim,    data.bindAim)

    return true
end

-- Silent load: restores preference values only (speeds, FOV, aim mode, keybinds).
-- Intentionally skips feature toggles so no hacks activate automatically.
local function silentLoadConfig()
    if not isfile(CFG_FILE) then return false end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CFG_FILE)) end)
    if not ok or type(data) ~= "table" then return false end

    if data.walkSpeed then _walkSpeed = data.walkSpeed end
    if data.flySpeed  then _flySpeed  = data.flySpeed  end
    if data.aimFOV    then _aimFOV    = data.aimFOV    end
    if data.aimSpeed  then _aimSpeed  = data.aimSpeed  end
    if data.aimMode   then _aimMode   = data.aimMode   end
    if data.espVisColorName   then
        _espVisColorName = data.espVisColorName
        _espVisColor = _espColorMap[data.espVisColorName] or _espVisColor
    end
    if data.espNoVisColorName then
        _espNoVisColorName = data.espNoVisColorName
        _espNoVisColor = _espColorMap[data.espNoVisColorName] or _espNoVisColor
    end

    _applyBind(_binds.fly,    data.bindFly)
    _applyBind(_binds.noclip, data.bindNoclip)
    _applyBind(_binds.aim,    data.bindAim)

    return true
end

-- Settings tab config buttons
local _autoLoad = _readMeta().autoLoad == true

elements:Label("— Universal Config —", Sections.Settings.Container)
elements:Button("Save Config",  Sections.Settings.Container, function() pcall(saveConfig)       end)
elements:Button("Load Config",  Sections.Settings.Container, function() pcall(loadConfig)       end)
elements:Button("Silent Load",  Sections.Settings.Container, function() pcall(silentLoadConfig) end)
local _setAutoLoad = elements:Toggle("Auto Load on Start", Sections.Settings.Container, function(v)
    _autoLoad = v
    local m = _readMeta()
    m.autoLoad = v
    pcall(_writeMeta, m)
end)
_setAutoLoad(_autoLoad)  -- reflect persisted preference immediately

-- Auto-load on start (only when the preference is saved as enabled)
if _autoLoad then pcall(loadConfig) end
-- ──────────────────────────────────────────────────────────────────────────────

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

local function getESPData(uid)
    if not _espD[uid] then
        _espD[uid] = {
            box      = Drawing.new("Square"),
            hpBg     = newLine(Color3.fromRGB(0,0,0), 3),
            hpBar    = newLine(Color3.fromRGB(0,255,0), 3),
            nameT    = newText(13, Color3.fromRGB(255,255,255)),
            distT    = newText(11, Color3.fromRGB(160,210,255)),
            weapT    = newText(11, Color3.fromRGB(255,210,80)),
            sklLines = {},
        }
        local b = _espD[uid].box
        b.Filled = false
        b.Thickness = 1.5
        b.Color = Color3.fromRGB(255,50,50)
        b.Visible = false
    end
    return _espD[uid]
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

local function cleanESP(uid)
    local d = _espD[uid]
    if not d then return end
    pcall(function() d.box:Remove() end)
    pcall(function() d.hpBg:Remove() end)
    pcall(function() d.hpBar:Remove() end)
    pcall(function() d.nameT:Remove() end)
    pcall(function() d.distT:Remove() end)
    pcall(function() d.weapT:Remove() end)
    for _, l in ipairs(d.sklLines) do pcall(function() l:Remove() end) end
    _espD[uid] = nil
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

-- ── Players tab ───────────────────────────────────────────────────────────────
do
    local playersSection = Sections.Players.Container
    local Players        = game:GetService("Players")

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

    local function makePlayerRow(p)
        local row = Instance.new("Frame", rowContainer)
        row.Name = tostring(p.UserId)
        row.Size = UDim2.new(1, 0, 0, 48)
        row.BackgroundColor3 = Color3.fromRGB(20, 17, 38)
        row.BorderSizePixel = 0
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
        local rs = Instance.new("UIStroke", row)
        rs.Color = Color3.fromRGB(100, 80, 190)
        rs.Transparency = 0.7

        -- Name + info
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

        -- Buttons (4 across, 50px each, 6px gap → rightmost at -10)
        local function makeBtn(label, xOffset, color, cb)
            local btn = Instance.new("TextButton", row)
            btn.Size = UDim2.new(0, 50, 0, 26)
            btn.Position = UDim2.new(1, xOffset, 0.5, -13)
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
            return btn
        end

        -- TP To
        makeBtn("TP", -178, Color3.fromRGB(38, 28, 75), function()
            local myChar = plr.Character
            local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local tgtChar = p.Character
            local tgtHRP  = tgtChar and tgtChar:FindFirstChild("HumanoidRootPart")
            if myHRP and tgtHRP then
                myHRP.CFrame = tgtHRP.CFrame + Vector3.new(3, 0, 0)
            end
        end)

        -- Spectate
        makeBtn("Spec", -122, Color3.fromRGB(30, 22, 60), function()
            local cam = workspace.CurrentCamera
            local tgtChar = p.Character
            local hum = tgtChar and tgtChar:FindFirstChildOfClass("Humanoid")
            if hum then
                cam.CameraSubject = hum
                cam.CameraType = Enum.CameraType.Follow
            end
        end)

        -- Copy UserId
        makeBtn("Copy ID", -66, Color3.fromRGB(22, 18, 45), function()
            pcall(setclipboard, tostring(p.UserId))
        end)

        -- Fling: teleport onto target, spin hard, return
        makeBtn("Fling", -10, Color3.fromRGB(55, 10, 10), function()
            local myChar = plr.Character
            if not myChar then return end
            local myHRP   = myChar:FindFirstChild("HumanoidRootPart")
            local tgtChar = p.Character
            local tgtHRP  = tgtChar and tgtChar:FindFirstChild("HumanoidRootPart")
            if not myHRP or not tgtHRP then return end

            local origCF = myHRP.CFrame
            myHRP.CFrame = tgtHRP.CFrame  -- snap onto target

            local bav = Instance.new("BodyAngularVelocity")
            bav.AngularVelocity = Vector3.new(0, 4e4, 0)
            bav.MaxTorque       = Vector3.new(4e4, 4e4, 4e4)
            bav.P               = 4e4
            bav.Parent          = myHRP

            local bv = Instance.new("BodyVelocity")
            bv.Velocity  = Vector3.new(0, 60, 0)
            bv.MaxForce  = Vector3.new(1e4, 1e4, 1e4)
            bv.P         = 1e4
            bv.Parent    = myHRP

            task.delay(0.15, function()
                pcall(function() bav:Destroy() end)
                pcall(function() bv:Destroy() end)
                if myHRP and myHRP.Parent then
                    myHRP.CFrame = origCF
                end
            end)
        end)

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
        task.wait()  -- let the player actually leave before counting
        rebuild()
    end)
end

setTab("Home")

local hudRows = {
    {keyStr = "Insert",               desc = "Toggle Menu", bindRef = nil},
    {keyStr = _binds.fly.displayName,    desc = "Fly",    bindRef = _binds.fly},
    {keyStr = _binds.noclip.displayName, desc = "Noclip", bindRef = _binds.noclip},
    {keyStr = _binds.aim.displayName,    desc = "Aimbot", bindRef = _binds.aim},
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
    RunService:UnbindFromRenderStep("AstroAimRestore")
    RunService:Set3dRenderingEnabled(true)

    -- fly cleanup
    if _flyBV then _flyBV:Destroy(); _flyBV = nil end
    if _flyBG then _flyBG:Destroy(); _flyBG = nil end

    -- fullbright restore (uses locals _fullbrightOn and _fbOrig)
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

    -- clear all ESP drawings
    for uid in pairs(_espD) do
        cleanESP(uid)
    end

    -- destroy GUI (triggers AncestorRemoving on game script section → cleans MM2 targetGui etc.)
    gui:Destroy()
end

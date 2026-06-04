local hui = gethui or get_hidden_gui
local getexec = identifyexecutor
local players = game:GetService("Players")
local coregui = game:GetService("CoreGui")
local userinputservice = game:GetService("UserInputService")
local httpservice = game:GetService("HttpService")
local exservice = game:GetService("ExperienceService")
local tweenservice = game:GetService("TweenService")

-- Build UI programmatically (replaces external asset)
local ui = Instance.new("ScreenGui")
ui.Name = "CustomUI"
ui.ResetOnSpawn = false
ui.DisplayOrder = 10
local player = players.LocalPlayer
local playerGui = player and player:FindFirstChild("PlayerGui")
ui.Parent = playerGui or hui and hui() or coregui

-- Top-left astro label
local AstroLabel = Instance.new("TextLabel")
AstroLabel.Name = "AstroLabel"
AstroLabel.Size = UDim2.new(0, 120, 0, 28)
AstroLabel.Position = UDim2.new(0, 8, 0, 8)
AstroLabel.BackgroundTransparency = 1
AstroLabel.Text = "astro"
AstroLabel.TextXAlignment = Enum.TextXAlignment.Left
AstroLabel.Parent = ui

-- Toggle button (visible when menu hidden)
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "togglebtn"
ToggleButton.Size = UDim2.new(0, 36, 0, 36)
ToggleButton.Position = UDim2.new(0, 8, 0, 44)
ToggleButton.Text = "+"
ToggleButton.Parent = ui

-- MainFrame container
local MainFrame = Instance.new("Frame")
MainFrame.Name = "Frame"
MainFrame.Size = UDim2.new(0, 520, 0, 340)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -170)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Visible = false
MainFrame.Parent = ui

-- TopBar inside MainFrame
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1,0,0,36)
TopBar.Position = UDim2.new(0,0,0,0)
TopBar.Parent = MainFrame

local hidebtn = Instance.new("TextButton")
hidebtn.Name = "hidebtn"
hidebtn.Size = UDim2.new(0, 48, 0, 28)
hidebtn.Position = UDim2.new(1, -56, 0.5, -14)
hidebtn.Text = "x"
hidebtn.Parent = TopBar

-- Tablist (left side)
local TabList = Instance.new("Frame")
TabList.Name = "tablist"
TabList.Size = UDim2.new(0, 120, 1, -36)
TabList.Position = UDim2.new(0,0,0,36)
TabList.Parent = MainFrame

local function makeTab(name, y)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = UDim2.new(1, -8, 0, 32)
    b.Position = UDim2.new(0, 4, 0, y)
    b.Text = name:gsub("Tab", "")
    b.Parent = TabList
    return b
end

local HomeTab = makeTab("HomeTab", 8)
local GameTab = makeTab("GameTab", 48)
local GameslistTab = makeTab("GameslistTab", 88)
local SettingsTab = makeTab("SettingsTab", 128)
local CreditsTab = makeTab("CreditsTab", 168)

-- Section containers (right side)
local SectionContainers = Instance.new("Frame")
SectionContainers.Name = "sectionContainers"
SectionContainers.Size = UDim2.new(1, -120, 1, -36)
SectionContainers.Position = UDim2.new(0,120,0,36)
SectionContainers.Parent = MainFrame

local function makeSection(name)
    local f = Instance.new("Frame")
    f.Name = name
    f.Size = UDim2.new(1,0,1,0)
    f.AnchorPoint = Vector2.new(0.5, 0)
    f.Position = UDim2.new(0.5, 0, 1, 0)
    f.Visible = false
    f.Parent = SectionContainers
    return f
end

local homeframe = makeSection("homeframe")
local gameFrame = makeSection("gameFrame")
local gamelistFrame = makeSection("gamelistFrame")
local settingsFrame = makeSection("settingsFrame")
local creditsFrame = makeSection("creditsFrame")

local function styleGuiObject(obj)
    pcall(function() obj.BackgroundColor3 = Color3.fromRGB(0, 0, 0) end)
    pcall(function() obj.BorderColor3 = Color3.fromRGB(255, 255, 255) end)
    pcall(function() obj.TextColor3 = Color3.fromRGB(255, 255, 255) end)
    pcall(function() obj.PlaceholderColor3 = Color3.fromRGB(255, 255, 255) end)
    pcall(function() obj.ImageColor3 = Color3.fromRGB(255, 255, 255) end)
    if obj:IsA("UIStroke") then
        obj.Color = Color3.fromRGB(255, 255, 255)
        obj.Transparency = 0
    end
    if obj:IsA("UIGradient") then
        obj.Enabled = false
    end
end

local function applyBlackAndWhiteTheme(root)
    styleGuiObject(root)
    for _, obj in ipairs(root:GetDescendants()) do
        styleGuiObject(obj)
    end
end

applyBlackAndWhiteTheme(ui)

local Topbar = TopBar
local HideButton = hidebtn

local Sections = {
    Home = {
        TabBtn = HomeTab,
        Container = homeframe
    },

    Game = {
        TabBtn = GameTab,
        Container = gameFrame
    },

    GamesList = {
        TabBtn = GameslistTab,
        Container = gamelistFrame
    },

    Settings = {
        TabBtn = SettingsTab,
        Container = settingsFrame
    },

    Credits = {
        TabBtn = CreditsTab,
        Container = creditsFrame
    }
}

local CurSection

local function setActiveSection(sect)
    if CurSection then
        CurSection.TabBtn.BackgroundTransparency = 1
        CurSection.Container:TweenPosition(UDim2.new(0.5, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2)
    end

    sect.TabBtn.BackgroundTransparency = 0
    sect.Container.Visible = true
    sect.Container.Position = UDim2.new(0.5, 0, 0, 0)
    CurSection = sect
end

for _, sect in pairs(Sections) do
    sect.TabBtn.MouseEnter:Connect(function()
        for _, stroke in pairs(sect.TabBtn:GetChildren()) do
            if stroke.Name == "InnerShadow" then
                stroke.Transparency = 0.95
            end
        end
    end)

    sect.TabBtn.MouseLeave:Connect(function()
        for _, stroke in pairs(sect.TabBtn:GetChildren()) do
            if stroke.Name == "InnerShadow" then
                stroke.Transparency = 1
            end
        end
    end)

    sect.TabBtn.MouseButton1Click:Connect(function()
        if CurSection == sect then return end
        setActiveSection(sect)
    end)
end

setActiveSection(Sections.Home)

HideButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    ToggleButton.Visible = true
end)

ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    ToggleButton.Visible = false
end)

-- Toggle menu with Insert key
userinputservice.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Insert then
        if MainFrame.Visible then
            MainFrame.Visible = false
            ToggleButton.Visible = true
        else
            MainFrame.Visible = true
            ToggleButton.Visible = false
        end
    end
end)

local dragging = false
local dragInput, mousePos, framePos

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        mousePos = input.Position
        framePos = MainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

userinputservice.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - mousePos
        MainFrame.Position = UDim2.new(
            framePos.X.Scale,
            framePos.X.Offset + delta.X,
            framePos.Y.Scale,
            framePos.Y.Offset + delta.Y
        )
    end
end)

if Sections.Home.Container:FindFirstChild("bugsLabel") then
    Sections.Home.Container.bugsLabel.Text = Sections.Home.Container.bugsLabel.Text:gsub("redacted", "discord.gg/C2ySUrv99U")
end
if Sections.Home.Container:FindFirstChild("discan") then
    Sections.Home.Container.discan.Text = Sections.Home.Container.discan.Text:gsub("redacted", "discord.gg/C2ySUrv99U")
end
if Sections.Home.Container:FindFirstChild("ythead") then
    Sections.Home.Container.ythead.Text = Sections.Home.Container.ythead.Text:gsub("redacted", "astro")
end
if Sections.Home.Container:FindFirstChild("execLabel") then
    Sections.Home.Container.execLabel.Text = "Executor: astro"
end


local ok, gamePath = pcall(function()
    return game:HttpGet(getgitpath("games") .. tostring(game.PlaceId) .. ".lua")
end)
local gameList = httpservice:JSONDecode(game:HttpGet(getgitpath("src").. "gameslist.json"))
local creditsList = httpservice:JSONDecode(game:HttpGet(getgitpath("src").. "credits.json"))
local elements = loadstring(game:HttpGet(getgitpath("src").."elements.lua"))()
if not ok or #gamePath == 0 or gamePath == "404: Not Found" then
    local handledLocally = false

    if getgenv().FileScripts then
        if isfile("test/"..tostring(game.PlaceId)..".lua") then
            local gameModule = loadstring(readfile("test/"..tostring(game.PlaceId)..".lua"))()
            gameModule(Sections.Game.Container)
            handledLocally = true
        end
    end

    if not handledLocally then
        elements:Unsupported(Sections.Game.Container, function()
            if CurSection then
                CurSection.TabBtn.BackgroundTransparency = 1
                CurSection.Container:TweenPosition(UDim2.new(0.5, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2)
            end

            Sections.GamesList.TabBtn.BackgroundTransparency = 0
            Sections.GamesList.Container:TweenPosition(UDim2.new(0.5, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2)
            Sections.GamesList.Container.Visible = true

            CurSection = Sections.GamesList
        end)
    end
else
    local gameModule, err
    if type(gamePath) == "string" then
        gameModule, err = loadstring(gamePath)
    else
        err = "gamePath is not a valid string"
    end

    if type(gameModule) == "function" then
        gameModule(Sections.Game.Container)
    else
        warn("Failed to load game module for place " .. tostring(game.PlaceId) .. ": " .. tostring(err))
        elements:Unsupported(Sections.Game.Container, function()
            if CurSection then
                CurSection.TabBtn.BackgroundTransparency = 1
                CurSection.Container:TweenPosition(UDim2.new(0.5, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2)
            end

            Sections.GamesList.TabBtn.BackgroundTransparency = 0
            Sections.GamesList.Container:TweenPosition(UDim2.new(0.5, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2)
            Sections.GamesList.Container.Visible = true

            CurSection = Sections.GamesList
        end)
    end
end

for _, g in ipairs(gameList) do
    elements:Button(g.status .. " " .. g["game"], Sections.GamesList.Container, function()
        exservice:LaunchExperience({placeId = g.id})
    end)
end

for sect, c in pairs(creditsList) do
    elements:CredHead(Sections.Credits.Container, sect)

    for _, person in ipairs(c) do
        elements:CredPerson(Sections.Credits.Container, person)
    end
end

elements:Toggle("Disable 3D Rendering", Sections.Settings.Container, function(v)
    game:GetService("RunService"):Set3dRenderingEnabled(not v)
end)

elements:Toggle("Auto Rejoin (when kicked)", Sections.Settings.Container, function(v)
    getgenv().autorjjjj = v
end)

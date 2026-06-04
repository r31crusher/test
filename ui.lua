local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ExperienceService = game:GetService("ExperienceService")

local function getPlayerGui()
    local player = Players.LocalPlayer
    if not player then
        return nil
    end
    return player:FindFirstChild("PlayerGui")
end

local function fetchRemote(path)
    local ok, result = pcall(function()
        return game:HttpGet(path, true)
    end)
    if ok and result and result ~= "" and result ~= "404: Not Found" then
        return result
    end
    return nil
end

local function readLocal(name)
    if type(isfile) == "function" and isfile(name) then
        return readfile(name)
    end
    return nil
end

local function getGitPath(name)
    if type(getgitpath) == "function" then
        if name == "games" then
            return getgitpath("games")
        end
        return getgitpath()
    end
    return "https://raw.githubusercontent.com/r31crusher/test/main/"
end

local function fetchRemoteOrLocal(name)
    local remotePath
    if name:match("^games/") then
        remotePath = getGitPath("games") .. name:sub(7)
    else
        remotePath = getGitPath() .. name
    end

    local source = fetchRemote(remotePath)
    if not source then
        source = readLocal(name)
    end
    return source
end

local function safeLoad(name)
    local source = fetchRemoteOrLocal(name)
    if not source then
        error("Unable to load: " .. name)
    end

    local fn, compileError = loadstring(source)
    if not fn then
        error("Unable to compile " .. name .. ": " .. tostring(compileError))
    end

    local ok, result = pcall(fn)
    if not ok then
        error("Unable to execute " .. name .. ": " .. tostring(result))
    end

    return result
end

local elements = safeLoad("elements.lua")

local gui = Instance.new("ScreenGui")
gui.Name = "SolarisUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 1000
gui.Parent = getPlayerGui() or CoreGui

local function createFrame(name, parent, size, position, bgColor)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = size
    frame.Position = position
    frame.BackgroundColor3 = bgColor or Color3.fromRGB(18, 18, 18)
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.8
    stroke.Thickness = 1
    stroke.Parent = frame

    return frame
end

local MainFrame = createFrame("MainFrame", gui, UDim2.new(0, 760, 0, 520), UDim2.new(0.5, -380, 0.5, -260), Color3.fromRGB(14, 14, 14))

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 52)
TopBar.Position = UDim2.new(0, 0, 0, 0)
TopBar.BackgroundTransparency = 1
TopBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(0.7, 0, 1, 0)
TitleLabel.Position = UDim2.new(0, 20, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Solaris"
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextSize = 24
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.TextYAlignment = Enum.TextYAlignment.Center
TitleLabel.Parent = TopBar

local Subtitle = Instance.new("TextLabel")
Subtitle.Name = "Subtitle"
Subtitle.Size = UDim2.new(0.7, 0, 0, 20)
Subtitle.Position = UDim2.new(0, 20, 0, 28)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "Clean GUI powered by Solaris-style design"
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextSize = 14
Subtitle.TextColor3 = Color3.fromRGB(180, 180, 180)
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.TextYAlignment = Enum.TextYAlignment.Top
Subtitle.Parent = TopBar

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 44, 0, 32)
CloseButton.Position = UDim2.new(1, -52, 0.5, -16)
CloseButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
CloseButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.BorderSizePixel = 1
CloseButton.Text = "X"
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 18
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Parent = TopBar
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = CloseButton

local sidebar = createFrame("Sidebar", MainFrame, UDim2.new(0, 160, 1, -52), UDim2.new(0, 0, 0, 52), Color3.fromRGB(20, 20, 20))
local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Padding = UDim.new(0, 10)
sidebarLayout.Parent = sidebar
sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sidebarLayout.VerticalAlignment = Enum.VerticalAlignment.Top

local function createSidebarButton(text)
    local btn = Instance.new("TextButton")
    btn.Name = text .. "Button"
    btn.Size = UDim2.new(1, -24, 0, 44)
    btn.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    btn.BorderColor3 = Color3.fromRGB(255, 255, 255)
    btn.BorderSizePixel = 1
    btn.Text = text
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.AutoButtonColor = false
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn
    return btn
end

local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -160, 1, -52)
contentFrame.Position = UDim2.new(0, 160, 0, 52)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = MainFrame

local sectionFrames = {}
local sectionButtons = {}

local function createSection(name)
    local frame = Instance.new("Frame")
    frame.Name = name .. "Section"
    frame.Size = UDim2.new(1, -28, 1, -28)
    frame.Position = UDim2.new(0, 14, 0, 14)
    frame.BackgroundTransparency = 1
    frame.Visible = false
    frame.Parent = contentFrame

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 12)
    layout.Parent = frame

    return frame
end

local function createCard(parent, title)
    local card = createFrame(title .. "Card", parent, UDim2.new(1, 0, 0, 120), UDim2.new(0, 0, 0, 0), Color3.fromRGB(22, 22, 22))
    local cardTitle = Instance.new("TextLabel")
    cardTitle.Name = "CardTitle"
    cardTitle.Size = UDim2.new(1, -24, 0, 28)
    cardTitle.Position = UDim2.new(0, 12, 0, 12)
    cardTitle.BackgroundTransparency = 1
    cardTitle.Text = title
    cardTitle.Font = Enum.Font.GothamBold
    cardTitle.TextSize = 16
    cardTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    cardTitle.TextXAlignment = Enum.TextXAlignment.Left
    cardTitle.Parent = card
    return card
end

for _, name in ipairs({"Home", "Game", "Gameslist", "Settings", "Credits"}) do
    sectionFrames[name] = createSection(name)
    local btn = createSidebarButton(name)
    btn.LayoutOrder = #sidebar:GetChildren()
    btn.Parent = sidebar
    sectionButtons[name] = btn
end

local activeName
local activeButton

local function setActiveSection(name)
    if activeName then
        sectionFrames[activeName].Visible = false
    end
    if activeButton then
        activeButton.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    end
    activeName = name
    activeButton = sectionButtons[name]
    sectionFrames[name].Visible = true
    if activeButton then
        activeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end
end

for name, btn in pairs(sectionButtons) do
    btn.MouseButton1Click:Connect(function()
        setActiveSection(name)
    end)
end

CloseButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    MainFrame.Position = UDim2.new(0.5, -MainFrame.AbsoluteSize.X / 2, 0.5, -MainFrame.AbsoluteSize.Y / 2)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Insert then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

local function safeJson(name)
    local source = fetchRemoteOrLocal(name)
    if not source then
        return nil
    end
    local ok, result = pcall(function()
        return HttpService:JSONDecode(source)
    end)
    if ok then
        return result
    end
    return nil
end

local function safeLoadGameModule(placeId)
    local function compileSource(source)
        if type(source) ~= "string" then
            return nil, "source invalid"
        end
        local fn, err = loadstring(source)
        if not fn then
            return nil, err
        end
        return fn
    end

    local remote = fetchRemote(getGitPath("games") .. tostring(placeId) .. ".lua")
    if remote then
        local fn, err = compileSource(remote)
        if fn then
            return fn
        end
        warn("Remote game module compile failed: " .. tostring(err))
    end

    local localFile = readLocal("test/" .. tostring(placeId) .. ".lua")
    if localFile then
        local fn, err = compileSource(localFile)
        if fn then
            return fn
        end
        warn("Local game module compile failed: " .. tostring(err))
    end

    return nil, "Game module unavailable"
end

local function createCardContent(title, subtitle, parent)
    local card = createCard(parent, title)
    local sub = Instance.new("TextLabel")
    sub.Name = "CardSubtitle"
    sub.Size = UDim2.new(1, -24, 0, 20)
    sub.Position = UDim2.new(0, 12, 0, 42)
    sub.BackgroundTransparency = 1
    sub.Text = subtitle
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 14
    sub.TextColor3 = Color3.fromRGB(175, 175, 175)
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.TextYAlignment = Enum.TextYAlignment.Top
    sub.Parent = card
    return card
end

-- Home Section
local homeCard = createCardContent("Welcome", "Solaris-style UI rebuilt with clean layout.", sectionFrames.Home)
elements:Label("Use the sidebar to jump between sections.", homeCard)

elements:Label("Tips:", homeCard)
elements:Label("- Insert toggles visibility.", homeCard)
elements:Label("- All sections are powered by Solaris style.", homeCard)

-- Game Section
local gameModule, gameError = safeLoadGameModule(game.PlaceId)
if type(gameModule) == "function" then
    local ok, result = pcall(function()
        gameModule(sectionFrames.Game)
    end)
    if not ok then
        elements:Label("Game module executed with an error.", sectionFrames.Game)
        elements:Label(tostring(result), sectionFrames.Game)
    end
else
    elements:Unsupported(sectionFrames.Game, function()
        setActiveSection("Gameslist")
    end)
    elements:Label("Game-specific UI is unavailable.", sectionFrames.Game)
    elements:Label("Error: " .. tostring(gameError), sectionFrames.Game)
end

-- Gameslist Section
local gamesList = safeJson("gameslist.json") or {}
if #gamesList == 0 then
    elements:Label("No games found.", sectionFrames.Gameslist)
else
    for _, gameEntry in ipairs(gamesList) do
        elements:Button(gameEntry.status .. " " .. tostring(gameEntry.game), sectionFrames.Gameslist, function()
            ExperienceService:LaunchExperience({placeId = gameEntry.id})
        end)
    end
end

-- Settings Section
local settingsCard = createCardContent("Settings", "Toggle features and performance options.", sectionFrames.Settings)
elements:Toggle("Disable 3D Rendering", settingsCard, function(value)
    game:GetService("RunService"):Set3dRenderingEnabled(not value)
end)
elements:Toggle("Auto Rejoin on kick", settingsCard, function(value)
    getgenv().autorjjjj = value
end)

-- Credits Section
local creditsData = safeJson("credits.json") or {}
if next(creditsData) == nil then
    elements:Label("No credits available.", sectionFrames.Credits)
else
    for sectionName, people in pairs(creditsData) do
        elements:CredHead(sectionFrames.Credits, sectionName)
        for _, person in ipairs(people) do
            elements:CredPerson(sectionFrames.Credits, person)
        end
    end
end

setActiveSection("Home")
MainFrame.Visible = true

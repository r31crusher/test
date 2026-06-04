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

local function createNavButton(text, positionY)
    local button = Instance.new("TextButton")
    button.Name = text .. "Button"
    button.Size = UDim2.new(1, -16, 0, 36)
    button.Position = UDim2.new(0, 8, 0, positionY)
    button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    button.BorderColor3 = Color3.fromRGB(255, 255, 255)
    button.BorderSizePixel = 1
    button.Text = text
    button.Font = Enum.Font.SourceSans
    button.TextSize = 16
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.AutoButtonColor = false
    return button
end

local function createSection(name)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0, 0, 0, 0)
    frame.BackgroundTransparency = 1
    frame.Visible = false

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = frame

    return frame
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.Size = UDim2.new(0, 640, 0, 420)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
MainFrame.BorderSizePixel = 1
MainFrame.Parent = gui

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 36)
TopBar.Position = UDim2.new(0, 0, 0, 0)
TopBar.BackgroundTransparency = 1
TopBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(0.5, 0, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Solaris Menu"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 18
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.TextYAlignment = Enum.TextYAlignment.Center
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.Parent = TopBar

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 36, 0, 28)
CloseButton.Position = UDim2.new(1, -44, 0.5, -14)
CloseButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
CloseButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.BorderSizePixel = 1
CloseButton.Text = "X"
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.TextSize = 18
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Parent = TopBar

local NavFrame = Instance.new("Frame")
NavFrame.Name = "NavFrame"
NavFrame.Size = UDim2.new(0, 140, 1, -36)
NavFrame.Position = UDim2.new(0, 0, 0, 36)
NavFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
NavFrame.BorderSizePixel = 0
NavFrame.Parent = MainFrame

local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, -140, 1, -36)
ContentFrame.Position = UDim2.new(0, 140, 0, 36)
ContentFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ContentFrame.BorderSizePixel = 0
ContentFrame.Parent = MainFrame

local toggleOpen = Instance.new("TextButton")
toggleOpen.Name = "ToggleOpen"
toggleOpen.Size = UDim2.new(0, 40, 0, 40)
toggleOpen.Position = UDim2.new(0, 8, 0, 8)
toggleOpen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
toggleOpen.BorderColor3 = Color3.fromRGB(255, 255, 255)
toggleOpen.BorderSizePixel = 1
toggleOpen.Text = "+"
toggleOpen.Font = Enum.Font.SourceSansBold
toggleOpen.TextSize = 24
toggleOpen.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleOpen.Parent = gui

local sectionFrames = {
    Home = createSection("HomeSection"),
    Game = createSection("GameSection"),
    Gameslist = createSection("GameslistSection"),
    Settings = createSection("SettingsSection"),
    Credits = createSection("CreditsSection")
}

for _, frame in pairs(sectionFrames) do
    frame.Parent = ContentFrame
end

local navButtons = {
    Home = createNavButton("Home", 12),
    Game = createNavButton("Game", 60),
    Gameslist = createNavButton("Gameslist", 108),
    Settings = createNavButton("Settings", 156),
    Credits = createNavButton("Credits", 204)
}

for _, button in pairs(navButtons) do
    button.Parent = NavFrame
end

local activeSection = nil
local activeButton = nil

local function resetButton(button)
    button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
end

local function selectSection(name)
    if activeSection then
        activeSection.Visible = false
    end
    if activeButton then
        resetButton(activeButton)
    end
    activeSection = sectionFrames[name]
    activeButton = navButtons[name]
    if activeSection then
        activeSection.Visible = true
    end
    if activeButton then
        activeButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        activeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end

for name, button in pairs(navButtons) do
    button.MouseButton1Click:Connect(function()
        selectSection(name)
    end)
end

CloseButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    toggleOpen.Visible = true
end)

toggleOpen.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    toggleOpen.Visible = false
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Insert then
        MainFrame.Visible = not MainFrame.Visible
        toggleOpen.Visible = not MainFrame.Visible
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
    local path = getGitPath("games") .. tostring(placeId) .. ".lua"
    local source = fetchRemote(path)
    if not source then
        return nil, "no remote game module"
    end
    local fn, compileError = loadstring(source)
    if not fn then
        return nil, compileError
    end
    return fn
end

-- Home section
elements:Label("Welcome to Solaris", sectionFrames.Home)
elements:Label("Use the sidebar to select a section.", sectionFrames.Home)
elements:Label("This menu is rebuilt using Solaris-style UI.", sectionFrames.Home)

-- Game section
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
        selectSection("Gameslist")
    end)
    elements:Label("Game-specific UI is unavailable.", sectionFrames.Game)
    elements:Label("Error: " .. tostring(gameError), sectionFrames.Game)
end

-- Gameslist section
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

-- Settings section
elements:Label("Settings", sectionFrames.Settings)
elements:Toggle("Disable 3D Rendering", sectionFrames.Settings, function(value)
    game:GetService("RunService"):Set3dRenderingEnabled(not value)
end)
elements:Toggle("Auto Rejoin (when kicked)", sectionFrames.Settings, function(value)
    getgenv().autorjjjj = value
end)

-- Credits section
local creditsList = safeJson("credits.json") or {}
if next(creditsList) == nil then
    elements:Label("No credits available.", sectionFrames.Credits)
else
    for sectionName, people in pairs(creditsList) do
        elements:CredHead(sectionFrames.Credits, sectionName)
        for _, person in ipairs(people) do
            elements:CredPerson(sectionFrames.Credits, person)
        end
    end
end

selectSection("Home")
MainFrame.Visible = true
toggleOpen.Visible = false

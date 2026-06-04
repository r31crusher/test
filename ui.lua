local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

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
    local base = "https://raw.githubusercontent.com/r31crusher/test/main/"
    if name == "games" then
        return base .. "games/"
    end
    return base
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

local elementsOk, elementsResult = pcall(safeLoad, "elements.lua")
if not elementsOk then
    warn("Solaris: failed to load elements.lua - " .. tostring(elementsResult))
end
local elements = elementsOk and elementsResult or setmetatable({}, {
    __index = function() return function() end end
})

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
    frame.BackgroundColor3 = bgColor or Color3.fromRGB(15, 13, 26)
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(110, 85, 210)
    stroke.Transparency = 0.6
    stroke.Thickness = 1
    stroke.Parent = frame

    return frame
end

local MainFrame = createFrame("MainFrame", gui, UDim2.new(0, 760, 0, 520), UDim2.new(0.5, -380, 0.5, -260), Color3.fromRGB(10, 9, 18))

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 50)
TopBar.Position = UDim2.new(0, 0, 0, 0)
TopBar.BackgroundColor3 = Color3.fromRGB(8, 7, 15)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 14)
topCorner.Parent = TopBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(0.7, 0, 1, 0)
TitleLabel.Position = UDim2.new(0, 20, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Solaris"
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextSize = 22
TitleLabel.TextColor3 = Color3.fromRGB(220, 210, 255)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.TextYAlignment = Enum.TextYAlignment.Center
TitleLabel.Parent = TopBar

local Subtitle = Instance.new("TextLabel")
Subtitle.Name = "Subtitle"
Subtitle.Size = UDim2.new(0.7, 0, 0, 18)
Subtitle.Position = UDim2.new(0, 20, 0, 26)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "Clean GUI powered by Solaris"
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextSize = 12
Subtitle.TextColor3 = Color3.fromRGB(130, 118, 175)
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.TextYAlignment = Enum.TextYAlignment.Top
Subtitle.Parent = TopBar

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 40, 0, 30)
CloseButton.Position = UDim2.new(1, -48, 0.5, -15)
CloseButton.BackgroundColor3 = Color3.fromRGB(20, 16, 38)
CloseButton.BorderSizePixel = 0
CloseButton.Text = "X"
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 16
CloseButton.TextColor3 = Color3.fromRGB(180, 170, 220)
CloseButton.Parent = TopBar

CloseButton.MouseEnter:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(40, 28, 70)
    CloseButton.TextColor3 = Color3.fromRGB(255, 100, 100)
end)

CloseButton.MouseLeave:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(20, 16, 38)
    CloseButton.TextColor3 = Color3.fromRGB(180, 170, 220)
end)

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = CloseButton

local sidebar = createFrame("Sidebar", MainFrame, UDim2.new(0, 160, 1, -50), UDim2.new(0, 0, 0, 50), Color3.fromRGB(13, 11, 22))
local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Padding = UDim.new(0, 10)
sidebarLayout.Parent = sidebar
sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sidebarLayout.VerticalAlignment = Enum.VerticalAlignment.Top

local function createSidebarButton(text)
    local btn = Instance.new("TextButton")
    btn.Name = text .. "Button"
    btn.Size = UDim2.new(1, -20, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(15, 13, 26)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(170, 160, 210)
    btn.AutoButtonColor = false

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    btn.MouseEnter:Connect(function()
        btn.TextColor3 = Color3.fromRGB(220, 210, 255)
        btn.BackgroundColor3 = Color3.fromRGB(25, 20, 48)
    end)

    btn.MouseLeave:Connect(function()
        if activeName ~= text then
            btn.TextColor3 = Color3.fromRGB(170, 160, 210)
            btn.BackgroundColor3 = Color3.fromRGB(15, 13, 26)
        end
    end)
    
    return btn
end

local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -160, 1, -50)
contentFrame.Position = UDim2.new(0, 160, 0, 50)
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
    local card = createFrame(title .. "Card", parent, UDim2.new(1, 0, 0, 110), UDim2.new(0, 0, 0, 0), Color3.fromRGB(16, 14, 28))
    local cardTitle = Instance.new("TextLabel")
    cardTitle.Name = "CardTitle"
    cardTitle.Size = UDim2.new(1, -20, 0, 26)
    cardTitle.Position = UDim2.new(0, 10, 0, 10)
    cardTitle.BackgroundTransparency = 1
    cardTitle.Text = title
    cardTitle.Font = Enum.Font.GothamBold
    cardTitle.TextSize = 15
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
        if sectionButtons[activeName] then
            sectionButtons[activeName].BackgroundColor3 = Color3.fromRGB(15, 13, 26)
            sectionButtons[activeName].TextColor3 = Color3.fromRGB(170, 160, 210)
        end
    end
    activeName = name
    activeButton = sectionButtons[name]
    sectionFrames[name].Visible = true
    if activeButton then
        activeButton.BackgroundColor3 = Color3.fromRGB(38, 28, 75)
        activeButton.TextColor3 = Color3.fromRGB(210, 195, 255)
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
        return fn, nil
    end

    local lastErr

    local localFile = readLocal("games/" .. tostring(placeId) .. ".lua")
    if localFile then
        local fn, err = compileSource(localFile)
        if fn then return fn end
        lastErr = err
    end

    local remote = fetchRemote(getGitPath("games") .. tostring(placeId) .. ".lua")
    if remote then
        local fn, err = compileSource(remote)
        if fn then return fn end
        lastErr = err
    end

    return nil, lastErr
end

local function createCardContent(title, subtitle, parent)
    local card = createCard(parent, title)
    local sub = Instance.new("TextLabel")
    sub.Name = "CardSubtitle"
    sub.Size = UDim2.new(1, -20, 0, 18)
    sub.Position = UDim2.new(0, 10, 0, 38)
    sub.BackgroundTransparency = 1
    sub.Text = subtitle
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 12
    sub.TextColor3 = Color3.fromRGB(130, 118, 175)
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.TextYAlignment = Enum.TextYAlignment.Top
    sub.Parent = card
    return card
end

-- Home Section
local homeCard = createCardContent("Welcome", "Press Insert to toggle menu", sectionFrames.Home)
elements:Label("Navigate using the sidebar", homeCard)

-- Game Section
local gameScroll = Instance.new("ScrollingFrame")
gameScroll.Name = "GameScroll"
gameScroll.Size = UDim2.new(1, 0, 1, 0)
gameScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
gameScroll.BackgroundTransparency = 1
gameScroll.ScrollBarThickness = 4
gameScroll.ScrollBarImageColor3 = Color3.fromRGB(110, 85, 210)
gameScroll.BorderSizePixel = 0
gameScroll.Parent = sectionFrames.Game

local gameScrollLayout = Instance.new("UIListLayout")
gameScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
gameScrollLayout.Padding = UDim.new(0, 8)
gameScrollLayout.Parent = gameScroll

local gameScrollPad = Instance.new("UIPadding")
gameScrollPad.PaddingTop = UDim.new(0, 4)
gameScrollPad.PaddingLeft = UDim.new(0, 4)
gameScrollPad.PaddingRight = UDim.new(0, 4)
gameScrollPad.Parent = gameScroll

gameScrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    gameScroll.CanvasSize = UDim2.new(0, 0, 0, gameScrollLayout.AbsoluteContentSize.Y + 16)
end)

local function gameLabel(msg, color)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -8, 0, 28)
    lbl.BackgroundTransparency = 1
    lbl.Text = msg
    lbl.TextColor3 = color or Color3.fromRGB(210, 200, 255)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextWrapped = true
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = gameScroll
end

local gameModule, gameModuleErr = safeLoadGameModule(game.PlaceId)
if type(gameModule) == "function" then
    local ok, result = pcall(function()
        gameModule(gameScroll, elements)
    end)
    if not ok then
        gameLabel("Error: " .. tostring(result), Color3.fromRGB(255, 100, 100))
    end
else
    local reason = gameModuleErr and tostring(gameModuleErr) or "No module for game " .. tostring(game.PlaceId)
    gameLabel(reason, Color3.fromRGB(170, 160, 210))
end

-- Gameslist Section
local gamesList = safeJson("gameslist.json") or {}
if #gamesList > 0 then
    for _, gameEntry in ipairs(gamesList) do
        elements:Button((gameEntry.status or "●") .. " " .. tostring(gameEntry.game), sectionFrames.Gameslist, function()
            TeleportService:Teleport(gameEntry.id)
        end)
    end
else
    local gamesCard = createCardContent("Library", "No games in list", sectionFrames.Gameslist)
    elements:Label("Add games to gameslist.json", sectionFrames.Gameslist)
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
    local credCard = createCardContent("Credits", "No credits data", sectionFrames.Credits)
    elements:Label("credits.json not found", sectionFrames.Credits)
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

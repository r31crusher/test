local elements = {}
local stuff = {}

local function makeLabelTemplate()
    local lbl = Instance.new("TextLabel")
    lbl.Name = "LabelElement"
    lbl.Size = UDim2.new(1, 0, 0, 24)
    lbl.BackgroundTransparency = 1
    lbl.Text = ""
    return lbl
end

local function makeButtonTemplate()
    local btn = Instance.new("TextButton")
    btn.Name = "ButtonElement"
    btn.Size = UDim2.new(1, 0, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(0,0,0)
    btn.Text = ""
    local txt = Instance.new("TextLabel")
    txt.Name = "TextLabel"
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Text = "Button"
    txt.Parent = btn
    return btn
end

local function makeToggleTemplate()
    local tog = Instance.new("TextButton")
    tog.Name = "ToggleElement"
    tog.Size = UDim2.new(1,0,0,24)
    tog.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    tog.AutoButtonColor = false
    tog.Text = ""
    tog.TextTransparency = 1
    local txt = Instance.new("TextLabel")
    txt.Name = "TextLabel"
    txt.Size = UDim2.new(1, -40, 1, 0)
    txt.Position = UDim2.new(0,0,0,0)
    txt.BackgroundTransparency = 1
    txt.Text = "Toggle"
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.TextYAlignment = Enum.TextYAlignment.Center
    txt.Parent = tog

    local togglebg = Instance.new("Frame")
    togglebg.Name = "togglebg"
    togglebg.Size = UDim2.new(0, 36, 0, 18)
    togglebg.AnchorPoint = Vector2.new(1,0)
    togglebg.Position = UDim2.new(1, -4, 0.5, -9)
    togglebg.BackgroundColor3 = Color3.fromRGB(0,0,0)
    togglebg.Parent = tog

    local leftrightlol = Instance.new("Frame")
    leftrightlol.Name = "leftrightlol"
    leftrightlol.Size = UDim2.new(0.5, -2, 1, 0)
    leftrightlol.Position = UDim2.new(0, 2, 0, 0)
    leftrightlol.BackgroundColor3 = Color3.fromRGB(255,255,255)
    leftrightlol.Parent = togglebg

    return tog
end

local function makeTextboxTemplate()
    local tb = Instance.new("Frame")
    tb.Name = "TextboxElement"
    tb.Size = UDim2.new(1,0,0,30)
    local txt = Instance.new("TextLabel")
    txt.Name = "TextLabel"
    txt.Size = UDim2.new(1, -8, 0, 16)
    txt.Position = UDim2.new(0,4,0,4)
    txt.BackgroundTransparency = 1
    txt.Text = "Textbox"
    txt.Parent = tb

    local tbbg = Instance.new("Frame")
    tbbg.Name = "tbbg"
    tbbg.Size = UDim2.new(1,0,0,20)
    tbbg.Position = UDim2.new(0,0,0,10)
    tbbg.BackgroundColor3 = Color3.fromRGB(0,0,0)
    tbbg.Parent = tb

    local inp = Instance.new("TextBox")
    inp.Name = "Inp"
    inp.Size = UDim2.new(1, -4, 1, -4)
    inp.Position = UDim2.new(0,2,0,2)
    inp.BackgroundTransparency = 1
    inp.Text = ""
    inp.Parent = tbbg

    return tb
end

local function makeUnsupportedTemplate()
    local us = Instance.new("Frame")
    us.Name = "unsupportElement"
    us.Size = UDim2.new(1,0,0,80)
    local suggestbtn = Instance.new("TextButton")
    suggestbtn.Name = "suggestbtn"
    suggestbtn.Size = UDim2.new(0.5, -8, 0, 28)
    suggestbtn.Position = UDim2.new(0.25, 4, 0.5, -14)
    suggestbtn.Text = "Suggest Game"
    suggestbtn.Parent = us
    local glbtn = Instance.new("TextButton")
    glbtn.Name = "glbtn"
    glbtn.Size = UDim2.new(0.5, -8, 0, 28)
    glbtn.Position = UDim2.new(0.25, 4, 0.85, -14)
    glbtn.Text = "Open"
    glbtn.Parent = us
    return us
end

local function makeCreditHeader()
    local h = Instance.new("TextLabel")
    h.Name = "CreditHeader"
    h.Size = UDim2.new(1,0,0,20)
    h.Text = ""
    h.BackgroundTransparency = 1
    return h
end

local function makeCreditPerson()
    local p = Instance.new("TextLabel")
    p.Name = "CreditPerson"
    p.Size = UDim2.new(1,0,0,18)
    p.Text = ""
    p.BackgroundTransparency = 1
    return p
end

elements.LabelElement = makeLabelTemplate()
elements.ButtonElement = makeButtonTemplate()
elements.ToggleElement = makeToggleTemplate()
elements.TextboxElement = makeTextboxTemplate()
elements.unsupportElement = makeUnsupportedTemplate()
elements.CreditHeader = makeCreditHeader()
elements.CreditPerson = makeCreditPerson()

local function styleGuiObject(obj)
    pcall(function() obj.BackgroundColor3 = Color3.fromRGB(16, 14, 28) end)
    pcall(function() obj.BorderColor3 = Color3.fromRGB(110, 85, 210) end)
    pcall(function() obj.TextColor3 = Color3.fromRGB(210, 200, 255) end)
    pcall(function() obj.PlaceholderColor3 = Color3.fromRGB(130, 118, 175) end)
    pcall(function() obj.ImageColor3 = Color3.fromRGB(210, 200, 255) end)
    -- hide/remove unwanted 'brainrot police' labels or similar
    pcall(function()
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            local ok, txt = pcall(function() return obj.Text end)
            if ok and type(txt) == "string" then
                local ltxt = string.lower(txt)
                if ltxt:find("brain") or ltxt:find("brainrot") or ltxt:find("police") then
                    obj.Visible = false
                end
            end
        end
        if obj.Name then
            local lname = string.lower(obj.Name)
            if lname:find("brain") or lname:find("police") or lname:find("brainrot") then
                obj.Visible = false
            end
        end
    end)
    if obj:IsA("UIStroke") then
        obj.Color = Color3.fromRGB(110, 85, 210)
        obj.Transparency = 0.5
    end
    if obj:IsA("UIGradient") then
        obj.Enabled = false
    end
end

local function styleElement(root)
    styleGuiObject(root)
    for _, obj in ipairs(root:GetDescendants()) do
        styleGuiObject(obj)
    end
end

function stuff:Label(str, king)
    local newLabel = elements.LabelElement:Clone()
    newLabel.Text = str
    styleElement(newLabel)
    newLabel.Parent = king
end

function stuff:Button(str, king, cb)
    local newBtn = elements.ButtonElement:Clone()
    newBtn.TextLabel.Text = str
    styleElement(newBtn)
    newBtn.Parent = king

    newBtn.MouseButton1Click:Connect(cb)
end

function stuff:Toggle(str, king, cb)
    local newTog = elements.ToggleElement:Clone()
    newTog.TextLabel.Text = str
    styleElement(newTog)
    newTog.togglebg.BackgroundColor3 = Color3.fromRGB(20, 16, 38)
    newTog.Parent = king

    local isTog = false

    newTog.MouseButton1Click:Connect(function()
        isTog = not isTog
        if isTog then
            newTog.togglebg.BackgroundColor3 = Color3.fromRGB(110, 75, 220)
            newTog.togglebg.leftrightlol.AnchorPoint = Vector2.new(1, 0.5)
            newTog.togglebg.leftrightlol.Position = UDim2.new(1, 0, 0.5, 0)
            cb(isTog)
        else
            newTog.togglebg.BackgroundColor3 = Color3.fromRGB(20, 16, 38)
            newTog.togglebg.leftrightlol.AnchorPoint = Vector2.new(0, 0.5)
            newTog.togglebg.leftrightlol.Position = UDim2.new(0, 0, 0.5, 0)
            cb(isTog)
        end
    end)
end

function stuff:Textbox(str, king, cb)
    local newTb = elements.TextboxElement:Clone()
    newTb.TextLabel.Text = str
    styleElement(newTb)
    newTb.Parent = king

    newTb.tbbg.Inp.FocusLost:Connect(function(ep)
        cb(newTb.tbbg.Inp.Text)
    end)
end

function stuff:Unsupported(king, cb)
    local newUs = elements.unsupportElement:Clone()
    styleElement(newUs)
    newUs.Parent = king

    newUs.suggestbtn.MouseButton1Click:Connect(function()
        setclipboard("https://discord.gg/C2ySUrv99U")
        newUs.suggestbtn.Text = "Copied Link!"
        wait(1)
        newUs.suggestbtn.Text = "Suggest Game"
    end)

    newUs.glbtn.MouseButton1Click:Connect(cb)
end

function stuff:CredHead(king, txt)
    local newHead = elements.CreditHeader:Clone()
    newHead.Text = "> " .. txt
    styleElement(newHead)
    newHead.Parent = king
end

function stuff:CredPerson(king, txt)
    local newCred = elements.CreditPerson:Clone()
    newCred.Text = "      + " .. txt
    styleElement(newCred)
    newCred.Parent = king
end

return stuff

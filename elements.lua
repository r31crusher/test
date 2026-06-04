local elements = {}
local stuff = {}

-- ── Templates (astro palette, no runtime re-styling) ─────────────────────────

local function newLabel()
    local lbl = Instance.new("TextLabel")
    lbl.Name = "LabelElement"
    lbl.Size = UDim2.new(1, 0, 0, 24)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextColor3 = Color3.fromRGB(200, 190, 255)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = ""
    return lbl
end

local function newButton()
    local btn = Instance.new("TextButton")
    btn.Name = "ButtonElement"
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(20, 17, 38)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = ""
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(100, 80, 190)
    stroke.Transparency = 0.6
    local txt = Instance.new("TextLabel", btn)
    txt.Name = "TextLabel"
    txt.Size = UDim2.new(1, -12, 1, 0)
    txt.Position = UDim2.new(0, 10, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.GothamSemibold
    txt.TextSize = 13
    txt.TextColor3 = Color3.fromRGB(200, 190, 255)
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Text = "Button"
    return btn
end

local function newToggle()
    local tog = Instance.new("TextButton")
    tog.Name = "ToggleElement"
    tog.Size = UDim2.new(1, 0, 0, 32)
    tog.BackgroundColor3 = Color3.fromRGB(20, 17, 38)
    tog.BorderSizePixel = 0
    tog.AutoButtonColor = false
    tog.Text = ""
    Instance.new("UICorner", tog).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", tog)
    stroke.Color = Color3.fromRGB(100, 80, 190)
    stroke.Transparency = 0.6
    local txt = Instance.new("TextLabel", tog)
    txt.Name = "TextLabel"
    txt.Size = UDim2.new(1, -60, 1, 0)
    txt.Position = UDim2.new(0, 10, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.GothamSemibold
    txt.TextSize = 13
    txt.TextColor3 = Color3.fromRGB(200, 190, 255)
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Text = "Toggle"
    local bg = Instance.new("Frame", tog)
    bg.Name = "togglebg"
    bg.Size = UDim2.new(0, 36, 0, 18)
    bg.AnchorPoint = Vector2.new(1, 0.5)
    bg.Position = UDim2.new(1, -8, 0.5, 0)
    bg.BackgroundColor3 = Color3.fromRGB(35, 28, 65)
    bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)
    local dot = Instance.new("Frame", bg)
    dot.Name = "leftrightlol"
    dot.Size = UDim2.new(0, 12, 0, 12)
    dot.AnchorPoint = Vector2.new(0, 0.5)
    dot.Position = UDim2.new(0, 3, 0.5, 0)
    dot.BackgroundColor3 = Color3.fromRGB(160, 150, 220)
    dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    return tog
end

local function newTextbox()
    local tb = Instance.new("Frame")
    tb.Name = "TextboxElement"
    tb.Size = UDim2.new(1, 0, 0, 50)
    tb.BackgroundColor3 = Color3.fromRGB(20, 17, 38)
    tb.BorderSizePixel = 0
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", tb)
    stroke.Color = Color3.fromRGB(100, 80, 190)
    stroke.Transparency = 0.6
    local lbl = Instance.new("TextLabel", tb)
    lbl.Name = "TextLabel"
    lbl.Size = UDim2.new(1, -12, 0, 20)
    lbl.Position = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = Color3.fromRGB(160, 150, 210)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = "Textbox"
    local tbbg = Instance.new("Frame", tb)
    tbbg.Name = "tbbg"
    tbbg.Size = UDim2.new(1, -12, 0, 22)
    tbbg.Position = UDim2.new(0, 6, 0, 24)
    tbbg.BackgroundColor3 = Color3.fromRGB(12, 10, 22)
    tbbg.BorderSizePixel = 0
    Instance.new("UICorner", tbbg).CornerRadius = UDim.new(0, 4)
    local inp = Instance.new("TextBox", tbbg)
    inp.Name = "Inp"
    inp.Size = UDim2.new(1, -8, 1, -4)
    inp.Position = UDim2.new(0, 4, 0, 2)
    inp.BackgroundTransparency = 1
    inp.Font = Enum.Font.Gotham
    inp.TextSize = 12
    inp.TextColor3 = Color3.fromRGB(200, 190, 255)
    inp.PlaceholderColor3 = Color3.fromRGB(110, 100, 155)
    inp.Text = ""
    inp.PlaceholderText = "Type here..."
    inp.ClearTextOnFocus = false
    return tb
end

local function newUnsupported()
    local us = Instance.new("Frame")
    us.Name = "unsupportElement"
    us.Size = UDim2.new(1, 0, 0, 90)
    us.BackgroundColor3 = Color3.fromRGB(20, 17, 38)
    us.BorderSizePixel = 0
    Instance.new("UICorner", us).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", us)
    stroke.Color = Color3.fromRGB(100, 80, 190)
    stroke.Transparency = 0.6
    local lbl = Instance.new("TextLabel", us)
    lbl.Size = UDim2.new(1, -12, 0, 24)
    lbl.Position = UDim2.new(0, 10, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextColor3 = Color3.fromRGB(200, 190, 255)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = "No module for this game."
    local suggestbtn = Instance.new("TextButton", us)
    suggestbtn.Name = "suggestbtn"
    suggestbtn.Size = UDim2.new(0.5, -10, 0, 28)
    suggestbtn.Position = UDim2.new(0, 6, 0, 36)
    suggestbtn.BackgroundColor3 = Color3.fromRGB(28, 22, 52)
    suggestbtn.BorderSizePixel = 0
    suggestbtn.Font = Enum.Font.GothamSemibold
    suggestbtn.TextSize = 12
    suggestbtn.TextColor3 = Color3.fromRGB(200, 190, 255)
    suggestbtn.Text = "Suggest Game"
    Instance.new("UICorner", suggestbtn).CornerRadius = UDim.new(0, 6)
    local glbtn = Instance.new("TextButton", us)
    glbtn.Name = "glbtn"
    glbtn.Size = UDim2.new(0.5, -10, 0, 28)
    glbtn.Position = UDim2.new(0.5, 4, 0, 36)
    glbtn.BackgroundColor3 = Color3.fromRGB(38, 28, 75)
    glbtn.BorderSizePixel = 0
    glbtn.Font = Enum.Font.GothamSemibold
    glbtn.TextSize = 12
    glbtn.TextColor3 = Color3.fromRGB(210, 195, 255)
    glbtn.Text = "Games List"
    Instance.new("UICorner", glbtn).CornerRadius = UDim.new(0, 6)
    return us
end

local function newCredHead()
    local h = Instance.new("TextLabel")
    h.Name = "CreditHeader"
    h.Size = UDim2.new(1, 0, 0, 22)
    h.BackgroundTransparency = 1
    h.Font = Enum.Font.GothamBold
    h.TextSize = 13
    h.TextColor3 = Color3.fromRGB(200, 190, 255)
    h.TextXAlignment = Enum.TextXAlignment.Left
    h.Text = ""
    return h
end

local function newCredPerson()
    local p = Instance.new("TextLabel")
    p.Name = "CreditPerson"
    p.Size = UDim2.new(1, 0, 0, 18)
    p.BackgroundTransparency = 1
    p.Font = Enum.Font.Gotham
    p.TextSize = 12
    p.TextColor3 = Color3.fromRGB(160, 150, 210)
    p.TextXAlignment = Enum.TextXAlignment.Left
    p.Text = ""
    return p
end

-- ── Store templates ───────────────────────────────────────────────────────────
elements.LabelElement     = newLabel()
elements.ButtonElement    = newButton()
elements.ToggleElement    = newToggle()
elements.TextboxElement   = newTextbox()
elements.unsupportElement = newUnsupported()
elements.CreditHeader     = newCredHead()
elements.CreditPerson     = newCredPerson()

-- ── API ───────────────────────────────────────────────────────────────────────

function stuff:Label(str, king)
    local lbl = elements.LabelElement:Clone()
    lbl.Text = str
    lbl.Parent = king
end

function stuff:Button(str, king, cb)
    local btn = elements.ButtonElement:Clone()
    btn.TextLabel.Text = str
    btn.Parent = king
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(30, 25, 55) end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(20, 17, 38) end)
    btn.MouseButton1Click:Connect(cb)
end

function stuff:Toggle(str, king, cb)
    local tog = elements.ToggleElement:Clone()
    tog.TextLabel.Text = str
    tog.Parent = king
    local on = false
    tog.MouseButton1Click:Connect(function()
        on = not on
        if on then
            tog.togglebg.BackgroundColor3 = Color3.fromRGB(80, 55, 180)
            tog.togglebg.leftrightlol.AnchorPoint = Vector2.new(1, 0.5)
            tog.togglebg.leftrightlol.Position = UDim2.new(1, -3, 0.5, 0)
            tog.togglebg.leftrightlol.BackgroundColor3 = Color3.fromRGB(210, 200, 255)
        else
            tog.togglebg.BackgroundColor3 = Color3.fromRGB(35, 28, 65)
            tog.togglebg.leftrightlol.AnchorPoint = Vector2.new(0, 0.5)
            tog.togglebg.leftrightlol.Position = UDim2.new(0, 3, 0.5, 0)
            tog.togglebg.leftrightlol.BackgroundColor3 = Color3.fromRGB(160, 150, 220)
        end
        cb(on)
    end)
end

function stuff:Textbox(str, king, cb)
    local tb = elements.TextboxElement:Clone()
    tb.TextLabel.Text = str
    tb.Parent = king
    tb.tbbg.Inp.FocusLost:Connect(function()
        cb(tb.tbbg.Inp.Text)
    end)
end

function stuff:Unsupported(king, cb)
    local us = elements.unsupportElement:Clone()
    us.Parent = king
    us.suggestbtn.MouseButton1Click:Connect(function()
        pcall(function() setclipboard("https://discord.gg/C2ySUrv99U") end)
        us.suggestbtn.Text = "Copied!"
        task.delay(1.5, function()
            if us and us.Parent then
                us.suggestbtn.Text = "Suggest Game"
            end
        end)
    end)
    us.glbtn.MouseButton1Click:Connect(cb)
end

function stuff:CredHead(king, txt)
    local h = elements.CreditHeader:Clone()
    h.Text = "> " .. txt
    h.Parent = king
end

function stuff:CredPerson(king, txt)
    local p = elements.CreditPerson:Clone()
    p.Text = "  + " .. txt
    p.Parent = king
end

return stuff

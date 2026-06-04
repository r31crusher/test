local env = getgenv()

if not isfolder("test") then makefolder("test") end

function env.import(id)
    return game:GetObjects(id)[1]
end

function env.getgitpath(where)
    local base = "https://raw.githubusercontent.com/r31crusher/test/main/"
    if where == "src" then
        return base
    elseif where == "games" then
        return base .. "games/"
    end
    return base
end

game:GetService("GuiService").ErrorMessageChanged:Connect(function()
    if env.autorjjjj then
        game:GetService("TeleportService"):Teleport(game.PlaceId)
    end
end)

loadstring(game:HttpGet(getgitpath("src") .. "ui.lua"))()

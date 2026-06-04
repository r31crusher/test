local env = getgenv()

if not isfolder("test") then
    makefolder("test")
end

function env.import(id)
    return game:GetObjects(id)[1]
end

function env.getgitpath(where)
    local base = "https://raw.githubusercontent.com/r31crusher/test/main/"
    if where == "games" then
        return base .. "games/"
    end
    return base
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

local function loadRemoteOrLocal(name)
    local remotePath

    if name:match("^games/") then
        remotePath = env.getgitpath("games") .. name:sub(7)
    else
        remotePath = env.getgitpath() .. name
    end

    local source = fetchRemote(remotePath)

    if not source and isfile(name) then
        source = readfile(name)
    end

    if not source then
        error("Unable to load: " .. name)
    end

    return loadstring(source)()
end

game:GetService("GuiService").ErrorMessageChanged:Connect(function()
    if env.autorjjjj then
        game:GetService("TeleportService"):Teleport(game.PlaceId)
    end
end)

loadRemoteOrLocal("ui.lua")

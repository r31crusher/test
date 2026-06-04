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

    local func, err = loadstring(source)
    if not func then
        if isfile(name) then
            source = readfile(name)
            func, err = loadstring(source)
        end
    end

    if not func then
        error("Unable to compile: " .. tostring(err))
    end

    local ok, result = pcall(func)
    if ok then
        return result
    end

    if source ~= nil and isfile(name) then
        local localSource = readfile(name)
        local localFunc, localErr = loadstring(localSource)
        if localFunc then
            local ok2, result2 = pcall(localFunc)
            if ok2 then
                return result2
            end
        end
    end

    error("Unable to execute " .. name .. ": " .. tostring(result))
end

game:GetService("GuiService").ErrorMessageChanged:Connect(function()
    if env.autorjjjj then
        game:GetService("TeleportService"):Teleport(game.PlaceId)
    end
end)

loadRemoteOrLocal("ui.lua")

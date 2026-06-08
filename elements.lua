local _idCounter = 0
local function uid(prefix)
    _idCounter += 1
    return prefix .. tostring(_idCounter)
end

return function(groupbox)
    local adapter = {}

    function adapter:Toggle(label, _parent, cb)
        local obj = groupbox:AddToggle(uid("toggle_"), {
            Text = label,
            Default = false,
            Callback = cb
        })
        return function(v) obj:SetValue(v) end
    end

    function adapter:Slider(label, _parent, min, max, default, cb)
        local obj = groupbox:AddSlider(uid("slider_"), {
            Text = label,
            Min = min,
            Max = max,
            Default = default,
            Rounding = 0,
            Callback = cb
        })
        return function(v) obj:SetValue(v) end
    end

    function adapter:Button(label, _parent, cb)
        groupbox:AddButton(label, cb)
    end

    function adapter:Label(text, _parent)
        groupbox:AddLabel(text)
    end

    function adapter:Textbox(label, _parent, cb)
        groupbox:AddInput(uid("input_"), {
            Text = label,
            Placeholder = "",
            Finished = true,
            Callback = cb
        })
    end

    function adapter:Unsupported(_parent, gameslistCb)
        groupbox:AddLabel("No module for this game.")
        groupbox:AddButton("Games List", gameslistCb)
    end

    function adapter:CredHead(_parent, text)
        groupbox:AddLabel("> " .. text)
    end

    function adapter:CredPerson(_parent, text)
        groupbox:AddLabel("  + " .. text)
    end

    return adapter
end

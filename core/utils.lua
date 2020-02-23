function table.copy(tb)
    local t={}
    for k,v in pairs(tb) do
        t[k]=v
    end
    return t
end

function table.keys(tb)
    local t={}
    for k,v in pairs(tb) do
        table.insert(t, k)
    end
    return t
end

function table.keymap(tb)
    local t = {}
    for k,v in pairs(tb) do
        t[k] = true
    end
    return t
end

function tpairs(tb)
    local keys = table.keymap(tb)
    return function(t, k)
        local nk = next(t, k)
        return nk, tb[nk]
    end, keys, nil
end

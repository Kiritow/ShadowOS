local thread = kloadlib("thread")
local term = kloadlib("term")


local function CreateBasicEnv()
    local ecb = {
        subterm = term.create(component.proxy(component.list("gpu")()))
    }
    local env = {
        _VERSION=_G._VERSION,
        type=_G.type,
        assert=_G.assert,
        tostring=_G.tostring,
        tonumber=_G.tonumber,
        pairs=_G.pairs,
        ipairs=_G.ipairs,
        select=_G.select,
        rawlen=_G.rawlen,
        rawequal=_G.rawequal,
        rawset=_G.rawset,
        rawget=_G.rawget,
        getmetatable=_G.getmetatable,
        setmetatable=_G.setmetatable,
        load=_G.load,
        pcall=_G.pcall,
        xpcall=_G.select,
        math=table.copy(_G.math),
        table=table.copy(_G.table),
        string=table.copy(_G.string),
        debug=table.copy(_G.debug),
        unicode=table.copy(_G.unicode),
        checkArg=_G.checkArg,
        os = {
            time=_G.os.time,
            date=_G.os.date,
            difftime=_G.os.difftime,
            clock=_G.os.clock
        },
        coroutine = table.copy(thread.co),  -- debug only, not functionable.
        component = table.copy(_G.component),  -- debug only, direct r/w
        print = function(...)
            local t = table.pack(...)
            t.n = nil
            for k, v in pairs(t) do
                t[k] = tostring(v)
            end
            ecb.subterm:print(table.concat(t, ' '))
        end,
        -- computer = {}
    }
    env._G = env
    ecb.env = env
    return ecb
end

local process = {
    list = {}
}

function process.nextpid()
    local i = 1
    while process.list[i] do i = i + 1 end
    return i
end

function process.createFrom(ppid, token, name, code, ...)
    local ecb = CreateBasicEnv()
    local env = ecb.env
    for k, v in pairs(thread.api) do
        env[k] = v
    end
    local fn, err = load(code, name, "t", env)
    if fn then
        return true, process.create(ppid, token, env, fn, ...)
    else
        return false, err
    end
end

function process.create(ppid, token, env, fn, ...)
    local pid = process.nextpid()
    local proc = {
        pid = pid,
        ppid = ppid,
        token = token,
        env = env,
        main = thread.create(fn, ...),
        threads = {}
    }
    process.list[pid] = proc
    return proc
end

return process, thread

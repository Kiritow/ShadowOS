local thread = {
    co = {},
    api = {},
    pool = {}
}

function thread.create(fn, ...)
    local args = table.pack(...)
    local td = {
        co = coroutine.create(function()
            local stack
            local ret = table.pack(xpcall(fn, function(msgh) stack = debug.traceback() return msgh end, table.unpack(args)))
            if ret[1] then
                return table.unpack(ret, 2)
            else
                error({ret[2], stack})
            end
        end),
        status = "ready",  -- blocking / running / wait / sleep / terminated
        standalone = true,
        stack = {},
        params = {},
        filter = nil
    }
    thread.pool[td.co] = td
    return td
end

function thread.co.create(f)
    local td = thread.create(f)
    td.standalone = false
    td.status = "idle"
    return td.co
end

function thread.co.running()
    local co = coroutine.running()
    local td = thread.pool[co]
    return co, td.standalone
end

function thread.co.status(co)
    local td = thread.pool[co]
    if td.standalone then
        local transmap = {
            ready = "normal",
            blocking = "normal",
            running = "running",
            wait = "normal",
            sleep = "normal",
            terminated = "dead"
        }
        return transmap[td.status]
    else
        local transmap = {
            ready = "normal",
            blocking = "normal",
            running = "running",
            wait = "normal",
            sleep = "normal",
            terminated = "dead",
            idle="suspended",
        }
        return transmap[td.status]
    end
end

function thread.co.resume(co, ...)
    local td = thread.pool[coroutine.running()]
    local xtd = thread.pool[co]
    if thread.co.status(co) == "suspended" then
        table.insert(td.stack, coroutine.running())
        td.status = "wait"
        xtd.stack = td.stack
        xtd.status = "ready"
        xtd.params = table.pack(...)
        coroutine.yield("switch")
    elseif thread.co.status(co) == "dead" then
        return false, "cannot resume dead coroutine"
    else
        return false, "cannot resume non-suspended coroutine"
    end
end

function thread.co.isyieldable()
    local td = thread.pool[coroutine.running()]
    if td.standalone then
        if next(td.stack) then
            return true
        else
            return false
        end
    else
        return true
    end
end

function thread.co.yield(...)
    if thread.co.isyieldable() then
        local td = thread.pool[coroutine.running()]
        local lastidx = #td.stack
        local ptd = thread.pool[td.stack[lastidx]]
        td.status = "idle"
        td.stack = {}
        ptd.status = "ready"
        ptd.params = table.pack(...)
        coroutine.yield("switch")
    else
        error("attempt to yield from outside a coroutine")
    end
end

function thread.co.running()
    return coroutine.running()
end

function thread.co.wrap(f)
    local co = thread.co.create(f)
    return function(...)
        local ret = table.pack(thread.co.resume(co, ...))
        if ret[1] then
            return table.unpack(ret, 2)
        else
            error(ret[2])
        end
    end
end

function thread.api.WaitEvent(timeout, name)
    local td = thread.pool[coroutine.running()]
    td.status = "blocking"
    td.filter = name
    if timeout < 0 then
        timeout = math.huge
    end
    return coroutine.yield("waitevent", timeout, td.filter)
end

return thread

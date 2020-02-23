local process, thread = kloadlib("process")

local sched = {}
local listeners = {}

function sched.ksleep(sec)  -- blocking, should not use
    local target = computer.uptime() + sec
    repeat
        computer.pullSignal(target - computer.uptime())
    until computer.uptime() >= target
end

local function KPollEvent()
    local t = {}
    while true do
        local s = table.pack(computer.pullSignal(0))
        if s[1] then
            table.insert(t, s)
            ktalk(string.format("event params: %d", s.n))
        else break end        
    end
    return t
end

local function KAddEventListener(td, name, timeout, oneshot)
    if not listeners[name] then
        listeners[name] = {}
    end
    if not listeners[name][td] then
        listeners[name][td] = {
            deadline = computer.uptime() + timeout,
            oneshot = oneshot
        }
    end
end

local function KRemoveEventListener(td, name)
    if listeners[name] and listeners[name][td] then
        listeners[name][td] = nil
    end
end

function sched.start()
    while next(process.list) do
        ktalk("schedule...")
        for pid, pcb in tpairs(process.list) do
            local tcb = pcb.main
            if tcb.status == "ready" then
                tcb.status = "running"
                local ret = table.pack(coroutine.resume(pcb.main.co, table.unpack(tcb.params)))
                if not ret[1] then
                    kpanic(string.format('unexpected error in process %d: %s', pid, ret[2]))
                end
                if ret[2] == "waitevent" then
                    if ret[4] and ret[4] ~= "" then
                        KAddEventListener(tcb, ret[4], ret[3], true)
                    else
                        KAddEventListener(tcb, "__any__", ret[3], true)
                    end
                end
            end
        end

        ktalk("poll event")
        local events = KPollEvent()
        for _, event in pairs(events) do
            if listeners[event[1]] then
                for tcb, tconf in tpairs(listeners[event[1]]) do
                    tcb.status = "ready"
                    tcb.params = event
                    if tconf.oneshot or computer.uptime() >= tconf.deadline then
                        ktalk("listener removed")
                        listeners[event[1]][tcb] = nil
                    end
                end
            end
            if listeners["__any__"] then
                for tcb, tconf in tpairs(listeners["__any__"]) do
                    tcb.status = "ready"
                    tcb.params = event
                    if tconf.oneshot or computer.uptime() >= tconf.deadline then
                        ktalk("listener removed")
                        listeners["__any__"][tcb] = nil
                    end
                end
            end
        end
    end
end

return sched, process

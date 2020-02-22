local process = kloadlib("process")

local sched = {}

function sched.ksleep(sec)  -- blocking, should not use
    local target = computer.uptime() + sec
    repeat
        computer.pullSignal(target - computer.uptime())
    until computer.uptime() >= target
end

function sched.start()

end

return sched

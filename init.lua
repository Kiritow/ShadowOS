local kfs = component.proxy(computer.getBootAddress())
local kgpu = component.proxy(component.list("gpu")())

local function ktalk(msg)
    local kchat = component.list("chat_box")()
    if kchat then
        component.proxy(kchat).say(msg)
    end
end

local function kxprint(line, s)
    local w, h = kgpu.getResolution()
    local cl = line
    for k in s:gmatch(".-\n") do
        k = k:sub(1, -2):gsub("\t", "  ")
        kgpu.fill(1, cl, w, cl, " ")
        kgpu.set(1, cl, k)
        cl = cl + 1
    end
end

function kpanic(msg)
    local w,h = kgpu.getResolution()
    kgpu.fill(1, 1, w, h, ' ')
    kgpu.set(1, 1, "-- Kernel Panic / BSOD --")
    if type(msg) == "function" then
        pcall(msg, kgpu)
    else
        kgpu.set(1, 2, msg)
        kxprint(3, debug.traceback())
    end
    while true do computer.pullSignal() end
end

function kloadfile(filename, env)
    local f, err = kfs.open(filename, "r")
    if not f then
        return false, err
    end
    local code = ""
    while true do
        local tmp = kfs.read(f, 2048)
        if not tmp then break else code = code .. tmp end
    end
    kfs.close(f)
    return load(code, filename, "t", env)
end

function kloadlib(libname, env)
    local fn, msg = kloadfile(string.format("core/%s.lua", libname), env)
    if fn then
        local ret = table.pack(pcall(fn))
        if ret[1] then
            return table.unpack(ret, 2)
        else
            kpanic(string.format("kloadlib `%s`: %s", libname, ret[2]))
        end
    else
        kpanic(string.format("kloadfile `%s`: %s", libname, msg))
    end
end

local sched = kloadlib("sched")
local term = kloadlib("term").create(kgpu)
term:clear()
term:print("Hello World")
for i=1, 50 do
    term:print("Nice to meet you " .. tostring(i))
    sched.ksleep(0.1)
end

sched.ksleep(3)

sched.start()

kpanic("success")

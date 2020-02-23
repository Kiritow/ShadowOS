local kfs = component.proxy(computer.getBootAddress())
local kgpu = component.proxy(component.list("gpu")())

function ktalk(msg)
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

function kreadfile(path)
    local f, err = kfs.open(path, "r")
    if not f then
        return false, err
    end
    local code = ""
    while true do
        local tmp = kfs.read(f, 2048)
        if not tmp then break else code = code .. tmp end
    end
    kfs.close(f)
    return code
end

function kloadfile(path, env)
    local code = kreadfile(path)
    return load(code, path, "t", env)
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

kloadlib("utils")
local sched, process = kloadlib("sched")
local term = kloadlib("term").create(kgpu)
term:clear()

computer.beep(1000, 1)

process.createFrom(0, "", "test", kreadfile("home/test.lua"))

sched.start()

kpanic("success")

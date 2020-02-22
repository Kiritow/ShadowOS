local term = {}

function term.create(gpu)
    local obj = {}
    obj.gpu = gpu
    obj.w, obj.h = gpu.getResolution()
    obj.x = 1
    obj.y = 1
    return setmetatable(obj, {__index = term})
end

function term.putline(self, str)
    if self.y > self.h then
        self.gpu.copy(1, 2, self.w, self.h-1, 0, -1)
        self.y = self.h
    end
    self.gpu.set(self.x, self.y, str)
    self.y = self.y + 1
    self.x = 1
end

function term.print(self, str, wrap)
    if wrap == nil then
        wrap = true
    end
    for line in str:gmatch("([^\n]+)") do
        line = line:gsub("\t", "  "):gsub("\n", "")
        self:putline(line)
    end
end

function term.clear(self)
    self.gpu.fill(1, 1, self.w, self.h, ' ')
    self.x = 1
    self.y = 1
end

return term

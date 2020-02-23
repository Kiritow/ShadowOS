print("Hello World")
while true do
    local t = table.pack(WaitEvent(-1))
    print(table.unpack(t))
end

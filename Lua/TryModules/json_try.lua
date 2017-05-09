#!/usr/bin/lua

-- luarocks install json4lua 先安装json模块
--

local json = require("json")

local json_str = '{"name":"Anna", "age":30, "level":"top"}'

local json_tab = json.decode(json_str)
for k, v in pairs(json_tab) do
    print(k, v)
end

local tab = { "lover", 123, name = "XiaoXian", age = 30, level = "sub-top"}

io.write(json.encode(tab) .. "\n")

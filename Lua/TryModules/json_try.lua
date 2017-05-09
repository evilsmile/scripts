#!/usr/bin/lua

-- luarocks install json4lua 先安装json模块
--

local json = require("json")

-- json解析
local json_str = [[
        {
            "name":"Anna",
            "age":30,
            "level":"top",
            "places":["hill", "river"],
            "info":{
                "born":"ShiCheng",
                "college":"GanzhouLigong"
            }
        }
        ]]

local json_tab = json.decode(json_str)
for k, v in pairs(json_tab) do
    if (type(v) == "table") then
        io.write(string.format("%s:", k ))
        for k2, v2 in pairs(v) do
           io.write(k2 .. " : " .. v2 .. ' ')
        end
        io.write('\n')
    else
         print(k, v)
    end
end

-- json编码

local tab = { 
       name = "XiaoXian", 
       info = {        -- 对象
            born = "FuJian", 
            college="Nvzi"
        },
        sign = {123, 34},   -- 数组
        age = 30,
        level = "sub-top"
    }

io.write(json.encode(tab) .. "\n")

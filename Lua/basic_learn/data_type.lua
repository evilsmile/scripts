#!/usr/bin/lua

--[[
lua中的8个基本类型为 nil boolean number thread userdata table function string
--]]
print(type("X"))
print(type(1.1))
print(type(true))
print(type(tonumber))
print(type(nil))

tab1 = {key1 = "val1", key2 = "val2"}
for k, v in pairs(tab1) do
    print(k.." - "..v)
end

--[[
 对于全局变量和table, nil 还有一个作用就是"删除". 给它们一个nil值等同于把它们删除
--]]
tab1.key1 = nil
for k, v in pairs(tab1) do
    print(k.." - "..v)
end

--[[
-- false 和 nil 都是假
--]]
if false or nil then
    print("one of false and nil is true")
else
    print("both false!")
end

--[[
-- 默认只有一种 number 类型 -- double (双精度) 
--]]
print(2)
print(2.2)
print(2e1)
print(0.2e-1)
print(7234234.23e-3)

-- [[
-- 可以用 [[]] 来表示一块字符串
-- ]]
html = [[
<html>
<head>
</head>
<body>
 <a href="#">
</body>
</html>
]]

print(html)


--[[
-- 对数字字符串进行算术操作时，lua会尝试把它转化为数字
-- 字符串使用" .. "进行连接
-- 使用"#"计算字符串长度
--]]
print("2" + 6)
print(123 .. 234)
print(#"123445")

--[[
-- table:
-- 可以用最简单的{}来创建空表，也可以直接初始化表
-- table其实是一个关联数组，数组的索引可以是数字或者是字符串
-- Lua的表默认初始索引一般从1开始
--]]
local table1={}
local table2={"one", "two", "three"}
local table3={name="lan", sex="femail", age= 30}
for k, v in pairs(table1) do
    print(k .. " - " .. v)
end
for k, v in pairs(table2) do
    print(k .. " - " .. v)
end
for k, v in pairs(table3) do
    print(k .. " - " .. v)
end


--[[
-- 函数可以存在变量里
-- 函数可以通过匿名的方式传递
--]]
function factoria1(n)
    if n == 0 then
        return 1
    else
        return n * factoria1(n-1)
    end
end
print(factoria1(5))
fact2 = factoria1
print(fact2(6))

function anonymous(tab, fn)
    for k, v in pairs(tab) do
        print(fn(k, v))
    end
end
anonymous(table3, function(key, value) 
    return key .. " = " .. value
end)


--[[
-- 在 Lua 里，最主要的线程是协同程序（coroutine）。它跟线程（thread）差不多，拥有自己独立的栈、局部变量和指令指针，可以跟其他协同程序共享全局变量和其他大部分东西。
线程跟协程的区别：线程可以同时多个运行，而协程任意时刻只能运行一个，并且处于运行状态的协程只有被挂起（suspend）时才会暂停。
--]]
--
--[[
--userdata 是一种用户自定义数据，用于表示一种由应用程序或 C/C++ 语言库所创建的类型，可以将任意 C/C++ 的任意数据类型的数据（通常是 struct 和 指针）存储到 Lua 变量中调用。
--]]

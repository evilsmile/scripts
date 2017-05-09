#!/usr/bin/lua

--[[
-- 变量在使用前，必须在代码中进行声明，即创建该变量
-- 编译程序执行代码之前编译器需要知道如何给语句变量开辟存储区，用于存储变量的值
-- Lua变量有三种类型：全局变量、局部变量、表中的域
-- Lua中的变量全部是全局变量，哪怕是语句块或是函数里，除非用local显示声明为局部变量
-- 局部变量的作用域为从声明位置开始到所在语句块结束
-- 变量的默认值均为nil
--]]

global_var = "global var"
local local_var = "local var"

function joke()
    global_var = "global var reset"
    local local_var = "local var reset"
end

joke()
print(global_var, local_var)

--[[ -- 同时对多个变量赋值 --]]
v1, v2 = "v1", 2222

-- 遇到赋值语句lua会先计算右边的所有值然后再执行赋值操作，所以可这样进行交换变量的值
x, y = y, x

-- 变量多于值的个数，则补足nil
a, b, c = 0, 1
print(a,b,c)
-- 值太多则忽略后面的值
a, b, c = 5, 6, 7, 8
print(a, b, c)

function ret_2()
    return "one", "two"
end

-- 函数返回两个值，第一个赋给str1, 第二个赋值给str2
str1, str2 = ret_2()
print(str1, str2)

-- 对table的索引使用方括号，也可以用"."
site={}
site["Key"] = "www.bai.com"
print(site["Key"])
print(site.Key)

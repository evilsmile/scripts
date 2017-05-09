#!/usr/bin/lua

-- 以下都属于块
if x then
    stuff()
end

for i = 1, 10 do
    local x = "foo"
end

function stuff()
    --
end

do
    local x = 3
    local y = 4
end

-- Lua使用词法作用域，每个块都有自己的作用域
x = 5                            -- 全局
function foo()
    local x = 6                  -- 局部
    print(x)             -- 6

    if x == 6 then
        local x = 7             
        y = 10                   -- 全局
        print(x)          -- 7
    end

    print (x, y)          -- 6, 10

    do
        x = 3
        print(x)          -- 3
    end

    print(x)              -- 3
end

foo()
print(x, y)               -- 5, 10

--- 块可以写在一行里
function foo2(x) return x * 5 end
do foo2(3) end
if x then print(x) end

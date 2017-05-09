#!/usr/local/bin/lua

-- 实现多重继承的关键还是在__index的用法上。
-- 元表的__index可以是一个表，也可以是一个函数
-- 当表a调用自身所没有的方法或者属性时，lua会通过getmetatable得到a的元表
-- 而该元表的__index是个表时，则lua会在这个表中查找，如果找到则调用
-- 而如果该元表的__index是个函数，该函数的实参依次为正在调用方法、属性的表a以及表a中缺失的方法名或属性(键值key)，lua会将这两个实参传入进去并调用__index指向的函数

local function search(k, t) 
    for i, v in ipairs(t) do
        if v[k] then
            return v[k]
        end
    end

    return nil
end

function createMultiInheritClass(...)
    local c = {}
    local parents = {...}

    setmetatable(c, {__index = function(t, k)
            return search(k, parents)
        end 
        })

    function c:new(o)
        o = o or {}
        setmetatable(o, {__index = c})
        return o
    end

    return c
end

Human = {name = "Human"}
function Human:eat()
    print("human eat")
end

Programmer = {name = "coder"}
function Programmer:doPrograming()
    print("do coding")
end

FemaleProgrammer = createMultiInheritClass(Human, Programmer)
local femaleCoder = FemaleProgrammer:new({sex = "femail"})
femaleCoder:eat()
femaleCoder:doPrograming()

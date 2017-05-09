#!/usr/bin/lua

--[[
-- Lua 编程语言函数定义格式如下：
-- optional_function_scope function function_name( argument1, argument2, argument3..., argumentn)
    --  function_body
    --      return result_params_comma_separated
    --      end
    --      解析：
    --      optional_function_scope
    --      : 该参数是可选的制定函数是全局函数还是局部函数，未设置该参数默认为全局函数，如果你需要设置函数为局部函数需要使用关键字 local。
    --      function_name:
    --      指宝函数名称。
    --      argument1, argument2, argument3..., argumentn:
    --      函数参数，多个参数以逗号隔开，函数也可以不带参数。
    --      function_body:
    --      函数体，函数中需要执行的代码语句块。
    --      result_params_comma_separated:
    --      函数返回值，Lua语言函数可以返回多个值，每个值以逗号隔开
--]]

myprint = function(param)
     print("This is my print: ", param)
    end

function add(num1, num2, print_fn)
    result = num1 + num2
    print_fn(result)
end

myprint(10)
add(2, 5, myprint)

-- 多返回值 --
-- find 返回匹配串的开始和结束的下标
s, e = string.find("She is lan", "is")
print(s, e)

function max(a)
    local max_indx = 1
    local max_value = a[max_indx]

    for i, val in ipairs(a) do
        if val > max_value then
            max_value = val
            max_indx = i
        end
    end
    return max_indx, max_value
end

print(max({8,10,32,44,21,2}))

-- 可变参数 --
function average(...)
    result = 0
    -- 函数参数放在arg表中， #arg表示会改主参数的个数
    local arg = {...}
    for i, v in ipairs(arg) do
        result = result + v
    end
    print("total: " .. #arg)
    return result/#arg
end
print("average: ", average(10, 9, 8, 2, 1))


-- note for a object to work, it needs a closure(inner function with an
-- upvalue ( a local value from a higher scope)
-- the more closures made, the slower the program would run
function mg1(n)
    local function get()
        return n
    end
    local function inc(m)
        n = n + m
    end
    return {get = get, inc = inc}
end
object = mg1(50)
print(object["get"]())
object.inc(30)
print(object.get())

-----------
do
    local function get(o)
        return o.one
    end
    local function inc(self, two)
        self.one = self.one + two
    end
    function mg3(one)
        return {one = one, get = get, inc = inc}
    end
end
a = mg3(55)
print(a:get())
a.inc(a, 4)
print(a:get())


-- 参数默认值
-- Lua不直接支持参数默认值，但是如果一个函数调用的时候没有指明参数，那么该参数使用缺省值nil
function func(x, y, z)
    if not y then y = 0 end
    -- 用or更简短
    z = z or 1
end

-- 只有一个table参数的函数可以省去括号
function foo(t)
    return t[1] * t.x + t[2] * t.y
end
print(foo{3, 4, x = 5, y = 6}) -- 39

-- 参数数目不定时
function sum(...)
    local ret = 0
    for i, v in ipairs{...} do ret = ret + v end
    return ret
end
print(sum(3, 5, 8, 9))

-- 把参数置于table{...}中，还可以通过select函数访问
function sum2(...)
    local ret = 0
    for i = 1, select("#", ...) do ret = ret + select(i, ...) end
    return ret
end
print(sum2(8, 5, 8, 9))


-- table 内的函数可以通过下面的方式调用
t = {}
function t:func(x, y)
    self.x = x
    self.y = y
end
t:func(10, 1)
print(t.x)

-- 等价于如下
function t.func2(self, x, y)
    self.x = x
    self.y = y
end
t.func2(t, 20, 3)
print(t.y)

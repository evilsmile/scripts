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

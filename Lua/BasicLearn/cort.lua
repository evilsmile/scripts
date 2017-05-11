#!/usr/local/bin/lua

function foo(a)
    print("foo", a)
    return coroutine.yield(2*a)
end

co = coroutine.create(function (a, b)
        print("co-body1", a, b)
        local r = foo(a+1)
        print("co-body2", r)
        local r, s = coroutine.yield(a+b, a-b)
        print("co-body3", r, s)
        return b, "end"
    end)

-- 从foo中的yield返回
-- co-body1 1 10
-- foo 2
-- main1  true 4 
print("main1", coroutine.resume(co, 1, 10))  

-- 从foo返回并继承执行，到12行处的yield返回，a+b a-b
-- co-body2 r1
-- main2 true 11 -9
print("main2", coroutine.resume(co, "r1"))

-- 从12行继承执行，此时
-- co-body3 r2 x
-- main3 true 10 end
print("main3", coroutine.resume(co, "r2", "x"))

-- 协程已死
-- main4	false	cannot resume dead coroutine
print("main4", coroutine.resume(co, "x", "y"))

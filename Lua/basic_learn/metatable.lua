#!/usr/bin/lua

-- 在Lua table中我们可以访问对应 的key来得到value值，但是却无法对两个table进行操作
-- 因此lua提供了过犹不及(Metatable)， 允许我们改变table的行为，每个行为关联了对应的元方法
-- 例如，使用元表我们可以定义lua如何计算两个table的相加操作a+b
-- 当Lua试图对两个表进行相加时，先检查两者之一是否有元素，之后检查是否有一个叫"__add"的字段，若找到，则调用对应 的值
-- 有两个很重要的函数来处理元表：
-- + setmetatable(table, metatable): 对指定table设置元表(metatable)，如果元表中存在__metatable键值，setmetatable会失败
-- + getmetatable(table): 返回对象的元表
--

mytable = {}
mymetable = {}
setmetatable(mytable, mymetable)
--或者直接写成
mytable = setmetatable({}, {})

print(getmetatable(mytable))

-- __index元方法
-- 这是metatable最常用的键
-- 当你通过键来访问table时如果这个键没有值，那么lua就会寻找该table的metatable中的__index键。如果__index包含一个表格，Lua会在表格中查找相应的键

other = { foo = 3 }
t = setmetatable({}, {__index = other})
print(t.foo)   -- 3
print(t.bar)   -- nil

-- 如果__index包含一个函数的话，Lua就会调用那个函数，table和键会作为参数传递给函数
-- __index元方法查看表中的元素是否存在，如果不存在，返回结果为nil; 如果存在则由__index返回结果

mytable = setmetatable({key1= "value1"}, {
    __index = function(mytable, key)
        if key == "key2" then
            return "metatablevalue"
        else
            return nil
        end
    end
})

-- 解析：
-- mytable表赋值为{key1 = "value1"}
-- mytable设置了元表，元方法为__index
-- 在mytable中查找key1， 如果找到，返回该元素，找不到则继续
-- 在mytable表中查找key2，如果找到则返回metatablevalue，找不到则继续
-- 判断元表有没有__index方法，如果__index是一个函数，则调用该函数
-- 元方法中查看是否传入"key2"键的参数，如果传入"key2"则返回 metatablevalue，否则返回 mytable对应的键值
print(mytable.key1, mytable.key2)

-- 以上也可以写成
mytable = setmetatable({key1 = "value1"}, {__index = {key2 = "metatablevalue"}})
print(mytable.key1, mytable.key2)


-- __newindex元方法
-- __newindex 元方法用来对表更新， __index则用来对表访问
-- 当你给表的一个缺少的索引赋值，解释器就会查找__newindex元方法: 如果存在则调用这个函数而不进行赋值
mymetable = {}
mytable = setmetatable({key1 = "value1"}, { __newindex = mymetable})
print(mytable.key1)

mytable.newkey = "Newvalue2"
print(mytable.newkey, mymetable.newkey)
mytable.key1 = "NewValue1"
print(mytable.key1, mymetable.key1)

-- 为表添加操作符
function table_maxn(t)
    local mn = 0
    for k, v in pairs(t) do
        if mn < k then
            mn = k
        end
    end
    return mn
end

mytable = setmetatable({1, 2, 3}, {
    __add = function(mytable, newtable)
        for i = 1, table_maxn(newtable) do
            table.insert(mytable, table_maxn(mytable)+1, newtable[i])
        end
        return mytable
    end
})

secondtable = {4, 5, 6}
mytable = mytable + secondtable
for k, v in ipairs(mytable) do
    print(k, v)
end

-- _add键包含在元表中，并进行相加操作。 表中对应的操作列表如下：
-- __add => '+'
-- __sub => '-'
-- __mul => '*'
-- __div => '/'
-- __mod => '%'
-- __unm => '-'
-- __concat => '...'
-- __eq => '=='
-- __lt => '<'
-- __le => '<='

-- __call元方法
-- __call元方法在Lua调用一个值时调用
mytable = setmetatable({10}, {
    __call = function(mytable, newtable) 
        sum = 0
        for i = 1, table_maxn(mytable) do
            sum = sum + mytable[i]
        end
        for i = 1, table_maxn(newtable) do
            sum = sum + newtable[i]
        end
        return sum
    end
})
newtable = {10, 20, 30}
print(mytable(newtable)) -- 70


-- __tostring元方法
-- __tostring元方法用于修改表的输出行为
mytable = setmetatable({10, 20, 30}, {
    __tostring = function(mytable)
        sum = 0
        for k, v in pairs(mytable) do
            sum = sum + v
        end
        return "Sum of elements in table is " .. sum
    end
})
print(mytable)


------------------- 从本文中我们可以知道元表可以很好地简化我们的代码功能，所以了解Lua的元表，可以让我们写出更加优秀的Lua代码

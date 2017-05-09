#!/usr/bin/lua

-- Lua中的面向对象

CTest = { cnt = 0 }
function CTest:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function CTest.add(self, v)
    self.cnt = self.cnt + v
end

function CTest:pprint()
    print("CTest...")
end

c1 = CTest
c1.add(c1, 10)
print(c1.cnt)
c1:add(99)
print(c1.cnt)
c1:pprint()

-- 一般使用this或self来指向当前对象。
-- lua中，可以用冒号语法省略self参数的传递。
-- 如上面的c1:pprint()等价于c1.pprint(self)


------- 继承 -------
-- DTest继承自CTest，重写了pprint()
DTest = CTest:new()
function DTest:pprint()
    print("DTest..")
end
d1 = DTest:new{cnt = 2009}
print(d1.cnt)
d1.pprint()

------ 封装 -----
function ETest(initCnt)
    local self = {cnt = initCnt}
    local add = function(v)
        self.cnt = self.cnt + v
    end
    local pprint = function() 
        print("ETest..")
    end
    return {
        add = add,
        pprint = pprint
    }
end
e1 = ETest(0)
e1.pprint()
print(e1.cnt)  -- 访问不了cnt，相当于是私有变量

----------------- Another TRY ----------
-- 1. 类
-- 声明，这里声明了类名还有属性，并且给出了属性的初始值
Class = {x = 0, y = 0}

-- 这句是重定义元表的索引，就是说有了这句，这个才是一个类
Class.__index = Class

function Class:new(x, y)
    local self = {}
    setmetatable(self, Class)
    self.x = x
    self.y = y
    return self
end

function Class:test()
    print(self.x, self.y)
end

function Class:plus()
    self.x = self.x + 1
    self.y = self.y + 1
end

-- 将要多态的函数
function Class:gto()
    return 100
end

function Class:gio()
    return self:gto() * 2
end

a = Class:new(10, 2)
a:test()
b = Class:new(11, 23)
b:test()

-- 2. 继承
-- 声明新的属性
Main = {z = 0}
-- 设置类型是Class
setmetatable(Main, Class)
-- 还是和类定义一样，表索引设定为自身
Main.__index = Main
-- 新的构造体
function Main:new(x, y, z)
    -- 初始化对象本身 
    local self = {}
    -- 将对象自身设定为父类, 这个语句相当于其他语言的super
    self = Class:new(x, y)
    -- 将对象自身元表设定为Main类
    setmetatable(self, Main)
    self.z = z
    return self
end

-- 定义新方法
function Main:go()
    self.x = self.x + 10
end
 
-- 重定义父类方法
function Main:test()
    print(self.x, self.y, self.z)
end

function Main:gto()
    return 50
end

c = Main:new(20, 40, 100)
c:test()
c:go()
c:plus()
c:test()

Super = {}
Super.__index = Super
setmetatable(Super, Main)
function Super:new(x, y, z)
    local self = {}
    setmetatable(self, Super)
    return self
end

function Super:gto()
    return 2344
end
s = Super:new(30, 22, 23)

-- 3. 多态
print(a:gio())
print(c:gio())
print(s:gio())

--- 调用Lua类的属性请使用点号，而调用其方法请使用冒号！
-- 总结一下，实现类的关键是__index赋值和setmetatable()
-- 当你通过索引来访问表, 不管它是什么(例如t[4], t.foo, 和t["foo"]), 以及并没有分配索引的值时，
-- Lua 会先在查找已有的索引，接着查找表的metatable里（如果它有）查找__index 索引。 如果__index 包含了表, Lua会在__index包含的表里查找索引。

#!/usr/bin/lua

-- 模块类似于整体上封装库，从Lua5.1开始，Lua加入了标准的模块管理机制，可以把一些公用的代码放在一个文件里，以API接口的形式在其他地方调用，有利于代码的重用和降低代码耦合度。
-- Lua的模块是由变量、函数等已知元素组成的table，因此创建一个模块很简单，就是创建一个table，然后把需要导出的常量、函数放入其中，最后返回这个table就行。
--
-- Lua提供了一个名为require的函数用于加载模块。要加载一个模块，只需要简单地调用就可以了。
-- 执行require后会返回一个由模块常量或函数组成的table，并且还会定义一个包含该table的全局变量

require("module_to_import")

print(module.const)
print(module.func3())

-- 加载机制
-- 对于自定义的模块，模块文件不是放在哪个文件目录都行，函数require有它自己的文件加载策略，它会尝试从Lua文件或C程序中加载模块
-- require用于搜索Lua文件的路径是存放在全局变量package.path中，当Lua启动后，会以环境变量LUA_PATH的值 来初始化这个变量。如果没找到，则使用一个编译时定义的默认路径来初始化。
-- 当然，可以自己设置 LUA_PATH
-- export LUA_PATH="~/lua/?.lua;;"
-- 文件路径以";"号分隔，最后的2个";;"表示新加的路径后面加上原来的默认路径
--

-- C包
-- Lua和C是很容易结合的，使用C为Lua写包
-- 与Lua中写包不同，C包在使用以前必须首先加载并连接，在大多数系统中最容易的实现方式是通过动态链接库机制 
-- Lua在一个叫loadlib的函数内提供了所有的动态链接的功能。这个函数有两个参数：库的绝对路径和初始化函数，所以典型的调用例子如下：
local path = "/usr/local/lua/lib/libluasocket.so"
--local f = loadlib(path, "luaopen_socket")

-- loadlib函数加载指定的库并且连接到lua，然而它并不打开库（也就是说没有调用初始化函数），反之他返回初始化函数作为Lua的一个函数，这样我们就可以直接在Lua中调用它
-- 如果加载动态库或者查找初始化函数时出错 ，loadlib将返回nil和错误信息，我们可修改前面一段代码，使其检测错误然后调用初始化函数
local f = assert(loadlib(path, "luaopen_socket"))
f()

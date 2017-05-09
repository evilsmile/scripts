#!/usr/local/bin/lua

-- Lua IO库用于读取和处理文件。分为简单模式（和C一样）、完全模式。
-- + 简单模式：拥有一个当前输入文件和一个当前输出文件，并且提供针对这些文件相关的操作
-- + 完全模式：使用外部的文件句柄来实现。 它以一种面对对象的形式，将所有的文件操作定义为文件句柄的方法
-- 简单模式在做一些简单的文件操作时较为合适。但是在进行一些高级的文件操作时，简单模式就显得力不从心。如同时取多个文件这样的操作，使用完全模式更为合适。
-- 打开文件操作语句如下：
-- file = io.open(filename [, mode])
-- mode的值有:r | w | a | r+ |  w+ | a+ | b | +表示对文件既可读也可以写

--简单模式：

-- 以只读方式打开
file = io.open("data.txt", "r")

-- 设置默认输入文件为 test.lua
io.input(file)

-- read()可带如下参数:
-- "*n": 读取一个数字并返回。如file.read("*n")
-- "*a": 读取整个文件。如file.read("*a")
-- "*l": 默认的读取行为，读取下一行。在文件尾(EOF)返回处返回nil。如file.read("*a")
-- number: 返回一个指定字符个数的字符串，或在EOF处返回nil。如file.read(5)
-- 输入文件第一行
print(io.read())
-- 读入数字
print(io.read("*n"))
-- 读入7个字符
print(io.read(7))
-- 读入剩下的内容
print(io.read("*a"))

io.close()

-- 以附加的方式打开
file = io.open("data.txt", "a")
-- 设置默认输出文件
io.output(file)

--io.write("-- GOD comes to see you --")
io.close()

-- 其它的io方法还有：
-- io.tmpfile(): 返回一个临时文件句柄，该文件以更新模式打开，程序结束时自动删除
tmpf=io.tmpfile()            
-- io.type(file): 检测obj是否一个可用的文件句柄
print(io.type(tmpf))            
-- io.lines(optional file name): 返回一个迭代函数，每次调用将获得文件中的一行内容，当到文件尾时，将返回nil，但不关闭文件
print("------ read by lines -----")                                 
for line in io.lines("data.txt") do
    print(line)
end

print("\n---- complete mode ----\n")

-- 完全模式
-- 通常我们需要在同一时间 处理多个文件。我们需要使用file:function_name来代替io.function_name方法。
file = io.open("data.txt", "r")
-- read参数与简单模式一致
print(file:read())

file:close()

file = io.open("data.txt", "a")
--file:write("-- complete --\n")
file:close()

file = io.open("data.txt", "r")
-- 设置和获取当前文件位置，成功则返回最终文件位置（按字节），失败则返回nil加错误信息。参数whence可能是："set", "cur", "end"
-- file:seek(optional whence, optional offset)
-- offset默认为0
file:seek("end", -25)
print(file:read("*a"))
file:close()

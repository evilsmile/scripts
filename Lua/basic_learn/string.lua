#!/usr/bin/lua

-- 字符串是由数字、字母、下划线组成的
-- Lua中字符串可以使用以下三种方式：
-- + 单引号  + 双引号  + [[]]

string1 = "DoubleQuotationString"
string2 = 'SingleQuotationString'
string3 = [[DoubleBracketString]]

print(string1)
print(string2)
print(string3)

-- functions of string

-- upper
print(string.upper(string1))

-- lower
print(string.lower(string2))

-- gsub(mainString, findString, replaceString, [num])
print(string.gsub(string3, "D", "W"))

-- find(str, substr, [init, [end]]
-- 在一个指定的目标字符串中搜索指定的内容（init为开始搜索的位置), 返回其具体位置
print(string.find(string3, "Bra"))

-- reverse(argument)
print(string.reverse(string3))

-- format(...)
print(string.format("Tell me what happend. %s", "I don't know too"))

-- char(argument)
-- 将整形数字转成字符并连接
print(string.char(97, 98, 99, 100))

-- byte(argument)
-- 转换字符为整数(可以指定某个字符，默认第一个字符)
print(string.byte("ABCD", 3))
print(string.byte("ABCD", -2))
print(string.byte("ABCD"))

-- len(arg)
-- 计算字符串长度
print(string.len("Happy new world!"))

-- rep(string, n)
-- 返回字符串的n个拷贝
print(string.rep("do you miss me?\n", 20))

-- ..
-- 链接两个字符串
print("part 1" .. "  " .. " with part 2")

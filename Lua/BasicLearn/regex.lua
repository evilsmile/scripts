#!/usr/local/bin/lua

-- 在string库中功能最强大的函数是: string.find(字符串查找), string.gsub(全局字符替换) 和 string.gfind(全局字符串查找). 这些函数都是基于模式匹配的。
-- 出于程序大小方面的考虑，Lua并未实现POSIX所规范的所有功能。

function pp(t)
    for k, v in pairs(t) do
        print(k, '->', '|'..v..'|')
    end
end

s = "!!!hello!world!!!YOU!!!"
i, j = string.find(s, "ello") 
print(i, j)                              -- 2 6
print(string.sub(s, i, j))               -- ello
print(string.find(s, "lll"))             -- nil

local t = {}
local start = 1
local kw = "!"
while true do
    i, _ = string.find(s, kw, start)   -- find next word
    -- 忽略连续的空格
    if i ~= start then
        -- 插入最后一个
        if i == nil then 
            -- 避免插入最后一个关键字
            if string.sub(s, -1) ~= kw then
                table.insert(t, string.sub(s, start))
            end
            break 
        else
            table.insert(t, string.sub(s, start, i-1))
        end
    end
    start = i + 1
end

pp(t)


-- gsub的最后一个参数可选，用来限制替换范围
s = string.gsub("Lua is cute cute", "cute", "greate", 2)
print(s)


-- 使用模式串
s = "Deadline is 30/05/1999, %firm"
date = "%d%d/%d%d/%d%d%d%w%A%A%%"
print(string.sub(s, string.find(s, date))) -- 30/05/1999

-- Lua支持的所有字符类
-- . 任意字符
-- %a 字母
-- %c 控制字符
-- %d 数字
-- %l 小写字母
-- %p 标点字符
-- %s 空白字符
-- %u 大写字母
-- %w 字母和数字
-- %x 十六进制
-- %z 代表0的字符

-- 上面字符类的大写形式表示小写所代表的集合的补集. 如果'%A'表示非字母的字符

print(string.gsub("hello, up-down!", "%A", ".")) -- hello..up.down. 4 (4表示替换的次数)

-- Lua中的特殊字符如下:
-- ( ) . % + - * ? [ ^ $
-- '%' 用作特殊字符的转义字符，因此'%.'匹配点,'%%'匹配字符'%'。转义字符不仅可以用来转义特殊字符，还可以用于所有的非字母的字符。

-- 统计文本中元音字母出现的次数
-- 用'[]'创建字符集
_, nvow = string.gsub("abcdeeAAIL", "[AEIOUaeiou]", "")
print(nvow)

-- 可以使用修饰符来修饰模式增强表达能力
-- Lua中的模式修饰符有四个:
-- + 匹配前一个字符1次或多次(总是进行最长匹配)
-- * 匹配前一个字符0次或多次(最长匹配)
-- - 匹配前一个字符0次或多次(最短匹配)
-- ? 匹配前一个字符0次或1次

print(string.gsub("one and tow and three", "%a+", "word"))
-- 每个单词的替换
print(string.gsub("one and tow and three", "%w+", "word"))
-- 每个字母的替换
print(string.gsub("one and tow and three", "%w-", "word"))

test = "int x; int y;"
print(string.gsub(test, "(int)", "<comment>"))

-- ‘%b'用来匹配对称的字符，常写为'%bxy', x和y是任意两个不同的字符; x作为匹配的开始，y作为匹配的结束。如'%b()'匹配以'('开始，以')'结束的字符串。常用的模式有: '%b()', '%b[]', '%b%{%}'和'%b<>'
print(string.gsub("a (enclosed {in} parentheses) line", "%b{}", ""))

-- 捕获
-- 捕获是指这样一种机制：可以使用模式串的一部分匹配目标串的一部分。将你shhn捕获的模式用圆括号括起来，就指定了一个捕获。

-- 在string.find使用捕获的时候，函数会返回捕获的值作为额外的结果，这常被用来将一个目标串拆分成多个：
pair = "name = Anna"
_, _, key, value = string.find(pair, "(%a+)%s*=%s*(%a+)")
print(key, value)
date = "17/7/1990"
_, _, d, m, y = string.find(date, "(%d+)/(%d+)/(%d+)")
print(d, m, y)

-- 可以在模式中使用向前引用，'%d'(d代表1-9的数字)表示捕获第d个捕获的拷贝
s = [[ then he said: "its' all right"!]]
-- 
a, b, c, quotedPart = string.find(s, "([\"'])(.*)%1")
print(quotedPart)
print(c)

-- 捕获值也可以应用在函数gsub中。与其他模式一样，gsub的替换串可以包含'%d'，当替换发生时他被转换为对应的捕获值。
-- 将字母复制并用-连接
print(string.gsub("Hello Lua!", "(%a)", "%1-%1"))

-- 替换\command{sometext} 为<command>sometext<command>
s = [[ the \quote{task} is to \em{change} that ]]
print(string.gsub(s, "\\(%a+)%{(.-)%}", "<%1>%2<%1>"))

function trim(s)
    -- 使用额外的圆括号丢弃多余的结果
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end
print('|'.. trim('  1234   ') .. '|')


-- 捕获值的一个强大功能，就是可以使用一个函数作为string.gsub的第三个参数调用gsub。
-- 在这种情况下，string.gsub每次发现一个匹配的时候就会调用给定的作为参数的函数，捕获值可以作为被调用的这个函数的参数，而这个函数的返回值作为gsub的替换串。

-- 将一个字符串中全局变量$varname出现的地方替换为变量varname的值
function expand(s)
    s = string.gsub(s, "%$(%w+)", function(n)
            return tostring(_G[n])
        end)
    return s
end

name = "LUA"; status = 666
print(expand("$name is $status, isn't it"))

-- 使用loadstring来计算一段文本内$后面跟着一对方括号内的表达式的值
s = "sin(3) = $[math.sin(3)]; 2^5 = $[2^5]"

print((string.gsub(s, "$%[(.-)%]", function (m) 
                x = "return " .. m
                local f = load(x)
                return f()
                end)))

-- 使用正则表达式找单词真是简单!
s = "   Count these words!   "
words = {}
string.gsub(s, "%a+", function (m) 
        table.insert(words, m)
        end)
pp(words)

-- URL编码简单转换
function unescape_url(s)
    s = string.gsub(s, "+", " ")
    s = string.gsub(s, "%%(%x%x)", function(h)
            return string.char(tonumber(h, 16))
        end)
    return s
end
print(unescape_url('a%2Bb+%3D+c'))

function escape_url(s)
    s = string.gsub(s, "([&=+%c])", function(c)
            -- 将字符转换为16进制
            return string.format("%%%02X", string.byte(c))
        end)
    s = string.gsub(s, " ", "+")
    return s
end
function encode_url(t)
    local s = ""
    for k, v in pairs(t) do
        s = s .. "&" .. escape_url(k) .. "=" .. escape_url(v)
    end
    return string.sub(s, 2)  -- remove first '&'
end
t = {name = "al", query = "a+b = c", q = "yes or no"}
print(encode_url(t))


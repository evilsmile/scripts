#!/usr/bin/lua

-- Lua数组
-- 就是相同数据类型的元素按一定顺序排列的集合，可以是一维数组和多维数组
-- Lua数组的索引键值可以用整数表示，数组的大小不是固定的

-- Lua的索引从1开始
array = {"Lua", "Tutorial"}

-- 指定从0开始，第一个为0
for i = 0, 2 do
    print(array[i])
end

-- 可以以负数为数组索引值
array = {}
for i = -2, 2 do
    array[i] = i * 2
end
for i = -2, 2 do
    print(array[i])
end

-- 多维数组
array = {}
for i = 1, 3 do
    array[i] = {}
    for j = 1, 3 do
        array[i][j] = i * j
    end
end

for i = 1, 3 do
    for j = 1, 3 do
        print(array[i][j])
    end
end

#!/usr//bin/lua

-- table是Lua的一种数据结构用来帮助我们创建不同的数据类型，如数字、字典等
-- Lua table 使用关联型数组，你可以用任意类型的值来作数组的索引，但不能是nil
-- Lua table是不固定大小的，你可根据自己需要进行扩容
-- Lua也是通过table来解决模块(module)、包(package)、对象(Object)的。

-- table表的构造 
-- 构造器是创建和初始化表的表达式。表是Lua特有的功能强大的东西。 最简单的构造函数是{}，创建一个空表。也可以直接初始化数组
mytable={}
mytable[1] = "Lua"
mytable["Two"] = "Again lua"
mytable["delete"] = "This will be deleted!"
-- 移除引用 
mytable["delete"] = nil
mytable.sign = "123123128283lwsjlsdf3"

for k, v in pairs(mytable)
do
    print(k, v)
end

-- 当我们为table a并设置元素，然后将a赋值给b，则a和b指向同一个内存。
-- 如果a设置为nil，则b同样能访问table的元素。如果没有指定的变量指向a，Lua的垃圾回收机制会清理相对应的内存

mytable={}
mytable[1] = "Lua"
mytable["wow"] = "Before_Modify"
print("mytable[1] is: ", mytable[1])
print("mytable[\"wow\"] is: ", mytable["wow"])

-- 指向同一个table
alternatetable = mytable

print("alternatetable[1] is: ", alternatetable[1])
print("alternatetable[\"wow\"] is: ", alternatetable["wow"])

alternatetable["wow"] = "After_Modify"
print("mytable[\"wow\"] is: ", mytable["wow"])

-- 释放变量
alternatetable = nil
print("alternatetable is: ", alternatetable)

-- mytable仍然可以访问
print("mytable[1] is : ", mytable[1])


-- table操作的常用方法
-- table.concat(table, [, sep [, start [, end]]])
-- table表的连接。列出参数中指定table的数组部分从start到end的所有元素，元素 间以指定的分隔(sep)隔开
like_fruit = {"banana", "apple", "orange"}
print("All fruits mentioned: ", table.concat(like_fruit, ", ", 2, 3))

-- table.insert(table, [pos], value)
-- 在table的数组部分指定位置（pos）插入值为value的一个元素，pos参数可选
table.insert(like_fruit, "mango")
print("All fruits after insert: ", table.concat(like_fruit, ", ", 2, 4))

-- table.remove(table, [, pos])
-- 返回table数组部分位于pos位置的元素，其后的元素会被前移，pos参数可选。默认为长度，即从最后一个元素删起
table.remove(like_fruit)
print("All fruits after remove: ", table.concat(like_fruit, ", "))

-- table.sort(table, [, cmp])
-- 对给定的table进行升序排序
table.sort(like_fruit)
print("All fruits after sort: ", table.concat(like_fruit, ", "))

function p_tab(t)
	for k, v in pairs(t)
	do
	    print(k, "->", v)
	end
end

-- Lua用table管理全局变量，将其放入_G的table内
--p_tab(_G)

free_tab = {["name2"]="go2", name3="go3"}
free_tab.name1 = {}
p_tab(free_tab)

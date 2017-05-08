#!/usr/bin/lua

-- load driver
luasql= require "luasql.mysql"

-- create environment object
env=assert(luasql.mysql())

-- connect to data source
conn=env:connect("es", "root", "123Naruto", "127.0.0.1", 3306)

-- reset table
res = conn:execute("DROP table if exists es.jobs ")

res = assert(conn:execute[[
    CREATE TABLE es.jobs(
        com_name varchar(50),
        work_duration int comment 'how many month',
        primary key (com_name)
        ) charset=utf8
        ]])
list = {
    { com_name="Le Shua", work_duration=22, },
    { com_name="TianXiaZhiFu", work_duration=9, },
}

for i, p in pairs (list) do
    res = assert(conn:execute(string.format([[
        INSERT INTO es.jobs VALUES ('%s', %d)]], p.com_name, p.work_duration)
    ))
end

-- retrieve a cursor
cur=conn:execute("select com_name, work_duration from es.jobs")

-- print all rows
row=cur:fetch({}, "a")

while row do
    var=string.format("[%s] - %d month", row.com_name, row.work_duration)
    print(var)

    row=cur:fetch(row, "a")
end

-- close everything
cur:close()
conn:close()
env:close()

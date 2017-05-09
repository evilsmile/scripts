#!/usr/bin/lua

a=2

-- repeat...until
repeat
    print(a)
    a=a+1
until a==4

-- while
while a>0
do
    print(a)
    a=a-1
end

-- for
for a=1, 10, a+1 do
    print(a)
end

#!/bin/bash

# 斐波那契数列

function f()
{
    local n=$1
    if [ $n -eq 1 -o $n -eq 2 ]; then
        echo "1"
        return
    fi

    local n1=$((n-1))
    local n2=$((n-2))
    local s1=$(f $n1)
    local s2=$(f $n2)
    local res=$((s1+s2))

    echo $res
}

echo `f 6`

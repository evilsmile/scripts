#!/bin/bash

GREP=/usr/bin/grep
VIM=/usr/bin/vim

if [ $# != 1 ]; then
    echo "Usage: key_word"
    exit -1
fi

function show_result_with_lineno()
{
    local res=$1
    echo "$res" | awk '{printf("[%d] %s\n", NR, $0)}'
}

echo "--- TIP: Enter 'q' to exit. ---"

key_word=$1

result=$($GREP --color=never --include="*.cpp" --include="*.h" -rnw $key_word .)

line_no=$(echo "$result" | wc -l)

if [ $line_no -eq 1 ]; then
    eval $(echo "$result" | awk -F":" '{printf("file=%s;line=%s;", $1, $2)}')
    
    $VIM $file +$line

    exit 0
fi

choice=-1

while true; do
    show_result_with_lineno "$result"
    read choice
    if [ ".$choice" = ".q" ]; then
        break
    fi

    if [ $line_no -lt $choice ]; then
        echo "max line is $line_no"
        continue
    fi

    eval $(echo "$result" | awk -F":" '{if(NR=='$choice'){printf("file=%s;line=%s;", $1, $2)}}')
    
    $VIM $file +$line
done

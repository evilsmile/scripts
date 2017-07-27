#!/bin/bash

GREP=/usr/bin/grep
VIM=/usr/bin/vim

if [ $# != 1 ]; then
    echo "Usage: key_word"
    exit -1
fi

echo "--- TIP: Enter 'q' to exit. ---"

key_word=$1

result=$($GREP --color=never --include="*.cpp" --include="*.h" -rnw $key_word .)
line_no=$(echo "$result" | wc -l)

function show_result_with_lineno()
{
    echo "$result" | awk '{printf("[%d] %s\n", NR, $0)}'
}

choice=-1
while true; do
    show_result_with_lineno
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

#!/bin/bash
VIM=/usr/bin/vim

if [ $# != 1 ]; then
    echo "Usage: grep_result"
    exit -1
fi

file_and_line=$1

eval $(echo $file_and_line | awk -F":" '{printf("file=%s;line=%s;", $1, $2)}')

$VIM $file +$line

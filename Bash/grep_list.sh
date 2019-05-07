#!/bin/bash

params="$*"

result=$(grep $params)

while true; do
    echo "$result" | awk 'BEGIN{i=1;}{printf("[%d]: %s\n", i, $0); i++}'
    read choice
    if [ "$choice" == "q" ]; then
        break
    fi

    eval $(echo "$result" | awk -F":" '{if(NR=='$choice'){printf("fn=%s;line=%s", $1, $2)}}')
    echo "file: $fn line: $line"
    vim $fn +$line
done

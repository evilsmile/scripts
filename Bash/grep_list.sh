#!/bin/bash

params="$*"

result=$(grep $params)

# 去掉色彩二进制
# 先把二进制转换成文本, 替换, 再转换成二进制
nocol_result=$(echo -n "$result" | hexdump -ve '1/1 "%.2x"' | sed -e 's/1b5b6d//g' -e 's/1b5b4b//g' -e 's/1b5b33..6d//g' -e 's/1b5b30313b33316d//g' | xxd -r -p)

while true; do
    echo "$result" | awk 'BEGIN{i=1;}{printf("[%d]: %s\n", i, $0); i++}'
    read choice
    if [ "$choice" == "q" ]; then
        break
    fi

    eval $(echo "$nocol_result" | awk -F":" '{if(NR=='$choice'){printf("fn=%s;line=%s", $1, $2)}}')
    echo "file: $fn line: $line"
    vim -R $fn +$line
done

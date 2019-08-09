#!/bin/bash

sqlfile=../db.sql
awk_file=convert.awk
db_template_file=db.go.tpl
registers_temp_file=registers.go.tmp
types_temp_file=types.go.tmp
out_file=db.go

if [ $# -gt 0 ]; then
    out_file=$1
fi

# 转换 SQL 中的表和字段为 Go中的类和字段
awk -v types_go_file=$types_temp_file -v registers_go_file=$registers_temp_file -f $awk_file $sqlfile 
if [ $? -ne 0 ]; then
    echo "failed. check awk"
    exit -1
fi

if [ ! -e $registers_temp_file -o ! -e $types_temp_file ]; then
    echo "error. no '$registers_temp_file' or '$types_temp_file'"
    exit -1
fi

# 把类和注册相关代码填进模板中
go run replace_go_template.go $db_template_file $registers_temp_file $types_temp_file > $out_file
if [ $? -ne 0 ]; then
    echo "failed. check replace go"
    exit -1
fi

echo "Convert success."
rm -f $registers_temp_file $types_temp_file

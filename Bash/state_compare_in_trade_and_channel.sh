#!/bin/bash

t_db=db

mysql_exec="mysql -u "

called_by_crond=-1
function judge_crond()
{
	crond_pid=$(pidof crond)

	ppid=$(ps -p ${1:-$$} -o ppid=;)

	if [ $ppid -eq 1 ]; then
		called_by_crond=1
	else
		called_by_crond=0
	fi
}

judge_crond

if [ $called_by_crond -eq 1 ]; then
	title="${day} 通道状态与交易状态不一致？是不是交易重启了？"
else
	title=$(echo "${day} 通道状态与交易状态不一致？是不是交易重启了？" | iconv -f utf-8 -t gbk)
fi

inconsistent_order=$($mysql_exec -e "SELECT * FROM db.t_db as a LEFT JOIN db.t_channel_order as b ON a.channel_order_id=b.db_id 
		WHERE date(a.create_time)=curdate() AND a.status!=2 AND b.status=21")
if [ "x$inconsistent_order" != "x" ]; then
	export LANG=zh_CN.UTF-8 && echo "$inconsistent_order" | mail -s "XMCMBC ${title}" freedominmind@163.com
fi

inconsistent_order=$($mysql_exec -e "SELECT * FROM db.t_db as a LEFT JOIN db.t_channel_order as b ON a.channel_order_id=b.db_id 
     WHERE date(a.create_time)=curdate() AND a.status!=2 AND b.status=21")

if [ "x$inconsistent_order" != "x" ]; then
	export LANG=zh_CN.UTF-8 && echo "$inconsistent_order" | mail -s "SJS ${title}" freedominmind@163.com
fi

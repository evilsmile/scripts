# 从昨天开始到20161010为止的交易
#!/bin/bash

start_time=$(date -d '-1 day' +"%Y%m%d")
end_time=20161010


day=$start_time
interval=1

# 使用start_pids和end_pids文件进行多进程管理

>statis/start_pids
>statis/end_pids
while true; do
	
	day=$(date -d "-$interval day" +"%Y%m%d")
	if [ $day -lt $end_time ]; then
		echo "end"
		break
	fi
	echo "$day"

	interval=$((interval + 1))

	# '&' 后台运行，速度飞快
	./statis_trade_sum.sh $day &

done

while true; do
	echo "task_running...."
	start_line=$(wc -l statis/start_pids | awk '{print $1}')
	end_line=$(wc -l statis/end_pids | awk '{print $1}')
	if [ $start_line -eq $end_line ]; then
		echo "all task done."
		echo "datetime, amount, totalFee, merchantProfit, guocaiProfit" > statis/final.txt
		cat statis/20* | sort >> statis/final.txt
		break;
	fi
	sleep 1
done

rm statis/start_pids
rm statis/end_pids

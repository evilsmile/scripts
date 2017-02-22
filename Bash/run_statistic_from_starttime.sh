# 从昨天开始到20161010为止的交易
#!/bin/bash

start_time=$(date -d '-1 day' +"%Y%m%d")
end_time=20161010


day=$start_time
interval=1

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

#!/bin/bash

xsql_cmd="mysql -u "

today=$(date +"%Y-%m-%d")
sql="SELECT db_id, mcht_id FROM db.tb_t0 
		WHERE create_time>='${today} 00:03:00' 
			  AND create_time<='${today} 23:50:00' 
			  AND state in (32, 22) 
			  AND amount>1 "

failed_list=$($xsql_cmd -N -B -e "$sql")

if [ "X$failed_list" == "X" ]; then
	echo "[$(date +"%Y%m%d %H:%M:%S")] no failed order."
fi

t0_log=/tmp/t0_repay.log

#收集多次打款失败的订单号及信息
stubborn_orders_info="order_id	db_id	amount	mcht_id	daifu_respcode	daifu_respmsg	state	create_time	update_time"
need_mail=0

echo "$failed_list" | while read db_id mch_id ; do
	sql="SELECT count(*) FROM db.tb_t0_flow WHERE db_id='$db_id'"
	try_cnt=$($xsql_cmd -N -B -e "$sql")

	# 商户是否在最后一次打款失败后有更新操作
	sql="SELECT 1 FROM db.tb_merchant 
		 WHERE mch_id='${mch_id}'
		   AND update_time > 
					(SELECT create_time FROM db.tb_t0_flow 
					 WHERE mcht_id='${mch_id}' 
					 ORDER BY create_time DESC 
					 LIMIT 1)"
	mch_update_after_last_flow=$($xsql_cmd -N -B -e "$sql")

	if [ "X$mch_update_after_last_flow" == "X" ]; then
		#no update today
		if [ "X$update_time" == "X" ]; then
			#超过3次重新打款，则不再重试
			if [ $try_cnt -gt 3 ]; then
				sql="SELECT order_id,db_id,amount,mcht_id,daifu_respcode,
							daifu_respmsg,state,create_time,update_time 
							FROM db.tb_t0 WHERE db_id='$db_id'"
				stubborn_orders_info="${stubborn_orders_info}\n\n$($xsql_cmd -N -B -e "$sql")"
		
				need_mail=1
				continue
			fi
		else
			echo "update today: db_id:${db_id}"
		fi
	else
		echo "[$(date +"%Y%m%d %H:%M:%S")] db_id:${db_id} mch_id:${mch_id} update mch info. Do repay" >> $t0_log
	fi

	echo "[$(date +"%Y%m%d %H:%M:%S")] repay $db_id" >> $t0_log

	/usr/local/qrpos/tools/t0_tool repay $db_id >> /tmp/t0_repay.list
done

if [ $need_mail -eq 1 ]; then
	export LANG=zh_CN.UTF-8 && echo -e "${stubborn_orders_info}" | mail -s "今天多次打款失败的T0订单" lijing@cpp-pay.com
fi

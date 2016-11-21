#!/bin/bash

sql="mysql -u "

yestorday=$(date -d yesterday +"%Y-%m-%d")
file=/tmp/txjg_daily_deal_summary
total_file=/tmp/txjg_total_deal_summary

echo "----- [ $yestorday ] ----" > $file
$sql -N -B -e "SELECT  case channel_id 
                            WHEN 1005 then 'cmbc: ' 
							WHEN 1001 then 'wft: ' 
							WHEN 1006 then 'tfbqr: '  
							WHEN 1007 then 'pab: ' 
							WHEN 1008 then 'sj: ' 
						end,
						round(sum(amount)/100, 2), '元' 
				FROM db.tb_db 
				WHERE date(create_time)=date_sub(curdate(), interval 1 day) and status=2 
				GROUP BY channel_id" >> $file
$sql -N -B -e "SELECT  case pay_channel_name
							WHEN 'daifu_t' then 'T_D0: '
							WHEN 'daifu_xm' then 'XM_D0: '
						end, 
						round(sum(pay_amount)/100, 2), '元' 
						FROM db.tb_t0 
						WHERE date(create_time)=date_sub(curdate(), interval 1 day) and state=31
						GROUP BY pay_channel_name
			   " >> $file

$sql -N -B -e "SELECT 'T1打款: ', round(sum(amount)/1000000, 2), '元'
			   FROM db2.tb_pay_report 
			   WHERE stat=1 AND date(ret_time)=date_sub(curdate(), interval 1 day);
			  " >> $file

cat $file >> $total_file
cat $file | mail -s "天下金柜 [${yestorday}] 交易统计" freedominmind@163.com

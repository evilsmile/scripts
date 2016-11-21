#!/bin/bash

mysql_exec="mysql -u"

day=`date +%F -d '-1 day'`
if [ $# -gt 0 ]; then
  day=$1
fi

d0_file=/tmp/deal_detail/d0_${day}_list.txt
t1_file=/tmp/deal_detail/t1_order_${day}.txt

called_by_crond=-1
function judge_crond()
{
	ppid=$(ps -p ${1:-$$} -o ppid=;)

	#ppid=1? crond called!
	if [ $ppid -eq 1 ]; then
		called_by_crond=1
	else
		called_by_crond=0
	fi
}

function do_d0_summary()
{
$mysql_exec -N -B -e "select a.create_time,
	case fee_type 
			WHEN 0 then 'WX' 
			WHEN 1 then 'ZFB' 
			WHEN 2 then 'WX' 
			WHEN 3 then 'ZFB' 
			WHEN 4 then 'TFB' 
			WHEN 5 then 'TFB' 
	end as pay_type,
	b.order_id, 
	case channel_id 
			WHEN 1005 then 'xmcmbc' 
			WHEN 1001 then 'wft'  
			WHEN 1007 then 'xmpab' 
			WHEN 1008 then 'sjs' 
			WHEN 1006 then 'tfb' 
	end as channel,
	round(a.amount/100,2), 
	case state 
		WHEN 4 then round(a.base_fee/100,2) 
		WHEN 31 then round(a.t0_fee/100,2) 
	end, 
	case state 
		WHEN 4 then 'F' 
		WHEN 31 then 'S' 
	end  
	FROM db.tb_t0 as a left join db.tb_db as b using(db_id) 
	WHERE date(a.create_time)='${day}' and a.amount>1;" > $d0_file
}

function do_t1_summary()
{
>$t1_file
for i in {0..99}
do
    m=$(($i/10))
    n=$(($i%10))

    $mysql_exec -e "select time,
		case pay_type 
			WHEN 8 then 'WX' 
			WHEN 9 then 'ZFB' 
			WHEN 4 then 'TFB' end,
		order_id,
		case channel_id 
			WHEN 22 then 'xmcmbc' 
			WHEN 23 then 'wft' 
		end,
		round(amount/1000000, 2),
		round(mch_fee_amount/1000000, 2),
		'S' 
		FROM db2.tb_merchant_stat_${m}${n} 
		WHERE date(time)='${day}' 
		GROUP BY order_id having count(*)=1" >> $t1_file
done
}

date >> /tmp/txjg_d0_t1_sum_log
judge_crond
echo "judge_crond done" >> /tmp/txjg_d0_t1_sum_log
do_d0_summary
echo "do_d0_summary done" >> /tmp/txjg_d0_t1_sum_log
do_t1_summary
echo "do_t1_summary done" >> /tmp/txjg_d0_t1_sum_log

if [ $called_by_crond -eq 1 ]; then
	title="${day} 交易详情"
else
	title=$(echo "${day} 交易详情" | iconv -f utf-8 -t gbk)
fi

export LANG=zh_CN.UTF-8 && echo "see attachment" | mail -a ${d0_file} -a ${t1_file} -s "${title}" freedominmind@163.com

echo "mail done" >> /tmp/txjg_d0_t1_sum_log

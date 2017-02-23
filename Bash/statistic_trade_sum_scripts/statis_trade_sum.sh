#传入日期，统计那天的数据

#!/bin/bash

mysql_exec="mysql "

day=`date +%F -d '-1 day'`

if [ $# -gt 0 ]; then
  day=$1
fi

base_dir=statis
mkdir $base_dir 2>/dev/null

pid=$$

echo "$pid">> $base_dir/start_pids

# 查D0成功
echo "$day-----------"
eval $($mysql_exec -N -B -e "select round(sum(amount)/100, 2),round(sum(amount-pay_amount)/100,2) FROM db.t0_order WHERE date(create_time)='${day}' and state=31;" | awk '{printf("amount=%.2f;fee=%.2f", $1, $2)}')


#To debug
#echo $amount,$fee
#amount=0.00
#fee=0.00

# 查D0失败
eval $($mysql_exec -N -B -e "select round(sum(amount)/100, 2),round(sum(if(base_fee_by_wan!=0, base_fee+1,base_fee))/100,2) 
		FROM db.t0_order WHERE date(create_time)='${day}' and state=4;" \
		| awk -v amount=$amount -v fee=$fee '{amount+=$1;fee+=$2;printf("amount=%.2f;fee=%.2f", amount, fee)}')


#To debug
#echo $amount,$fee
#amount=0.00
#fee=0.00

# 查T1
for i in {0..99}
do
#	echo "$m$n..."
    m=$(($i/10))
    n=$(($i%10))

    result=$($mysql_exec -e "select sum(amount),sum(fee),count(*) FROM (select round(a.amount/1000000, 2) as amount, round(a.mch_fee_amount/1000000, 2) as fee 
			FROM settle.mch_statement_${m}${n} as a LEFT JOIN db.trade_${m}${n} as b USING(order_id)
			WHERE date(a.time)='${day}' and b.status=2 
			GROUP BY a.order_id having count(*)=1) b ")
	eval $(echo "$result" | awk -v amount=$amount -v fee=$fee '{amount+=$1;fee+=$2;printf("amount=%.2f;fee=%.2f", amount, fee)}')
done

mch_profit=$($mysql_exec -NBe "select round(ifnull(sum(profit_amount), 0)/1000000,2) from settle.mch_share_profit_statement_report where date(trade_time)='$day'")
gc_profit=$(awk -v mch_profit=$mch_profit -v fee=$fee 'BEGIN{printf("%.2f", fee-mch_profit)}')

#To debug
#echo "$day, $amount, $fee, $mch_profit, $gc_profit"

echo "$day, $amount, $fee, $mch_profit, $gc_profit" > $base_dir/$day
echo "$day done."
echo "$pid" >> $base_dir/end_pids

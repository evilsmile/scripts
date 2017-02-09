#!/bin/bash

sql_cmd='mysql '

day=$(date -d yesterday +"%Y%m%d")

if [ $# -ge 1 ]; then
	day=$1
fi

db_t0_file=db_id_t0.list
db_t1_file=db_id_t1.list
diff_file=db_id.diff
fee_file=db_id.fee
fee_sql_file=db_id.sql
t1_pay_file=t1_pay.list

ONE_WAN=10000

function calc_fee()
{

$sql_cmd -N -B -e "SELECT mch_id,floor(amount/10000) 
					FROM db.t_paybill_order_report 
					WHERE date='$day'"   					\
					| sort | sed 's/\t/ /g' > $t1_pay_file

# 收集db_id
$sql_cmd -N -B -e "SELECT trade_id,mch_id,amount,
						case pay_type 
						   WHEN 0 THEN 0
						   WHEN 1 THEN 1
						   WHEN 2 THEN 4
						   WHEN 3 THEN 6
						END 
					FROM db.t_db 
					WHERE date(channel_time)='$day' AND status=2" \
					| sort > $db_t1_file 

$sql_cmd  -N -B -e "SELECT trade_id,mcht_id,amount,
						  CASE fee_type
						    WHEN 2 then 0
						    WHEN 3 then 1
						    WHEN 5 then 4
						    WHEN 7 then 6
						  END 
					FROM db.t_t0_order 
					WHERE date(create_time)='$day' AND state=31"  \
					| sort > $db_t0_file

>$fee_sql_file
diff $db_t1_file $db_t0_file  \
 | grep "^<"  			\
 | sed 's/<//g'          \
 | awk '{sum[$2][$4]+=$3;}END{for(m in sum){for(n in sum[m]){print m" "n" "sum[m][n]}}}' \
 | while read mch_id pay_type amount; do
	mn=-1
	eval $(echo $mch_id | awk '{printf("mn=%02s", substr($1, length($1)-1))}')

	echo "SELECT mch_id,
				${amount},
				${amount}*$ONE_WAN - ${amount}*fee_rate 
				FROM db.t_fee_${mn} WHERE mch_id='$mch_id' AND fee_type=$pay_type;" >> $fee_sql_file
done

cat $fee_sql_file | $sql_cmd -N -B  | sort > $fee_file

>fee_detail.list
>tmp
eval $(awk '{
	   mch_id=$1
	   db_amount=$2
	   pay_amount_by_wan=$3 
	   total_mch_pay[mch_id] += $3
	   total_mch_db[mch_id] += $2

	   total_db+=$2
	   calc_total_pay+=int($3/'$ONE_WAN')
	 }
	 END {
		for(m in total_mch_pay) {
			printf("%s %d\n", m, int(total_mch_pay[m]/'$ONE_WAN')) >> "tmp"
		}
		printf("calc_total_db=%d;calc_total_pay=%d", total_db, calc_total_pay)
	 }' $fee_file )

sort tmp >pay_amount.list 

eval $(awk '{sum+=$2}END{printf("real_t1_pay=%d;calc_total_fee=%d;real_t1_fee=%d;pay_diff=%d", sum, ('$calc_total_db'-'$calc_total_pay'), ('$calc_total_db'-sum), ('$calc_total_pay'-sum)) }' $t1_pay_file)

echo "total_t1_db_not_paid: $calc_total_db"
echo "calc_fee: $calc_total_fee"
echo "real_fee: $real_t1_fee"
echo "pay_diff: [" $pay_diff "]"

}

function check_diff() 
{

# check diff 
echo "-----------------"
echo "Check calc diff: =>"
diff pay_amount.list t1_pay.list | awk '
		# 数据样例:
		# 23d22
        # < 160000000003559 1900
        # 221c220
        # < 160000000027994 10065
        # ---
        # > 160000000027994 10058

		BEGIN {
			block_start=0
			block_end=0
			find_former=0
			find_latter=0
			former_mch_id=-1
			latter_mch_id=-1
			former_amount=-1
			latter_amount=-1
		}
		function handle() 
		{
			# 前文件有差异
			if (find_former==1) {
				# 后文件也有差异
				if (find_latter == 1) {
					printf("pay _diff_: %s %d %d [%d]\n", former_mch_id, former_amount, latter_amount, former_amount-latter_amount)
				} else {
					printf("pay _in_calc_list_: %s %d\n", former_mch_id, former_amount)
				}
			} else { 
				if (find_latter == 1) {
					printf("pay _in_real_list_: %s %d\n", latter_mch_id, latter_amount)
				}
			}
		}
		function reset()
		{
			block_start=1
			block_end=0
			find_former = 0
			find_latter = 0
		}
		{
			# 找到起始行, 如 "23d22"
			if (block_start == 0 && $0 ~ /^[0-9]{1,}[a-z][0-9]{1,}/) {
				block_start = 1
				block_end = 0
			# 找到结束行, 为下一个起始行，如 "221c220"
			} else if (block_end == 0 && $0 ~ /^[0-9]{1,}[a-z][0-9]{1,}/) {
				block_end=1
			}

			# 寻找结束的过程中
			if (block_start == 1 && block_end == 0) {
				# "<" 开头表示前一个文件有差异，取出对应的数据
				if ( $0 ~ /< /) {
					find_former=1
					if (match($0, /^< ([0-9]{10,}) ([0-9]{1,})/, arr) == 0) {
						print "No match-------------------"
					}
					former_mch_id=arr[1]
					former_amount=arr[2]
				# ">" 开头表示后一个文件有差异，取出对应的数据
				} else if ($0 ~ /> /) {
					find_latter=1
					match($0, /^> ([0-9]{10,}) ([0-9]{1,})/, arr)
					latter_mch_id=arr[1]
					latter_amount=arr[2]
				}
			# 取出完整数据块了，开始处理
			} else if (block_start == 1 && block_end == 1) {
				handle()
				reset()				
			}
		}
		END {
			#对最后一个差异块进行处理
			handle()
		}'


}


#calc_fee
check_diff

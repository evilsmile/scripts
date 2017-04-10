#!/bin/bash

sql_cmd='mysql -u user -p123 -h 192.168.1.1 --default-character-set=utf8 '

day=$(date -d yesterday +"%Y%m%d")

if [ $# -ge 1 ]; then
	day=$1
fi

db_t0_file=db_id_t0.list
db_t1_file=db_id_t1.list
fee_file=db_id.fee
fee_sql_file=db_id.sql
t1_pay_file=t1_pay.list
result_fee_diff_file=result_fee_diff.list
result_only_in_calc_file=result_only_in_calc.list
result_only_in_realpay_file=result_only_in_realpay.list

ONE_WAN=10000

function calc_fee()
{

$sql_cmd -N -B -e "SELECT mch_id,floor(amount/10000) 
					FROM db.t_paybill_order_report 
					WHERE date='$day'"   					\
					| sort | sed 's/\t/ /g' > $t1_pay_file

# 收集db_id
$sql_cmd -N -B -e "SELECT db_id,mch_id,amount,
						case pay_type 
						   WHEN 0 THEN 0
						   WHEN 1 THEN 1
						   WHEN 2 THEN 4
						   WHEN 3 THEN 6
						END 
					FROM db.t_db 
					WHERE date(channel_time)='$day' AND status=2" \
					| sort > $db_t1_file 

$sql_cmd  -N -B -e "SELECT db_id,mcht_id,amount,
						  CASE fee_type
						    WHEN 2 then 0
						    WHEN 3 then 1
						    WHEN 5 then 4
						    WHEN 7 then 6
						  END 
					FROM db.t_tb2 
					WHERE date(create_time)='$day' AND state=31"  \
					| sort > $db_t0_file

>$fee_sql_file
# diff ... | grep ... | sed ... => 找出准备T1打款的交易流水
diff $db_t1_file $db_t0_file                 \
 | grep "^<"  			                           \
 | sed 's/<//g'                                    \
 | while read db_id mch_id amount fee_type; do
	mn=-1
	eval $(echo $mch_id | awk '{printf("mn=%02s", substr($1, length($1)-1))}')

	# 找到对应的流水，用流水里的费率进行计算
	echo "SELECT mch_id,
				${amount},
				${amount}*$ONE_WAN - ${amount}*fee_rate 
				FROM db.t_db_${mn} WHERE db_id='$db_id';" >> $fee_sql_file

done

# 由sql文件一次完成查询
cat $fee_sql_file | $sql_cmd -N -B  | sort > $fee_file

>fee_detail.list
>tmp
eval $(awk '{
	   # 进行统计
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
>$result_fee_diff_file
>$result_only_in_calc_file
>$result_only_in_realpay_file

# check diff 
echo "-----------------"
echo "Check calc diff: =>"
diff pay_amount.list t1_pay.list | awk '
		# 数据样例:
		# 23d22
        # < 160000000003559 1900
        # < 160000000007582 980
        # 221c220
        # < 160000000027994 10065
        # < 160000000007582 982
        # ---
        # > 160000000027994 10058
		#
		#
		# 计算过程:
		# 前文件，计算手续费文件
		# 后文件，实际手续费文件
		# 1. 以23d22这样的行当作比较起点
		# 2. 如找到"<"开头的行，把商户号和金额分别放入 数组former_mch_ids和former_amounts中
		# 3. 如找到">"开头的行，把商户号和金额分别放入 数组latter_mch_ids和latter_amounts中
		# 4. 对比former_mch_ids和latter_mch_ids，如果有一方有另一方没有的，则打印“仅存在于“结果；如果都有，则计算手续费差异

		BEGIN {
			# 对比块的开始和结束标志。在block_start后搜集商户号金额
			block_start=0

			# 在block_end后开始进行former_mch_ids和latter_mch_ids的比较
			block_end=0

			#找到former标志
			find_former=0

			#找到latter标志
			find_latter=0

			# 如果连续多行出现"<"，则要用数组存储。此为数组的下标
			former_index=0
			latter_index=0
		}

		function handle() 
		{
			# 前文件有不同
			if (find_former==1) {
				# 后文件也有不同。
				if (find_latter == 1) {

					find=0;
					# 循环比较前后两个数组
					for(f_mch_idx in former_mch_ids) {
						for(l_mch_idx in latter_mch_ids) {
							# 在两个数组中都找到了
							if (latter_mch_ids[l_mch_idx] == former_mch_ids[f_mch_idx]) {
								find=1;
								break;
							}
						}
						# 则表明只是手续费有差异
						if (find == 1) {
							find = 0;
							printf("%s %d %d [%d]\n", former_mch_ids[f_mch_idx], former_amounts[f_mch_idx], latter_amounts[l_mch_idx], former_amounts[f_mch_idx]-latter_amounts[l_mch_idx]) >> "'$result_fee_diff_file'"
						} # 否则表示单独存在
						else {
							printf("%s %d\n", former_mch_ids[f_mch_idx], former_amounts[f_mch_idx]) >> "'$result_only_in_calc_file'"
						} 	
					}
				} # 后文件里没有
				else {
					# 则只存在于前文件
					for (f_mch_idx in former_mch_ids) {
						printf("%s %d\n", former_mch_ids[f_mch_idx], former_amounts[f_mch_idx]) >> "'$result_only_in_calc_file'"
					}
				}
			} else { 
				# 只存在于后文件 
				if (find_latter == 1) {
					for (l_mch_idx in latter_mch_ids) {
						printf("%s %d\n", latter_mch_ids[l_mch_idx], latter_amounts[l_mch_idx]) >> "'$result_only_in_realpay_file'"
					}
				}
			}
		}

		function reset()
		{
			block_start=1
			block_end=0
			find_former = 0
			find_latter = 0
			former_index=0
			latter_index=0
			delete former_amounts
			delete former_mch_ids
			delete latter_amounts
			delete latter_mch_ids
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
					#需要置标志位
					find_former=1

					# 匹配 "mch_id amount" 格式
					if (match($0, /^< ([0-9]{10,}) ([0-9]{1,})/, arr) == 0) {
						print "No match-------------------"
					}
					# 循环塞进数组
					former_mch_ids[former_index]=arr[1]
					former_amounts[former_index]=arr[2]
					former_index++;
				
				} # ">" 开头表示后一个文件有差异，取出对应的数据
				else if ($0 ~ /> /) {

					#需要置标志位
					find_latter=1

					# 匹配 "mch_id amount" 格式
					match($0, /^> ([0-9]{10,}) ([0-9]{1,})/, arr)
					# 循环塞进数组
					latter_mch_ids[latter_index]=arr[1]
					latter_amounts[latter_index]=arr[2]
			
					latter_index++;
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

function confirm_fee_diff_result()
{
	if [ ! -s "$fee_diff_content" ]; then
		return;
	fi
	echo "手续费有差异的商户: " 
	echo "$fee_diff_content"
}

function confirm_only_in_calc_result()
{
	# -s判断文件是否存在且不为空
	if [ ! -s "$result_only_in_calc_file" ]; then
		return
	fi

	echo -e "\n只存在于计算列表中的商户:-------------"
	cnt=1
	while read mch_id amount; do
		echo "[$cnt]: $mch_id, $amount"
		echo -e "\t===========Collected INFO: ============"
		cnt=$(($cnt+1))

		# 看看是不是因为商户状态不对所以没有打款
		status=$($sql_cmd -NBe "SELECT CASE status 
								 			 WHEN 0 THEN 'Normal' 
								 			 WHEN 1 THEN 'ForbidSettle' 
								 			 WHEN 2 THEN 'Verifying' 
								 			 WHEN 3 THEN 'Logoff'
								 			 WHEN 4 THEN 'ForbidAll'
								 			 ELSE 'Unknown'
									   END
						         FROM db.t_mch WHERE mch_id='$mch_id'")
		echo -e "\tMch status : [$status]"
		# 查看日期内的T1交易总额
		t1_db=$($sql_cmd -NBe "SELECT round(sum(amount)/100,2) as t1_db FROM db.t_db WHERE mch_id='$mch_id' and date(update_time)='$day' and status=1")
		# 查看日期内的成功D0交易总额
		d0_db=$($sql_cmd -NBe "SELECT round(ifnull(sum(amount), 0)/100, 2) as d0_db FROM db.t_tb2 WHERE mcht_id='$mch_id' and date(update_time)='$day' and state=1")
		# 查看日期内的未知D0交易总额
		unknown_d0_db=$($sql_cmd -NBe "SELECT round(ifnull(sum(amount), 0)/100, 2) as d0_db FROM db.t_tb2 WHERE mcht_id='$mch_id' and date(update_time)='$day' and state=3")
		t1_d0_db_diff=$(echo "$t1_db - $d0_db" | bc)
		# 加入'      '对齐格式
		# 查看商户的冻结列表 
		freeze_list=$($sql_cmd -NBe "SELECT '         | ',round(amount/1000000, 2), update_time, '  |' FROM db.t_paybill_frozen_order WHERE mch_id='$mch_id' AND state=0")
		echo -e "\tt1_db: [$t1_db] d0_db: [$d0_db] unknown_d0_db: [$unknown_d0_db] d0-t1: [$t1_d0_db_diff]"
		echo -e "\tfreeze_list: "
		echo "$freeze_list"
		
	done < $result_only_in_calc_file

}

function confirm_only_in_realpay_result()
{
	# -s判断文件是否存在且为空
	if [ ! -s "$result_only_in_realpay_file" ]; then
		return
	fi

	echo "只存在于计算列表中的商户: ARE YOU SURE?"
}
function confirm_result()
{
	confirm_fee_diff_result
	confirm_only_in_calc_result
	confirm_only_in_realpay_result
}

calc_fee
check_diff
confirm_result

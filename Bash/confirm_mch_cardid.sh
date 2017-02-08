#!/bin/bash

sql_cmd='mysql '

db_info=""
file=""
line=""
db_card_id=""
cardid_from_log=""

MATCH="Match!"
NOTFOUND="+++++++++++++ NOT Found in log +++++++++++++"
NOTMATCH="--------------- Not Match! ---------------"

function debug()
{
	msg=$1
	echo "$msg"
	echo "DB_INFO: [  $db_info  ]"
	echo "EDIT? [ vim $file +$line ]"
	echo "LOG_CARDID: $cardid_from_log"
}

function check_in_log()
{
	mch_id=$1

	# 1. 从最新的更新日志中找出更新的时间
	echo "-->>>>>> searching logs using database cardid ...."
	dbcardid_update_log=$(grep --color=never -rnw "$db_card_id" /data/log/tfb_usermgr.log_* | grep -w UPDATE | grep -w card_id | tail -1)
	dbcardid_update_date=$(echo $dbcardid_update_log | awk -F"[] []" '{print $2}')

#	echo $dbcardid_update_log
	echo $dbcardid_update_date

	# 2. 从最新的更新日志中找出更新的时间
	echo "-->>>>>> searching logs using log cardid ...."
	logcardid_update_log=$(grep --color=never -rnw "$cardid_from_log" /data/log/tfb_usermgr.log_* | grep -w UPDATE | grep -w card_id | tail -1)
	logcardid_update_date=$(echo $logcardid_update_log | awk -F"[] []" '{print $2}')

#	echo $logcardid_update_log
	echo $logcardid_update_date

	# 3. 对比两个更新时间，如果数据库数据更新，则OK，否则有问题
	if [ "$dbcardid_update_date" -gt "$logcardid_update_date" ]; then
		echo "card id updated. check OK"
	else
		echo "check FAILED. db updated on $dbcardid_update_date, but log telling $logcardid_update_date"
		debug "$mch_id $NOTMATCH"
	fi
}


# 找出所有的成功D0过的商户
# [mysql中也是用'#'作注释]
# STEP 1. 
sql="SELECT distinct mcht_id 
		FROM db.t_t0_flow 
		WHERE state=31 
				AND mcht_id like '%91' 
				AND pay_channel_name!='d0_balance'
#				AND mcht_id = '160000000023091'
	"

$sql_cmd -NBe "$sql" | while read mch_id ; do

	# 表后缀
	eval $(echo $mch_id | awk '{printf("mn=%s", substr($1, length($1)-1, 2))}')

	# STEP 2. 
	# 找一个最新的订单号
	eval $($sql_cmd -NBe "SELECT a.order_id,
							a.pay_channel_name, 
							b.card_holder,
						    b.card_id, 
							a.flow_id 
				          FROM db.t_t0_flow a LEFT JOIN db.t_mch_${mn} b ON a.mcht_id=b.mch_id
				          WHERE a.mcht_id='$mch_id' AND a.state=31 AND a.pay_channel_name!='d0_balance' 
				          ORDER BY a.create_time DESC LIMIT 1" 			                             \
							| awk '{ printf("                                                            \
							d0_order_prefix=%s;                                  						 \
							d0_channel_name=%s;                                  						 \
							card_holder=%s;                                      						 \
							db_card_id=%s;																 \
							flow_id=%s",            													 \
							substr($1, 0, 8),       													 \
							$2,                     													 \
							$3,                     													 \
						    $4,                     													 \
						    $5)                     													 \
							}'                       													 \
			)

	db_info="$mch_id $card_holder $db_card_id"

	# STEP 3. 
	# 找到当天的D0日志文件
	d0_log_file=/data/log/t0_service.log_${d0_order_prefix}

	# STEP 5. 
	# 从匹配到的行开始往后找该线程的日志
	eval $(awk -v channel_name=$d0_channel_name  \
					   'BEGIN{
							card_id="-1"
							xmcmbc_find=0
							start_line=0
							thread_id=0
						}
						{													 
                            # 还未找到关键行
							if (start_line == 0) {
								if ( $0 ~ /INSERT.*\('$flow_id'/ ) {
									start_line=NR
									if (match($0, /^\[.*\]\[.*\]\[.*]\[.*\]\[(.*)\]-- .*/, arr) == 0) {
										cardid_from_log=0
                                        exit
									}
                                    # 找到关键行，取出线程id
									thread_id=arr[1]
								} 
							} else {
                                # 从关键行之后开始，根据不同的通道匹配不同的关键字
								if(NR>=start_line) {
						
									if ($0 ~ thread_id && channel_name == "daifu_tfb") {
                                        # 匹配acc_id=...模式，取出卡号
										if (match($0, /.*acct_id=(.*)\&acct_name.*/, arr) > 0) {
											card_id=arr[1]
										}
									} else {
                                        # 加上新的匹配字符串确认发起请求的行
										pat=thread_id".*cmbc_rt"
			 							if ($0 ~ pat) {
											xmcmbc_find=1
										}
                                        # 在后续的行找到ACC_NO模式，取出卡号
										if (xmcmbc_find == 1 && match($0, /.*<ACC_NO>(.*)<\/AC/, arr) > 0) {
											card_id=arr[1]
										}
									}
								}
								if (length(card_id)>5) {
									exit
								}
							}
					   }
					   END{
						printf("cardid_from_log=%s", card_id)
					   }' $d0_log_file  					  \
			 )

	if [ "X$cardid_from_log" == "X" ]; then
		debug "$mch_id $NOTFOUND"
		continue
	fi

	# STEP 7. 
	# 是否有包含
	echo "$db_info" | grep $cardid_from_log > /dev/null

	if [ $? -eq 0 ]; then	
		echo "$mch_id $MATCH"
	else
		echo "........ $mch_id need further check...."
		check_in_log $mch_id
	
		continue
	fi
	

#	vim $file +$line +/$thread_id < /dev/tty

done 

#!/bin/bash

sql_cmd='mysql -u selectuser -pqrpos123 -h 192.168.1.174 --default-character-set=utf8'

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
	dbcardid_update_log=$(grep --color=never -rnw "$db_card_id" /data/log/tfb_usermgr.log_* | grep -w UPDATE | grep -w F_card_id | tail -1)
	dbcardid_update_date=$(echo $dbcardid_update_log | awk -F"[] []" '{print $2}')

#	echo $dbcardid_update_log
	echo $dbcardid_update_date

	# 2. 从最新的更新日志中找出更新的时间
	echo "-->>>>>> searching logs using log cardid ...."
	logcardid_update_log=$(grep --color=never -rnw "$cardid_from_log" /data/log/tfb_usermgr.log_* | grep -w UPDATE | grep -w F_card_id | tail -1)
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
sql="SELECT distinct F_mcht_id 
		FROM trade.t_t0_flow 
		WHERE F_state=31 
				AND F_mcht_id like '%91' 
				AND F_pay_channel_name!='d0_balance'
#				AND F_mcht_id = '160000000010291'
	"

$sql_cmd -NBe "$sql" | while read mch_id ; do

	# 表后缀
	eval $(echo $mch_id | awk '{printf("mn=%s", substr($1, length($1)-1, 2))}')

	# STEP 2. 
	# 找一个最新的订单号
	info_from_db=$($sql_cmd -NBe "SELECT a.F_order_id,a.F_pay_channel_name, b.F_card_holder, b.F_card_id ,a.F_flow_id 
				FROM trade.t_t0_flow a LEFT JOIN trade.t_mch_${mn} b ON a.F_mcht_id=b.F_mch_id
				WHERE a.F_mcht_id='$mch_id' AND a.F_state=31 AND a.F_pay_channel_name!='d0_balance' 
				ORDER BY a.F_create_time DESC LIMIT 1")

	eval $( echo $info_from_db | awk '{ printf("                                 \
							d0_order_prefix=%s;                                  \
							d0_channel_name=%s;                                  \
							card_holder=%s;                                      \
							db_card_id=%s;										\
							flow_id=%s",            substr($1, 0, 8), $2, $3, $4, $5)}')

	db_info="$mch_id $card_holder $db_card_id"

	# STEP 3. 
	# 找到当天的D0日志文件
	d0_log_file=/data/log/t0_service.log_${d0_order_prefix}

	# STEP 4. 
	key_log_line=$(grep -Hnw "INSERT.*($flow_id" $d0_log_file | head -1)

	# 取出匹配到D0订单号的文件名和行号
	eval $(echo $key_log_line | awk -F":" '{printf("file=%s;line=%s", $1, $2)}')

	# 取出线程号, 作为后面的匹配
	eval $(echo $key_log_line | awk -F"[][]" '{printf("thread_id=%s;", $10)}')

	# STEP 5. 
	# 从匹配到的行开始往后找50行该线程的日志, 对于一个请求50行日志足够了
	thread_log=$(awk -v line=$line '{if(NR>=line) { print NR,$0 }}' $d0_log_file 	\
						| grep -w $thread_id 										\
						| head -50													\
				)

	# STEP 6. 
	# 根据打款通道用不同的过滤
	if [ $d0_channel_name == "daifu_tfb" ]; then
		# 用acct_id 过滤出打款请求行，并过滤出acct_id=..acct_name=...
		cardid_from_log=$(echo "$thread_log" 											 \
						| grep -w "acct_id"    											 \
						| head -1            											 \
						| sed 's/.*acct_id=\(.*\)&acct_name=\(.*\)&business_type.*/\1/g' \
						)
	else
		# 用cmbc_rt 找出打款请求行，并找到此行后面的<ACC_NO>..</ACC_NO>
		first_xmcmbc_line=$(echo "$thread_log" 			\
							| grep -w "cmbc_rt" -m 1    \
							| awk '{print $1}'          \
							)

		if [ "X$first_xmcmbc_line" = "X" ];then
			debug "$mch_id $NOTFOUND"
			continue
		fi

		cardid_from_log=$(awk -v line=$first_xmcmbc_line '{if(NR>=line) {print}}' $d0_log_file   \
						| grep -w ACC_NO -m 1 													 \
						| sed 's/<ACC_NO>\([0-9]\{2,\}\)<\/AC.*/\1/g' 							 \
				)
	fi

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

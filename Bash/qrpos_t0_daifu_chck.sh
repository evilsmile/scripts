#!/bin/bash

s_db=settle
t_db=db

slave_mysql_exec="/usr/local/mysql/bin/mysql -u"
local_mysql_exec="/usr/local/mysql/bin/mysql -u"

TRADE_DATE="`date -d last-day '+%Y-%m-%d'`"
if [ $# -eq 1 ]
then
	TRADE_DATE=$1
fi

TMPDIR=/usr/local/daifu/tmp
WORKDIR=/usr/local/daifu/bin

t0_record_file="${TMPDIR}/t0_${TRADE_DATE}.txt"
tfb_df_record_file="${TMPDIR}/${TRADE_DATE}.txt"

called_by_crond=-1
function judge_crond()
{
	crond_pid=$(pidof crond)

	ppid=$(ps -p ${1:-$$} -o ppid=;)

	if [ $ppid -eq 1 ]; then
		called_by_crond=1
	else
		called_by_crond=0
	fi
}

#选择t0打款记录
function select_t0_records(){
	local sql="select flow_id,daifu_order_id,pay_amount,pay_channel_name,create_time from ${t_db}.t_t0_flow where state=31 and pay_channel_name='daifu_tfb' and date(create_time)='${TRADE_DATE}'"
	$slave_mysql_exec ${t_db} -e "${sql}" | sort > ${t0_record_file};	
}


#save to db
function save_statement_result_to_DB(){
	local RESULT_SQL=$1;
	test -e ${RESULT_SQL} && $local_mysql_exec < ${RESULT_SQL}
}

function tfb_df_statement_down() {

	#BILL_DATE=`echo $TRADE_DATE | tr -d '-'`
	local ftp_url="ftp://user:passw@11.11.11.11/"

	local pay_file_name="${TRADE_DATE}.txt"
	
	curl "${ftp_url}${pay_file_name}" | awk  '{if($8=="T0打款"){print $2,$3,$5,$9,$10}}' | sort > $tfb_df_record_file
}

function do_t0_df_statement(){

		local tfb_file="$tfb_df_record_file";
		local t0_file="$t0_record_file";
		local result_file="${TMPDIR}/t0_df_${TRADE_DATE}.result";
		local result_sql="${TMPDIR}/t0_df_${TRADE_DATE}.sql";

		#tfb: 代付订单号，通道交易号,金额,日期 时间,
		#t0:flow_id,bill_id,amount,channel_uin,bankret_time
		if test -f ${tfb_file} && test -f ${t0_file}
		then
			# 全连接
	        
      join -a1 -a2 ${tfb_file} ${t0_file} > ${result_file};
			
			/bin/awk -v bus_id="t0" -v acc_date=${TRADE_DATE} '{
						if (NF==5){
							# t0缺单
							sql="replace into db.t_daifu"
							sql=sql"(bus_id,channel_order_id,channel_amount,channel_time,account_date,account_state,create_time)"
							sql=sql"values("
							sql=sql"\047"bus_id"\047,"
							sql=sql"\047"$2"\047,"
							sql=sql"\047"$3"\047,"
							sql=sql"\047"$4" "$5"\047,"
							sql=sql"\047"acc_date"\047,"
							sql=sql"-1,now());"
							
							print sql
						}else if(NF==6){
							# 代付通道缺单
							sql="replace into db.t_daifu"
							sql=sql"(bus_id,order_id,channel_order_id,bus_amount,channel,channel_time,"
							sql=sql"account_date,account_state,create_time)"
							sql=sql"values("
							sql=sql"\047"bus_id"\047,"
							sql=sql"\047"$1"\047,"
							sql=sql"\047"$2"\047,"
							sql=sql"\047"$3"\047,"
							sql=sql"\047"$4"\047,"
							sql=sql"\047"$5" "$6"\047,"
							sql=sql"\047"acc_date"\047,"
							sql=sql"1,now());"
							print sql
						}else{
							# 能够关联上
							sql="replace into db.t_daifu"
							sql=sql"(bus_id,channel_order_id,channel_amount,channel_time,"
							sql=sql"order_id,bus_amount,channel,"
							sql=sql"account_date,account_state,create_time)"
							sql=sql"values("
							sql=sql"\047"bus_id"\047,"
							sql=sql"\047"$2"\047,"
							sql=sql"\047"$3"\047,"
							sql=sql"\047"$4" "$5"\047,"
							
							sql=sql"\047"$1"\047,"
							sql=sql"\047"$7"\047,"
							sql=sql"\047"$8"\047,"

							
							sql=sql"\047"acc_date"\047,"
							sql=sql"0,now());"
							print sql
						}
					}' ${result_file} > ${result_sql} ;
		fi
		
		# 对账结果入库 	
		save_statement_result_to_DB ${result_sql};
		
		rm -rf ${tfb_file}
		rm -rf ${t0_file}
		rm -rf ${result_file}
		rm -rf ${result_sql}
}

function check_diff() {

> /tmp/t0_daifu_diff

	diff=$($local_mysql_exec -N -B -e "SELECT count(*) FROM db.t_daifu WHERE bus_id='t0' AND account_state!=0")
	if [ "x$diff" != "x" ]; then
		echo "order number NOT match: [$diff]" >> /tmp/t0_daifu_diff
	fi

	diff=$($local_mysql_exec -N -B -e "SELECT count(*) FROM db.t_daifu WHERE channel_amount != bus_amount AND bus_id='t0' AND account_state=0")
	if [ "x$diff" != "x" ]; then
		echo "amount not match [$diff]" >> /tmp/t0_daifu_diff

	else
		echo "check succ"
	fi
}

judge_crond

select_t0_records;

tfb_df_statement_down;

do_t0_df_statement;

check_diff;

if [ $called_by_crond -eq 1 ]; then
	title="${day} 对账结果"
else
	title=$(echo "${day} 对账结果" | iconv -f utf-8 -t gbk)
fi

export LANG=zh_CN.UTF-8 && cat /tmp/t0_daifu_diff | mail -s "${title}" freedominmind@163.com

exit

#!/bin/bash

sql_cmd="mysql -u "

function usage() {
	echo -e "Usage:
  -t db_id
  -o order_id
  -m mch_id"
	exit
}

while getopts "p:d:t:o:m:c:h" arg ; do
	case $arg in
		t)
		  db_id=$OPTARG
			;;
		o)
		  order_id=$OPTARG
			;;
		d)
		  date=$OPTARG
			;;
		p)
		  phone=$OPTARG
			;;
		m)
		  mch_id=$OPTARG
			;;
	    c)
		  channel_order_id=$OPTARG
			;;
		h)
		  usage
			;;
	esac
done

sql="SELECT a.F_order_id as t0_order_id, b.F_flow_id as t0_flow_id, a.F_amount,a.F_db_id as db_id, a.F_daifu_order_id as daifu_order_id, a.F_mcht_id as mch_id, a.F_state as order_status, 
	 a.F_daifu_respmsg as order_respmsg,  a.F_create_time as order_time, b.F_state as flow_order, b.F_daifu_respmsg as flow_resmsg  , a.F_pay_channel_name as pay_channel, b.F_create_time as flow_time 
	 FROM db.tb_t0 as a LEFT JOIN db.tb_t0_flow as b using(F_order_id)
     WHERE 1=1 "

has_condition=0

#其它选项可以唯一确定，而如果是商户号的话则最好加日期
if [ "x$mch_id" != "x" ]; then
	has_condition=1
	$sql_cmd -e "SELECT F_mch_id, F_mch_name, F_status, F_referrer, F_d0_flag, F_owner_mobile, F_card_holder, F_bank_segment, F_bank_name, F_card_id, F_create_time, F_update_time FROM db.tb_merchant WHERE F_mch_id='$mch_id'"
	sql="$sql AND a.F_mcht_id like '%${mch_id}'"
fi

if [ "x$phone" != "x" ]; then
	has_condition=1
	mch_id=$(./convert_phone_to_mch.sh $phone)
	$sql_cmd -e "SELECT F_mch_id, F_mch_name, F_status, F_referrer, F_d0_flag, F_owner_mobile, F_card_holder, F_bank_segment, F_bank_name, F_card_id, F_create_time, F_update_time FROM db.tb_merchant WHERE F_mch_id='$mch_id'"
	sql="$sql AND a.F_mcht_id like '%${mch_id}' "
fi


if [ "x$date" != "x" ]; then
	has_condition=1
	sql="$sql AND date(a.F_create_time)='$date'"
fi

if [ "x$db_id" != "x" ]; then
	has_condition=1
	sql="$sql AND a.F_db_id='${db_id}'"
fi

if [ "x$order_id" != "x" ]; then
	has_condition=1
	sql="$sql AND a.F_order_id='${order_id}'"
fi

if [ "x$channel_order_id" != "x" ]; then
	has_condition=1
	sql="$sql AND b.F_order_id='${channel_order_id}'"
fi

if [ $has_condition -eq 0 ]; then
	sql="$sql AND date(a.F_create_time)=curdate()"
fi
	
$sql_cmd -e "$sql"

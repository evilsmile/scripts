#!/bin/bash

sql_cmd="mysql -u "

function usage() {
	echo -e "Usage:
  -t db_id
  -o order_id
  -p phone_num
  -m mch_id"
	exit
}

while getopts "p:t:o:d:m:c:h" arg ; do
	case $arg in
		t)
		  db_id=$OPTARG
			;;
		o)
		  order_id=$OPTARG
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
		d)
		  date=$OPTARG
			;;
		h)
		  usage
			;;
	esac
done
sql="SELECT a.db_id as db_id, a.order_id as order_id, round(a.amount/100, 2) as amount, 
	 a.mch_id as mch_id, a.mch_name as mch_name, c.mch_name as channel_mch_name, 
	 case a.status 
		  WHEN 0 THEN 'create'
		  WHEN 1 THEN 'paying'
 		  WHEN 2 THEN 'succ'
 		  WHEN 3 THEN 'fail'
     END as status, 
	 case a.pay_type 
		  WHEN 0 THEN 'WX'
		  WHEN 1 THEN 'ZFB'
          WHEN 2 THEN 'TFBQR'
     END as pay_type, 
	 case a.pay_channel_id 
		  WHEN 0 THEN 'wft'
		  WHEN 1 THEN 'xmcmbc'
		  WHEN 2 THEN 'tfbqr'
		  WHEN 3 THEN 'sjs'
		  WHEN 4 THEN 'xmpab'
	 END as channel_id,
	 a.channel_mch_id as channel_mch_id, a.channel_trans_id as channel_order_id, 
	 a.create_time as create_time, a.update_time as update_time
	 FROM db.tb_db as a 
         LEFT JOIN db.tb_channel_sjs_mch_bind as b ON a.channel_mch_id=b.channel_mch_id 
	     LEFT JOIN db.tb_merchant as c ON c.mch_id=b.mch_id 
     WHERE 1=1 "

has_condition=0

#其它选项可以唯一确定，而如果是商户号的话则最好加日期
if [ "x$mch_id" != "x" ]; then
	has_condition=1
	sql="$sql AND a.mch_id like '%${mch_id}' "
fi

if [ "x$phone" != "x" ]; then
	has_condition=1
	mch_id=$(./convert_phone_to_mch.sh $phone)
	sql="$sql AND a.mch_id like '%${mch_id}' "
fi


if [ "x$date" != "x" ]; then
	has_condition=1
	sql="$sql AND date(a.create_time)='${date}'"
fi

if [ "x$db_id" != "x" ]; then
	has_condition=1
	sql="$sql AND a.db_id='${db_id}'"
fi

if [ "x$channel_order_id" != "x" ]; then
	has_condition=1
	sql="$sql AND a.channel_trans_id='${channel_order_id}'"
fi

if [ "x$order_id" != "x" ]; then
	has_condition=1
	sql="$sql AND a.order_id='${order_id}'"
fi

if [ $has_condition -eq 0 ]; then
	sql="$sql AND date(a.create_time)=curdate()"
fi
	
#echo "$sql;"
$sql_cmd -e "$sql"

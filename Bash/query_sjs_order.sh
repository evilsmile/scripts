#!/bin/bash

sql_cmd="mysql -u "

function usage() {
	echo -e "Usage:
  -t db_id
  -o order_id
  -m mch_id
  -c channel_order_id"
	exit
}

while getopts "t:o:m:c:h" arg ; do
	case $arg in
		t)
		  db_id=$OPTARG
			;;
		o)
		  order_id=$OPTARG
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

sql="SELECT a.F_db_id as db_id, a.F_order_id as order_id, a.F_mch_id as mch_id, a.F_status as status,
	 a.F_amount as amount, a.F_channel_mch_id as channel_mch_id, b.F_order_id as channel_order_id, 
	 b.F_status as channel_status, b.F_channel_order_id as sjs_order_id, a.F_create_time, b.F_channel_resp_time, b.F_update_time 
	 FROM db.tb_db as a LEFT JOIN db.tb_channel_order as b on a.F_channel_order_id=b.F_db_id 
     WHERE 1=1 "

#其它选项可以唯一确定，而如果是商户号的话则最好加日期
if [ "x$mch_id" != "x" ]; then
	sql="$sql AND a.F_mch_id='${mch_id}' AND date(a.F_create_time)=curdate() "
fi

if [ "x$db_id" != "x" ]; then
	sql="$sql AND a.F_db_id='${db_id}'"
fi

if [ "x$order_id" != "x" ]; then
	sql="$sql AND a.F_order_id='${order_id}'"
fi

if [ "x$channel_order_id" != "x" ]; then
	sql="$sql AND b.F_order_id='${channel_order_id}'"
fi
	
$sql_cmd -e "$sql"

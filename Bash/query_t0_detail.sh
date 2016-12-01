#!/bin/bash

sql_cmd="mysql -u "

function usage() {
	echo "Usage: -d days_ago     # default 0"
	echo "       -f              #only fail orders"
	echo "       -s              #only succ orders"
	exit -1
}

succ_flag=-1
days_ago=0
while getopts "fsd:h" arg; do
	case $arg in 
		f)
			succ_flag=0
			;;
		s)
			succ_flag=1
			;;
		d)
			days_ago=$OPTARG
			;;
		h)
			usage
			;;
	esac
done

if [ $succ_flag -eq 0 ]; then
	sql="SELECT * FROM db.t_tb_t0 WHERE date(create_time)=date_sub(curdate(), interval $days_ago day) and amount>1 and state!=31"
elif [ $succ_flag -eq 1 ]; then
	sql="SELECT * FROM db.t_tb_t0 WHERE date(create_time)=date_sub(curdate(), interval $days_ago day) and amount>1 and state=31"
else
	sql="SELECT * FROM db.t_tb_t0 WHERE date(create_time)=date_sub(curdate(), interval $days_ago day) and amount>1"
fi

$sql_cmd -e "$sql"

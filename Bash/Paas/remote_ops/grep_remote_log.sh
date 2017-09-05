#!/bin/bash

ATOMOP_DIR=atom_ops/
CONFIG_FILE=config/host_ip.list
TMPDIR=tmp/

# 合并最后一列，把","换成"\n"然后唯一化，再合并起来，逗号连接
SUPPORTED_COMP=$(sed -e 's/.* \([^ ]*\)/\1/g' -e 's/,/\n/g' $CONFIG_FILE | sort | uniq | awk  'BEGIN{ORS=","}{print}')

if [ $# -lt 2 ]; then
	echo "Usage: keyword component_name[$SUPPORTED_COMP]"
exit
fi

keyword=$1
component=$2
today=$(date +"%Y%m%d")

local_ip=$(ifconfig eth1 | grep "inet addr" | sed 's/.*inet addr:\([0-9\.]\+\).*/\1/g')

log_file=/opt/paas/smsp5.0/smsp_${component}/logs/smsp_${component}_${today}.log

remote_cmd="grep -rnw \"$keyword\" $log_file"

# 由组件名搜索对应的IP
chosen_ips=$(grep --color=never -rw $component $CONFIG_FILE) 
if [ -z "$chosen_ips" ]; then
	echo "No match ip of component '$component'. Supported list is [$SUPPORTED_COMP]"
    exit 0
fi

filelist=""
echo "$chosen_ips" > $TMPDIR/chose_ips.list

# 取出相应ip的信息
while read host_ip user passwd components; do
	echo "handling $host_ip ..."
	# 忽略'#'开头的行
	if [ "${host_ip:0:1}" == "#" ]; then
		echo "ignore $host_ip";
		continue;
    fi

	grep_result_file=$TMPDIR/${host_ip}_${component}_${today}

	# 收集每个grep进程的日志输出名,后面统计时用于cat输出
	filelist="${filelist} $grep_result_file"

	if [ "$host_ip" == "$local_ip" ]; then
		# 本机的话本地执行就可以
		$remote_cmd >  $grep_result_file &
    else
		$ATOMOP_DIR/exe_remote.exp $host_ip $user $passwd "$remote_cmd" >  $grep_result_file &
	fi
done  < $TMPDIR/chose_ips.list

# 收集各机器的grep结果
while true ; do
	still_running=$(ps u | grep exe_remote.exp | grep -vw "grep exe_remote.exp" | wc -l)
    if [ "$still_running" -eq 0 ]; then
        echo -e " [ ==================== Search over. =================]\n\n"
		for f in $filelist; do
			echo "----------------------------> log_file: $f <--------------------------"
			cat $f
			echo -e "\n\n"
		done
		exit 0
	fi
	sleep 1
done
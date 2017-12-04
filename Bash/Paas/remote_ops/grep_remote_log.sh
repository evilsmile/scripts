#!/bin/bash

ATOMOP_DIR=atom_ops/
CONFIG_FILE=config/host_ip.list
TMPDIR=tmp/

# 合并最后一列，把","换成"\n"然后唯一化，再合并起来，逗号连接
SUPPORTED_COMP=$(sed -e 's/.* \([^ ]*\)/\1/g' -e 's/,/\n/g' $CONFIG_FILE | sort | uniq | awk  'BEGIN{ORS=","}{print}')

function usage()
{
	echo "Usage: -m -k keyword -c component_name -i ip"
	echo "       -m 找到一个就返回"
	echo "       -k 指定关键字"
	echo "       -c 指定组件名字 [$SUPPORTED_COMP]"
	echo "       -i 指定查找的主机IP地址 "
	exit -1
}

today=$(date +"%Y%m%d")

keyword=""
component=""
ip=""
grep_options="-rnw"

while getopts "mk:c:i:" arg; do 
    case $arg in
      m)
		grep_options="-m 1 $grep_options"
        ;;
      k)
        keyword=$OPTARG
        ;;
      c)
        component=$OPTARG
        ;;
      i)
        ip=$OPTARG
        ;;
     esac
done

if [ -z "$keyword"  -o   -z "$component" ]; then
	usage
fi

local_ip=$(ifconfig eth1 | grep "inet addr" | sed 's/.*inet addr:\([0-9\.]\+\).*/\1/g')

real_component=$(echo $component | sed -e 's/_hy$//g' -e 's/_yx$//g')
log_file=/opt/paas/smsp5.0/smsp_${real_component}/logs/smsp_${real_component}_${today}.log

REMOTE_CMD="grep $grep_options \"$keyword\" $log_file"

chosen_ips=""
if [ -z "$ip" ]; then
	# 由组件名搜索对应的IP
	chosen_ips=$(grep --color=never -rw $component $CONFIG_FILE) 
else
    # 使用指定的IP
	chosen_ips=$(grep --color=never -rw "10.10.202.$ip" $CONFIG_FILE)
fi
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

	grep_result_file=$TMPDIR/${host_ip}_${real_component}_${today}

	# 收集每个grep进程的日志输出名,后面统计时用于cat输出
	filelist="${filelist} $grep_result_file"

	if [ "$host_ip" == "$local_ip" ]; then
		# 本机的话本地执行就可以
		echo "search localhost: $REMOTE_CMD ";

		eval $REMOTE_CMD  >$grep_result_file &
    else
		$ATOMOP_DIR/exe_remote.exp $host_ip $user $passwd "$REMOTE_CMD" >  $grep_result_file &
	fi
done  < $TMPDIR/chose_ips.list

# 收集各机器的grep结果
while true ; do
	still_running=$(ps u | grep exe_remote.exp | grep -vw "grep exe_remote.exp" | wc -l)
    if [ "$still_running" -eq 0 ]; then
        echo -e " [ ==================== Search over. =================]\n\n"
		for f in $filelist; do
			echo "----------------------------> log_file: $f <--------------------------"
			cat $f | more
			echo -e "\n\n"
		done
		exit 0
	fi
	sleep 1
done

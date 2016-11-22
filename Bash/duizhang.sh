#!/bin/bash

sql_cmd='mysql -u '
download_sjs_bill_cmd='/usr/local/bin/download_bill_tool'

yesterday=$(date -d yesterday +"%Y%m%d")
day=${yesterday}

if [ $@ > 1 ]; then
	day=$1
fi

#目录文件元素
bill_dir=/data/alipay_duizhang/${day}
bill_filename=sjs_bill.txt
txjg_bill_filename=txjg_sjs_bill-1.txt
txjg_bill_orders_filename=txjg_orders_from_sjs_bill-2.txt
txjg_db_orders_filename=txjg_orders_from_db-3.txt

#文件的全路径
bill_ful_filename=${bill_dir}/${bill_filename}
txjg_bill_ful_filename=${bill_dir}/${txjg_bill_filename}
txjg_bill_orders_ful_filename=${bill_dir}/${txjg_bill_orders_filename}
txjg_db_orders_ful_filename=${bill_dir}/${txjg_db_orders_filename}

function filter_bill()
{
	#mkdir if not exists
	if [ ! -d ${bill_dir} ]; then
		echo "mkdir ${bill_dir}"
		mkdir -p ${bill_dir}
	fi
	
	#如果还未下载对账文件则下载
	if [ ! -f "$bill_ful_filename" ]; then 
		echo "no sjs bill. download it"
	
		curl --user user:passwd ftp://10.10.10.10/Data_${day}.txt -o $bill_ful_filename
	
		if [ ! -f $bill_ful_filename ]; then
			exit
		fi
	fi

	echo "filter order id from bill - 1...."

	#再进一步过滤出订单号
	awk -F"," '/SUCCESS/{
				if(length($3)==20) {
					print
				}
			  }' $bill_ful_filename | sort > $txjg_bill_ful_filename
	#去年'`'字符
	awk -F"," '/SUCCESS/{
				if(length($3)==20){
					printf("%s\t%.0f\n", substr($3, 2, 18), 100 * substr($6, 2, length($6)-2));
				}
			}' $bill_ful_filename | sort > $txjg_bill_orders_ful_filename
}


function query_db()
{
	echo "select order id from db - 2...."

	#用settle_date去查数据库中相应日期的订单号 
	$sql_cmd -N -B -e "SELECT order_id, 
							  amount 
						FROM db.tb_channel_order 
						WHERE date(channel_resp_time)='${day}' 
							  AND 
							  status=21" > $txjg_db_orders_ful_filename
}

function do_diff()
{
	echo "do diff - 3...."
	#对比
	bill_differ=$(diff -Nru $txjg_bill_orders_ful_filename $txjg_db_orders_ful_filename )
	
	echo "do diff - 3-1 ..."
	#只存在于对账单中的
	mail_content="$(echo "$bill_differ" | grep "\-201[0-9]\+"  | sed 's/-//g' | while read order amount; do
						$sql_cmd -N -e "SELECT order_id, 
											   db_id, 
											   amount, 
											   status, 
											   channel_mch_id, 
											   channel_resp_msg 
										FROM db.tb_channel_sjs_order 
										WHERE order_id='${order}'
										";
				   done)"
	# 发现有只存在于Sjs端的
	if [ "X${mail_content}" != "X" ] ; then
		mail_content="
					  [== orders only in Channel Bills ==]:\n
					  order_id\tdb_id\tamount\tstatus\tthird_mchid\tchannel_resp_msg\n
					  ${mail_content}
					 "
	fi
	
	echo "do diff - 3-2 ..."
	#只存在于数据库中的
	orders_only_in_db=$(echo "$bill_differ" | grep "+201[0-9]\+"  | sed 's/+//g')
	if [ "X${orders_only_in_db}" != "X" ]; then
		mail_content="${mail_content}\n
					  [== orders only in Local DB ==]:\n
					  $orders_only_in_db
					  "
	fi
}

function do_mail()
{
	echo "do mail - 4..."

	if [ $called_by_crond -eq 1 ]; then
		title="${day}: Bill "
	else
		title=$(echo "${day} Bill " | iconv -f utf-8 -t gbk)
	fi

	#添加标题
	if [ "x$mail_content" == "x" ]; 
	then
		mail_content="OK"
		title="${title} OK"
	else
		title="${title} FAIL"
	fi

	echo "send" > /tmp/123
	#发送邮件
	export LANG=zh_CN.UTF-8 && echo -e "$mail_content" | mail -s "$title" freedominmind@163.com
}

called_by_crond=-1
function judge_crond()
{
	ppid=$(ps -p ${1:-$$} -o ppid=;)

	if [ $ppid -eq 1 ]; then
		called_by_crond=1
	else
		called_by_crond=0
	fi
}

judge_crond

filter_bill

query_db

do_diff

do_mail

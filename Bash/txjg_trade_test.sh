#!/bin/bash

TEST_TYPE=TEST

#用于线上的测试数据
online_mysql_exec=""
online_order_id=2017
online_url=192.168
online_wecode=ohc6rv7Fb9VgOhDffyE8c2w889Z4

#用于测试环境的测试数据
test_mysql_exec=""
test_order_id=201610
test_url=192.168.
test_wecode=ov0_pwCWTVfmmHliM20xJ7-hSugU


#真正用的数据
sql_cmd=$test_mysql_exec
order_id=$test_order_id
url=$test_url
wecode=$test_wecode

function usage() 
{
    echo "Usage: -t wx/ali/tfb/qq  # trade_type to test. if not specified test all
       -o # test online
       -h # print usage"
    exit -1
}

function judge_pay_param() 
{

	if [ "$TEST_TYPE" == "ONLINE" ]; then
	    order_id=$online_order_id
	    sql_cmd=$online_mysql_exec
	    url=$online_url
        wecode=$online_wecode
	else
	    order_id=$test_order_id
	    sql_cmd=$test_mysql_exec
	    url=$test_url
        wecode=$test_wecode
	fi

	mn=$(echo $order_id | awk '{printf("%02s", substr($1, length($1)-8, 2))}')
	
	eval $($sql_cmd -N -B -e "SELECT 
	                a.amnt,a.mchid,b.mchname 
	                FROM db.order_${mn} as a 
	                    LEFT JOIN db.mch_${mn} as b 
	                    USING(mch_id) 
	                WHERE a.order_id='${order_id}'" | awk '{printf("amount=%d;mch_id=%s;mch_name=%s", $1, $2, $3)}')
	
}


function do_test() 
{
    trade_type=$1

    keyword="unknown"
	if [ "$trade_type" == "wx" ]; then
        keyword="MicroMessenger"
	elif [ "$trade_type" == "ali" ]; then
        keyword="AliApp"
	elif [ "$trade_type" == "tfb" ]; then
        keyword="tfbpay_client"
    elif [ "$trade_type" == "qq" ]; then
        keyword=" QQ"
	else
	    usage
	fi

    request='{
            "pay":{
                   "user_agent":"Mozilla/5.0 (iPhone; CPU iPhone OS 10_0_2 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) '${keyword}'",
                   "amount":'${amount}',
                   "goods_name":"phone",
                   "mch_id":"'${mch_id}'",
                   "mch_name":"'${mch_name}'",
                   "order_id":"'${order_id}'",
                   "term_id":"243",
                   "wechat_code":"'${wecode}'",
               }
             }'
    echo "Test [ $trade_type ... ] ==========> "
    # "`echo $request`" 用于输出成一行
	curl http://${url}/cgi-bin/tfb_gate.cgi -d "`echo $request`"
}

while getopts "t:ho" arg ; do
    case $arg in
        t)
          trade_type=$OPTARG
            ;;
        o)
          TEST_TYPE=ONLINE
            ;;
        h)
          usage
            ;;
    esac
done

judge_pay_param

if [ "X$trade_type" == "X" ]; then
    #无参数的话默认挨个测一遍
    do_test wx
    do_test ali
    do_test qq
    do_test tfb
else
    do_test $trade_type
fi


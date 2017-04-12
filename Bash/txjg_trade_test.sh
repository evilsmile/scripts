#!/bin/bash

TEST_TYPE=TEST

#用于线上的测试数据
online_mysql_exec="mysql -u "
online_mch_id=1600
online_url=192.168.1.1
online_wecode=ohc6rv7Fb9VgOhDffyE8c2w889Z4
online_amount=1000

#用于测试环境的测试数据
test_mysql_exec="mysql -u "
test_mch_id=000002002
test_url=192.168.1.1:1111
test_wecode=ov0_pwCWTVfmmHliM20xJ7-hSugU
test_amount=1


#真正用的数据
sql_cmd=$test_mysql_exec
url=$test_url
wecode=$test_wecode
mch_id=$test_mch_id
amount=$test_amount

function usage() 
{
    echo "Usage: -t wx/ali/tfb/qq/hs  # trade_type to test. if not specified test all
       -o # test online
       -h # print usage"
    exit -1
}

function judge_pay_param() 
{

	if [ "$TEST_TYPE" == "ONLINE" ]; then
	    mch_id=$online_mch_id
	    sql_cmd=$online_mysql_exec
	    url=$online_url
        wecode=$online_wecode
        amount=$online_amount
	else
	    mch_id=$test_mch_id
	    sql_cmd=$test_mysql_exec
	    url=$test_url
        wecode=$test_wecode
        amount=$test_amount
	fi
}

tfb_user_id_for_40=18682356030
tfb_user_id_for_test=13113005689

#tfb_user_id=$tfb_user_id_for_40
tfb_user_id=$tfb_user_id_for_test

order_id_init_value=0000000000000000000
order_id=$order_id_init_value

function create_order()
{
    request='{"from":"h5","to":"trade","info":{},"action":"create_order","data":{},"create_order":{"mch_id":"'${mch_id}'","amount":'${amount}',"term_id":"1658338"}}'
	reply=$(curl http://${url}/cgi-bin/tfb_gate.cgi -d "`echo $request`" 2>/dev/null)
    if [ $? != 0 ]; then
        echo "Create order failed!"
        exit;
    fi
    # 按',' 取出order_id域，去掉无用字符
    order_id=$(echo "$reply" | awk -F"," '{print $6}' | sed 's/.*order_id":"\([0-9]\+\)"}/\1/g')
}

function do_test() 
{
    create_order

    if [ "$order_id" == "$order_id_init_value" ]; then
        echo "Get order id failed!"
        exit -1;
    fi

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
    elif [ "$trade_type" == "hs" ]; then
        keyword="app_swiping"
	else
	    usage
	fi

    request='{
               "from":"h5",
               "to":"trade",
               "info":{},
               "action":"pay",
               "data":{},
               "pay":{
                   "user_agent":"'${keyword}'",
                   "amount":'${amount}',
                   "goods_name":"phone",
                   "mch_id":"'${mch_id}'",
                   "mch_name":"'${mch_name}'",
                   "order_id":"'${order_id}'",
                   "term_id":"243",
                   "wechat_code":"'${wecode}'",
                   "tfb_user_id":"'${tfb_user_id}'",
                   "card_data":"{
                        \"device_type\":\"1\",
                        \"pin\":null,
                        \"card_id\":null,
                        \"devicd_id\":\"00:00:00:00:06:55\",
                        \"ic_data\":null,
                        \"ic_card_seq\":\"00\",
                        \"track3_data\":null,
                        \"track2_data\":null
                        \"elec_sign\":\"AAABAAAAAUAAAABkAAAAAggAAxzL6+RsSf8CJrF+ddM4\/wI5hxb\/AheR\/wI2mP8CJqfTQP8CX\/En5dIRk61c6uXw\/wILXpbSYlQlHtDq\/wLBiS4i9hxF5v8Cp0gzDnFg\/wLgy1QwFED\/Arwg8WBY\/wIwSslKgP8CPq2PZP8CboWDQkiA\/wJqvyfw\/wJY39Mw\/wIJQvXg\/wIVJkBo\/wJWHJaKrsSA\/wLPIpqEUPSA\/wLkbDMTKpEhfqSA\/wIxtvLiBLD\/Ag\/pbkv\/Ap6dJZdg\/wLHwGG8Qb13q6D\/At3XqeePMKGA\/wLBCJGRNSuI\/wJEK\/EESqe14P8CIReS8DeIMID\/AiNVLU9duzzJ\/wI0Rg31USEQ\/wJlYii7\/wKjMeQQ\/wJ41\/8C7cZV4P8CwUbuGP8CTdU8wP8Ccsqe5WwFH8D\/AnYJHv8Cysj\/Ai9I\/wLWY0D\/AoqlgP8CcSj\/AvBw\/wL+2v8C\/wL\/Av8C\"
                  }"
               }
             }'

    echo "Test [ $trade_type ... ] ==========> "
    echo $request
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
    do_test hs
else
    do_test $trade_type
fi

#             request='{"action":"pay","to":"trade","info":{"os_type":"ios","app_version":"010400"},"pay":{"amount":100,"order_id":"20170331000000008731","mch_id":"160000000021731","card_data":"{\"ic_data\":\"9F3303604800950500000400009F1A0201569A031703319F37043D3EA77982027C009F360200849F26088614F9A09DBA65999F101307060103A02000010A01000000000038A576109C01009F02060000000000005F2A0201569F03060000000000009F34034203009F2701809F3501349F4104000002129F090200309F1E083132333435363738\",\"elec_sign\":\"AAABAAAAAUAAAABkAAAAAggAAxzL6+RsSf8CJrF+ddM4\/wI5hxb\/AheR\/wI2mP8CJqfTQP8CX\/En5dIRk61c6uXw\/wILXpbSYlQlHtDq\/wLBiS4i9hxF5v8Cp0gzDnFg\/wLgy1QwFED\/Arwg8WBY\/wIwSslKgP8CPq2PZP8CboWDQkiA\/wJqvyfw\/wJY39Mw\/wIJQvXg\/wIVJkBo\/wJWHJaKrsSA\/wLPIpqEUPSA\/wLkbDMTKpEhfqSA\/wIxtvLiBLD\/Ag\/pbkv\/Ap6dJZdg\/wLHwGG8Qb13q6D\/At3XqeePMKGA\/wLBCJGRNSuI\/wJEK\/EESqe14P8CIReS8DeIMID\/AiNVLU9duzzJ\/wI0Rg31USEQ\/wJlYii7\/wKjMeQQ\/wJ41\/8C7cZV4P8CwUbuGP8CTdU8wP8Ccsqe5WwFH8D\/AnYJHv8Cysj\/Ai9I\/wLWY0D\/AoqlgP8CcSj\/AvBw\/wL+2v8C\/wL\/Av8C\",\"card_expire\":\"2308\",\"track2_data\":\"6230901804110001585D230822027000000F\",\"card_id\":\"6230901804110001585\",\"ic_card_seq\":\"00\",\"devicd_id\":\"V27-00000000\",\"device_type\":\"1\",\"pin\":\"N9p10DtvvSqvUqrCo+9N3OK3vjWDm0Jg63KOprvLaFTil0hzewHQW\/LM6Uc6GaJcc64VIvnKtHNFamH3X79yWPBr1DOicGwvB7kNQVe80Rdh0iAInkrSL1ZZsUpi193IzUC6LDejGKWOQAaeoFo\/a+iw0zpAkKdVELLO68rlmqD3a6HRO6xwLxw4LA4B6a66tIbw5Z1GPfjtdHSiNF8\/H\/e+cSixV5VrGnsJQVJ+6O+NKtXsDDy6Mf7bZaYIjvYCe6Aj46bpBNRl7LWli8SSuDrpAbDQ026l0stYWg9nAZNRrregtMT+bBlwDuWh59houFtYKInu9h7DMdkD9ds5eg==\"}","term_id":"","goods_name":"dtghhhv扣扣图","user_agent":"app_swiping"},"session":{"session_id":"5C43C9C4B823EEC7FB1595B844AF285F","app_type":"1","device_id":"67F01B0B-D6C6-42C8-960B-243FCE1FD567","mch_id":"160000000021731"},"from":"app"}'

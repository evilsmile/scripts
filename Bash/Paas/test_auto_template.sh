#!/bin/bash

sqlcmd='mysql -u common_user -pucpaas.com -h 172.16.5.41 -A --default-character-set=utf8 smsp_message_5.5'

global=0
client=1
fixed=0
variable=1
global_temp_no_sign=0
global_temp_sign=1
TEST_TYPE_WHITE="White"
TEST_TYPE_BLACK="Black"

####################################### 彩色输出函数 ##############################
function notice_echo()
{
    msg=$1
    #黄底黑字 
    echo -e "\033[43;38m $msg \033[0m"
}

function error_echo()
{
    msg=$1
    #黑底黑字 
    echo -e "\033[41;38m $msg \033[0m"
}

function title_echo()
{
    msg=$1
    #天蓝底白字 
    echo -e "\033[46;37;1;4m $msg \033[0m"
}

function sub_title_echo()
{
    msg=$1
    #紫底白字
    echo -e "\033[45;38m $msg \033[0m"
}

function raw_echo()
{
    msg=$1
    echo -e "\033[30m $msg \033[0m"
}

########################################## 数据准备函数 ###############################
function insert_new_white_record()
{
    template_level=$1
    template_type=$2

    sign="天天篮球"
    content=" 不要只想着打篮球,看电影"

    global_sign_flag=$global_temp_sign

    if [ $# -gt 2 ];then
        global_sign_flag=$3
    fi

    if [ $global_sign_flag == $global_temp_no_sign ]; then
        sign=""
    fi

    if [ $template_type == $variable ]; then
        content=" 不要只想着{},{}"
    fi

    if [ $template_level == $global ]; then
        client_id="*"
    else
        client_id="b01221"
    fi
    clear_black
    clear_white
    insert_sql="INSERT INTO t_sms_auto_template SET client_id = '$client_id', 
                                                      template_level= $template_level,
                                                      template_type= $template_type,
                                                      sms_type=10,
                                                      sign='$sign',
                                                      content='$content',
                                                      submit_type=3,
                                                      state=1"

    echo "INSERT_SQL: $insert_sql"                                                      
    $sqlcmd -NBe "$insert_sql"
}

function clear_white()
{
    $sqlcmd -NBe "DELETE FROM t_sms_auto_template WHERE client_id in ('b01221', '*')"
}

function clear_black()
{
    $sqlcmd -NBe "DELETE FROM t_sms_auto_black_template WHERE client_id in ('b01221', '*')"
}

function insert_new_black_record()
{
    template_level=$1
    template_type=$2

    global_sign_flag=$global_temp_sign

    if [ $# -gt 2 ];then
        global_sign_flag=$3
    fi

    sign="天天篮球"
    content=" 不要只想着打篮球,看电影"

    if [ $global_sign_flag == $global_temp_no_sign ]; then
        sign=""
    fi

    if [ $template_type == $variable ]; then
        content=" 不要只想着{},{}"
    fi

    if [ $template_level == $global ]; then
        client_id="*"
    else
        client_id="b01221"
    fi
    clear_black
    insert_sql="INSERT INTO t_sms_auto_black_template SET client_id = '$client_id', 
                                                     template_level= $template_level,
                                                     template_type= $template_type,
                                                     sms_type=10,
                                                     sign='$sign',
                                                     content='$content',
                                                     state=1"
    echo "INSERT_SQL: $insert_sql"
    $sqlcmd -NBe "$insert_sql"
}
# TABLE operations
#alter_old_tbl
#create_new_tbl

#Clear
#clear_white
#clear_black

################################# 等待函数 ##################################
access_log_file=/opt/smsp/lijing/smsp5.0/smsp_access/logs/smsp_access.log

line_cnt_before_update=-1
function set_linecnt_before_update()
{
    line_cnt_before_update=$(wc -l $access_log_file | awk '{print $1}')
}

function wait_and_check_test_result()
{
    test_type=$1
    local log_keyword="CheckAutoBlackTemplate"
    if [ "$test_type" == "$TEST_TYPE_WHITE" ]; then
        log_keyword="CheckAutoWhiteTemplate"
    else
        log_keyword="CheckAutoBlackTemplate"
    fi
    wait_util_log_keyword $log_keyword

}
# 更新数据库数据后等待组件得到更新消息
function wait_for_tbl_update()
{
    test_type=$1
    tbl=t_sms_auto_black_template
    if [ "$test_type" == "$TEST_TYPE_WHITE" ]; then
        tbl=t_sms_auto_template
    else
        tbl=t_sms_auto_black_template
    fi
    log_keyword="update $tbl"
    wait_util_log_keyword "$log_keyword"
}

function wait_util_log_keyword()
{
    log_keyword=$1

    local tryseconds=1
    local timeout=10      # 只尝试timeout这么多次，一次/s
    local line_cnt_after_update=-1
	while true; do
        line_cnt_after_update=$(wc -l $access_log_file | awk '{print $1}')
        # 取更新前的行数，和更新后的行数之间的内容查找，确定搜索出的内容是本次的更新
	    get_updated=$(awk 'NR>'$line_cnt_before_update'&&NR<='$line_cnt_after_update'' $access_log_file | egrep -w "$log_keyword")
	    if [ -z "$get_updated" ]; then
            if [ $tryseconds -gt $timeout ]; then
                error_echo "Not find logkeyword '$log_keyword' in log.."
                exit -1
            fi
            tryseconds=$((tryseconds+1))
	        notice_echo "waiting for '$log_keyword'..."
	        sleep 1;
	    else
	        notice_echo "Find '$log_keyword'!"
            echo "[$get_updated]"
	        break
	    fi
	done
}

function pause()
{
    notice_echo "Enter to continue..."
    read X
}

####################################  执行测试函数 ######################

function send_http_req
{
    remain_keyword=打篮球
#    remain_keyword=dd
    sys_keyword=天天篮球
    json_req='{
                                                     "clientid": "b01221",
                                                     "password": "25d55ad283aa400af464c76d713c07ad",
                                                     "extend": "402",
                                                     "uid": "1234567890",
                                                     "mobile": "18589060708",
                                                     "smstype":"0",                                      
                                                     "content": "【'$sys_keyword'】 不要只想着'${remain_keyword}',看电影"
                                                    }'
    echo "Request: $json_req"
    curl 'http://172.16.5.52:29101/aaa/sendsms' -d "$json_req"
}

function do_test()
{
    test_type=$1
    title=$2
    temp_level=$3
    temp_type=$4

    global_sign_flag=$global_temp_sign

    if [ $# -gt 4 ]; then
        global_sign_flag=$5
    fi

    local log_result_keyword=""

    ##======== 准备数据 ==========##
    # 修改数据库前先存储日志的行数，后面在wait_for_tbl_update()中从该行数往后找内容关键字
    set_linecnt_before_update
    sub_title_echo "Now test [$title] --------------->"
    if [ "$test_type" == "$TEST_TYPE_WHITE" ]; 
    then
        insert_new_white_record $temp_level $temp_type $global_sign_flag
    elif  [ "$test_type" == "$TEST_TYPE_BLACK" ]; 
    then
        insert_new_black_record $temp_level $temp_type $global_sign_flag
    fi
    wait_for_tbl_update $test_type

    ##======== 发送请求并查看结果 ==========##
    set_linecnt_before_update
    send_http_req
    wait_and_check_test_result $test_type

    # 暂停等待，确认日志中业务内容后回车进入下一个测试
    pause
}

function test_white_or_black()
{
    test_type=$1
    title_echo "============== Test [$test_type] ========="
    do_test $test_type "Global-$test_type-Sign FIXED" $global $fixed

    do_test $test_type "Global-$test_type-Sign VARIABLE" $global $variable

    do_test $test_type "Global-$test_type-NO-Sign FIXED" $global $fixed $global_temp_no_sign

    do_test $test_type "Global-$test_type-NO-Sign VARIABLE" $global $variable $global_temp_no_sign

    do_test $test_type "Client-$test_type-Sign FIXED" $client $fixed

    do_test $test_type "Client-$test_type-Sign VARIABLE" $client $variable
}

test_white_or_black $TEST_TYPE_WHITE
#test_white_or_black $TEST_TYPE_BLACK

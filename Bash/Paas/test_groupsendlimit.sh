#!/bin/bash

####################### EXE CMDs ###########################
sqlcmd='mysql -u common_user -pucpaas.com -h 172.16.5.41 -A --default-character-set=utf8 smsp_message_5.5'
rediscmd='/opt/smsp/lijing/installs/redis-4.0.1/bin/redis-cli -h 172.16.5.41 -n 1'

###################### CONST ###########################
logfilename="/opt/smsp/lijing/smsp5.0/smsp_access/logs/smsp_access.log"
audit_result_mq_exchange_name="LIJING_AUDIT_RESULT_EX"
audit_result_mq_route_name="LIJING_AUDIT_RESULT_RT"

AUDIT_STATE_PASS_1=1
AUDIT_STATE_FAIL_2=2
AUDIT_STATE_PASS_MAN_EXPIRE_3=3
AUDIT_STATE_FAIL_MAN_EXPIRE_4=4
AUDIT_STATE_TIMEOUT_SYS_EXPIRE_5=5
AUDIT_STATE_GROUPSEND_UNLIMIT_TO_AUDIT_6=6
AUDIT_STATE_GROUPSEND_UNLIMIT_TO_SEND_7=7
AUDIT_STATE_PASS_SYS_EXPIRE_8=8
AUDIT_STATE_FAIL_SYS_EXPIRE_9=9

#################################### VARIABLES ###########################
msg=""
md5key=""
auditid=""

startline=0
endline=0

AuditStatusName=( "empty" 
             "审核通过[1]"                     
             "审核失败[2]" 
             "审核通过人工过期[3]" 
             "审核失败人工过期[4]" 
             "系统过期[5]" 
             "群发解锁转审核[6]" 
             "群发解锁转发送[7]" 
             "系统审核通过转过期[8]" 
             "系统审核失败转过期[9]")

EndgsauditsmsStatusName=( "empty" 
             "审核通过[1]"                     
             "审核失败[2]" 
             "群发解锁转发送[3]"
             "群发解锁转审核[4]" 
             )


#status=$AUDIT_STATE_PASS_1                                
status=$AUDIT_STATE_FAIL_2                              
#status=$AUDIT_STATE_PASS_MAN_EXPIRE_3                   
#status=$AUDIT_STATE_FAIL_MAN_EXPIRE_4                   
#status=$AUDIT_STATE_TIMEOUT_SYS_EXPIRE_5                
#status=$AUDIT_STATE_GROUPSEND_UNLIMIT_TO_AUDIT_6        
#status=$AUDIT_STATE_GROUPSEND_UNLIMIT_TO_SEND_7         
#status=$AUDIT_STATE_PASS_SYS_EXPIRE_8                   
#status=$AUDIT_STATE_FAIL_SYS_EXPIRE_9                   

######################################### ECHO #################################

function notice_echo()
{
    output_msg=$1
    now=$(date +"%Y-%m-%d %H:%m:%S")
    #黄底黑字 
    echo -e "[$now]\033[43;31;1m $output_msg \033[0m"
}

function warn_echo()
{
    output_msg=$1
    now=$(date +"%Y-%m-%d %H:%m:%S")
    #黑底黑字 
    echo -e "[$now]\033[47;43;1m $output_msg \033[0m"
}

function error_echo()
{
    output_msg=$1
    now=$(date +"%Y-%m-%d %H:%m:%S")
    #黑底黑字 
    echo -e "[$now]\033[41;38;1m $output_msg \033[0m"
}

function content_echo()
{
    output_msg=$1
    now=$(date +"%Y-%m-%d %H:%m:%S")
    #天蓝底白字 
    echo -e "[$now]\033[46;37;1;4m $output_msg \033[0m"
}

function title_echo()
{
    output_msg=$1
    now=$(date +"%Y-%m-%d %H:%m:%S")
    #紫底白字
    echo -e "[$now]\033[45;38;1m $output_msg \033[0m"
}

function raw_echo()
{
    output_msg=$1
    now=$(date +"%Y-%m-%d %H:%m:%S")
    echo -e "[$now]\033[30m $output_msg \033[0m"
}

#####################################################################

function send_http_req()
{
    data="{
            \"clientid\": \"b01221\",
            \"password\": \"25d55ad283aa400af464c76d713c07ad\",
            \"extend\": \"402\",
            \"uid\": \"1234567890\",
            \"mobile\": \"18664314691\",
            \"smstype\":\"0\",
            \"content\": \"【摩拜.车】 来了在这两个数列中33\"
        }"

    title_echo "[1]. Sending data ===> "
    echo "$data"

    curl -d  "$data" "http://172.16.5.52:29101/aaa/sendsms"
}
#  -------------------------
#  +                       +
#  +   发布消息到MQ        +
#  +                       +
#  -------------------------
function publish_mq()
{
    msg=$1

    echo "Publishing MQ msg: [$msg]"
    
    curl -u guest:guest -H 'content-type: application/json' 'http://172.16.5.41:15672/api/exchanges/%2f/'${audit_result_mq_exchange_name}'/publish' \
        -d "
    {
        \"properties\":{},
        \"routing_key\":\"${audit_result_mq_route_name}\",
        \"payload\":\"$msg\",
        \"payload_encoding\":\"string\"
    }
    "
}

#  -------------------------------------
#  +                                   +
#  +   获取当前日志文件的行数          +
#  +   用于在执行操作前和操作后        +
#  +   这之间的便是新日志              +
#  +                                   +
#  -------------------------------------
function count_loglines()
{
    wc -l ${logfilename} | awk '{print $1}'
}

# --------------------------------------------
# +                                          +
# +    里面的每个变量更新后都要重新更新 $msg +
# +                                          +
# --------------------------------------------
function update_mq_msg()
{
    msg="auditcontent=${md5key}&auditid=${auditid}&status=${status}&groupsendlim_flag=1&groupsendlim_userflag=0"
}


# --------------------------------------------
# +                                          +
# + 
function find_new_md5key()
{
    # 注意: sed 的时候不要把颜色显示相关的字符混进去了 ("\x1b[0m")
    ret=$(sed -n ''$startline','$endline's/.*redis proc cmd:HGETALL endgroupsendauditsms:\([0-9_a-zA-Z]\+\).*/\1/pg' $logfilename) 

    if [ -z "$ret" ]; then
        echo "Trying to find NEW MD5KEY from access_log ...."
    else
        echo "$ret"
    fi

}

#  ------------------------------------------
#  +                                        +
#  +   从 access_log 中过滤找到新的md5key   +
#  +                                        +
#  ------------------------------------------
function fetch_md5key_from_log()
{
    tries=0
    while true; do
        # 找到md5key不为空且符合 "日期_md5" 格式
        if [ ! -z "$md5key" ]; then
            ifmd5=$(echo "$md5key" | awk '/[0-9]+_[0-9a-zA-Z]+/')
            if [ ! -z "$ifmd5" ]; then
                break;
            else
                echo "$md5key" 
            fi
        fi

        # 否则多次尝试
        sleep 1

        endline=$(count_loglines)
        md5key=$(find_new_md5key)
        tries=$((tries+1))
        if [ $tries -gt 10 ]; then
            error_echo "Tries 10 times and not found new MD5Key. It must haven't experienced groupsend limit"
            exit
        fi
    done

    notice_echo "MD5KEY: $md5key"

    # md5key 更新了，同时要更新一下msg
    update_mq_msg
}

# --------------------------------------------
# +                                          +
# +   让用户选择是否要发布"审核结果消息"到MQ +
# +                                          +
# --------------------------------------------
function ask_for_fill_audit_result()
{
    notice_echo "Sent audit-result-msg[${AuditStatusName[$status]}] to MQ [$msg] ? "
    read -p "Sent or not [Y(y)/N]?" choice 

    if [ "$choice" == "Y" -o "$choice" == "y" ]; then
        publish_mq "$msg"
    else
        notice_echo "Sent audit-result-msg to MQ Canceled."
        exit 
    fi
}

# --------------------------------------------------------
# +                                                      +
# + 程序后面的操作由 keyword 参数标志，并给出 tip 的提示 +
# + @PARAM =>                                            +
# + @ keyword: keyword identifying what's going on       +
# + @ tip: if find keyword say what                      +
# --------------------------------------------------------
function check_whats_goingon()
{
    keyword=$1
    tip=$2

    endline=$(count_loglines)

    # 匹配关键字
    ret=$(awk 'NR>='"$startline"'&&NR<='"$endline" $logfilename | grep -rnw "$keyword")

    if [ ! -z "$ret" ]; then
        echo
        error_echo "$tip"
        echo "LOG: [$ret]"
        exit
    fi
}

# --------------------------------------------------------
# +                                                      +
# + 给出各种情况下的关键字，去找日志，然后提示           +
# + 注意：找到任意一种情况后会直接退出                   +
# +                                                      +
# --------------------------------------------------------
function see_whats_goingon()
{
    sleep 1

    check_whats_goingon "cmd:HGETALL endauditsms:.*" "Go AUDIT-AGAIN!!!!"

    check_whats_goingon "publish MQ.*audit_flag=1" "Go AUTO-PASS and Back to MQ!!!!!"

    check_whats_goingon "search in channelgroup" "Go SEND!!!!!"

    check_whats_goingon "errordesc=\"YX:7003\"" "Go TIMEOUT ERROR!!!!!"

    check_whats_goingon "HandlePublishMsg.*YX:7000\*auditnotpaas" "GO AUDIT-FAILED!!!!!"
}

# --------------------------------
# +                              +
# + 检查redis数据                +
# +                              +
# --------------------------------
function check_redis()
{
    # 看看缓存的 audit_detail 列表
    rediskey="audit_detail:${md5key}"
    title_echo "[2]. Checking  $rediskey ...."
    ret=$($rediscmd lrange "$rediskey" 0 -1)
    if [ -z "$ret" ]; 
    then
        error_echo "redis record [$rediskey] found!"
    else
        idx=0
        for i in $ret; do
            warn_echo "---> audit_detail[$idx]:"
            content_echo $i
            idx=$((idx+1))
        done
    fi

    # 查询 endgroupsendauditsms， 看看是否已审
    rediskey="endgroupsendauditsms:${md5key}"
    title_echo "[3]. Checking  $rediskey ===> "
    ret=$($rediscmd HGETALL $rediskey)
    # 已经有了 endgroupsendauditsms记录?
    if [ -z "$ret" ]; 
    then
        error_echo "redis record [$rediskey] not found!"
        ask_for_fill_audit_result
    else
        ret=$(echo "$ret" | tail -1)
        warn_echo "Find $redis=>status: [${EndgsauditsmsStatusName[$ret]}]"
    fi

    # 看看实际的处理是什么
    see_whats_goingon
}

function reset_test()
{
    # 此行数以后的内容作为本次请求产生的新日志
    # 数据都来源于此
    startline=$(count_loglines)
}

function init_param()
{
    # 使用总秒数作为auditid 
    auditid=$(date +"%s")
}

function dotest()
{
    #1. 新请求，重置相关参数 
    reset_test

    #2. 发送请求
    send_http_req

    #3. 从新日志中获取md5key
    fetch_md5key_from_log

    #4. 查询redis里的状态值决定下一步
    check_redis
}

init_param
dotest

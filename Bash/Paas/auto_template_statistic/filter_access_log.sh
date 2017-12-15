#!/bin/sh
#set -x

current_dir=$(cd `dirname $0`; pwd)

today=`date +"%Y%m%d"`
yestorday=$(date -d "1 day ago" +"%Y%m%d")
check_day=$yestorday

log_path=$current_dir/logs/
log_filename=filter_accesslog_${today}.log

# 定义日志文件后引用 util.sh
source $current_dir/util.sh

############################## 测试用配置 #############################
last_ip=52
remoteport=22
scp_timeout=120
remotepasswd="smsp123"
remote_path_to_upload=/opt/smsp/lijing/workspace/ScriptsDev/Script/auto_template_statistic/template_files_from_remote/
remotepath="smsp@172.16.5.52:$remote_path_to_upload"
access_log_file="/opt/smsp/lijing/smsp5.0/smsp_access/logs/smsp_access_${check_day}.log"
access_log_gz_file="${access_log_file}.gz"

tmp_errfile=/tmp/filter_access_tmp.err.out
############################# 正则相关 #########################

out_files_dir=${current_dir}/local_tempfiles/
if [ ! -d $out_files_dir ]; then
    log_info "Create $out_files_dir."
    mkdir $out_files_dir
fi
out_match_file_name=${out_files_dir}"/"${check_day}"_"${last_ip}"_matched.txt"
#### 此正则过滤日志中模板匹配成功的打印 ####
#[日期][时间].*Clientid[client_id], Content[content] or sign[sign] matched black-template.*temp-id:temp-id
match_pattern="^\[\([0-9-]\+\)\]\[\([0-9:]\+\)\].*Clientid\[\([0-9A-Za-z]\+\)\] Content\[\(.*\)\] SmsType\[\(.*\)\] Sign\[\(.*\)\] Match \(black\|white\)-template.*\[temp-id:\([0-9]\+\)\].*"
#[输出样例]: 89878|white|2017-12-01|16:37:40|b01221|0|天天篮球
match_output_format="\8|\7|\1|\2|\3|\5|\6"
#加上短信内容
#[输出样例]: 89878|white|2017-12-01|16:37:40|b01221|0|天天篮球|不要只想着打篮球,看电影
#match_output_format="\8|\7|\1|\2|\3|\5|\6|\4"

out_not_match_file_name=${out_files_dir}"/"${check_day}"_"${last_ip}"_not_match.txt"
#### 此正则过滤日志中未匹配上模板的打印 ######
#[日期][时间].*Clientid[client_id], Content[content] or sign[sign] NOT Matched any Auto-Black-Template
not_match_pattern="^\[\([0-9-]\+\)\]\[\([0-9:]\+\)\].*Clientid\[\([0-9A-Za-z]\+\)\] Content\[\(.*\)\] SmsType\[\(.*\)\] Sign\[\(.*\)\] NOT Matched any Auto-\(Black\|White\)-Template.*"
#[输出样例]: b01221| 不要只想着打篮球,看电影|0|天天篮球|Black|2017-12-01|16:39:33
not_match_output_format="\3|\4|\5|\6|\7|\1"
# 加上短信内容
#[输出样例]: b01221| 不要只想着打篮球,看电影|0|天天篮球|Black|2017-12-01|16:39:33|不要只想着打篮球
#not_match_output_format="\3|\4|\5|\6|\7|\1|\2"

############################# 业务函数 ###########################
function switch_to_online_setting()
{
    remote_path_to_upload=/home/chenlong/soft/auto_template/file/
    remotepath="root@10.10.202.22:$remote_path_to_upload"
    remotepasswd="ucpaas.com2017"

    last_ip=`ifconfig | grep "inet addr.*202" | grep -v 127 | awk '{print $2}' | awk -F"." '{print $4}'`
    access_log_file="/opt/paas/smsp5.0/smsp_access/logs/smsp_access_${check_day}.log"
    access_log_gz_file="${access_log_file}.gz"
    remoteport=60086
    scp_timeout=30
}

function do_pattern_filter()
{
    if [ $# -ne 3 ];then
        log_error "do_pattern_filter() needs pattern/output_format/outfile params."
        return -1
    fi
    pattern=$1
    output_format=$2
    outfile=$3

    rm -f $tmp_errfile

    if [ -f ${access_log_gz_file} ]
    then
        log_info "Filter from .gz file [${access_log_gz_file}]"
        zgrep --color ".*" ${access_log_gz_file}  2>$tmp_errfile | \ 
                    sed -n 's/'"$pattern"'/'"$output_format"'/pg' > ${outfile}
    else
        log_info "Filter from [${access_log_file}]"
        cat ${access_log_file} 2>$tmp_errfile |  \
                    sed -n 's/'"$pattern"'/'"$output_format"'/pg' > ${outfile} 
    fi

    # 用$tmp_errfile是否有内容来判断是否失败
    if [ -s $tmp_errfile ]; then
        error=$(cat $tmp_errfile)
        log_error "Filter log FAILED. Reason:[""$error""]"
        return 1
    fi
    log_info "Filter log SUCCESS."
    
    return 0
}

# 传送文件
function do_file_transfer()
{
    file_to_transfer=$1

    rm -f $tmp_errfile

    if [ -s ${file_to_transfer} ]
    then
        log_info "Do file transfer [$file_to_transfer].."

        base_file_name=$(basename $file_to_transfer)
        result=$(/usr/bin/expect $current_dir/scp_tempfiles.expect "$remotepath/$base_file_name" $remoteport $remotepasswd $file_to_transfer $scp_timeout )
        # 如果有100%标志则表明成功
        echo "$result" | grep -w "100%" 1>/dev/null 2>&1
        if [ $? -ne 0 ]; then
            log_error "File transfer [$file_to_transfer] FAILED. Reason:[$result]"
        else
            log_info "File transfer [$file_to_transfer] SUCC."
        fi
    fi
}

# 过滤模板相匹配
function do_not_match_handle()
{
    log_info "Filter NOT-MATCH log..."
    do_pattern_filter "$not_match_pattern" "$not_match_output_format" "$out_not_match_file_name"
    [ $? -ne 0 ] && log_error "Do not-match handle failed. Now exit." && exit -1
    do_file_transfer $out_not_match_file_name
}

# 过滤没有匹配上的
function do_match_handle()
{
    log_info "Filter MATCH log..."
    do_pattern_filter "$match_pattern" "$match_output_format" "$out_match_file_name"
    [ $? -ne 0 ] && log_error "Do match handle failed. Now exit." && exit -1
    do_file_transfer $out_match_file_name
}

log_info "=================> Filter access_log START <======================"
#switch_to_online_setting
#do_not_match_handle
do_match_handle
log_info "=================< Filter access_log END >======================"

#!/bin/sh
#set -x
sqlcmd='mysql -u common_user -pucpaas.com -h 172.16.5.41 -A --default-character-set=utf8 smsp_message_5.5'

###################################### 变量定义 #########################################
# 脚本所在根目录路径变量
current_dir=$(cd `dirname $0`; pwd)

# 日期变量
today=$(date +"%Y%m%d")
yestorday=$(date -d "1 day ago" +"%Y%m%d")

# 各机器过滤后的模板日志文件存放目录路径. 需要与filter_access_log.sh脚本中的scp传送路径一致
template_files_path=${current_dir}/template_files_from_remote/
# 指定模板日志文件的文件名
matched_file_pattern=${yestorday}_*_matched.txt

out_sql_dir=$current_dir/sql_files/
# 统计后生成每个模板的更新SQL语句,存放到该文件
out_sql_file=$out_sql_dir/template_statis_update_${yestorday}.sql

# 把各个机器传过来的文件处理后统一成一个
all_in_filename=$template_files_path/${yestorday}_all_match.txt

# 设定日志
log_path=$current_dir/logs/
log_filename=template_hitinfo_${today}.log

source $current_dir/util.sh

########################################### 功能函数 #################################
function sort_and_merge_and_statis()
{
    # 合并所有统计文件，并计数
    matched_files=$(ls $template_files_path/${matched_file_pattern})
    log_info "Handle filelist: [$matched_files]"

    # 输入->按template_id排序->统计个数->输出
    cat $matched_files | sort | uniq -c > $all_in_filename 

    [ $? -ne 0 ] && log_error "Merge and sort failed CMD:[cat $matched_files | sort | uniq -c > $all_in_filename]" && exit -1

    log_info "Merge and sort done..."
}

function gen_update_sql()
{
    if [ ! -d $out_sql_dir ]; then
        log_info "Create $out_sql_dir"
        mkdir $out_sql_dir
    fi
>$out_sql_file
    # $all_in_filename文件每一行格式:  1 89853|black|2017-12-01|16:40:08|b01221|0|天天篮球
    #                               个数 模板ID|类型|日期| 时间|用户id|SmsType|签名
    line_no=0
    handled_cnt=0
    while read cnt statis_info; do 
        line_no=$((line_no+1))

        # 信息为空，跳过
        if [ -z "$statis_info" ];then
            log_warn "DataLine[$line_no]'statis_info is empty. Ignore it."
            continue;
        fi
        # 如果域数目不对则置right_field为0，否则取前7个域，置right_field为1
        eval $(echo $statis_info |
        awk -F"|" '{
	        if(NF<7){
	            printf("right_field=0;");
	        }else{
	            printf("right_field=1;tempid=%s; tempbustype=%s;match_date=%s;match_time=%s;clientid=%s;smstype=%s;sign=%s;",
	                                   $1,              $2,           $3,           $4,          $5,        $6,     $7)
	        }
	      }'
            )
        # 域数目不对，跳过
        if [ $right_field -eq 0 ];then
            log_warn "DataLine[$line_no=>$statis_info]'field no is < 7. Ignore it"
            continue;
        fi

        tbl_name=""
        # 根据日志中的模板业务类型，分别更新相应的表
        if [ "$tempbustype" == "white" ]; then
            tbl_name="t_sms_auto_template"
        elif [ "$tempbustype" == "black" ]; then
            tbl_name="t_sms_auto_black_template"
        else
            # tempbustype不合法，跳过
            log_warn "DataLine[$line_no=>$statis_info] has invalid template-bus-type[$tempbustype]"
            continue
        fi
        match_full_time="$match_date $match_time"

        # 组装SQL语句
        echo "UPDATE $tbl_name SET lately_match_date='$match_full_time',lately_match_amount=$cnt,match_amount=match_amount+$cnt WHERE template_id=$tempid;" >> $out_sql_file

        # 计数加1 
        handled_cnt=$((handled_cnt+1))

    done < $all_in_filename

    log_info "SQL file done. Handled $handled_cnt/$line_no template_ids."
}

# 执行SQL语句
function execute_sql()
{
    tmp_file=/tmp/hitinfo_sql.err.out
    log_info "Now execute sql file."
    cat $out_sql_file | $sqlcmd 2>$tmp_file
    if [ $? -ne 0 ]; then
        error=$(cat $tmp_file)
        log_error "SQL execute Failed. Reason:[""$error""]"
        return
    fi
    log_info "SQL execute SUCC."
}

log_info "===========================> Start template HIT Info statistic <======================="
sort_and_merge_and_statis
gen_update_sql
execute_sql
log_info "===========================> template HIT Info statistic Finished <======================="

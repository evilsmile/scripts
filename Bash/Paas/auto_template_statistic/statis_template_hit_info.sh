#!/bin/sh
#set -x
sqlcmd='mysql -u common_user -pucpaas.com -h 172.16.5.41 -A --default-character-set=utf8 smsp_message_5.5'

###################################### �������� #########################################
# �ű����ڸ�Ŀ¼·������
current_dir=$(cd `dirname $0`; pwd)

# ���ڱ���
today=$(date +"%Y%m%d")
yestorday=$(date -d "1 day ago" +"%Y%m%d")

# ���������˺��ģ����־�ļ����Ŀ¼·��. ��Ҫ��filter_access_log.sh�ű��е�scp����·��һ��
template_files_path=${current_dir}/template_files_from_remote/
# ָ��ģ����־�ļ����ļ���
matched_file_pattern=${yestorday}_*_matched.txt

out_sql_dir=$current_dir/sql_files/
# ͳ�ƺ�����ÿ��ģ��ĸ���SQL���,��ŵ����ļ�
out_sql_file=$out_sql_dir/template_statis_update_${yestorday}.sql

# �Ѹ����������������ļ������ͳһ��һ��
all_in_filename=$template_files_path/${yestorday}_all_match.txt

# �趨��־
log_path=$current_dir/logs/
log_filename=template_hitinfo_${today}.log

source $current_dir/util.sh

########################################### ���ܺ��� #################################
function sort_and_merge_and_statis()
{
    # �ϲ�����ͳ���ļ���������
    matched_files=$(ls $template_files_path/${matched_file_pattern})
    log_info "Handle filelist: [$matched_files]"

    # ����->��template_id����->ͳ�Ƹ���->���
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
    # $all_in_filename�ļ�ÿһ�и�ʽ:  1 89853|black|2017-12-01|16:40:08|b01221|0|��������
    #                               ���� ģ��ID|����|����| ʱ��|�û�id|SmsType|ǩ��
    line_no=0
    handled_cnt=0
    while read cnt statis_info; do 
        line_no=$((line_no+1))

        # ��ϢΪ�գ�����
        if [ -z "$statis_info" ];then
            log_warn "DataLine[$line_no]'statis_info is empty. Ignore it."
            continue;
        fi
        # �������Ŀ��������right_fieldΪ0������ȡǰ7������right_fieldΪ1
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
        # ����Ŀ���ԣ�����
        if [ $right_field -eq 0 ];then
            log_warn "DataLine[$line_no=>$statis_info]'field no is < 7. Ignore it"
            continue;
        fi

        tbl_name=""
        # ������־�е�ģ��ҵ�����ͣ��ֱ������Ӧ�ı�
        if [ "$tempbustype" == "white" ]; then
            tbl_name="t_sms_auto_template"
        elif [ "$tempbustype" == "black" ]; then
            tbl_name="t_sms_auto_black_template"
        else
            # tempbustype���Ϸ�������
            log_warn "DataLine[$line_no=>$statis_info] has invalid template-bus-type[$tempbustype]"
            continue
        fi
        match_full_time="$match_date $match_time"

        # ��װSQL���
        echo "UPDATE $tbl_name SET lately_match_date='$match_full_time',lately_match_amount=$cnt,match_amount=match_amount+$cnt WHERE template_id=$tempid;" >> $out_sql_file

        # ������1 
        handled_cnt=$((handled_cnt+1))

    done < $all_in_filename

    log_info "SQL file done. Handled $handled_cnt/$line_no template_ids."
}

# ִ��SQL���
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

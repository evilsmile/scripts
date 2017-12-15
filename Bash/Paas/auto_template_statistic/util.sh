###################################### ÈÕÖ¾º¯Êý ######################################

function log_warn()
{
    log_msg=$1
    log "WARN" "$log_msg"
}
function log_error()
{
    log_msg=$1
    log "ERROR" "$log_msg"
}
function log_info()
{
    log_msg=$1
    log "INFO" "$log_msg"
}
function log()
{
    if [ -z "$log_filename" ]; then
        echo "empty log file name!"
        return
    fi

    local log_full_filename=$log_path/$log_filename

    if [ ! -d $log_path ]; then
        echo "Create dir $log_path"
        mkdir -p $log_path
    fi

    log_type="$1"
    log_msg="$2"
    ns_now=$(date +"%Y%m%d %H:%M:%S.%N")
    echo "[$ns_now][$log_type] $log_msg" >> $log_full_filename
}

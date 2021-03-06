 #!/bin/bash
 log_dir=/data/log
 
 day=$(date +"%Y%m%d")
 if [ $# -gt 0 ] ;then
     day=$1
 fi
 
 log_file=$log_dir/tfb_qqwallet_channel_service.log_${day}
 key_word=strUrl
 #log_file=$log_dir/tfb_gateway.log_${day}
 #key_word=MQQBrowser
 
 f1=qqwallet_req_${day}.list
 f2=qqwallet_req_duration_${day}.list
 
 grep --color=never -rnw  $key_word  $log_file | grep --color=never -w pay > $f1
 
 while read line; do
 #   echo $line
     # 找到发起请求的一行，找出行号，开始时线程号
     eval $(echo "$line" | awk -F"[]: .[]" '{start_seconds=$4*3600+$5*60+$6;printf("line_no=%s;start_seconds=%d;thread=%s", $1,start_seconds,$17)}')
     # 以线程号为线索往line_no之后找通道返回日志，并计算出返回的秒数，算出所耗的中间时�??
     eval $(awk -F"[]: .[]" '{
             if (NR>'$line_no' && $0~/.*'$thread'.*Back/) { 
                  end_seconds=$3*3600+$4*60+$5;
                  duration=end_seconds-'$start_seconds';
                  printf("duration=%d", duration);
                  exit;
             }
         }' $log_file)
     echo $duration
 
 done < $f1 | tee $f2


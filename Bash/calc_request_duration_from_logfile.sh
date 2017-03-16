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
     # ÕÒµ½·¢ÆðÇëÇóµÄÒ»ÐÐ£¬ÕÒ³öÐÐºÅ£¬¿ªÊ¼Ê±Ïß³ÌºÅ
     eval $(echo "$line" | awk -F"[]: .[]" '{start_seconds=$4*3600+$5*60+$6;printf("line_no=%s;start_seconds=%d;thread=%s", $1,start_seconds,$17)}')
     # ÒÔÏß³ÌºÅÎªÏßË÷Íùline_noÖ®ºóÕÒÍ¨µÀ·µ»ØÈÕÖ¾£¬²¢¼ÆËã³ö·µ»ØµÄÃëÊý£¬Ëã³öËùºÄµÄÖÐ¼äÊ±é??
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


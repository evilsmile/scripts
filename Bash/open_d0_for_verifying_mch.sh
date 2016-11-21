#!/bin/bash

xsql_cmd="mysql -u "

eval $(echo $mch_id | awk '{mn=$1%100;m=mn/10;n=mn%10;printf("m=%d;n=%d", m, n);}')

for m in {0..9}; do
	for n in {0..9}; do
		#查询出所有在审核中的商户号
		sql="SELECT mch_id FROM db.tb_merchant_$m$n WHERE d0_flag=2"

		mch_id_list=$($xsql_cmd -N -B -e "$sql")
		if [ "x$mch_id_list" != "x" ]; then
			echo "$mch_id_list" | while read mch_id ; do
				echo $mch_id
				#开通分表
				sql="UPDATE db.tb_merchant_$m$n SET d0_flag=1 WHERE mch_id='$mch_id'"
				$xsql_cmd -e "$sql"

				#开通总表
				sql="UPDATE db.tb_merchant SET d0_flag=1 WHERE mch_id='$mch_id'"
				$xsql_cmd -e "$sql"
			done
		fi
	done
done


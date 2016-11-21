#!/bin/bash

xsql_cmd="mysql "

if [ ! $# -eq 1 ]; then
	echo "Usage: phone_num"
	exit -1	
fi

phone=""
mch_id=""
m=-1
n=-1

var=$1

function update_index()
{
	local var=$1
	eval $(echo $var | awk '{mn=$1%100;m=mn/10;n=mn%10;printf("m=%d;n=%d", m, n);}')
}

arg_len=${#var}

if [ $arg_len -eq 11 ]; then
	phone=$var
elif [ $arg_len -eq 15 ]; then
	mch_id=$var
fi

if [ "x$mch_id" == "x" ]; then
	update_index $phone

	sql="SELECT merchant_id FROM db.tb_merchant_mobile_$m$n WHERE Fmobile='$phone'"
	mch_id=$($xsql_cmd -N -B -e "$sql")
fi

echo -n $mch_id

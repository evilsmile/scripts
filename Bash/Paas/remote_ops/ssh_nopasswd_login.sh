#!/bin/bash

ATOMOP_DIR=atom_ops/
CONFIG_FILE=config/host_ip.list

local_ip=$(ifconfig eth1 | grep "inet addr" | sed 's/.*inet addr:\([0-9\.]\+\).*/\1/g')

function scp_id_rsa()
{
    local user=$1
    local passwd=$2
    local host_ip=$3
    local filename=/home/lijing/.ssh/id_rsa.pub
    local remote_path=/home/lijing/.ssh/

    # try mkdir .ssh/
    $ATOMOP_DIR/exe_remote.exp $host_ip $user $passwd "mkdir $remote_path"
    # try create authorized_keys file
    $ATOMOP_DIR/exe_remote.exp $host_ip $user $passwd "touch $remote_path/authorized_keys"
    # copy local id_rsa file to remote
    $ATOMOP_DIR/copy_to_remte.exp $host_ip $user $passwd $filename $remote_path
    # copy content from id_rsa.pub to authorized_keys
    $ATOMOP_DIR/exe_remote.exp $host_ip $user $passwd "cat $filename >> $remote_path/authorized_keys"
}

while read host_ip user passwd components; do
	echo "handling $host_ip ..."
	if [ "${host_ip:0:1}" == "#" ]; then
		echo "ignore $host_ip";
		continue;
	elif [ "$host_ip" == "$local_ip" ]; then
                echo "ignore localip $host_ip"
		continue
	fi

        scp_id_rsa  $user $passwd $host_ip
done < $CONFIG_FILE

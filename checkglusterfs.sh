#!/bin/bash

#check glusterfs-client install or not when glusterfs=true in config.yaml

CONFIG_DIR=$INSTALL_PATH
#CONFIG_DIR="/opt/ibm-cloud-private-2.1.0/cluster"
CONFIG_FILENAME="config.yaml"

checkGlusterFS() {
. util.sh

glusterfs=$(cat $CONFIG_DIR/config.yaml|grep glusterfs:|awk '{print $3}')

if [ -f $glusterfs ]; then
	if [[ $glusterfs=*"true"* ]]; then
		check_glusterfs_client
	fi
else
	print_passed_message "glusterfs parameter is not defined."
fi
}

check_glusterfs_client() { 
local os=$(get_os_version)
echo "Your OS is $os"
echo
local hostname=$(hostname)
if [[ $os = *"Red"* ]]; then
        glusterfsclient=$(yum list installed | grep glusterfs-client)
        if [ -z "$glusterfsclient" ]; then
		print_failed_message "Please install glusterfs-client, yum install -y glusterfs-client"                
        else
		print_passed_message "glusterfs-client installed on host $hostname"
        fi
	
else
        glusterfsclient=$(apt list --installed|grep glusterfs-client)
        if [ -z $glusterfsclient ]; then
		print_failed_message "Please install glusterfs-client, apt-get install -y glusterfs-client"
        else
		print_passed_message "glusterfs-client installed on host $hostname"
	fi
fi


}

get_os_version() {
	if [ -s "/etc/redhat-release" ]; then
		#redhat
                os_version=$(cat /etc/redhat-release)
		if [ $? -eq 0 ]; then
                        echo $os_version
                return

                fi	
	else
		# ubuntu
                os_version=$(lsb_release -a 2>/dev/null)
                if [ $? -eq 0 ]; then
                        os_version=$(echo $os_version | grep "Description:" | awk '{print $2,$3}')
                        echo $os_version
                return
                fi
	fi
}

checkGlusterFS


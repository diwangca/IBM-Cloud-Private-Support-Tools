#!/bin/bash

HOSTS_FILENAME="hosts"
CONFIG_DIR=$INSTALL_PATH

cleanup_hosts() {
	if [[ -d /etc/cfc ]]; then
  		echo "Removing folder /etc/cfc" 
  	rm -rf /etc/cfc
	fi

	if [[ -d /var/lib/kubelet ]]; then
		echo "Removing folder /var/lib/kubelet" 
		rm /var/lib/kubelet
	fi

	if [[ -d /opt/kubernetes ]]; then
		echo Removing folder /opt/kubernetes 
		rm -rf /opt/kubernetes
	fi

	# Remove all the containers
	echo
	echo remove all the containers
	docker rm $(docker ps -aq)

	sleep 5

	# Remove all the existing images
	echo remove all the images
	docker rmi $(docker images -q)
	sleep 5

	echo "restarting docker"
	systemctl restart docker

# Cleanup glusterfs - not implemented yet
#echo rm -rf /var/lib/heketi
#echo rm -rf /var/lib/glusterd
#echo wipefs --all --force /dev/sdb
#echo /sbin/dmsetup remove_all
}

read -p " Press Y to continue, Any other key to quit: " useragree

if [[ $useragree == "Y" ]]; then
	echo "Start Cleaning..."
	cleanup_hosts
else
	echo "Thanks and quiting..."
fi

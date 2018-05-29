#!/bin/bash
#run only on master nodes


# find out version being installed
PRODUCT_VERSION="2.1.0.0"
RELEASE_DATE="Dec 2017"

setup() {
    . $UTIL_DIR/util.sh
    #commonly used func are inside of util.sh
    CONFIG_DIR=$INSTALL_PATH

    TEMP_DIR=$OUTPUT_DIR	
    PRE_STR=$(get_prefix)

    LOG_FILE="/tmp/icp_checker.log"
    echo
    echo =============================================================
    echo
    echo Running ICP Checker in Log Collector mode ...
    echo ICP Version: $PRODUCT_VERSION
    echo Release Date: $RELEASE_DATE
    echo =============================================================
}

log_collector() {
    local temp_dir=$1
	echo
        echo Collecting os information...
        echo ------------------------
	get_log_by_cmd $temp_dir os_info "uname -a"

	echo
	echo Collecting mem info...
        echo ------------------------
	get_log_by_cmd $temp_dir mem_info "cat /proc/meminfo"

	echo
	echo Collecting docker images info...
        echo ------------------------
	get_log_by_cmd $temp_dir docker_images "docker images" 

	echo
	echo Collecting docker status...
        echo ------------------------
	get_log_by_cmd $temp_dir docker_status "systemctl status docker"
	
	echo
	echo Collecting docker log...
        echo ------------------------
	get_log_by_cmd $temp_dir docker_log "journalctl -u docker"	
	
	echo
	echo Collecting kubelet config...
        echo ------------------------
	get_log_by_cmd $temp_dir kubelet_config "cat /var/lib/kubelet/kubelet-config"	

	echo
	echo Collecting kubelet status...
        echo ------------------------
	get_log_by_cmd $temp_dir kubelet_status "systemctl status kubelet"
	
	echo
	echo Collecting kubelet log...
	echo ------------------------
	get_log_by_cmd $temp_dir kubelet_log "journalctl -u kubelet"
	
	echo
	echo Collecting k8s_apiserver_k8s-master log...
	echo ------------------------
	get_container_log_by_name $temp_dir "k8s_apiserver_k8s-master"
	
	echo
	echo Collecting k8s_controller-manager_k8s-master log...
	echo ------------------------
	get_container_log_by_name $temp_dir "k8s_controller-manager_k8s-master"
	
	echo 
	echo Collecting k8s_scheduler_k8s-master log...
        echo ------------------------
	get_container_log_by_name $temp_dir "k8s_scheduler_k8s-master"
	echo
        	

	echo Collecting k8s_calico-node log...
	echo ------------------------
	get_container_log_by_name $temp_dir "k8s_calico-node"
	
	echo
	echo Collecting catalog cotroller manager log...
	echo ------------------------
	get_container_log_by_name $temp_dir "k8s_controller-manager_catalog" 

	echo
	echo Collecting catalog api server log...
	echo ------------------------
	get_container_log_by_name $temp_dir "k8s_apiserver_catalog-catalog"

	echo 
	echo Collecting catalog ui log...
	echo ------------------------
	get_container_log_by_name $temp_dir "k8s_catalog-ui_catalog-ui"

	echo
	echo Collecting helm api log...
        echo ------------------------
        get_container_log_by_name $temp_dir "k8s_helmapi_helm-api"

	echo
        echo Collecting icp-ds-0 log...
        echo ------------------------
        get_container_log_by_name $temp_dir "k8s_icp-ds_icp-ds-0"

	echo
        echo Collecting etcd log...
        echo ------------------------
        get_container_log_by_name $temp_dir "k8s_etcd_k8s-etcd"

	echo
        echo Collecting mariadb log...
        echo ------------------------
        get_container_log_by_name $temp_dir "k8s_mariadb_k8s-mariadb"
	
	echo 
	echo Collecting mariadb-monitor log...
	echo ------------------------
	get_container_log_by_name $temp_dir "k8s_mariadb-monitor"

	echo
        echo Collecting proxy log...
        echo ------------------------
        get_container_log_by_name $temp_dir "k8s_proxy_k8s-proxy"

	echo
        echo Collecting platform api log...
        echo ------------------------
        get_container_log_by_name $temp_dir "k8s_platform-api_platform-api"

	echo
        echo Collecting platform ui log...
        echo ------------------------
        get_container_log_by_name $temp_dir "k8s_platform-ui_platform-ui"


}


check_log_file_exist() {
	local log_file=$1
	local name=$2
	if [ -f $log_file ]; then
                print_passed_message "$name collected: $log_file"
        else
                print_failed_message "failed to collect $name"
        fi
}

get_log_by_cmd(){
	local temp_dir=$1
	local name=$2
	local cmd=$3
	local log_file=$temp_dir"/$name"
	$cmd > $log_file
	check_log_file_exist $log_file $name
}



get_container_log_by_name() {
    local temp_dir=$1
    local container_name=$2
    local log_file=$temp_dir"/"$container_name".log"
    local container_id=$(docker ps |grep $container_name|awk '{print $1}')
    docker logs $container_id >$log_file 2>&1
    
    if [ -f $log_file ]; then
        print_passed_message "$container_name log generated $log_file"
    else
        print_failed_message "failed to generate $container_name log:"
    fi
}


setup
sanity_checks
log_collector $TEMP_DIR




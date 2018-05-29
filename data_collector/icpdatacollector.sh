#!/bin/bash

collect_icp_image_versions() {
    LOG_FILE=$1
    echo Collecting docker image versions...
    docker images|grep icp 2>&1 > $LOG_FILE
    rc=$?
    if [ $rc -ne 0 ]; then
        print_failed_message "Could not get version of icp images, return code: $rc"
    fi
}

collect_env_data() {
    LOG_FILE=$1
    echo Collecting OS version ...
    touch $LOG_FILE
    get_os_version > $LOG_FILE

    # ubuntu logs for kubelet
    echo Collecting system logs for kubelet service ...
    journalctl -r -u kubelet >> $LOG_FILE
}

collect_icp_configuration() {
    local config_dir=$1
    local output_dir=$2
    local pre_str=$3
    tar czvf $output_dir/$pre_str"_icpconfig.tar.gz" $config_dir/config.yaml $config_dir/hosts 2>&1 >/dev/null
}

collect_k8s_data() {
    echo Collecting Kubernetes data...
    local log_file=$1
    kubectl -n kube-system get pods -o wide > $log_file 2>/dev/null
    #kubectl -n kube-system describe pods [any pod shown in an error state from above]
    # kubectl -n kube-system logs pods [any pod shown in an error state from above] --container [once for each container within the pod]
}

setup() {
    . $UTIL_DIR/util.sh

    TEMP_DIR=$(get_temp_dir)
    OUTPUT_DIR=$(get_temp_dir)
    PRE_STR=$(get_prefix)
}

collect_all() {
    local temp_dir=$1
    local pre_str=$2
    collect_icp_image_versions $temp_dir"/"$pre_str"_versions"
    collect_env_data $temp_dir"/"$pre_str"-host-env"
    collect_k8s_data $temp_dir"/k8s"
}

setup $@
collect_all $TEMP_DIR $PRE_STR
echo Building data archive...
archive_file="data-"$PRE_STR".tar.gz"
build_archive $OUTPUT_DIR $archive_file $TEMP_DIR 
echo Cleaning up temporary directory $TEMP_DIR
clean_up $TEMP_DIR
echo Done.
echo
echo Please attach the file $OUTPUT_DIR"/"$archive_file to report an issue.


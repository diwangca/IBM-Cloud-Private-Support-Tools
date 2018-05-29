#!/bin/bash

print_usage() {
    echo Usage: $($0) product-version cluster-dir
    echo Returns
    echo 0: all check passed.
    echo 1: one or more checks failed.
    echo 2: one or more checks failed, no more requirements should be checked.
}

build_message() {
    echo "Critical Pod: "$1": status: "$2
}

get_pod_status_with_name() {
    pod_name=$1
    status=$(curl http://127.0.0.1:8888/api/v1/pods 2>/dev/null | grep -A 200 -e '"name": "'$pod_name | grep phase |awk '{print $2}' | tr -d '",')
    echo $status
}

verify_pod_with_name() {
    pod_name=$1
    pod_status=$(get_pod_status_with_name $pod_name)
    message=$(build_message $pod_name $pod_status)
    if [[ $pod_status = "Running" ]]; then
        print_passed_message "$message"
    else
        print_failed_message "$message"
    fi
}

verify_key_pods() {
    declare -a critical_pods=("k8s-master" "k8s-etcd" "k8s-proxy" "k8s-mariadb")
    len=${#critical_pods[@]}
    for (( i=1; i<${len}+1; i++ )); do
        verify_pod_with_name ${critical_pods[$i-1]}
    done
}

setup() {
    echo
    echo 4. Checking the Status of Critical ICP Pods and Docker Containers...
    echo --------------------------------------------------------------------
    # sanity checks
    VERSIONS_FILE="./versions"

    if [ ! -f $VERSIONS_FILE ]; then
        echo expected file $VERSIONS_FILE to be present under current directory.
        exit 1
    fi

    # obtain product version and cluster directory
    PRODUCT_VERSION=""
    CLUSTER_DIR=""

    if [[ $# < 2 ]]; then
        print_usage
        exit 1
    fi

    PRODUCT_VERSION=$1
    if [ -z $PRODUCT_VERSION ]; then
        echo "invalid (empty) product version"
        exit 1
    fi

    grep -w $PRODUCT_VERSION $VERSIONS_FILE > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo could not find version "$PRODUCT_VERSION" in $VERSIONS_FILE
        exit 1
    fi
}

setup $@
verify_key_pods $@

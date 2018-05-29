#!/bin/bash

print_usage() {
    echo Usage: $($0) product-version cluster-dir
    echo Returns
    echo 0: all check passed.
    echo 1: one or more checks failed.
    echo 2: one or more checks failed, no more requirements should be checked.
}

get_icp_docker_containers_count() {
    count=$(docker ps |grep ibmcom|grep k8s| wc -l)
    echo $count
}

verify_icp_calico_containers() {
    cni=$(docker ps |grep ibmcom|grep k8s|grep calico\-cni |grep Up|wc -l)
    if [ $cni -eq 1 ]; then
        print_passed_message "Calico-cni container is running:"
    else
        print_failed_message "Calico-cni container Not running:"
    fi

    node=$(docker ps |grep 'ibmcom/calico\-node'|grep k8s|grep Up|wc -l)
    if [ $node -eq 1 ]; then
        print_passed_message "Calico-node container is running:"
    else
        print_failed_message "Calico-node container Not running:"
    fi
}

setup() {
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

check_docker_containers() {
    all=$(get_icp_docker_containers_count)
    EXPECTED_NUM=$(grep -w $PRODUCT_VERSION $VERSIONS_FILE | awk '{print $2}')
    if [[ $all -eq $EXPECTED_NUM ]]; then
        print_passed_message "Total ICP Containers Running: $all"
    else
        print_failed_message "Total ICP Containers Running: $all, expected $EXPECTED_NUM"
    fi
}

setup $@
check_docker_containers $@
verify_icp_calico_containers $@

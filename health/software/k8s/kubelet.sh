#!/bin/bash

HYPERKUBE_PATH="/opt/kubernetes/hyperkube"

print_usage() {
    echo Usage: $($0) product-version cluster-dir
    echo Returns
    echo 0: all check passed.
    echo 1: one or more checks failed.
    echo 2: one or more checks failed, no more requirements should be checked.
}

verify_hyperkube_exists() {
    if [ -f $HYPERKUBE_PATH ]; then
        echo -e Hyperkube installed at $HYPERKUBE_PATH ${COLOR_GREEN}\[OK\]${COLOR_NC}
        return 0
    else
        echo -e Hyperkube expected but not found at $HYPERKUBE_PATH ${COLOR_RED}\[FAILED\]${COLOR_NC}
        return 1
    fi
}

get_kubelet_version() {
    kubelet_version=$($HYPERKUBE_PATH kubelet --version 2>&1 | grep Kubernetes | awk '{print $2}')
    echo $kubelet_version
}

setup() {
    # output colors
    COLOR_RED='\033[0;31m'
    COLOR_GREEN='\033[0;32m'
    COLOR_NC='\033[0m' # No Color

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

check_kubelet_version() {
    kubelet_version=$(get_kubelet_version)
    VERSIONS_STR=$(grep -w $PRODUCT_VERSION $VERSIONS_FILE | awk '{print $2}')
    SUPPORTED_VERSIONS=$( echo $VERSIONS_STR | tr ',' '\n' )
    for version in $SUPPORTED_VERSIONS; do
        if [[ $kubelet_version =~ $version ]]; then
            echo -e kubelet: you are running kubelet version $kubelet_version ${COLOR_GREEN}\[OK\]${COLOR_NC} 
            exit 0
        fi
    done
    # no match found, docker server version not supported
    echo -e kubelet: you are running kubelet version $kubelet_version ${COLOR_RED}\[FAILED\]${COLOR_NC}, required either of: $VERSIONS_STR
    exit 1
}

setup $@
verify_hyperkube_exists $@
if [ $? -eq 0 ]; then
    check_kubelet_version $@
fi


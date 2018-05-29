#!/bin/bash

print_usage() {
    echo Usage: $($0) product-version cluster-dir
    echo Returns
    echo 0: all check passed.
    echo 1: one or more checks failed.
    echo 2: one or more checks failed, no more requirements should be checked.
}

check_port_availability() {
    port=$1
    purpose=$2
    in_use_ports=$(netstat -tupln |awk '{print $4}'|cut -d ':' -f 2)
    echo $in_use_ports | grep $port  > /dev/null
    if [ $? -eq 0 ]; then
        echo -e Port $port required for $purpose is not available ${COLOR_RED}\[FAILED\]${COLOR_NC}
    else
        echo -e Port $port required for $purpose is available ${COLOR_GREEN}\[OK\]${COLOR_NC}
    fi
}

verify_required_ports_open() {
    for item in $(grep -w $PRODUCT_VERSION $VERSIONS_FILE | awk '{print $2}'); do
        port=$(echo $item | cut -d ';' -f 1)
        purpose=$(echo $item | cut -d ';' -f 2)
        check_port_availability $port $purpose
    done
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

setup $@
verify_required_ports_open $@


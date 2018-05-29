#!/bin/bash

# CPU checker

print_usage() {
    echo Usage: $($0) product-version cluster-dir
    echo Returns
    echo 0: all check passed.
    echo 1: one or more checks failed.
    echo 2: one or more checks failed, no more requirements should be checked.
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

    if [ -d $2 ]; then
        CLUSTER_DIR=$2
    else
        echo expected $2 to be the path to cluster directory, but it does not exist
        exit 1
    fi

}

get_number_of_cores() {
    cores_count=$(grep processor /proc/cpuinfo | wc -l)
    echo $cores_count
}

check_cpu_requirements() {
    REQ_CORES=$(grep -w $PRODUCT_VERSION $VERSIONS_FILE | awk '{print $2}')
    num_cores=$(get_number_of_cores)

    NUM_RE='^[0-9]+$'
    if ! [[ $num_cores =~ $NUM_RE ]]; then
        echo "Error: unexpected format: $num_cores is not a number"
        exit 1
    fi

    if ! [[ $REQ_CORES =~ $NUM_RE ]]; then
        echo "Error: unexpected format: $REQ_CORES is not a number"
        exit 1
    fi

    if [[ $num_cores -ge $REQ_CORES ]]; then
        echo -e CPU: number of CPU cores: $num_cores, required: $REQ_CORES ${COLOR_GREEN}\[OK\]${COLOR_NC}
        exit 0
    else
        echo -e CPU: number of CPU cores: $num_cores, required: $REQ_CORES ${COLOR_RED}\[FAILED\]${COLOR_NC}
        exit 1
    fi
}

setup $@
check_cpu_requirements $@



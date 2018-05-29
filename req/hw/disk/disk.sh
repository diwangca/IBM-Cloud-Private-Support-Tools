#!/bin/bash

# Disk checker

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

get_free_disk_space() {
    space=$(df -BG $CLUSTER_DIR | awk '{print $4}' |tail -n 1|tr -d 'G')
    echo $space
}

check_disk_requirements() {
    REQ_SPACE=$(grep -w $PRODUCT_VERSION $VERSIONS_FILE | awk '{print $2}')
    avail_space=$(get_free_disk_space)

    NUM_RE='^[0-9]+$'
    if ! [[ $avail_space =~ $NUM_RE ]]; then
        echo "Error: unexpected format: $num_cores is not a number"
        exit 1
    fi

    if ! [[ $REQ_SPACE =~ $NUM_RE ]]; then
        echo "Error: unexpected format: $REQ_SPACE is not a number"
        exit 1
    fi

    if [[ $avail_space -ge $REQ_SPACE ]]; then
        echo -e Disk: available space: $avail_space G, required: $REQ_SPACE G${COLOR_GREEN}\[OK\]${COLOR_NC}
        exit 0
    else
        echo -e Disk: available space: $avail_space G, required: $REQ_SPACE G${COLOR_RED}\[FAILED\]${COLOR_NC}
        exit 1
    fi
}

setup $@
check_disk_requirements $@



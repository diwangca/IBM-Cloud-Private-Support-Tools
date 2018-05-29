#!/bin/bash

print_usage() {
    echo Usage: $($0) product-version cluster-dir
    echo Returns
    echo 0: all check passed.
    echo 1: one or more checks failed.
    echo 2: one or more checks failed, no more requirements should be checked.
}

get_docker_server_version() {
    server_version=$(docker version |grep -A 1 Server: |grep Version: | awk '{print $2}')
    echo $server_version
}

setup() {
    export OUTPUT_FILE=$OUTPUT_DIR"/log.txt"

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

    touch $OUTPUT_FILE
}

check_docker_server_version() {
    server_version=$(get_docker_server_version)
    VERSIONS_STR=$(grep -w $PRODUCT_VERSION $VERSIONS_FILE | awk '{print $2}')
    SUPPORTED_VERSIONS=$( echo $VERSIONS_STR | tr ',' '\n' )
    for version in $SUPPORTED_VERSIONS; do
        if [[ $server_version =~ $version ]]; then
            echo -e Docker: you are running docker version $server_version ${COLOR_GREEN}\[OK\]${COLOR_NC} >> $OUTPUT_FILE
            exit 0
        fi
    done
    # no match found, docker server version not supported
    echo -e Docker: you are running docker version $server_version ${COLOR_RED}\[FAILED\]${COLOR_NC}, required either of: $VERSIONS_STR >> $
    exit 1
}

setup $@
check_docker_server_version $@


#!/bin/bash

print_usage() {
    echo Usage: $($0) product-version cluster-dir
    echo Returns
    echo 0: all check passed.
    echo 1: one or more checks failed.
    echo 2: one or more checks failed, no more requirements should be checked.
}

check_platform_version() {
    echo Platform: $(get_platform)
}

check_os_version() {
    # echo Checking OS version ... 
    os_version=$(get_os_version)
    # echo You are running $os_version 
    SUPPORTED_VERSIONS=$(grep -w $PRODUCT_VERSION $VERSIONS_FILE | awk -F '"' '{print $2}')
    # printf '%s\n' "$SUPPORTED_VERSIONS" | while IFS= read -r version; do
    # for version in $(read -r $); do
    #IFS=$'\n' for version in $SUPPORTED_VERSIONS; do
    while read -r version; do
        if [[ $os_version =~ $version ]]; then
            echo -e OS: running $version ${COLOR_GREEN}\[OK\]${COLOR_NC}
            return 0
        fi
    done <<< "$SUPPORTED_VERSIONS"

    echo -e OS: running $os_version ${COLOR_RED}\[FAILED\]${COLOR_NC}
    return 1
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
check_platform_version $@
check_os_version $@
exit $?


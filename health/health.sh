#!/bin/bash

# find out version being installed
PRODUCT_VERSION="2.1.0.0"
RELEASE_DATE="Dec 2017"

# find cluster directory
CONFIG_FILENAME="config.yaml"
HOSTS_FILENAME="hosts"
CONFIG_DIR=$INSTALL_PATH
OUTPUT_DIR=$OUTPUT_DIR

HEALTH_DIRS=("hw" "software" "pods" "containers")

setup() {
    . $UTIL_DIR/util.sh

    LOG_FILE="/tmp/icp_checker.log"
    echo
    echo =============================================================
    echo
    echo Running ICP Checker in Health Check mode ...
    echo ICP Version: $PRODUCT_VERSION
    echo Release Date: $RELEASE_DATE
    echo =============================================================
}

verify_execution_host_is_master() {
    MASTER_IP=$(grep -A 1 -i '^\[master\]' $HOSTS_FILE | tail -n 1) 
    host_ips=$(ip addr show | grep inet | awk '{print $2}' | tr '/' ' ')
    grep $MASTER_IP <<< $host_ips >/dev/null
    if [[ $? = 0 ]]; then
        print_passed_message "Running on a master node"
    else
        print_failed_message "Running on a master node: IP $MASTER_IP not found on current host"
    fi
}

verify_running_as_root() {
    if [ `whoami` != 'root' ]; then
        print_failed_message "Running as user $(whoami), need to be root"
        echo Cannot perform further checks, exiting...
        exit 1
    else
        print_passed_message "Running as user root"
    fi
}

sanity_checks() {
    echo
    echo 1. Running sanity checks...
    echo ----------------------------
    config_file_count=$(find $CONFIG_DIR -name $CONFIG_FILENAME -type f |wc -l)
    if [ ! $config_file_count -ge 1 ]; then
        print_failed_message "could not find $CONFIG_FILENAME in $(readlink --canonicalize $CONFIG_DIR)" 
        exit 1
    else
        CONFIG_FILE=$(find $CONFIG_DIR -name $CONFIG_FILENAME -type f)
        print_passed_message "Config file found: $(readlink --canonicalize $CONFIG_FILE)"
    fi

    hosts_file_count=$(find $CONFIG_DIR -name $HOSTS_FILENAME | wc -l)
    if [ ! $hosts_file_count -eq 1 ]; then
        print_failed_message "Could not find file \"$HOSTS_FILENAME\" in $(readlink --canonicalize $CONFIG_DIR)"
        exit 1
    else
        HOSTS_FILE=$(find $CONFIG_DIR -name $HOSTS_FILENAME | head -n 1)
        print_passed_message "Hosts file found: $(readlink --canonicalize $HOSTS_FILE)"
    fi

    verify_running_as_root
    verify_execution_host_is_master
    
}

health_checks() {
    # under each sub-dir of req, run each script and pass it the version being installed 
    for d in ${HEALTH_DIRS[@]}; do
        for r in $(find $d -type d); do
            # echo running checks under $r ...
            # run all the scripts
            for s in `find $r/ -maxdepth 1 -type f -executable -exec basename {} \;`; do
                echo running the script $r/$s ... >> $LOG_FILE
                cd $r > /dev/null
                ./$s $PRODUCT_VERSION $CONFIG_DIR $OUTPUT_DIR
                return_code=$?
                cd - > /dev/null
                # verify whether the check passed
                if [[ $return_code == 0 ]]; then
                    echo Check passed for $r/$s >> $LOG_FILE
                elif [[ $return_code == 1 ]]; then
                    echo Check performed by $s failed. >> $LOG_FILE
                else
                    echo Check performed by $s failed, skipping further checks due to error code $return_code
                    exit 1
                fi
            done
        done
    done
}

setup
sanity_checks
health_checks




# Check configuration Prereq.
# =============================
# ---- Management node specification 

# ---- ssh keys specification
# 

# Check hardware Prereq.
# ===============================


# Check software Prereq.
# ===============================
# Collect Reqs for the version

# - docker version
# - kubelet


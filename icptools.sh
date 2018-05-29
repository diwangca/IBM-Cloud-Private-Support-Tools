#!/bin/bash

# formatting
LINE=$(printf "%*s\n" "30" | tr ' ' "#")

# icp version the script has been tested on
ICP_Tools_Version=0.3
Release_Date="April 2018"
Product_Versions=(
"ICP CE 2.1.0.2"
"ICP EE 2.1.0.2"
)

echo -e "\n${LINE}"
echo "ICP Tools Version: $ICP_Tools_Version"
echo "Release Date: $Release_Date"
echo -e "\nTested on:"
Product_Version=""
for Product_Version in "${Product_Versions[@]}"; do
  echo "$Product_Version"
done
echo ${LINE}
echo

Print_Usage() {
  echo "Usage:"
  echo "$0 [OPTIONS]"
  echo -e "\n  OPTIONS:"
  echo "      -pre: Run pre-installation requirements checker (CPU, RAM, and Disk space, etc.)"
  echo "      -health: Run post-installation cluster health checker (Running ICP services/pods/containers, etc.)"
  echo "      -c, --collect: Run data-collection tool to gather the data"
  echo "      -l, --log: Run log collection tool to collect log files from critical pods/containers"
  echo "      -h, --help: Prints this message"
  echo "      -i, --path <ICP_installation_path> Specify ICP installation path to collect configuration files."
  echo "      -u, --cleanup: Cleanup everything from the hosts on the cluster (Warning: Will destroy all data on the cluster)"
  echo -e "\n  EXAMPLES:"
  echo "      $0 -pre"
  echo "      $0 -health"
  echo "      $0 --log"
  echo
  exit 0
}

Selected_Option() {

    TEMP=`getopt -o pclhui: --long pre,health,collect,log,cleanup,help,path: -n 'icptools.sh' -- "$@"`

    if [ $? != 0 ] ; then 
        echo "error processing options..." >&2 
        exit 1
    fi

    eval set -- "$TEMP"

    TASK=""
    export INSTALL_PATH=../
    while true; do
        case "$1" in
            -h | --help ) TASK=Print_Usage; shift ;;
            -i | --path ) export INSTALL_PATH=$(readlink -f "$2"); shift 2 ;;
            -p | --pre  ) TASK=Prereq_CHK; shift ;;
            -l | --log ) TASK=Collect_Logs; shift ;;
            -c | --collect ) TASK=Collect_Data; shift ;;
            -u | --cleanup ) TASK=Cleanup; shift ;;
            --health ) TASK=Health_CHK; shift ;;
            -- ) shift; break ;;
            * ) break ;;
        esac
    done
    if [ ! -z "$TASK" ]; then
        $TASK $@
        exit $?
    fi
}

setup() {
	export UTIL_DIR=`pwd`"/util"
    . $UTIL_DIR/util.sh
}

Cleanup() {
echo
echo -e $1 ${COLOR_RED}\ !! Warning !! ${COLOR_NC}
echo "   This will permanently DELETE the following from all the hosts defined in your cluster's hosts file:"
echo "       - /etc/cfc if exists"
echo "       - All the docker containers"
echo "       - All the docker images"

read -p " Press Y to continue, Any other key to quit: " useragree

if [[ $useragree == "Y" ]]; then
	echo "Start Cleaning..."
    	run_on_all_nodes ./cleanup/cleanup.sh
else
	echo "Thanks and quiting..."
fi
}

Prereq_CHK() {
	local logs_dir=`mktemp -d`
	run_on_all_nodes ./req/prereq.sh $logs_dir
	local timestamp=`date +"%Y-%m-%d-%H-%M-%S"`
	local archive_name="prereq-check_"$$"_"$timestamp".tar.gz"
	local output_dir=`mktemp -d`
	build_archive $output_dir $archive_name $logs_dir "./"
	echo Logs collected at $output_dir/$archive_name
}

Health_CHK() {
	local logs_dir=`mktemp -d`
	run_on_all_nodes ./health/health.sh $logs_dir
	local timestamp=`date +"%Y-%m-%d-%H-%M-%S"`
	local archive_name="health-check_"$$"_"$timestamp".tar.gz"
	local output_dir=`mktemp -d`
	build_archive $output_dir $archive_name $logs_dir "./"
	echo Logs collected at $output_dir/$archive_name
}

Collect_Data() {
	echo Deprecated. Use "Collect Logs" feature instead.
	exit 0
}

Collect_Logs() {
	local logs_dir=`mktemp -d`
	run_on_all_nodes ./log_collector/icplogcollector-all-nodes.sh $logs_dir
	run_on_all_nodes ./log_collector/icplogcollector-master-nodes.sh $logs_dir
	local timestamp=`date +"%Y-%m-%d-%H-%M-%S"`
	local archive_name="logs_"$$"_"$timestamp".tar.gz"
	local output_dir=`mktemp -d`
	build_archive $output_dir $archive_name $logs_dir "./"
	echo Logs collected at $output_dir/$archive_name
	clean_up $logs_dir
}

ICP_Tools_Menu() {
  while true; do
    echo -e "Choose an option [1-5] \n";
    options=("Pre-install checks for ICP installation" "Health-check an installed ICP cluster" "Collect data needed to submit an issue" "Collect logs from critical containers" "Exit")
    COLUMNS=12;
    select opt in "${options[@]}";
    do
    	case $opt in
        "Pre-install checks for ICP installation")
          Prereq_CHK; break;;
    		"Health-check an installed ICP cluster")
    			Health_CHK; break;;
        "Collect data needed to submit an issue")
          Collect_Data; break;;
        "Collect logs from critical containers")
          Collect_Logs; break;;
        "Exit")
      		exitSCRIPT; break;;
    		*)
    			echo invalid option;
    			;;
    	esac
    done
  done
}

exitSCRIPT(){
  echo -e "Exiting...";
  exit 0;
}

setup $@
Selected_Option $@
ICP_Tools_Menu

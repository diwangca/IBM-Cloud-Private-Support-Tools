# ICP Tools
Run [icptools.sh](icptools.sh) to:
1. Pre-install checks for ICP installation
  * Run pre-installation requirements checker (CPU, RAM, and Disk space, etc.)
2. Health-check an installed ICP cluster
  * Run post-installation cluster health checker (Running ICP services/pods/containers, etc.)
3. Collect data needed to submit an issue
  * Run data-collection tool to gather the data
4. Collect logs from critical containers
  * Run log collection tool to collect log files from critical pods/containers and component, such as docker log, kubelet log, k8s_api_server, k8s_calico_node, catalog_api_server, catalog_ui, helm_api, icp-ds, etcd and more.  

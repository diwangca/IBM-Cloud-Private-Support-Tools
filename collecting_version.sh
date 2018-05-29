#!/bin/bash

verify_docker_version () {
DOCKER_VERSION=$(docker version --format '{{.Server.Version}}')
echo "Docer version is $DOCKER_VERSION"
}

verify_bx_version () {
BX_VERSION=$(bx -v)
echo $BX_VERSION
}

verify_kubectl_version () {
KUBECTL_VERSION=$(kubectl version --client --short=true)
echo "Kubectl $KUBECTL_VERSION"
}

verify_helm_version () {
HELM_VERSION=$(helm version --client --short=true)
echo "Helm version is $HELM_VERSION"
}

verify_docker_version
verify_bx_version
verify_kubectl_version
verify_helm_version

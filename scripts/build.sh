#!/usr/bin/env bash

set -e

K8S_VERSION=${K8S_VERSION:-v1.6.1}
KUBEADM_VERSION=${KUBEADM_VERSION:-v1.6.0-alpha.0.2074+a092d8e0f95f52}
CNI_VERSION=${CNI_VERSION:-07a8a28637e97b22eb8dfe710eeae1344f69d16e}

REPO=${REPO:-luxas/kubeadm-installer}
INSTALLER_REVISION=${KUBEADM_REVISION:-0}
TAG_LATEST=${TAG_LATEST:-1}
PUSH=${PUSH:-0}


set -u

# Workaround since Docker does not support SEMVER for tags
# Especially the '+'
#
# https://github.com/docker/distribution/pull/1202
KUBEADM_VERSION=${KUBEADM_VERSION/+/-g}

PROJECT_DIR="$(git rev-parse --show-toplevel)"

docker build \
  -e K8S_VERSION=${K8S_VERSION} \
  -e KUBEADM_RELEASE=${KUBEADM_VERSION} \
  -e CNI_RELEASE=${CNI_VERSION} \
  -t ${REPO}:${KUBEADM_VERSION}.${KUBEADM_REVISION} \
  ${PROJECT_DIR}

if [[ ${TAG_LATEST} == 1 ]]; then
	docker tag ${REPO}:${KUBEADM_VERSION}.${KUBEADM_REVISION}
fi

if [[ ${PUSH} == 1 ]]; then
	docker push ${REPO}:${KUBEADM_VERSION}.${KUBEADM_REVISION}
	docker push ${REPO}
fi

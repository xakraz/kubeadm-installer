#!/usr/bin/env bash


# Variables
# --
#
# These values can be overridden by ENV Vars
#
K8S_REPO="kubernetes/kubernetes"

# Example
#K8S_VERSION=${K8S_VERSION:-v1.6.1}
K8S_VERSION=${K8S_VERSION:-}

# Example
#KUBEADM_RELEASE=${KUBEADM_RELEASE:-v1.6.0-alpha.0.2074+a092d8e0f95f52}
KUBEADM_RELEASE=${KUBEADM_RELEASE:-}

# Example
#CNI_RELEASE=${CNI_RELEASE:-07a8a28637e97b22eb8dfe710eeae1344f69d16e}
CNI_RELEASE=${CNI_RELEASE:-}
CNI_REPO="containernetworking/cni"

# Installer variables
ARCH=${ARCH:-amd64}
CNI_BIN_DIR=${CNI_BIN_DIR:-/opt/cni}
ROOTFS=${ROOTFS:-/rootfs}


# Helpers
# --
get_git_latest_release() {
  curl --silent "https://api.github.com/repos/${1}/releases/latest" \
    | grep '"tag_name":' \
    | sed -E 's/.*"([^"]+)".*/\1/'
}


# Handle no values
# --
# If no values are provided, get the latest release of k8s
if [[ -z "${K8S_VERSION}" ]]; then
  K8S_VERSION=$(get_git_latest_release $K8S_REPO)
fi

# If no values are provided, use the same than k8s
if [[ -z "${KUBEADM_RELEASE}" ]]; then
  KUBEADM_RELEASE=${K8S_VERSION}
fi

# If no values are provided, get the latest release of CNI
if [[ -z "${CNI_RELEASE}" ]]; then
  CNI_RELEASE=$(get_git_latest_release $CNI_REPO)
fi


# Kubernetes Google Cloud Storage
# --
#
# Handling usage of Dev / Final release buckets
#
K8S_URL=${K8S_URL:-https://storage.googleapis.com/kubernetes-release/release}
CNI_URL=${CNI_URL:-https://storage.googleapis.com/kubernetes-release/network-plugins}

echo "Installing kubeadm version: ${KUBEADM_RELEASE}"
if [[ -z "${KUBEADM_URL}" ]]; then
  if [[ -n "${KUBEADM_VERSION/v[0-9].[0-9].[0-9]/}" ]]; then
    echo "Kubeadm: is a Git version"
    KUBEADM_URL=https://storage.googleapis.com/kubernetes-release-dev/ci-cross
  else
    echo "Kubeadm: is a Release version"
    KUBEADM_URL=https://storage.googleapis.com/kubernetes-release/release
  fi
fi
echo "Kubeadm: Download url - ${KUBEADM_URL}"


# Linux Distro
# --
#
# Environment settings according to Distro
#
if [[ $1 == "coreos" ]]; then
  BIN_DIR=${BIN_DIR:-/opt/bin}
  KUBELET_EXEC=${KUBELET_EXEC:-/usr/lib/coreos/kubelet-wrapper}
  EXTRA_ENVIRONMENT=${EXTRA_ENVIRONMENT:-"RKT_RUN_ARGS=--volume opt-cni,kind=host,source=/opt/cni --mount volume=opt-cni,target=/opt/cni --volume etc-cni,kind=host,source=/etc/cni --mount volume=etc-cni,target=/etc/cni"}
elif [[ $1 == "ubuntu" || $1 == "debian" || $1 == "fedora" || $1 == "centos" ]]; then
  BIN_DIR=${BIN_DIR:-/usr/bin}
  KUBELET_EXEC=${KUBELET_EXEC:-${BIN_DIR}/kubelet}
  EXTRA_ENVIRONMENT=${EXTRA_ENVIRONMENT:-"NOOP=true"}
  INSTALL_KUBELET=1
else
  cat <<-EOF
  Hi, you should run this container like this:
  docker run -it \
    -v /etc/:/rootfs/etc \
    -v /usr:/rootfs/usr \
    -v /opt:/rootfs/opt \
    luxas/kubeadm-installer your_os_here

  your_os_here can be coreos, ubuntu, debian, fedora or centos

  You can also revert this action with running:
  docker run -it \
    -v /etc/:/rootfs/etc \
    -v /usr:/rootfs/usr \
    -v /opt:/rootfs/opt \
    luxas/kubeadm-installer uninstall
  EOF
  exit 1
fi


if [[ $2 == "uninstall" ]]; then
  rm -rfv ${ROOTFS}/etc/cni \
    ${ROOTFS}/${BIN_DIR}/kubectl \
    ${ROOTFS}/${BIN_DIR}/kubelet \
    ${ROOTFS}/${BIN_DIR}/kubeadm \
    ${ROOTFS}/${CNI_BIN_DIR} \
    ${ROOTFS}/etc/systemd/system/kubelet.service
  exit 1
fi


# Setup
#
mkdir -p ${ROOTFS}/etc/cni \
  ${ROOTFS}/${BIN_DIR}

if [[ ! -f ${ROOTFS}/${BIN_DIR}/kubectl ]]; then
  curl -sSL ${K8S_URL}/${K8S_VERSION}/bin/linux/${ARCH}/kubectl > ${ROOTFS}/${BIN_DIR}/kubectl
  chmod +x ${ROOTFS}/${BIN_DIR}/kubectl
  echo "Installed kubectl in ${BIN_DIR}/kubectl"
else
  echo "Ignoring ${BIN_DIR}/kubectl, since it seems to exist already"
fi

if [[ ! -f ${ROOTFS}/${BIN_DIR}/kubelet && ${INSTALL_KUBELET} == 1 ]]; then
  curl -sSL ${K8S_URL}/${K8S_VERSION}/bin/linux/${ARCH}/kubelet > ${ROOTFS}/${BIN_DIR}/kubelet
  chmod +x ${ROOTFS}/${BIN_DIR}/kubelet
  echo "Installed kubelet in ${BIN_DIR}/kubelet"
else
  echo "Ignoring ${BIN_DIR}/kubelet, since it seems to exist already"
fi

if [[ ! -f ${ROOTFS}/${BIN_DIR}/kubeadm ]]; then
  curl -sSL ${KUBEADM_URL}/${KUBEADM_RELEASE}/bin/linux/${ARCH}/kubeadm > ${ROOTFS}/${BIN_DIR}/kubeadm
  chmod +x ${ROOTFS}/${BIN_DIR}/kubeadm
  echo "Installed kubeadm in ${BIN_DIR}/kubeadm"
else
  echo "Ignoring ${BIN_DIR}/kubeadm, since it seems to exist already"
fi

if [[ ! -d ${ROOTFS}/${CNI_BIN_DIR} ]]; then
  mkdir -p ${ROOTFS}/${CNI_BIN_DIR}
  curl -sSL ${CNI_URL}/cni-${ARCH}-${CNI_RELEASE}.tar.gz | tar -xz -C ${ROOTFS}/${CNI_BIN_DIR}
  echo "Installed CNI binaries in /opt/cni"
else
  echo "Ignoring /opt/cni, since it seems to exist already"
fi

if [[ ! -f ${ROOTFS}/etc/systemd/system/kubelet.service ]]; then
  cat > ${ROOTFS}/etc/systemd/system/kubelet.service <<-EOF
  [Unit]
  Description=kubelet: The Kubernetes Node Agent
  Documentation=http://kubernetes.io/docs/

  [Service]
  Environment="KUBELET_VERSION=${K8S_VERSION}_coreos.0"
  Environment="KUBELET_IMAGE_TAG=${K8S_VERSION}_coreos.0"
  Environment="${EXTRA_ENVIRONMENT}"
  ExecStart=${KUBELET_EXEC} --kubeconfig=/etc/kubernetes/kubelet.conf \
    --require-kubeconfig=true \
    --pod-manifest-path=/etc/kubernetes/manifests \
    --allow-privileged=true \
    --network-plugin=cni \
    --cni-conf-dir=/etc/cni/net.d --cni-bin-dir=/opt/cni/bin \
    --cluster-dns=10.96.0.10 --cluster-domain=cluster.local
  Restart=always
  StartLimitInterval=0
  RestartSec=10

  [Install]
  WantedBy=multi-user.target
  EOF
  echo "Installed the kubelet.service in /etc/systemd/system/kubelet.service"
else
  echo "Ignoring /etc/systemd/system/kubelet.service, since it seems to exist already"
fi


cat <<EOF
Done! Now run this in your terminal to enable docker and kubelet:

systemctl daemon-reload
systemctl enable docker kubelet
systemctl restart docker kubelet
EOF

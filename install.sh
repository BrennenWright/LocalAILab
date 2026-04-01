# Install script for install and setup of LocalAILab on:
#		- Ubuntu 22.04
#		- Ubuntu 24.04
#
# Optional integrations (prompted): CyPerf agents, CloudLens sidecars.
# Re-running this script restores integration manifests from git (needs a git
# clone, not a flat zip), then reapplies your answers so you can enable or
# disable CyPerf/CloudLens without manual YAML edits.
#
# Requirements:
#   Ubuntu 22.04
#   10 vCPU
#   24GB RAM
#   220GB HardDisk Space
#   8GB VRAM(Optional)

LOCALAILAB_ROOT="${LOCALAILAB_ROOT:-$HOME/LocalAILab}"

# install github
sudo apt -y update && sudo apt -y upgrade
sudo apt -y install git

# login to github

if [ ! -d "$LOCALAILAB_ROOT" ]; then
  echo "Clone the LocalAILab Repo"
  git clone https://github.com/BrennenWright/LocalAILab.git "$LOCALAILAB_ROOT"
fi
if [ ! -d "$LOCALAILAB_ROOT/manifest/base" ]; then
  echo "Expected manifests at $LOCALAILAB_ROOT/manifest/base — fix LOCALAILAB_ROOT or clone the repo."
  exit 1
fi

prompt_cyperf_controller() {
  echo ""
  echo "CyPerf Controller IP or hostname (AGENT_CONTROLLER). Press Enter or enter SKIP to skip CyPerf agents:"
  read -r CYPERF_CONTROLLER_IP
  CYPERF_CONTROLLER_IP="${CYPERF_CONTROLLER_IP//$'\r'/}"
  CYPERF_CONTROLLER_IP="${CYPERF_CONTROLLER_IP#"${CYPERF_CONTROLLER_IP%%[![:space:]]*}"}"
  CYPERF_CONTROLLER_IP="${CYPERF_CONTROLLER_IP%"${CYPERF_CONTROLLER_IP##*[![:space:]]}"}"
  _ci_lower="$(printf '%s' "$CYPERF_CONTROLLER_IP" | tr '[:upper:]' '[:lower:]')"
  if [ -z "$CYPERF_CONTROLLER_IP" ] || [ "$_ci_lower" = "skip" ]; then
    ENABLE_CYPERF=0
    echo "CyPerf agents: skipped."
  else
    ENABLE_CYPERF=1
    echo "CyPerf agents: enabled; controller=$CYPERF_CONTROLLER_IP"
  fi
}

prompt_cloudlens() {
  echo ""
  echo "CloudLens Manager IP or hostname. Press Enter or SKIP to skip CloudLens (no sidecars, no registry patch):"
  read -r CLOUDLENS_MANAGER_IP
  CLOUDLENS_MANAGER_IP="${CLOUDLENS_MANAGER_IP//$'\r'/}"
  CLOUDLENS_MANAGER_IP="${CLOUDLENS_MANAGER_IP#"${CLOUDLENS_MANAGER_IP%%[![:space:]]*}"}"
  CLOUDLENS_MANAGER_IP="${CLOUDLENS_MANAGER_IP%"${CLOUDLENS_MANAGER_IP##*[![:space:]]}"}"
  _cl_lower="$(printf '%s' "$CLOUDLENS_MANAGER_IP" | tr '[:upper:]' '[:lower:]')"
  if [ -z "$CLOUDLENS_MANAGER_IP" ] || [ "$_cl_lower" = "skip" ]; then
    ENABLE_CLOUDLENS=0
    CLOUDLENS_PROJECT_KEY=""
    echo "CloudLens: skipped."
    return 0
  fi
  ENABLE_CLOUDLENS=1
  while true; do
    echo "CloudLens project key (required, more than 10 characters):"
    read -r CLOUDLENS_PROJECT_KEY
    CLOUDLENS_PROJECT_KEY="${CLOUDLENS_PROJECT_KEY//$'\r'/}"
    CLOUDLENS_PROJECT_KEY="${CLOUDLENS_PROJECT_KEY#"${CLOUDLENS_PROJECT_KEY%%[![:space:]]*}"}"
    CLOUDLENS_PROJECT_KEY="${CLOUDLENS_PROJECT_KEY%"${CLOUDLENS_PROJECT_KEY##*[![:space:]]}"}"
    if [ -z "$CLOUDLENS_PROJECT_KEY" ]; then
      echo "Project key cannot be blank."
      continue
    fi
    if [ "${#CLOUDLENS_PROJECT_KEY}" -le 10 ]; then
      echo "Project key must be longer than 10 characters."
      continue
    fi
    break
  done
  echo "CloudLens: enabled; manager=$CLOUDLENS_MANAGER_IP"
}

prompt_cyperf_controller
prompt_cloudlens

restore_integration_manifests_from_git() {
  if [ -d "$LOCALAILAB_ROOT/.git" ]; then
    git -C "$LOCALAILAB_ROOT" checkout HEAD -- \
      manifest/base/kustomization.yaml \
      manifest/base/cyperf-agent-client.yaml \
      manifest/base/cyperf-agent-server.yaml \
      manifest/base/webui-deployment.yaml 2>/dev/null || true
  fi
}

patch_kustomization_cyperf() {
  local k="$LOCALAILAB_ROOT/manifest/base/kustomization.yaml"
  if [ "$ENABLE_CYPERF" -ne 1 ]; then
    sed -i '/^[[:space:]]*-[[:space:]]*cyperf-agent-client\.yaml[[:space:]]*$/d; /^[[:space:]]*-[[:space:]]*cyperf-agent-server\.yaml[[:space:]]*$/d' "$k"
  fi
}

patch_containerd_cloudlens_registry() {
  local host="$1"
  local cf="/etc/containerd/config.toml"
  if [ ! -f "$cf" ]; then
    return 0
  fi
  sudo sed -i '/# LocalAILAB CloudLens registry BEGIN/,/# LocalAILAB CloudLens registry END/d' "$cf"
  if [ -z "$host" ]; then
    return 0
  fi
  tmp_block="$(mktemp)"
  {
    echo ""
    echo "# LocalAILAB CloudLens registry BEGIN"
    echo "[plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors.\"$host\"]"
    echo "  endpoint = [\"https://$host\"]"
    echo ""
    echo "[plugins.\"io.containerd.grpc.v1.cri\".registry.configs.\"$host\".tls]"
    echo "  insecure_skip_verify = true"
    echo "# LocalAILAB CloudLens registry END"
  } > "$tmp_block"
  sudo tee -a "$cf" < "$tmp_block" > /dev/null
  rm -f "$tmp_block"
}

patch_agent_controller_ip() {
  local file="$1"
  local ip="$2"
  sed -i "/name: AGENT_CONTROLLER/{n;s|value: \".*\"|value: \"$ip\"|}" "$file"
}

patch_sidecar_args() {
  local file="$1"
  local project_key="$2"
  local server_host="$3"
  sed -i "s|--project_key\",\"[^\"]*\"|--project_key\",\"$project_key\"|g" "$file"
  sed -i "s|--server\",\"[^\"]*\"|--server\",\"$server_host\"|g" "$file"
}

remove_cloudlens_sidecar() {
  local file="$1"
  sed -i '/# BEGIN-CLOUDLENS-SIDECAR/,/# END-CLOUDLENS-SIDECAR/d' "$file"
  sed -i '/# BEGIN-CLOUDLENS-VOLUMES/,/# END-CLOUDLENS-VOLUMES/d' "$file"
}

apply_manifest_patches() {
  local client="$LOCALAILAB_ROOT/manifest/base/cyperf-agent-client.yaml"
  local server="$LOCALAILAB_ROOT/manifest/base/cyperf-agent-server.yaml"
  local webui="$LOCALAILAB_ROOT/manifest/base/webui-deployment.yaml"

  if [ "$ENABLE_CYPERF" -eq 1 ]; then
    patch_agent_controller_ip "$client" "$CYPERF_CONTROLLER_IP"
    patch_agent_controller_ip "$server" "$CYPERF_CONTROLLER_IP"
  fi

  if [ "$ENABLE_CLOUDLENS" -eq 1 ]; then
    patch_sidecar_args "$server" "$CLOUDLENS_PROJECT_KEY" "$CLOUDLENS_MANAGER_IP"
    patch_sidecar_args "$webui" "$CLOUDLENS_PROJECT_KEY" "$CLOUDLENS_MANAGER_IP"
  else
    remove_cloudlens_sidecar "$server"
    remove_cloudlens_sidecar "$webui"
  fi
}

apply_localailab_integration_manifests() {
  restore_integration_manifests_from_git
  patch_kustomization_cyperf
  apply_manifest_patches
}

# install NVIDIAs containet tools
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
# Register NVIDIA with containerd after /etc/containerd/config.toml exists (see containerd block below).
# If Docker is installed and you need GPU in Docker containers, run:
# sudo nvidia-ctk runtime configure --runtime=docker

# install k8s
#   sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

#   include overlay and netfilter
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

#  dissable the swap
sudo sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab
sudo swapoff -a

sudo apt-get install -y apt-transport-https ca-certificates curl gnupg
# If the folder `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
# sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg # allow unprivileged APT programs to read this keyring

# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list   # helps tools such as command-not-found to work correctly

sudo apt-get update && sudo apt-get install -y kubelet kubeadm kubectl helm
sudo apt-mark hold kubelet kubeadm kubectl

# install containerd (Kubernetes CRI)
sudo apt install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo nvidia-ctk runtime configure --runtime=containerd

if [ "$ENABLE_CLOUDLENS" -eq 1 ]; then
  patch_containerd_cloudlens_registry "$CLOUDLENS_MANAGER_IP"
fi

sudo systemctl restart containerd
sudo systemctl restart kubelet || true

# init k8s
sudo kubeadm init --pod-network-cidr=10.244.0.0/16


mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# setup for single node
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
kubectl label nodes --all node.kubernetes.io/exclude-from-external-load-balancers-

# Install a Network Plugin
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# GPU Operator (device plugin, etc.). Host must have NVIDIA drivers: install them before GPU workloads
# and verify `nvidia-smi` on this node. driver.enabled=false and toolkit.enabled=false mean the operator
# does not install drivers or reconfigure containerd; nvidia-ctk for containerd above remains required.
if ! helm repo list 2>/dev/null | awk 'NR>1 {print $1}' | grep -qx nvidia; then
  helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
fi
helm repo update
helm upgrade --install gpu-operator nvidia/gpu-operator -n gpu-operator --create-namespace --wait \
  --set driver.enabled=false --set toolkit.enabled=false

# setup local-storage
kubectl apply -f "$LOCALAILAB_ROOT/manifest/base/local-ai-lab-namespace.yaml"
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Configure CyPerf Prerequisites
cat <<EOF | sudo tee /etc/modules-load.d/cyperf.conf
ip6table_filter
ip6_table
EOF
sudo modprobe ip6table_filter && sudo modprobe ip6_table

apply_localailab_integration_manifests

if [ "$ENABLE_CYPERF" -eq 1 ]; then
  kubectl apply -f "$LOCALAILAB_ROOT/manifest/base/cyperf-agent-client.yaml"
  kubectl apply -f "$LOCALAILAB_ROOT/manifest/base/cyperf-agent-server.yaml"
fi

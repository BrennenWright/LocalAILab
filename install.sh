# Install script for install and setup of LocalAILab on:
#		- Ubuntu 22.04
#		- Ubuntu 24.04
#
#
#
# Requirements:
#   Ubuntu 22.04
#   10 vCPU
#   24GB RAM
#   220GB HardDisk Space
#   8GB VRAM(Optional)



# install github
sudo apt -y update && sudo apt -y upgrade
sudo apt -y install git
sudo apt -y install gh


# login to github

if [ ! -d "$HOME/LocalAILab" ]; then
  # commands to execute if the directory does not exist
  echo "Clone the LocalAILab Repo"
  gh repo clone BrennenWright/LocalAILab
fi


# install NVIDIAs containet tools
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker

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
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.27/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list   # helps tools such as command-not-found to work correctly

sudo apt-get update && sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# install containerd
sudo apt install -y containerd
sudo mkdir /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo service containerd restart


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


# setup local-storage
kubectl apply -f LocalAILab/manifest/base/local-ai-lab-namespace.yaml
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Configure CyPerf Prerequisites
cat <<EOF | sudo tee /etc/modules-load.d/cyperf.conf
ip6table_filter
ip6_table
EOF
sudo modprobe ip6table_filter && sudo modprobe ip6_table

kubectl apply -f LocalAILab/manifest/base/cyperf-agent-client.yaml
kubectl apply -f LocalAILab/manifest/base/cyperf-agent-server.yaml

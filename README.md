# LocalAILab
A mobile friendly AI lab for testing and demonstrating Keysight Visibility &amp; Validation for AI.

![ai solutions diagram](https://github.com/BrennenWright/LocalAILab/blob/main/AISolutionsClean.png?raw=true)

### TODO

- Built out Helm charts for the lab to replicate the completed lab
	- get the manifest correct first
- Include the setup script for the supporting helms and k8s node setup
- Complete test examples for CyPerf
- Deploy: 
	- Eggplant
	- BPS-VE
	- vAPPStack
- Complete example applications
- Implement Kubernetes Logging and reporting for visualization of test impacts
- Writeup the install guide and demo guides
- Add health checks to the database
- Add n8n load from backup scripts
- Add initial n8n workflows and load them in on launch like the docker lab does
- Fix the pod manager stuff as it needs a new default image and the script to be inbeded
- Try moving cyperf to persistant to reduce the stale agent issue
- Setup autoupdates for the Lab SSL Certificates 
- Include deploy instructions/script for the managers
- Include the kubernetes dashboard-user token for management in the setup script

- Include the user provided CloudLens Server FQDN/IP in the /etc/containerd/config.toml for insecure tls.


### Lab Components

#### Keysight
- Keysight CyPerf - Generates synthetic traffic from external or internal clients to an internal endpoint
- Keysight CloudLens - Sidecar and Deamonset for Precryption and traffic AI inspection
- Keysight AI Model Detection Tool(APPSTACK)
- Keysight Eggplant - AI Engine enabled User Experience test framework
        - Eggplant Functional [https://quay.io/repository/eggplantsoftware/fusion-engine-ubi8]
        - Eggplant [https://docs.eggplantsoftware.com/dai/dai-container-deploy/]
- Keysight BPS-VE - Client SIM if possible to send DANs and test prompt mitigation and inspection

#### OpenSource
- k8s [https://github.com/kubernetes/kubernetes]
- n8n [https://github.com/n8n-io/n8n]
- open webui [https://github.com/open-webui/open-webui]
- Qdrant
- PostgreSQL
- NVIDIA gpu-operator [https://github.com/NVIDIA/gpu-operator]
- Kubernetes stats [https://github.com/kubernetes-sigs/metrics-server]

## Installation

NOTE THIS IS A WORK IN PROGRESS AND NOT COMPLETE


### External Tools

	- Deploy Keysight Cloudlens Manager
	- Deploy Keysight CyPerf Manager


### System Requirements

Deploy a new server instance:

- Ubuntu 22.04 or 24.04
- 10 	CPU
- 24GB 	RAM
- 220GB Storage
- 8GB+	GPU VRAM(Optional sort of)

  > NVIDIA Tesla P4 is a great sub $150 option that fits most PCIex16 servers
  
  > NVIDIA Tesla L4 24GB is a great improvement with a similar formfactor but at ~$2,000 instead




### System Deployment

Boot the server to the ISO
- ensure the drive configuration uses the entire hard disk
- install OpenSSH Server if SSH is required for administration
- ignore the additional packages. Especially the MicroK8


### Cloning the Repository

```bash
gh auth login

git clone https://github.com/BrennenWright/LocalAILab.git
./LocalAILab/install.sh
```


### SingleNode Scripted Install for Ubuntu 22/24

```bash
wget https://raw.githubusercontent.com/BrennenWright/LocalAILab/refs/heads/main/install.sh
sudo chmod +x install.sh
./install.sh
```

### Deploy the Services
Once you have a functional kubernetes cluster do the following to deploy the services

Without GPU (CPU mode)
```bash
cd LocalAILab
kubectl apply -k ./manifest/base
```

If you have NVIDIA GPU resources
```bash
kubectl apply -k ./manifest/gpu/
```

**GPU prerequisites (summary):** Install the NVIDIA driver on the host and confirm `nvidia-smi` before relying on GPU workloads. The [install.sh](install.sh) flow registers the NVIDIA runtime with **containerd** (`nvidia-ctk`), installs **Helm**, and deploys **GPU Operator** with `driver.enabled=false` and `toolkit.enabled=false` (so the operator does not install drivers or reconfigure containerd on top of that). The GPU manifest overlay ships a `RuntimeClass` named `nvidia` and sets `runtimeClassName: nvidia` on Ollama.

> [!NOTE]
> I need to document the prerequisits to confirm for existing clusters. The  
> [install.sh](install.sh) includes most of these.

> [!NOTE]
> The services manifests include the settings for networks and ports. 
> I defaulted a number of these to NodePORT meaning they use the servers primary IP and a 30000 port to function
>
> - OpenWebUI - https://<YOUR_K8S_IP>:30000/
> - K8s Dashboard - https://<YOUR_K8S_IP>:30001/
> - n8n -  https://<YOUR_K8S_IP>:30678/

To localy administer the pods and system use kubectl such as:

```
kubectl get pods -A 
```

To login to and use the K8S Dashboard you will need the dashboard-user token

![kube dashboard login screenshot](https://github.com/BrennenWright/LocalAILab/blob/main/kubedashboard.png?raw=true)


Generate a new one with:
```
kubectl -n kubernetes-dashboard create token dashboard-user --duration=488h --output yaml
```

and read the stored token with:
```
kubectl get secret dashboard-user -n kubernetes-dashboard -o jsonpath="{.data.token}" | base64 -d
```


### CyPerf Integration

CyPerf Client and Server agents are included under: 

- manifest/base/cyperf-agent-client.yaml
- manifest/base/cyperf-agent-server.yaml

Cyperf containers are pulled from an internet accessible repo. 

modify the AGENT_CONTROLLER setting to your local cyperf manager servers IP address. 
For Example:

```
          env:
          - name: AGENT_CONTROLLER
            value: "10.10.4.25"
```

and reaply the manifest:
```
kubectl apply -k ./manifest/base/cyperf-agent-client.yaml
kubectl apply -k ./manifest/base/cyperf-agent-server.yaml
```

### Cloudlens Sensors 

The sidecar uses the public sensor image `public.ecr.aws/keysight/cloudlens-sensor:latest` with `imagePullPolicy: IfNotPresent`: nodes pull that tag when the image is not already present locally, then keep using the cached image across restarts (aligned with a stable manager deployment; use `Always` or a new tag/digest if you need to force a refresh on every rollout).

If your Cloudlens Manager is not using a production CA signed certificate you will need to add it to the insecure registry when pulling from a **private** registry (not required for the public ECR sensor image).

Update the config file to include
```
nano /etc/containerd/config.toml
```
for example:
```
   [plugins."io.containerd.grpc.v1.cri".registry]
     [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors."192.168.31.250"]
          endpoint = ["https://192.168.31.250"]
      [plugins."io.containerd.grpc.v1.cri".registry.configs]
        [plugins."io.containerd.grpc.v1.cri".registry.configs."192.168.31.250".tls]
          insecure_skip_verify = true
```
Then restart the container subsytem
```
sudo service containerd restart
```

Cloudlens sensors are currently configured as sidecars under:

- manifest/base/cyperf-agent-server.yaml
- manifest/base/webui-deployment.yaml


customize project key and manager URL as needed (image defaults to public ECR `latest`):
```
        - name: sidecar
          image: public.ecr.aws/keysight/cloudlens-sensor:latest
          imagePullPolicy: IfNotPresent
          args: ["--auto_update","y","--project_key","<YOUR_CL_PROJECT_KEY>","--accept_eula","yes","--server","<YOUR_CLOUDLENS_MANAGER_HOST>","--custom_tags", "source=cyperf-agent","--ssl_verify","no"]
```

and reaply the manifest:
```
kubectl apply -k ./manifest/base/cyperf-agent-server.yaml
kubectl apply -k ./manifest/base/webui-deployment.yaml
```


## Demonstration

#### Tax rules chat

#### AI Hallucination and Malicious Prompts

#### TCG Card Identification

#### Chat With Files

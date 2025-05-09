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
wget https://raw.githubusercontent.com/BrennenWright/LocalAILab/refs/heads/main/install.sh?token=GHSAT0AAAAAAC6BNVYPLYQXOKREF5VN62RKZ62IJVA
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
kubectl -n kubernetes-dashboard create token dashboard-user
```

and read the stored token with:
```
kubectl get secret dashboard-user -n kubernetes-dashboard -o jsonpath="{.data.token}" | base64 -d
```




## Demonstration

#### Tax rules chat

#### AI Hallucination and Malicious Prompts

#### TCG Card Identification

#### Chat With Files

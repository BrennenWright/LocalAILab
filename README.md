# LocalAILab
A mobile friendly AI lab for testing and demonstrating Keysight Visibility &amp; Validation for AI.

![ai solutions diagram](https://github.com/BrennenWright/LocalAILab/blob/main/AISolutionsClean.png?raw=true)

### TODO

- Built out Helm charts for the lab to replicate the completed lab
	- get the manifest correct first
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


### Lab Components

#### Keysight
- Keysight CyPerf - Generates synthetic traffic from external or internal clients to an internal endpoint 
- Keysight CloudLens - Sidecar and Deamonset for Precryption and traffic AI inspection
- Keysight AI Model Detection Tool
- Keysight Eggplant - AI Engine enabled User Experience test framework
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

Deploy a new server instance:

- Ubuntu 22.04 or 24.04
- 10 	CPU
- 24GB 	RAM
- 220GB Storage
- 8GB+	GPU VRAM(Optional sort of)


### Cloning the Repository

```bash
gh auth login

git clone https://github.com/BrennenWright/LocalAILab.git
./LocalAILab/install.sh
```


### One Shot Install for Ubuntu 22

```bash
wget https://raw.githubusercontent.com/BrennenWright/LocalAILab/refs/heads/main/install.sh?token=GHSAT0AAAAAAC6BNVYPLYQXOKREF5VN62RKZ62IJVA
sudo chmod +x install.sh
./install.sh
```

### For Existing K8S Clusters

```bash
kubectl apply -k ./manifest/base
```

> [!NOTE]
> I need to document the prerequisits to confirm for existing clusters. The  
> [install.sh](install.sh) includes most of these.



If you have NVIDIA GPU resources

```bash
kubectl apply -k ./manifest/gpu/
```

> [!NOTE]
> If you have not used your Nvidia GPU with Docker before, please follow the
> [Ollama Docker instructions](https://github.com/ollama/ollama/blob/main/docs/docker.md).


## Demonstration

#### Tax rules chat

#### AI Hallucination and Malicious Prompts

#### TCG Card Identification

#### Chat With Files

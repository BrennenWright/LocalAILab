# LocalAILab
A mobile friendly AI lab for testing and demonstrating Keysight Visibility &amp; Validation for AI.

![alt text](https://github.com/BrennenWright/LocalAILab/blob/main/AISolutionsClean.png?raw=true)

### TODO

- Built out Helm charts for the lab to replicate the completed lab
	- get the manifest correct first
- Complete test examples for CyPerf
- Deploy: 
	- Eggplant
	- BPS-VE
	- VAPPStack
- Complete example applications
- Implement Kubernetes Logging and reporting for visualization of test impacts
- Writeup the install guide and demo guides
- Add health checks to the database
- Add n8n load from backup scripts
- Add initial n8n builds and load on launch
- Fix the pod manager stuff as it needs a new default image and the script to be inbeded
- try moving cyperf to persistant to reduce the stale agent issue
- Setup autoupdates for the 

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

NOTE THIS IS NOT COMPLETE YET

### Cloning the Repository

```bash
git clone https://github.com/BrennenWright/LocalAILab.git
cd LocalAILab
```

### Running n8n using Docker Compose

#### For Nvidia GPU users

```
git clone https://github.com/BrennenWright/LocalAILab.git
cd LocalAILab
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

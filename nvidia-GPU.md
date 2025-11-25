# Troubleshooting gpu Nvidia Plugin 
## How to troubleshoot by exec into the pod to esnure the GPU plugin is working and resgistering the GPU workloads


#### nvidia-smi
 nvidia-smi
 ```
Tue Nov 25 22:56:35 2025
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 580.105.08             Driver Version: 580.105.08     CUDA Version: 13.0     |
+-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  Tesla T4                       On  |   00000000:00:1E.0 Off |                    0 |
| N/A   22C    P8              9W /   70W |       0MiB /  15360MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|  No running processes found                                                             |
+-----------------------------------------------------------------------------------------+
Tesla T4 with full driver + CUDA stack:
Driver Version: 580.105.08
CUDA Version: 13.0
GPU: Tesla T4

```
✅ FIX: Install the correct GPU device plugin for Kubernetes v1.34

Your cluster is running:

v1.34.2-eks-ecaa3a6


The stable nvidia plugin that works with EKS ≥ 1.27 is:

nvidia/k8s-device-plugin:v0.17.0


Failed to install the plugin ! 
Resolution : use yaml 
kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.17.3/deployments/static/nvidia-device-plugin.yml
#### This installed the daemon set 

verify  : dev-EC2-->kubectl get pods -n kube-system | grep nvidia
nvidia-device-plugin-daemonset-kdcg6   1/1     Running   0          2m
dev-EC2-->


#### Plugin cannot talk to GPU drivers
Even though nvidia-smi works on the node, the plugin container may NOT have:

✅ access to /dev/nvidia*
❌ correct driver volume mount
❌ correct privileged mode
❌ correct GPU feature gate in kubelet
❌ correct nvidia-container-toolkit inside AMI

solution : 
✔️ Step 1 — Get NVIDIA plugin logs

Run:
kubectl logs -n kube-system daemonset/nvidia-device-plugin-daemonset
```
1125 23:02:14.069657       1 main.go:235] "Starting NVIDIA Device Plugin" version=<
        e0a461e1
        commit: e0a461e1e7ad1d239d4708c954f08c3038e2654a
 >
I1125 23:02:14.069725       1 main.go:238] Starting FS watcher for /var/lib/kubelet/device-plugins
I1125 23:02:14.069771       1 main.go:245] Starting OS watcher.
I1125 23:02:14.070048       1 main.go:260] Starting Plugins.
I1125 23:02:14.070072       1 main.go:317] Loading configuration.
I1125 23:02:14.070934       1 main.go:342] Updating config with default resource matching patterns.
I1125 23:02:14.071172       1 main.go:353] 
Running with config:
{
  "version": "v1",
  "flags": {
    "migStrategy": "none",
    "failOnInitError": false,
    "mpsRoot": "",
    "nvidiaDriverRoot": "/",
    "nvidiaDevRoot": "/",
    "gdsEnabled": false,
    "mofedEnabled": false,
    "useNodeFeatureAPI": null,
    "deviceDiscoveryStrategy": "auto",
    "plugin": {
      "passDeviceSpecs": false,
      "deviceListStrategy": [
        "envvar"
      ],
      "deviceIDStrategy": "uuid",
      "cdiAnnotationPrefix": "cdi.k8s.io/",
      "nvidiaCTKPath": "/usr/bin/nvidia-ctk",
      "containerDriverRoot": "/driver-root"
    }
  },
  "resources": {
    "gpus": [
      {
        "pattern": "*",
        "name": "nvidia.com/gpu"
      }
    ]
  },
  "sharing": {
    "timeSlicing": {}
  },
  "imex": {}
}
I1125 23:02:14.071186       1 main.go:356] Retrieving plugins.
I1125 23:02:14.102024       1 server.go:195] Starting GRPC server for 'nvidia.com/gpu'
I1125 23:02:14.102981       1 server.go:139] Starting to serve 'nvidia.com/gpu' on /var/lib/kubelet/device-plugins/nvidia-gpu.sock
I1125 23:02:14.105449       1 server.go:146] Registered device plugin for 'nvidia.com/gpu' with Kubelet
```

#### Step 2 — Check device files inside plugin pod
dev-EC2-->kubectl exec -n kube-system -it daemonset/nvidia-device-plugin-daemonset -- ls -l /dev | grep nvidia
drwxr-xr-x. 2 root root       40 Nov 25 23:02 nvidia-caps
crw-rw-rw-. 1 root root 195, 254 Nov 25 23:02 nvidia-modeset
crw-rw-rw-. 1 root root 238,   0 Nov 25 23:02 nvidia-uvm
crw-rw-rw-. 1 root root 238,   1 Nov 25 23:02 nvidia-uvm-tools
crw-rw-rw-. 1 root root 195,   0 Nov 25 23:02 nvidia0
crw-rw-rw-. 1 root root 195, 255 Nov 25 23:02 nvidiactl

If these are missing → plugin can’t see the GPU.

#### Step 3 — Confirm GPU feature is registered
kubectl describe node ip-10-0-1-230.ec2.internal | grep -i feature
You should see:
FeatureGates: DevicePlugins=true
#### If missing → kubelet is NOT enabling device plugin support (rare on EKS GPU AMI).

#### Step 4 — Confirm correct AMI
Run:

aws ec2 describe-instances \
  --instance-ids <your-node-id> \
  --query 'Reservations[].Instances[].ImageId' \
  --profile nancy-devops

You should see something like:
amazon-eks-gpu-node-<version>

If instead you see:

❌ Amazon Linux 2023 generic
❌ EC2 default AMI
❌ Any Ubuntu AMI not built for EKS

→ GPU plugin will FAIL even if nvidia-smi works.

#### 🧩 Why this matters?

Kubernetes needs three layers:
1️⃣ GPU hardware (you have it)
2️⃣ NVIDIA driver installed in AMI (you have it — nvidia-smi works)
3️⃣ Kubernetes device plugin detect GPUs (this fails)

The device plugin logs will tell us:

“failed to load NVML”

“could not open /dev/nvidia0”

“no GPU devices found”

“failed to initialize NVML”

These are the exact causes.

#### If kubectl describe node | grep -i feature returns nothing, that means:

❗ Your node has no GPU-related labels, which means the NVIDIA driver is NOT active on the EC2 instance.

Even though the NVIDIA Device Plugin is running, Kubelet only advertises GPU resources when the underlying OS has NVIDIA drivers loaded.

### GPU TEST POD - EXEC INTO POD TO VERIFY 
=============================================

- create a test yaml file - gpu-test.yaml
- ✅ 2. Apply it
kubectl apply -f gpu-test.yaml

✅ 3. Check Pod Status
kubectl get pods -o wide

✅ 4. Exec into pod
kubectl exec -it gpu-test 

 - Then run:
 -  nvidia-smi

Expected output:

+-----------------------------------------------------------------------------+
| NVIDIA-SMI 535.xx ... GPU 0: Tesla T4 ...                                   |
+-----------------------------------------------------------------------------+



```
ev-EC2-->kubectl exec -it gpu-test -- bash
root@gpu-test:/# nvidia-smi
Tue Nov 25 23:36:43 2025       
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 580.105.08             Driver Version: 580.105.08     CUDA Version: 13.0     |
+-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  Tesla T4                       On  |   00000000:00:1E.0 Off |                    0 |
| N/A   22C    P8              9W /   70W |       0MiB /  15360MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|  No running processes found                                                             |
+-----------------------------------------------------------------------------------------+
root@gpu-test:/# 
```
If you see the GPU → drivers & device plugin are working.
You can now safely deploy Triton.

#### dev-EC2-->kubectl describe node ip-10-0-1-230.ec2.internal 
Name:               ip-10-0-1-230.ec2.internal
Roles:              <none>
Labels:             accelerator=nvidia
                    beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/instance-type=g4dn.xlarge
                    beta.kubernetes.io/os=linux
                    eks.amazonaws.com/capacityType=ON_DEMAND
                    eks.amazonaws.com/nodegroup=gpu-e2e-cluster-gpu-on-demand
                    eks.amazonaws.com/nodegroup-image=ami-0c4ca6471e3246940
                    failure-domain.beta.kubernetes.io/region=us-east-1
                    failure-domain.beta.kubernetes.io/zone=us-east-1a
                    k8s.io/cloud-provider-aws=36ba6312c5cced003c295089f34e99e3
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=ip-10-0-1-230.ec2.internal
                    kubernetes.io/os=linux
                    node.kubernetes.io/instance-type=g4dn.xlarge
                    topology.k8s.aws/zone-id=use1-az6
                    topology.kubernetes.io/region=us-east-1
                    topology.kubernetes.io/zone=us-east-1a
Annotations:        alpha.kubernetes.io/provided-node-ip: 10.0.1.230
                    node.alpha.kubernetes.io/ttl: 0
                    volumes.kubernetes.io/controller-managed-attach-detach: true
CreationTimestamp:  Tue, 25 Nov 2025 22:01:45 +0000
Taints:             <none>
Unschedulable:      false
Lease:
  HolderIdentity:  ip-10-0-1-230.ec2.internal
  AcquireTime:     <unset>
  RenewTime:       Tue, 25 Nov 2025 23:49:15 +0000
Conditions:
  Type             Status  LastHeartbeatTime                 LastTransitionTime                Reason                       Message
  ----             ------  -----------------                 ------------------                ------                       -------
  MemoryPressure   False   Tue, 25 Nov 2025 23:47:30 +0000   Tue, 25 Nov 2025 22:01:42 +0000   KubeletHasSufficientMemory   kubelet has sufficient memory available
  DiskPressure     False   Tue, 25 Nov 2025 23:47:30 +0000   Tue, 25 Nov 2025 22:01:42 +0000   KubeletHasNoDiskPressure     kubelet has no disk pressure
  PIDPressure      False   Tue, 25 Nov 2025 23:47:30 +0000   Tue, 25 Nov 2025 22:01:42 +0000   KubeletHasSufficientPID      kubelet has sufficient PID available
  Ready            True    Tue, 25 Nov 2025 23:47:30 +0000   Tue, 25 Nov 2025 22:01:57 +0000   KubeletReady                 kubelet is posting ready status
Addresses:
  InternalIP:   10.0.1.230
  ExternalIP:   3.80.253.84
  InternalDNS:  ip-10-0-1-230.ec2.internal
  Hostname:     ip-10-0-1-230.ec2.internal
  ExternalDNS:  ec2-3-80-253-84.compute-1.amazonaws.com
Capacity:
  cpu:                4
  ephemeral-storage:  20893676Ki
  hugepages-1Gi:      0
  hugepages-2Mi:      0
  memory:             16164852Ki
  nvidia.com/gpu:     1
  pods:               29
Allocatable:
  cpu:                3920m
  ephemeral-storage:  18181869946
  hugepages-1Gi:      0
  hugepages-2Mi:      0
  memory:             15474676Ki
  nvidia.com/gpu:     1
  pods:               29
System Info:
  Machine ID:                 ec2e2043a2a52e027c45e668f184ae5d
  System UUID:                ec2e2043-a2a5-2e02-7c45-e668f184ae5d
  Boot ID:                    0f7660d2-92ac-42bc-b665-38bf20c6225f
  Kernel Version:             6.12.55-74.119.amzn2023.x86_64
  OS Image:                   Amazon Linux 2023.9.20251117
  Operating System:           linux
  Architecture:               amd64
  Container Runtime Version:  containerd://2.1.4
  Kubelet Version:            v1.34.2-eks-ecaa3a6
  Kube-Proxy Version:         
ProviderID:                   aws:///us-east-1a/i-001ef381ad7bde56f
Non-terminated Pods:          (6 in total)
  Namespace                   Name                                    CPU Requests  CPU Limits  Memory Requests  Memory Limits  Age
  ---------                   ----                                    ------------  ----------  ---------------  -------------  ---
  default                     gpu-test                                0 (0%)        0 (0%)      0 (0%)           0 (0%)         13m
  kube-system                 aws-node-kbj29                          50m (1%)      0 (0%)      0 (0%)           0 (0%)         107m
  kube-system                 coredns-7d58d485c9-5c4m4                100m (2%)     0 (0%)      70Mi (0%)        170Mi (1%)     120m
  kube-system                 coredns-7d58d485c9-f5v9n                100m (2%)     0 (0%)      70Mi (0%)        170Mi (1%)     115m
  kube-system                 kube-proxy-vxtjq                        100m (2%)     0 (0%)      0 (0%)           0 (0%)         107m
  kube-system                 nvidia-device-plugin-daemonset-kdcg6    0 (0%)        0 (0%)      0 (0%)           0 (0%)         47m
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests    Limits
  --------           --------    ------
  cpu                350m (8%)   0 (0%)
  memory             140Mi (0%)  340Mi (2%)
  ephemeral-storage  0 (0%)      0 (0%)
  hugepages-1Gi      0 (0%)      0 (0%)
  hugepages-2Mi      0 (0%)      0 (0%)
  nvidia.com/gpu     1           1
Events:              <none>
dev-EC2-->

#### verification : 
```
dev-EC2-->kubectl logs gpu-test
Running nvidia-smi...
Tue Nov 25 23:35:40 2025       
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 580.105.08             Driver Version: 580.105.08     CUDA Version: 13.0     |
+-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  Tesla T4                       On  |   00000000:00:1E.0 Off |                    0 |
| N/A   22C    P8              9W /   70W |       0MiB /  15360MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|  No running processes found                                                             |
+-----------------------------------------------------------------------------------------+
dev-EC2-->
```

#### Result : 
Your gpu-test pod successfully ran nvidia-smi inside Kubernetes.

It detected the Tesla T4 GPU, driver version 580.105.08, CUDA 13.0.

GPU memory is visible (15360MiB), utilization is 0% because no workload is running yet.

No processes are bound → exactly what we expect from a test pod that only probes GPU visibility.

This proves end‑to‑end GPU scheduling is working:

Node advertises nvidia.com/gpu.

Pod requested GPU and was scheduled.

NVIDIA driver + CUDA runtime are functional inside the container.


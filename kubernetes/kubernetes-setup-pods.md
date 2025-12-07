## Kubernetes pods vs nodes vs network 

Node: ip-10-0-1-230.ec2.internal → Ready → kubelet + networking are healthy. 
Version: v1.34.2-eks-ecaa3a6 → latest EKS release, so you’re on AL2023 with nodeadm.

System Pods (kube-system namespace):

aws-node → 2/2 Running → VPC CNI is healthy.

coredns → 1/1 Running (two replicas) → DNS resolution works.

kube-proxy → 1/1 Running → service routing is functional.

This means your control plane + networking stack are stable. The cluster is waiting for workloads.

### Validation Steps : 

kubectl get nodes

Describe the node 
kubectl describe node ip-10-0-1-230.ec2.internal | grep -A5 "Capacity"
```
dev-EC2-->kubectl describe node ip-10-0-1-230.ec2.internal
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
  RenewTime:       Tue, 25 Nov 2025 22:31:01 +0000
Conditions:
```

2. Describe the node
bash
kubectl describe node ip-10-0-1-230.ec2.internal | grep -A5 "Capacity"
Look for:

Code
nvidia.com/gpu: 1
If present → GPU plugin is working and advertising GPU resources.

3. Check GPU plugin pods
bash
kubectl get pods -n kube-system | grep nvidia
Expect something like:

Code
nvidia-device-plugin-daemonset-xxxxx   1/1   Running   0   5m

4. Inspect plugin logs
bash
kubectl logs -n kube-system <nvidia-device-plugin-pod>
Should show GPUs discovered and registered.


### Search HELM CHART
helm search repo nvdp



























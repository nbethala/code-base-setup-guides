# This document lists the steps needed to ensure services are up and running in the cloud

Terraform init
terraform apply 
-- GPU node scheduling starts : 
-- If you can access the GPU-node via session manager then do the below steps to check for bottlenecks during bootstrapping : 
```
 sudo systemctl status kubelet
 ```
#### scenario : kubelet is up and running but "Container runtime network not ready"
How to troubleshoot ? 
What the Logs Mean ?
 - Container runtime network not ready → kubelet can’t initialize pod networking.
 - Error syncing pod, skipping → kubelet tried to start a pod but failed because networking wasn’t ready.
 - This happens when:
 - VPC CNI DaemonSet (aws-node) isn’t running or crashed.
- Node IAM role missing AmazonEKS_CNI_Policy.
- Subnet routing/NAT misconfigured — node can’t reach API server.
- Security groups block traffic between node and control plane.

#### 🛠 Checks to Run (inside SSM session + kubectl)

#### ERROR: 

```
dev-EC2-->kubectl get nodes  -o wide

NAME                        STATUS     ROLES    AGE   VERSION               INTERNAL-IP   EXTERNAL-IP     OS-IMAGE                       KERNEL-VERSION                   CONTAINER-RUNTIME
ip-10-0-1-76.ec2.internal   NotReady   <none>   43m   v1.34.2-eks-ecaa3a6   10.0.1.76     18.234.117.60   Amazon Linux 2023.9.20251117   6.12.55-74.119.amzn2023.x86_64   containerd://2.1.4
dev-EC2-->kubectl get pods -n kube-system | grep aws-node

kubectl get pods -n kube-system | grep aws-node
aws-node-7ggwm             1/2     CrashLoopBackOff   13 (4m9s ago)   43m
```
Issue : aws-node CNI DaemonSet is crashing, which explains why kubelet logs show “Container runtime network not ready”. Without a healthy CNI, nodes stay NotReady.

#### check logs at pod level : 

1) Check the aws-node pod logs (most important)
```
kubectl -n kube-system get pods -l k8s-app=aws-node -o wide
kubectl -n kube-system describe pod <aws-node-pod-name>
```
What to look for in logs: AccessDenied, failed to create network interface, missing /opt/cni/bin/aws-cni, or kernel/module missing messages.

2) Describe the node to see kubelet events

This often shows why the node is NotReady (cni issues, image pull, taints, etc.)
```
kubectl describe node ip-10-0-1-76.ec2.internal
kubectl get events --sort-by='.lastTimestamp' -A | tail -n 50
```
Look for events mentioning kubelet, network, cni, docker, or node_not_ready.


3) Confirm the instance IAM role & attached policies

If CNI is failing for permissions, the node role is often missing AmazonEKS_CNI_Policy. Get the instance-id and role, then list policies:
Required policies on the node role:

arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy

arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy

arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

You found the root cause.
Your node is NotReady because the aws-node (VPC CNI) pod does not have the IAM permissions it needs.
This exact error confirms it:

MissingIAMPermissions: failed to call ec2:DescribeNetworkInterfaces

##### ✅ AmazonEKS_CNI_Policy
Until that policy is attached, aws-node cannot manage ENIs → CNI fails → node never becomes Ready.
Fix the policies !!!! 










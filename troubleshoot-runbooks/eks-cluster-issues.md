# Cluster creation checklist : Healthy or Issues

```
📝 Cluster Creation Health Checklist
1. Check cluster status
bash
aws eks describe-cluster --name triton-gpu-cluster --region us-east-1 \
  --query "cluster.status" --output text
Expected: ACTIVE.

If it stays CREATING for too long (>15–20 min), something is blocking (IAM, VPC, subnets).

2. Verify control plane logs
bash
aws eks describe-cluster --name triton-gpu-cluster --region us-east-1
Look for statusMessage or errors in the JSON output.

Common blockers: IAM role trust issues, missing VPC endpoints, subnet misconfig.

3. Confirm EC2 node state
bash
aws ec2 describe-instances --filters "Name=tag:eks:cluster-name,Values=triton-gpu-cluster" \
  --query "Reservations[].Instances[].State.Name"
Expected: running.

If stuck in pending or stopped, check launch template, AMI type, or quotas.

4. Update kubeconfig (only if cluster shows ACTIVE)
bash
aws eks update-kubeconfig --name triton-gpu-cluster --region us-east-1
kubectl get nodes -o wide
Expected: GPU node shows Ready.

If NotReady, kubelet/nodeadm may be failing to bootstrap.

5. Inspect system pods
bash
kubectl get pods -n kube-system
Expected: coredns, aws-node, kube-proxy → Running.

If pods are CrashLoopBackOff or Pending, check IAM permissions and CNI setup.

6. Check nodeadm logs (on EC2 node)
SSH into the GPU node (if needed):

bash
journalctl -u nodeadm -f
Confirms whether nodeadm applied your NodeConfig correctly.
```

Look for errors about CA, endpoint, or kubelet flags.

⚡ Quick “Is it working?” signals
Cluster status = ACTIVE.

At least one EC2 node = running.

kubectl get nodes shows node(s) in Ready.

kubectl get pods -n kube-system shows system pods Running.

NVIDIA device plugin pod is Running once deployed.

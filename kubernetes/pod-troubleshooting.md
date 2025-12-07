# k8's Node quick troubleshooting guide 

```
Quick diagnostics if you want root cause
Node conditions snapshot:

bash
kubectl describe node ip-10-0-1-223.ec2.internal | sed -n '/Conditions:/,/Addresses:/p'
kubectl describe node ip-10-0-1-223.ec2.internal | sed -n '/Events:/,$p'
On the node (SSH):

Kubelet status/logs:

bash
sudo systemctl status kubelet
sudo journalctl -u kubelet -n 200 --no-pager
Container runtime:

bash
sudo systemctl status containerd
sudo journalctl -u containerd -n 200 --no-pager
Disk/image filesystem:

bash
df -h
sudo du -sh /var/lib/containerd /var/lib/kubelet
If imagefs shows 0 or missing, that matches “InvalidDiskCapacity” and warrants instance replacement.

CNI sanity (aws-node):

bash
kubectl -n kube-system logs -l k8s-app=aws-node --tail=200
NVIDIA plugin note
If the NVIDIA device plugin is broken on that node, it can cascade into kubelet/runtime instability.

Clear the release conflict first:

bash
helm uninstall nvidia-device-plugin -n kube-system
Then let Terraform re-create it cleanly, or import the existing release into TF.

After node replacement, confirm GPU readiness:

bash
kubectl -n kube-system get ds nvidia-device-plugin
kubectl get nodes -o json | jq '.items[].status.capacity.nvidia.com/gpu'
After recovery
Re-run Terraform apply to reconcile Helm and Kubernetes resources once nodes are healthy.

Kick CI pipelines after Terraform completes; monitoring and GPU workloads will schedule cleanly on fresh nodes.

```

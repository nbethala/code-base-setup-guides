#  GPU node securtiy group while bootstrapping 

ensure a security group is attached to the main in the gpu_module . During the launch, the template used for bootstrapping using nodeadm uses the security group to launch the instance into SSM - using which you can check the health and metrics of the node server. 


✅ Which SG the GPU node group should use?
EKS creates 2 types of security groups:
1️⃣ The cluster security group (control plane SG)

AWS automatically creates this.
It allows:

inbound 443 from worker nodes

outbound to worker nodes

You do NOT attach this to nodes manually — AWS manages that.

2️⃣ The cluster shared node security group

This is the one nodes must use.
It allows:

Nodes ↔ Cluster communication

Kubelet, API, health checks

Required ports to join cluster

By default, this group is output by AWS EKS as:
cluster_resources.cluster_security_group_id

But you need to check your module structure.

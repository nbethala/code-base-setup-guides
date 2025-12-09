# This file will help to bootstrap an eks cluster with a GPU Node using Nodeadm 

```
📝 Two‑Phase Terraform Plan
Phase 1 — Cluster only
Apply just the cluster module

bash
terraform apply -target=module.eks -auto-approve
This provisions the control plane only.

No nodegroups yet, so you don’t risk failed joins.

Terraform warns about -target because it’s partial, but here it’s intentional.

Fetch cluster details

bash
aws eks describe-cluster --name triton-gpu-cluster \
  --query "cluster.endpoint" --output text
aws eks describe-cluster --name triton-gpu-cluster \
  --query "cluster.certificateAuthority.data" --output text
endpoint → API server URL.

certificateAuthority.data → base64 CA bundle.

These values go into your userdata-nodeadm.yaml.

Phase 2 — Nodegroups with nodeadm
Place userdata-nodeadm.yaml in module/gpu_node_group/

text
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="//"

--//
Content-Type: application/node.eks.aws

apiVersion: node.eks.aws/v1alpha1
kind: NodeConfig
spec:
  cluster:
    name: triton-gpu-cluster
    apiServerEndpoint: https://<cluster-endpoint>
    certificateAuthority: <base64-ca>
  kubelet:
    flags:
      - --node-labels=nvidia.com/gpu=true
    config:
      clusterDNS:
        - 10.100.0.10
--//
Reference it in your launch template (module/gpu_node_group/main.tf):

hcl
resource "aws_launch_template" "gpu_nodes" {
  name_prefix            = "gpu-node-"
  update_default_version = true

  user_data = base64encode(file("${path.module}/userdata-nodeadm.yaml"))
}
Define nodegroup:

hcl
resource "aws_eks_node_group" "gpu_nodes" {
  cluster_name    = module.eks.cluster_name
  node_group_name = "triton-gpu-cluster-gpu-on-demand"
  node_role_arn   = aws_iam_role.eks_gpu_node_role.arn
  subnet_ids      = module.vpc.private_subnets

  ami_type       = "AL2023_x86_64_NVIDIA"
  instance_types = ["g4dn.xlarge"]
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 0
  }

  launch_template {
    id      = aws_launch_template.gpu_nodes.id
    version = "$Latest"
  }
}
Apply full stack

bash
terraform apply -auto-approve
Now Terraform reconciles all modules (eks + gpu_node_group).

```

Nodes boot with nodeadm config and join automatically.

✅ Why this works
Phase 1 ensures you have stable cluster values (endpoint + CA).

Phase 2 wires those values into nodeadm config before nodes launch.

Full apply after that keeps Terraform state consistent — no drift, no partial resources.

⚡ Bottom line: create the cluster first, capture its endpoint/CA, then apply the full configuration including nodegroups with nodeadm.


# Node failed to register in EKS

```

✅ Recovery Steps
Step 1 — Inspect nodegroup events
bash
aws eks describe-nodegroup --cluster-name triton-gpu-cluster \
  --nodegroup-name triton-gpu-cluster-gpu-on-demand --region us-east-1
Look at statusMessage and health.issues.

# It will look something like this -

        },
        "health": {
            "issues": [
                {
                    "code": "NodeCreationFailure",
                    "message": "Instances failed to join the kubernetes cluster",
                    "resourceIds": [
                        "i-00fdb344294ab9da5"
                    ]
                }
            ]

This often tells you exactly why nodes failed (IAM, networking, bootstrap).

Step 2 — Verify IAM role policies
Attach missing policies if needed:

bash
aws iam attach-role-policy --role-name triton-gpu-cluster-node-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy

aws iam attach-role-policy --role-name triton-gpu-cluster-node-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy

aws iam attach-role-policy --role-name triton-gpu-cluster-node-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
Step 3 — Check nodeadm logs
SSH into one of the GPU nodes:

bash
journalctl -u nodeadm -f
Look for errors about CA, endpoint, or kubelet flags.

If endpoint/CA are wrong, fix your launch template user_data.

Step 4 — Recreate the nodegroup
Once fixes are in place:

bash
terraform apply -replace="module.gpu_node_group.aws_eks_node_group.gpu_on_demand"
This destroys and recreates the GPU nodegroup cleanly.

With IAM + nodeadm fixed, nodes should join successfully.

```
## nodes launched but couldn’t authenticate to the cluster. 
 Solution : Fix IAM policies, nodeadm bootstrap values, and networking, then re‑apply the nodegroup.

```
📝 Root Causes to Check
1. IAM Role Policies
Your GPU node role (triton-gpu-cluster-node-role) must have:

AmazonEKSWorkerNodePolicy

AmazonEKS_CNI_Policy

AmazonEC2ContainerRegistryReadOnly

Check:

bash
aws iam list-attached-role-policies --role-name triton-gpu-cluster-node-role
If any are missing, attach them:

bash
aws iam attach-role-policy --role-name triton-gpu-cluster-node-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy

aws iam attach-role-policy --role-name triton-gpu-cluster-node-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy

aws iam attach-role-policy --role-name triton-gpu-cluster-node-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
2. Nodeadm Bootstrap Config
Ensure your launch template user_data has:

Correct apiServerEndpoint (from aws eks describe-cluster)

Correct base64 certificateAuthority (from cluster output)

Correct cluster name (triton-gpu-cluster)

If any of these are wrong, kubelet can’t authenticate.

3. Networking
Nodes must be in private subnets with outbound access to the EKS control plane.

Security groups must allow HTTPS (443) to the cluster endpoint.

Check route tables and SG rules.

4. Inspect Node Logs
SSH into the failed instance:

bash
ssh -i <your-key.pem> ec2-user@<PublicIP>
journalctl -u nodeadm -f
Look for:

TLS errors → CA mismatch

Connection refused → wrong endpoint or blocked networking

Auth errors → IAM role not mapped or missing policies

✅ Recovery Path
Fix IAM role policies and confirm aws-auth mapping.

Verify nodeadm config (endpoint + CA).

Check networking/security group rules.

Recreate the nodegroup cleanly:

bash
terraform apply -replace="module.gpu_node_group.aws_eks_node_group.gpu_on_demand"
```

























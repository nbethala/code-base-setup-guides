## Guide to query aws cli commands
=====================================

# 1. Describe the cluster itself (endpoint, cert, IAM role, VPC config)
aws eks describe-cluster \
  --region us-east-1 \
  --name mlops-gpu-eks \
  --output json

# 2. List all node groups attached to the cluster
aws eks list-nodegroups \
  --region us-east-1 \
  --cluster-name mlops-gpu-eks \
  --output json

# 3. For each node group, describe it (IAM role, scaling config, subnets)
aws eks describe-nodegroup \
  --region us-east-1 \
  --cluster-name mlops-gpu-eks \
  --nodegroup-name <your-nodegroup-name> \
  --output json

# 4. List Fargate profiles (if you use Fargate)
aws eks list-fargate-profiles \
  --region us-east-1 \
  --cluster-name mlops-gpu-eks \
  --output json

# 5. Describe IAM identity used by your CLI (to confirm permissions)
aws sts get-caller-identity

# 6. List all clusters in the region (sanity check)
aws eks list-clusters \
  --region us-east-1 \
  --output json


What each gives you
describe-cluster → cluster endpoint, certificate authority, IAM role, VPC/subnet config.

list-nodegroups → names of all node groups.

describe-nodegroup → IAM role for nodes, scaling config, subnets, AMI type.

list-fargate-profiles → if you’re running pods on Fargate.

sts get-caller-identity → confirms which AWS account/role your CLI is using.

list-clusters → shows all clusters in the region.

### Pro Tip - If you want everything in one go, you can chain them:

aws eks describe-cluster --region us-east-1 --name mlops-gpu-eks --output json
aws eks list-nodegroups --region us-east-1 --cluster-name mlops-gpu-eks --output json | jq -r '.nodegroups[]' | while read ng; do
  aws eks describe-nodegroup --region us-east-1 --cluster-name mlops-gpu-eks --nodegroup-name "$ng" --output json
done
aws eks list-fargate-profiles --region us-east-1 --cluster-name mlops-gpu-eks --output json

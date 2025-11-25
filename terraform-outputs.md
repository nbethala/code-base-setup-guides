# This file to explain terraform IAC : 

Terraform init 
Terraform validate
Terraform apply 

------

Outputs: 
Cluster endpoint: https://78E7CB00EA9421E848DAA3FB3C9EB247.gr7.us-east-1.eks.amazonaws.com → This is the API server endpoint you’ll hit with kubectl.
Cluster name: gpu-e2e-cluster → Use this in aws eks update-kubeconfig.
Cluster role ARN: arn:aws:iam::478253497479:role/gpu-e2e-cluster-eks-cluster-role → This is the IAM role trusted by eks.amazonaws.com for control plane ops.
Private subnets: subnet-08b252da5a9b453bd, subnet-0e35456b2c64d49d2 → Control plane + nodes are running in these private subnets. Make sure NAT gateways are in place for outbound traffic.
VPC ID: vpc-0859595ac3d69546b → Your cluster networking backbone.

✅ Your Outputs Explained Clearly
1️⃣ Cluster Endpoint

https://78E7CB00EA9421E848DAA3FB3C9EB247.gr7.us-east-1.eks.amazonaws.com

This is the EKS API Server URL.

kubectl talks to this endpoint.

You do not change it manually; aws eks update-kubeconfig puts it in your kubeconfig.

2️⃣ Cluster Name

gpu-e2e-cluster

Used for:

aws eks update-kubeconfig --region us-east-1 --name gpu-e2e-cluster --profile nancy-devops


This ensures your kubeconfig context is updated.

3️⃣ Cluster Role ARN

arn:aws:iam::478253497479:role/gpu-e2e-cluster-eks-cluster-role

This IAM role is:

✔ Trusted by eks.amazonaws.com
✔ Used by the control plane to manage resources:

ENIs, security groups

CloudWatch logs

Load balancers

You never assign this to nodes.

4️⃣ Private Subnets

subnet-08b252da5a9b453bd, subnet-0e35456b2c64d49d2

These are where:

✔ Control plane ENIs live
✔ Worker nodes live (unless you use public subnets)

⚠ IMPORTANT:
Private subnets require a NAT Gateway for:

pulling container images

AWS API calls

VPC CNI communication

kubelet -> EKS control plane connectivity

If NAT is missing → nodes stay NotReady.

5️⃣ VPC ID

vpc-0859595ac3d69546b

Your entire EKS network stack:

Subnets

Route tables

IGW / NAT

Security groups

ENIs

Load balancers

All live inside this VPC.



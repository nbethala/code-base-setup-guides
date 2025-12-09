⭐ 1. The Three-Layer Mental Model of EKS

Think of EKS as three big layers:

┌───────────────────────────────────────────┐
│  LAYER 3: Kubernetes Workloads            │
│  (Pods, Deployments, Services, Triton)    │
└───────────────────────────────────────────┘
┌───────────────────────────────────────────┐
│  LAYER 2: Kubernetes Nodes (EC2 / GPU)    │
│  Node bootstrap, Kubelet, CNI, IAM Roles  │
└───────────────────────────────────────────┘
┌───────────────────────────────────────────┐
│  LAYER 1: Control Plane (AWS-managed)     │
│  API Server, etcd, EKS Endpoint, CA cert  │
└───────────────────────────────────────────┘

You never manage Layer 1. AWS does.

But Layers 2 & 3 are yours.

⭐ 2. What Terraform Actually Does

Terraform has ONE job:

Declare what you want → Terraform figures out how to build it in AWS.

Terraform manages:

VPC

Subnets

EKS cluster

Node groups (EC2/GPU)

IAM roles/policies

Security groups

Add-ons (CNI, Kube-proxy, CoreDNS)

ECR repositories

ALBs / NLBs for services

You don’t directly “create” anything. You define the desired state.

⭐ 3. EKS Control Plane: The 4 Values You MUST Understand

Every EKS cluster has four critical pieces:

1️⃣ Endpoint
https://ABCDEF123456.gr7.us-east-1.eks.amazonaws.com


The URL kubectl talks to.

2️⃣ Certificate Authority (CA)

A base64 string used by kubectl to trust the cluster endpoint.

3️⃣ Cluster IAM Role

The control plane's permissions to talk to AWS.

4️⃣ Node IAM Role

Permissions your worker nodes have (e.g., pulling images, CNI, logs).

These four are foundational — everything in EKS revolves around them.

⭐ 4. Node Bootstrap = The Most Misunderstood Concept

Nodes don’t magically join EKS. Something must configure them.

This something is the bootstrap script, which runs through user_data.

Your user_data file usually does this:

/etc/eks/bootstrap.sh cluster-name \
  --kubelet-extra-args ...


The bootstrap script:

Fetches cluster endpoint

Fetches CA

Tries to join the node to the control plane

Starts kubelet

Installs CNI plugins

Labels/taints nodes

Without bootstrap, nodes NEVER appear in:

kubectl get nodes


🔥 This is the #1 root cause of "node not joining" issues.

⭐ 5. Terraform Modules: What They Actually Do
module.vpc

Creates:

VPC

3 public + 3 private subnets

Internet Gateway/NAT Gateway

Route tables

module.eks

Creates:

EKS control plane

IAM control-plane role

IAM node roles

Node groups (GPU/CPU)

OIDC provider (for IAM service accounts)

Kubernetes add-ons

module.monitoring

Creates:

Prometheus

Grafana

AlertManager

Node exporter, DCGM exporter for GPUs

module.github_actions_oidc

Enables GitHub to deploy to EKS securely without static credentials.

module.ecr

Stores your Triton container images.

⭐ 6. EKS Networking — The “Trinity”

There are only 3 networking things that matter in EKS:

1. CNI (AWS VPC CNI)

Every pod gets a VPC IP.

2. kube-proxy

Routes Service traffic.

3. CoreDNS

DNS inside Kubernetes.

If these 3 add-ons fail, the cluster is broken.

⭐ 7. Terraform’s “known after apply” → What It Really Means

When Terraform shows:

eks_cluster_endpoint = (known after apply)


This means:

AWS will only generate this value after creating the cluster.

Terraform knows the structure but not the actual value yet.

This happens for:

Endpoint

CA certificate

Role ARN

Security group IDs

Subnet IDs

EBS volume IDs

You don’t need to fix it — it’s normal.

⭐ 8. State Management — The Source of 90% Problems

Terraform maintains a state file containing:

AWS resources Terraform created


If state is out of sync:

Terraform tries to recreate existing resources

Or fails deleting resources that are gone

Or complains resources already exist

When you deleted your EKS manually, Terraform state still thought it existed → errors.

⭐ 9. Clean-Slate Plan (your situation)

You want:

✓ Delete old cluster
✓ Delete ECR repositories
✓ Delete VPC
✓ Delete IAM roles
✓ Start fresh with clean repo

This is EXACTLY correct when things are messy.

⭐ 10. Mastery Path (Short but Deep Learning)

Here’s how to become “senior-level” with EKS & cloud infra in weeks:

Phase 1: Visual Mental Models

Understand:

Cluster components

Node bootstrap

Networking

CI/CD flow

Phase 2: Hands-On Deep Dive

Deploy:

1 EKS cluster

1 GPU node group

1 workload (Triton)

1 monitoring stack

1 CI/CD pipeline

Phase 3: Rebuild it 3–4 times

Every rebuild gives you 2× clarity.

Phase 4: Debugging Patterns

Learn:

Nodes not joining

Pods stuck Pending

CNI issues

ALB ingress issues

IAM role misconfigurations

Phase 5: Scale & Optimize

Autoscaling

IRSA

GPU monitoring

Spot nodes

Taints/tolerations

Horizontal Pod Autoscaling

Optimized container images

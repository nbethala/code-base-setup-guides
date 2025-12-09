# Study guide - read 20% high level for 80% throughput
==========================================================

1 — Master mental map 

Visualize an EKS deployment as three concentric/stacked zones:

[ User / CI/CD / External ]  --> interacts with
[ Control Plane (AWS-managed) ]  --> exposes Endpoint + CA + Auth
[ Node Plane (your EC2 GPU/CPU nodes) ]  --> runs pods (Triton, exporters)
[ Cloud Infra (VPC, Subnets, LB, Storage, IAM, ECR) ]  --> networking & permissions


Short labels:

Control Plane = API + etcd (AWS-managed)

Node Plane = EC2 instances (kubelet, docker/containerd, gpu drivers, kube-proxy, CNI)

Cloud Infra = VPC, IGW/NAT, route tables, SGs, EBS, ELB/NLB

Glue = IAM roles, OIDC/IRSA, user-data bootstrap, kubeconfigs/tokens

Observability = Prometheus, Grafana, CloudWatch, DCGM for GPUs

CI/CD = GitHub Actions (OIDC) → builds → pushes to ECR → deploys manifests

2 — Component mental maps (one-by-one, high-yield)
A. Control Plane (EKS)

What: AWS-managed Kubernetes API + state.

Key outputs you care about: endpoint, cluster_ca_certificate, cluster IAM role ARN.

Why it matters: all kubectl and provider connections need endpoint+CA+token.

Terraform signals: data.aws_eks_cluster.* for reads; resource.aws_eks_cluster for managed cluster.

Quick checks: aws eks list-clusters, kubectl get nodes (after kubeconfig).

Common pitfalls: expecting to manage etcd; data sources failing after manual deletion.

B. Nodes (EC2 / NodeGroups)

What: worker VMs running kubelet + container runtime; GPU nodes have drivers.

Glue: user_data bootstrap → joins nodes to control plane.

Key roles: Node IAM (pull from ECR, attach CNI, CloudWatch).

Common issues: nodes stuck in NotReady — usually bootstrap, CNI, or AMI mismatch.

Practice task: inspect user-data and watch systemctl status kubelet; journalctl -u kubelet -f.

C. Networking & VPC

What matters: subnets (public/private), route tables, IGW, NAT gateway, service ELBs.

K8s nuance: Pods IP allocation (AWS CNI) — affects subnet IP capacity.

Terraform focus: create subnet-per-AZ, route tables, security groups with least privilege.

Check: aws ec2 describe-vpcs, kubectl get svc for LoadBalancer addresses.

D. IAM & IRSA (Identity)

What: roles for control plane, node instance roles, IRSA (service-account -> role).

Mental model: one role per trust boundary; OIDC provider gives fine-grained service account perms.

Commands: list roles/policies, detach before delete.

Pitfall: role name collisions when reapplying without state/import.

E. Container Registry (ECR)

What: stores images (Triton). Usually push with GitHub Actions.

Important: repositories must be emptied before deletion (or force_delete=true).

Check: aws ecr describe-repositories, aws ecr list-images.

F. Storage & Volumes

EBS for persistent volumes; EFS for shared storage.

Provisioner: use StorageClass; GPU models need PVs only sometimes (model weights).

Pitfall: orphaned EBS volumes after node termination — watch DescribeVolumes.

G. CI/CD (GitHub Actions + OIDC)

What: ephemeral tokens via OIDC; avoid long-lived creds.

Flow: Action builds → aws ecr get-login-password via OIDC → push → K8s manifests via kubectl.

Practice: create a minimal OIDC role and test aws sts get-caller-identity from GH runner.

H. Observability & GPU Telemetry

Prometheus + Grafana for metrics, DCGM-exporter for GPU metrics, node-exporter for host metrics.

Common checks: GPU metrics visible? kubectl top nodes, nvidia-smi on node.

Alerting: set alerts for GPU mem, temperature, node NotReady.

3 — Step-by-step “Read → Understand → Build” workflow (actionable)

Follow these stages in order. After each stage, perform the short exercise and the verification checks.

Stage 0 — Preconditions (what you need now)

AWS CLI configured (aws sts get-caller-identity works).

Terraform v1.x installed.

kubectl installed.

jq installed.

Access to the repo mlops-NEW locally.

Stage 1 — Understand the design (read)

Open modules/eks/main.tf and modules/vpc/* — identify outputs and data sources.

Locate userdata-nodeadm.yaml — read it. Identify bootstrap command (eks bootstrap).

Exercise: write a one-sentence summary: “This module does X and creates Y.”

Stage 2 — Local dry-run & safety

terraform init

terraform plan -out=tfplan

Inspect plan for resources with (known after apply) — note them.

Exercise: find the aws_eks_cluster and note outputs.

Stage 3 — Clean up conflicts (if any)

If AWS has leftover resources from previous runs, either import them to state or delete them manually. Use the one-shot IAM detach/delete script you ran earlier.

Commands: aws eks list-clusters, aws iam list-roles | grep triton, aws ec2 describe-vpcs.

Stage 4 — Create core infra (apply in order)

Apply VPC & networking:

cd infra/terraform && terraform apply -target=module.vpc -auto-approve

Verify: aws ec2 describe-subnets --filters Name=vpc-id,...

Apply IAM roles & ECR:

terraform apply -target=module.iam -target=module.ecr -auto-approve

Verify roles exist: aws iam get-role --role-name <role>

Apply EKS cluster:

terraform apply -target=module.eks -auto-approve

Verify cluster: aws eks describe-cluster --name <cluster> and kubectl via generated kubeconfig.

Apply node groups (GPU):

terraform apply -target=module.eks.node_groups -auto-approve (adjust to your module structure)

Verify nodes: kubectl get nodes and kubectl describe node <name> then nvidia-smi on node (ssh).

Deploy Triton workload + monitoring.

Note: using -target is tactical for learning; when comfortable you can terraform apply the full root.

Stage 5 — CI/CD & ECR integration

Build a tiny image and push to ECR manually to test registry auth.

Configure GitHub Action OIDC (if using) and test push.

Exercise: create a GitHub Action job that builds and pushes a tiny nginx image.

Stage 6 — Observability & Ops

Deploy Prometheus + Grafana using your module or Helm.

Deploy DCGM exporter to GPU nodes.

Create dashboards and set one alert.

4 — Verification & checks (commands to run and what success looks like)

Cluster exists: aws eks list-clusters → contains triton-gpu-cluster

Kubeconfig works: kubectl cluster-info

Nodes Ready: kubectl get nodes → STATUS Ready

GPU visible: kubectl get nodes -o wide and on node: nvidia-smi

Pods running: kubectl get pods -A → desired pods in Running

ECR image list: aws ecr list-images --repository-name triton-infer

No orphan VPCs: aws ec2 describe-vpcs --filters Name=tag:Name,Values=<your-prefix>

5 — Troubleshooting cheat-sheet (fast fixes)

Node stuck NotReady: check journalctl -u kubelet and user-data logs at /var/log/cloud-init-output.log.

Pods Pending (Insufficient resources): kubectl describe pod to see reason (Insufficient cpu/memory).

Image pull error: kubectl describe pod → imagePullBackOff → check ECR repo and IAM role for nodes.

Control plane data source error (couldn't find resource): cluster deleted — comment out data source or re-import cluster.

Plan tries to create resources that already exist: import them (terraform import ...) or delete the AWS resource.

6 — Hands-on micro-exercises (do these in order)

Read userdata-nodeadm.yaml and annotate each command with one-line purpose.

Run terraform plan -destroy and explain why each resource is listed.

Launch a single small node group (one t3.medium), get it to Ready, run kubectl run hello --image=nginx.

Build & push a tiny image to ECR, deploy it as a Deployment and expose as ClusterIP + port-forward to test.

Install node-exporter + prometheus + visualize node metrics in Grafana.

7 — Reference checklist & cheat commands (copyable)

Initialize & plan:

terraform init
terraform validate
terraform plan -out=tfplan


Apply safely (module by module):

terraform apply -target=module.vpc -auto-approve
terraform apply -target=module.iam -target=module.ecr -auto-approve
terraform apply -target=module.eks -auto-approve


Quick AWS checks:

aws eks list-clusters
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*triton*"
aws iam list-roles | grep triton
kubectl get nodes
kubectl get pods -A


Detach & delete role (if stuck):

ROLE="triton-mlops-github-actions-oidc-role"
aws iam list-attached-role-policies --role-name $ROLE --query "AttachedPolicies[*].PolicyArn" --output text \
  | xargs -n 1 -I {} aws iam detach-role-policy --role-name $ROLE --policy-arn {}
aws iam list-role-policies --role-name $ROLE --query "PolicyNames" --output text \
  | xargs -n 1 -I {} aws iam delete-role-policy --role-name $ROLE --policy-name {}
aws iam delete-role --role-name $ROLE

8 — Learning path & next actions (what to do right now)

Read this mental map top to bottom — 10 minutes.

Do Stage 1 (open files) and Stage 2 (terraform init + plan) — annotate as you go.

Run Stage 3 cleanup commands if you still have AWS leftovers.

Apply VPC → IAM → EKS in order and run the verification checks.

Stop & reflect after each stage; write 2–3 sentences about what you learne

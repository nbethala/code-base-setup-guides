Summary
This script prepares a GPU-backed EC2 instance for Triton or other inference workloads with:

NVIDIA driver + container runtime

Docker with GPU support

Swap disabled (required for Kubernetes GPU scheduling)

SSM-only access and instance tagging

ECR login validation

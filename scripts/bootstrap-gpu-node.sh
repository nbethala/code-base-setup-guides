# Use this script to setup a GPU node in cloud

#!/bin/bash
set -euo pipefail

echo "🔧 Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo "🛠️ Installing core tools..."
sudo apt install -y curl unzip jq git htop python3-pip

echo "🐳 Installing Docker..."
curl -fsSL https://get.docker.com | sudo bash
sudo usermod -aG docker $USER
sudo systemctl enable docker
sudo systemctl start docker

echo "📦 Installing NVIDIA drivers and container runtime..."
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt update
sudo apt install -y nvidia-driver-525 nvidia-container-toolkit
sudo systemctl restart docker

echo "🧠 Disabling swap (required for GPU scheduling)..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

echo "✅ Verifying GPU access..."
nvidia-smi || echo "⚠️ NVIDIA driver or GPU not detected"

echo "🔐 Disabling SSH (SSM-only access assumed)..."
sudo systemctl stop ssh || true
sudo systemctl disable ssh || true

echo "🔍 Verifying SSM agent..."
sudo systemctl status amazon-ssm-agent || echo "⚠️ SSM agent not running"

echo "📦 Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws/

echo "🧪 Tagging instance (requires metadata access)..."
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
aws ec2 create-tags --resources "$INSTANCE_ID" --region "$REGION" \
  --tags Key=env,Value=gpu Key=owner,Value=nancy Key=purpose,Value=triton-infer

echo "🔐 Testing ECR login (replace with your ECR URL)..."
aws ecr get-login-password --region "$REGION" | \
  docker login --username AWS --password-stdin <your-ecr-url>

echo "✅ GPU bootstrap complete. Reboot recommended to finalize driver and Docker group setup."

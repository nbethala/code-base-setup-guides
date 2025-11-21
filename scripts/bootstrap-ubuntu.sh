# use this script to prep EC2 instance

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

echo "✅ Verifying Docker installation..."
docker run --rm hello-world || echo "⚠️ Docker test failed — check permissions"

echo "📦 Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws/

echo "🔐 Disabling SSH (SSM-only access assumed)..."
sudo systemctl stop ssh || true
sudo systemctl disable ssh || true

echo "🔍 Verifying SSM agent..."
sudo systemctl status amazon-ssm-agent || echo "⚠️ SSM agent not running"

echo "🧠 Disabling swap (GPU nodes only)..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

echo "🧪 Tagging instance (requires instance metadata access)..."
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
aws ec2 create-tags --resources "$INSTANCE_ID" --region "$REGION" \
  --tags Key=env,Value=dev Key=owner,Value=nancy Key=purpose,Value=triton-build

echo "🔐 Testing ECR login (replace with your ECR URL)..."
aws ecr get-login-password --region "$REGION" | \
  docker login --username AWS --password-stdin <your-ecr-url>

echo "✅ Bootstrap complete. Please reboot or re-login to activate Docker group permissions."

# script : This script bootstraps a new EC2 Instance 

#!/usr/bin/env bash
set -e

##############################################
# 1. UPDATE SYSTEM & INSTALL ESSENTIALS
##############################################
echo ">> Updating system and installing base packages..."
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y \
    git \
    curl \
    wget \
    unzip \
    build-essential \
    tmux \
    python3 \
    python3-venv \
    python3-pip

##############################################
# 2. INSTALL AWS CLI v2
##############################################
if ! command -v aws &> /dev/null; then
    echo ">> Installing AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws
else
    echo ">> AWS CLI already installed."
fi

##############################################
# 3. INSTALL DOCKER
##############################################
if ! command -v docker &> /dev/null; then
    echo ">> Installing Docker..."
    sudo apt install -y docker.io
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker $USER
else
    echo ">> Docker already installed."
fi

##############################################
# 4. ENABLE DOCKER BUILDX (multi-arch support)
##############################################
echo ">> Enabling Docker Buildx..."
sudo docker buildx create --use || true

##############################################
# 5. PYTHON ENVIRONMENT (VENV)
##############################################
echo ">> Creating Python virtual environment..."
if [ ! -d "$HOME/venv" ]; then
    python3 -m venv $HOME/venv
fi

echo ">> Activating venv..."
source $HOME/venv/bin/activate

##############################################
# 6. BASIC PYTHON ML PACKAGES (optional)
##############################################
echo ">> Installing essential Python packages..."
pip install --upgrade pip
pip install \
    jupyterlab \
    boto3 \
    numpy \
    pandas \
    requests

##############################################
# 7. GIT CONFIG (OPTIONAL BUT RECOMMENDED)
##############################################
if [ -z "$(git config --global user.name)" ]; then
    echo ">> Setting up Git defaults..."
    git config --global pull.rebase false
    git config --global init.defaultBranch main
fi

##############################################
# 8. PRINT COMPLETION MESSAGE
##############################################
echo "--------------------------------------------------"
echo "Bootstrap completed successfully!"
echo "IMPORTANT: Log out and log back in to use Docker."
echo "--------------------------------------------------"

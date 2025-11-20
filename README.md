# code-base-setup-guides
code and scripts to help setup instances .

## This repo will host scripts,code, notes to setup environment quickly to increase productivity .

### ec2-bootstrap-script.sh 
usage : A full bootstrap bash shell script that installs everything needed to get started automatically

📌 How to Use It
1) SSH into your EC2 dev instance
ssh -i your-key.pem ubuntu@<public-ip>

2) Save script
nano bootstrap.sh

3) Make executable
chmod +x bootstrap.sh

4) Run it
./bootstrap.sh

5) Logout → log back in
Docker group changes apply only after re-login.

🎯 What Your Dev Machine Can Now Do

✔ Pull your GitHub repo
✔ Run Python/ML code
✔ Build Docker images
✔ Authenticate to ECR
✔ Push images to ECR
✔ Prepare model containers
✔ Launch local Jupyter if needed
✔ Use tmux for long-running jobs
✔ Trigger deployments to GPU EC2

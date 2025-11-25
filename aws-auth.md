✅ How To Auto-Generate aws-auth via Terraform (recommended)

Create a Terraform-managed configmap instead of doing it manually.

Example:

resource "kubectl_manifest" "aws_auth" {
  yaml_body = <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${module.iam.eks_node_role_arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes

    - rolearn: ${module.iam.eks_operator_role_arn}
      username: eks-operator
      groups:
        - system:masters
EOF
}


This ensures the ConfigMap is always correct, without manual edits.

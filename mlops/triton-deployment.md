# Triton deployment in kubernetes 

### ✔ 1. Triton has many moving parts

A typical deployment includes:

Deployment / DaemonSet

ConfigMap or model repository mounts

Service (gRPC + HTTP)

Liveness/readiness probes

GPU resources

Node affinity / tolerations

Model repository sidecars (optional)

With YAML, you manually maintain all.
With Helm, these are template-driven & versioned.

✔ 2. Version upgrades are safer

Upgrading Triton manually = delete + recreate, risk of outages
Helm upgrades = atomic, rollback capable:

✔ 3. Easy to plug in auto-scaling + custom configs

You can pass GPU-related values in values.yaml:

✔ 4. Production IaC best practices

You’re building a production-style portfolio project.

Modern Infra teams expect:

Terraform for infra

Helm for k8s apps

GitOps or CI/CD for promoting values.yaml

Raw YAML = junior.
Helm = production engineer.

When YAML is better

Only when:

You are writing a highly custom microservice

You want to deeply understand k8s object properties

You are building the base Helm chart itself

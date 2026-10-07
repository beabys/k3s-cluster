.PHONY: plan plan-bootstrap apply bootstrap destroy

# Fresh cluster: preview pass 1 (Helm releases + CRDs). CRD manifests are gated off.
plan-bootstrap:
	terraform plan -var-file=terraform.tfvars -var enable_crd_manifests=false

# Pass 1: install Helm releases (installs all CRDs) + core ingresses. Required before `make apply` on a fresh cluster.
bootstrap:
	terraform apply -var-file=terraform.tfvars -var enable_crd_manifests=false

# Preview pass 2 (CRD manifests). Only valid AFTER `make bootstrap` (CRDs must exist).
plan:
	terraform plan -var-file=terraform.tfvars -var enable_crd_manifests=true

# Pass 2: create CRD manifests (Middleware, IPAddressPool, ServiceMonitor, ClusterSecretStore, Fission CRs).
apply:
	terraform apply -var-file=terraform.tfvars -var enable_crd_manifests=true

destroy:
	terraform destroy -var-file=terraform.tfvars

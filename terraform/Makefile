.PHONY: plan apply bootstrap destroy

bootstrap:
	terraform apply -var-file=terraform.tfvars -var enable_crd_manifests=false

apply:
	terraform apply -var-file=terraform.tfvars -var enable_crd_manifests=true

plan:
	terraform plan -var-file=terraform.tfvars -var enable_crd_manifests=true

destroy:
	terraform destroy -var-file=terraform.tfvars
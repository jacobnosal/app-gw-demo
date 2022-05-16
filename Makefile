default: docs

.PHONY: docs
docs: 
	cat README.md

build:
	set -o errexit; set -o allexport; source .env; set +o allexport; \
	terraform plan -out main.tfplan; \
	terraform apply main.tfplan

destroy:
	set -o errexit; \
	terraform plan -destroy -out main.destroy.tfplan; \
	terraform apply main.destroy.tfplan
default: docs

.PHONY: docs
docs: 
	cat README.md

build:
	set -o errexit; set -o allexport; source .env; set +o allexport; \
	terraform plan -out main.tfplan -var-file demo.tfvars; \
	terraform apply main.tfplan

.PHONY: agic
agic:
	set -o errexit; set -o allexport; source .env; set +o allexport; \
	./agic/install.sh; \
	cd ..

.phony: services
services:
	set -o errexit; \
	cd app; \
	kubectl apply -f services.yaml; \
	cd ..

.phony: pods
pods:
	set -o errexit; \
	cd app; \
	kubectl apply -f pods.yaml; \
	cd ..

.phony: delete-apps
delete-apps:
	set -o errexit; \
	cd app; \
	kubectl delete -f pods.yaml; \
	kubectl delete -f services.yaml; \
	cd ..

destroy:
	set -o errexit; \
	terraform plan -destroy -out main.destroy.tfplan; \
	terraform apply main.destroy.tfplan
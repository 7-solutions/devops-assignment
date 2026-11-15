.PHONY: build image kustomize ansible-syntax

DOCKERHUB_USER ?= your-dockerhub-username
IMAGE_TAG ?= 0.1.0
IMAGE ?= docker.io/$(DOCKERHUB_USER)/hello-api

build:
	go build -trimpath -ldflags="-s -w" -o bin/hello-api .

image:
	docker build -t $(IMAGE):$(IMAGE_TAG) .

kustomize:
	kubectl kustomize infra/k8s/overlays/prod

ansible-syntax:
	cd ansible && ansible-playbook -i inventory.ini.example site.yml --syntax-check

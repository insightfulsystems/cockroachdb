export IMAGE_NAME?=insightful/cockroachdb
export VCS_REF=`git rev-parse --short HEAD`
export VCS_URL=https://github.com/insightfulsystems/cockroachdb
export BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
export TAG_DATE=`date -u +"%Y%m%d"`
export GOLANG_TAG=1.13.3-alpine3.10
export BUILD_IMAGE_NAME=golang
export TARGET_ARCHITECTURES=amd64 arm64v8 arm32v7 arm32v6
export QEMU_ARCHITECTURES=arm aarch64
export SHELL=/bin/bash
export DOCKER=docker
export COCKROACH_VERSION=v19.1.5

# Permanent local overrides
-include .env

.PHONY: build qemu wrap push manifest clean

qemu:
	@echo "==> Setting up QEMU"
	-$(DOCKER) run --rm --privileged multiarch/qemu-user-static:register --reset
	-mkdir tmp
	$(foreach ARCH, $(QEMU_ARCHITECTURES), make fetch-qemu-$(ARCH);)
	@echo "==> Done setting up QEMU"

fetch-qemu-%:
	$(eval ARCH := $*)
	@echo "--> Fetching QEMU binary for $(ARCH)"
	cd tmp && \
	curl -L -o qemu-$(ARCH)-static.tar.gz \
		https://github.com/multiarch/qemu-user-static/releases/download/v$(QEMU_VERSION)/qemu-$(ARCH)-static.tar.gz && \
	tar xzf qemu-$(ARCH)-static.tar.gz && \
	cp qemu-$(ARCH)-static ../qemu/
	@echo "--> Done."

build:
	@echo "==> Building all containers"
	$(foreach ARCH, $(TARGET_ARCHITECTURES), make build-$(ARCH);)
	@echo "==> Done."

build-%:
	$(eval ARCH := $*)
	@echo "--> Building $(ARCH)"
	$(DOCKER) build --build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg COCKROACH_VERSION=$(COCKROACH_VERSION) \
		--build-arg ARCH=$(ARCH) \
		--build-arg BASE=$(ARCH)/$(BUILD_IMAGE_NAME):$(GOLANG_TAG) \
		--build-arg VCS_REF=$(VCS_REF) \
		--build-arg VCS_URL=$(VCS_URL) \
		-t $(IMAGE_NAME):$(ARCH) src
	@echo "--> Done building $(ARCH)"

push:
	@echo "==> Pushing $(IMAGE_NAME)"
	$(DOCKER) push $(IMAGE_NAME)
	@echo "==> Done."

push-%:
	$(eval ARCH := $*)
	$(DOCKER) push $(IMAGE_NAME):$(ARCH)

expand-%: # expand architecture variants for manifest
	@if [ "$*" == "amd64" ] ; then \
	   echo '--arch $*'; \
	elif [[ "$*" == *"arm"* ]] ; then \
	   echo '--arch arm --variant $*' | cut -c 1-21,27-; \
	fi

manifest:
	@echo "==> Building multi-architecture manifest"
	$(foreach STEP, build push, make $(STEP)-manifest;)
	@echo "==> Done."	

build-manifest:
	@echo "--> Creating manifest"
	$(eval DOCKER_CONFIG := $(shell echo "$(DOCKER)" | cut -f 2 -d=)/config.json)
	cat $(DOCKER_CONFIG) | grep -v auth
	$(DOCKER) manifest create --amend \
		$(IMAGE_NAME):latest \
		$(foreach arch, $(TARGET_ARCHITECTURES), $(IMAGE_NAME):$(arch) )
	$(foreach arch, $(TARGET_ARCHITECTURES), \
		$(DOCKER) manifest annotate \
			$(IMAGE_NAME):latest \
			$(IMAGE_NAME):$(arch) $(shell make expand-$(arch));)

push-manifest:
	@echo "--> Pushing manifest"
	$(DOCKER) manifest push $(IMAGE_NAME):latest

clean:
	@echo "==> Cleaning up old images..."
	-$(DOCKER) rm -fv $$($(DOCKER) ps -a -q -f status=exited)
	-$(DOCKER) rmi -f $$($(DOCKER) images -q -f dangling=true)
	-$(DOCKER) rmi -f $(BUILD_IMAGE_NAME)
	-$(DOCKER) rmi -f $$($(DOCKER) images --format '{{.Repository}}:{{.Tag}}' | grep $(IMAGE_NAME))
	@echo "==> Done."
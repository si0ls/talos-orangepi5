NAME ?= talos-orangepi5

REGISTRY ?= ghcr.io
USERNAME ?= si0ls
REGISTRY_AND_USERNAME ?= $(REGISTRY)/$(USERNAME)
SOURCE ?= https://github.com/${USERNAME}/${NAME}.git
AUTHORS ?= Louis S. <louis@schne.id>
PUSH ?= false
ARTIFACTS ?= ./out

TAG ?= $(shell git describe --tag --always --dirty --match v[0-9]\*)

KERNEL_TAG ?= 6.8.1
KERNEL_SOURCE ?= https://git.kernel.org/stable/t/linux-${KERNEL_TAG}.tar.gz
KERNEL_TAG_SEMVER ?= $(shell echo $(KERNEL_TAG) | sed 's/^\([0-9]*\.[0-9]*\)$$/\1.0/')
KERNEL_TAINT ?= -$(NAME)
KERNEL_VERSION ?= $(KERNEL_TAG_SEMVER)$(KERNEL_TAINT)
KERNEL_OUTPUT_NAME ?= $(NAME)-kernel
KERNEL_OUTPUT_TAG ?= $(KERNEL_TAG_SEMVER)-$(TAG)
KERNEL_OUTPUT_IMAGE ?= $(REGISTRY_AND_USERNAME)/$(KERNEL_OUTPUT_NAME):$(KERNEL_OUTPUT_TAG)

TALOS_TAG ?= v1.7.0-alpha.1
TALOS_SOURCE ?= https://github.com/siderolabs/talos.git
TALOS_VERSION ?= $(TALOS_TAG)
TALOS_AMD64_KERNEL ?= ghcr.io/siderolabs/kernel:v1.7.0-alpha.0-35-g8804a60
IMAGER_TALOS ?= talos/$(TALOS_VERSION)
IMAGER_OUTPUT_NAME ?= $(NAME)-imager
IMAGER_OUTPUT_TAG ?= $(TALOS_VERSION)-$(TAG)
IMAGER_OUTPUT_IMAGE ?= $(REGISTRY_AND_USERNAME)/$(IMAGER_OUTPUT_NAME):$(IMAGER_OUTPUT_TAG)

INSTALLER_VERSION ?= $(TAG)
INSTALLER_OUTPUT_NAME ?= $(NAME)-installer
INSTALLER_OUTPUT_TAG ?= $(TAG)
INSTALLER_OUTPUT_IMAGE ?= $(REGISTRY_AND_USERNAME)/$(INSTALLER_OUTPUT_NAME):$(INSTALLER_OUTPUT_TAG)

SATA_EXTENSION_VERSION ?= $(TAG)
SATA_EXTENSION_OUTPUT_NAME ?= $(NAME)-sata-extension
SATA_EXTENSION_OUTPUT_TAG ?= $(TAG)
SATA_EXTENSION_OUTPUT_IMAGE ?= $(REGISTRY_AND_USERNAME)/$(SATA_EXTENSION_OUTPUT_NAME):$(SATA_EXTENSION_OUTPUT_TAG)

EXTENSIONS :=
IMAGER_ARGS :=
SATA ?= false
SATA_NAME :=
ifeq ($(SATA),true)
#	EXTENSIONS += --system-extension-image=$(SATA_EXTENSION_OUTPUT_IMAGE)
	IMAGER_ARGS += --sata=true
	SATA_NAME := -sata
endif

BUILD := docker buildx build
PROGRESS ?= auto
PLATFORM ?= linux/arm64
COMMON_ARGS := --progress="$(PROGRESS)"
COMMON_ARGS += --platform="$(PLATFORM)"
COMMON_ARGS += --push="$(PUSH)"
COMMON_ARGS += --build-arg="IMAGE_SOURCE="$(SOURCE)"
COMMON_ARGS += --build-arg="IMAGE_AUTHORS="$(AUTHORS)"

.PHONY: all
all: build

.PHONY: build
build: kernel imager installer

.PHONY: build-%
build-%:
	$(BUILD) \
		$(COMMON_ARGS) \
		$(BUILD_ARGS) \
		--file="$*/Dockerfile" \
		--target="$*" \
		$*

.PHONY: kernel
kernel:
	$(MAKE) build-kernel \
		BUILD_ARGS="--tag=\"$(KERNEL_OUTPUT_IMAGE)\" \
			--build-arg=\"KERNEL_VERSION=$(KERNEL_VERSION)\" \
			--build-arg=\"KERNEL_SOURCE=$(KERNEL_SOURCE)\" \
			$(BUILD_ARGS)"

$(IMAGER_TALOS):
	git clone --depth 1 --single-branch --branch $(TALOS_TAG) $(TALOS_SOURCE) $@ && \
		sed -i "s/DefaultKernelVersion = \".*\"/DefaultKernelVersion = \"$(KERNEL_VERSION)\"/g" $@/pkg/machinery/constants/constants.go && \
		rm $@/hack/modules-arm64.txt && cp imager/modules.txt $@/hack/modules-arm64.txt

.PHONY: imager
imager: $(IMAGER_TALOS)
	$(MAKE) -C $< \
		REGISTRY="$(REGISTRY)" \
		USERNAME="$(USERNAME)" \
		TAG="$(TALOS_TAG)" \
		PKG_KERNEL="$(KERNEL_OUTPUT_IMAGE)" \
		PLATFORM=$(PLATFORM) \
		ARCH=arm64 \
		PUSH=$(PUSH) \
		target-$@ \
		TARGET_ARGS="--output=\"type=image,name=$(IMAGER_OUTPUT_IMAGE)\" \
			--label=\"org.opencontainers.image.name=$(IMAGER_OUTPUT_NAME)\" \
			--label=\"org.opencontainers.image.title=Talos Orange Pi 5 imager\" \
			--label=\"org.opencontainers.image.description=Talos Orange Pi 5 imager\" \
			--label=\"org.opencontainers.image.source=$(SOURCE)\" \
			--label=\"org.opencontainers.image.authors=$(AUTHORS)\" \
			--label=\"org.opencontainers.image.vendor=Sidero Labs, Inc.\" \
			--label=\"org.opencontainers.image.version=$(IMAGER_OUTPUT_TAG)\" \
			--build-context=\"pkg-kernel-amd64=docker-image://$(TALOS_AMD64_KERNEL)\" \
			$(BUILD_ARGS)"

.PHONY: installer
installer:
	$(MAKE) build-installer \
		BUILD_ARGS="--tag=\"$(INSTALLER_OUTPUT_IMAGE)\" \
			--build-arg=KERNEL=\"$(KERNEL_OUTPUT_IMAGE)\" \
			--build-arg=VERSION=\"$(INSTALLER_VERSION)\" \
			$(BUILD_ARGS)"

.PHONY: sata-extension
sata-extension:
	$(MAKE) build-sata-extension \
		BUILD_ARGS="--tag=\"$(SATA_EXTENSION_OUTPUT_IMAGE)\" \
			--build-arg=KERNEL=\"$(KERNEL_OUTPUT_IMAGE)\" \
			--build-arg=VERSION=\"$(SATA_EXTENSION_VERSION)\" \
			$(BUILD_ARGS)"

.PHONY: artifacts
artifacts:
	mkdir -p $(ARTIFACTS)
	docker container run \
		--privileged \
		--platform=$(PLATFORM) \
		--pull=always \
		--net=host \
		-v /dev:/dev \
		--rm \
		-it \
		-v $(ARTIFACTS):/out \
		$(IMAGER_OUTPUT_IMAGE) \
		metal \
		--arch=arm64 \
		--overlay-name=orangepi-5 \
		--overlay-image=$(INSTALLER_OUTPUT_IMAGE) \
		$(IMAGER_ARGS) \
		$(EXTENSIONS) && \
		mv $(ARTIFACTS)/metal-arm64.raw.xz $(ARTIFACTS)/$(NAME)$(SATA_NAME).raw.xz

.PHONY: push
push:
	$(MAKE) build PUSH=true

.PHONY: clean
clean:
	rm -rf $(IMAGER_TALOS) $(ARTIFACTS)

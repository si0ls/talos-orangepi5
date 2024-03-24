NAME ?= talos-orangepi5

REGISTRY ?= ghcr.io
USERNAME ?= si0ls
REGISTRY_AND_USERNAME ?= $(REGISTRY)/$(USERNAME)
SOURCE ?= https://github.com/${USERNAME}/${NAME}.git
AUTHORS ?= Louis S. <louis@schne.id>
PUSH ?= false

TAG ?= $(shell git describe --tag --always --dirty --match v[0-9]\*)

KERNEL_TAG ?= 6.8
KERNEL_SOURCE ?= https://git.kernel.org/torvalds/t/linux-${KERNEL_TAG}.tar.gz
KERNEL_TAG_SEMVER ?= $(shell echo $(KERNEL_TAG) | sed 's/^\([0-9]*\.[0-9]*\)$$/\1.0/')
KERNEL_TAINT ?= -$(NAME)
KERNEL_VERSION ?= $(KERNEL_TAG_SEMVER)$(KERNEL_TAINT)
KERNEL_OUTPUT_NAME ?= $(NAME)-kernel
KERNEL_OUTPUT_TAG ?= $(KERNEL_TAG_SEMVER)-$(TAG)
KERNEL_OUTPUT_IMAGE ?= $(REGISTRY_AND_USERNAME)/$(KERNEL_OUTPUT_NAME):$(KERNEL_OUTPUT_TAG)

U_BOOT_TAG ?= v2024.04-rc4
U_BOOT_SOURCE ?= https://gitlab.denx.de/u-boot/u-boot/-/archive/$(U_BOOT_TAG)/u-boot-$(U_BOOT_TAG).tar.gz
U_BOOT_RKBIN_SOURCE ?= https://github.com/rockchip-linux/rkbin/archive/refs/heads/master.tar.gz
U_BOOT_VERSION ?= $(U_BOOT_TAG)
U_BOOT_OUTPUT_NAME ?= $(NAME)-u-boot
U_BOOT_OUTPUT_TAG ?= $(U_BOOT_VERSION)-$(TAG)
U_BOOT_OUTPUT_IMAGE ?= $(REGISTRY_AND_USERNAME)/$(U_BOOT_OUTPUT_NAME):$(U_BOOT_OUTPUT_TAG)

TALOS_TAG ?= v1.7.0-alpha.1
TALOS_SOURCE ?= https://github.com/siderolabs/talos.git
TALOS_VERSION ?= $(TALOS_TAG)
IMAGER_OUTPUT_NAME ?= $(NAME)-imager
IMAGER_OUTPUT_TAG ?= $(TALOS_VERSION)-$(TAG)
IMAGER_OUTPUT_IMAGE ?= $(REGISTRY_AND_USERNAME)/$(IMAGER_OUTPUT_NAME):$(IMAGER_OUTPUT_TAG)

INSTALLER_VERSION ?= $(TAG)
INSTALLER_OUTPUT_NAME ?= $(NAME)-installer
INSTALLER_OUTPUT_TAG ?= $(TAG)
INSTALLER_OUTPUT_IMAGE ?= $(REGISTRY_AND_USERNAME)/$(INSTALLER_OUTPUT_NAME):$(INSTALLER_OUTPUT_TAG)

BUILD := docker buildx build
PROGRESS ?= auto
PLATFORM ?= linux/arm64
ARCH ?= $(shell echo $(PLATFORM) | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/')
COMMON_ARGS := --progress=$(PROGRESS)
COMMON_ARGS += --platform=$(PLATFORM)
COMMON_ARGS += --build-arg=IMAGE_SOURCE=$(SOURCE)
COMMON_ARGS += --build-arg=IMAGE_AUTHORS=$(AUTHORS)

.PHONY: all
all: build

.PHONY: build
build: kernel u-boot imager installer

.PHONY: build-%
build-%:
	@$(BUILD) \
		$(COMMON_ARGS) \
		--context $* \
		--file $*/Dockerfile \
		$(BUILD_ARGS)

.PHONY: kernel
kernel:
	@$(MAKE) build-kernel \
		BUILD_ARGS="--tag $(KERNEL_OUTPUT_IMAGE) \
			--build-arg KERNEL_VERSION=$(KERNEL_VERSION) \
			--build-arg KERNEL_SOURCE=$(KERNEL_SOURCE) \
			$(BUILD_ARGS)"

.PHONY: u-boot
u-boot:
	@$(MAKE) build-u-boot \
		BUILD_ARGS="--tag $(U_BOOT_OUTPUT_IMAGE) \
			--build-arg U_BOOT_VERSION=$(U_BOOT_VERSION) \
			--build-arg U_BOOT_SOURCE=$(U_BOOT_SOURCE) \
			--build-arg RKBIN_SOURCE=$(U_BOOT_RKBIN_SOURCE) \
			$(BUILD_ARGS)"

imager/talos:
	@git clone --depth 1 --single-branch --branch $(TALOS_TAG) $(TALOS_SOURCE) $@ && \
		sed -i "s/DefaultKernelVersion = \".*\"/DefaultKernelVersion = \"$(KERNEL_VERSION)\"/g" $@/pkg/machinery/constants/constants.go && \
		rm $@/hack/modules-arm64.txt && cp imager/modules.txt $@/hack/modules-arm64.txt

.PHONY: imager
imager: imager/talos
	@$(MAKE) -C $< \
		REGISTRY=$(REGISTRY) \
		USERNAME=$(USERNAME) \
		TAG = $(TALOS_TAG) \
		PKG_KERNEL=$(KERNEL_OUTPUT_IMAGE)
		PLATFORM=$(PLATFORM) \
		PUSH=$(PUSH)
		ARCH=$(ARCH) \
		target-$@ \
		TARGET_ARGS="--output type=image,name=$(IMAGER_OUTPUT_IMAGE) \
			--label org.opencontainers.image.name=$(IMAGER_OUTPUT_NAME) \
			--label org.opencontainers.image.title=\"Talos Orange Pi 5 imager\"
			--label org.opencontainers.image.description=\"Talos Orange Pi 5 imager\"
			--label org.opencontainers.image.source=$(SOURCE) \
			--label org.opencontainers.image.authors=$(AUTHORS) \
			--label org.opencontainers.image.vendor=\"Sidero Labs, Inc.\" \
			--label org.opencontainers.image.version=$(IMAGER_OUTPUT_TAG) \
			$(BUILD_ARGS)"

.PHONY: installer
installer:
	@$(MAKE) build-installer \
		BUILD_ARGS="--tag $(INSTALLER_OUTPUT_IMAGE) \
			--build-arg KERNEL=$(KERNEL_OUTPUT_IMAGE) \
			--build-arg VERSION=$(INSTALLER_VERSION) \
			$(BUILD_ARGS)"

.PHONY: push
push:
	@$(MAKE) build PUSH=true

.PHONY: clean
clean:
	@rm -rf imager/talos

USERNAME ?= si0ls
REGISTRY ?= ghcr.io

TAG ?= $(shell git describe --tag --always --dirty)

U_BOOT_VERSION ?= v2024.04-rc4
KERNEL_VERSION ?= 6.8
TALOS_VERSION ?= $(shell cd imager/talos; git describe --tag --always --dirty)
SOURCE_DATE_EPOCH ?= $(shell git log -1 --pretty=%ct)

BUILD=docker builx bake
PLATFORM ?= linux/arm64
PROGRESS ?= auto
PUSH ?= false
COMMON_ARGS=--progress=$(PROGRESS)
COMMON_ARGS+=--platform=$(PLATFORM)
COMMON_ARGS+=--push=$(PUSH)

PATCH := patch
IMAGER_PATCHES := $(wildcard imager/patches/*.patch)

all: build

.PHONY: imager
imager: $(IMAGER_PATCHES)
	@for patch in $^; do \
		$(PATCH) -p1 -d imager/talos < $$patch; \
	done

.PHONY: build
build: imager
	@
		TAG=$(TAG) \
		USERNAME=$(USERNAME) \
		REGISTRY=$(REGISTRY) \
		SOURCE_DATE_EPOCH=$(SOURCE_DATE_EPOCH) \
		$(BUILD) \
		$(COMMON_ARGS) \
		-f docker-bake.hcl \
		system
	@
		TAG=$(TAG) \
		USERNAME=$(USERNAME) \
		REGISTRY=$(REGISTRY) \
		SOURCE_DATE_EPOCH=$(SOURCE_DATE_EPOCH) \
		$(BUILD) \
		$(COMMON_ARGS) \
		-f docker-bake.hcl \
		talos

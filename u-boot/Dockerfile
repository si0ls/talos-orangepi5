# syntax=docker/dockerfile:1

FROM ubuntu:22.04 AS base-arm64

RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install --no-install-recommends -y \
    bc \
    bison \
    build-essential \
    ca-certificates \
    coccinelle \
    curl \
    device-tree-compiler \
    dfu-util \
    efitools \
    flex \
    gdisk \
    git \
    graphviz \
    imagemagick \
    liblz4-tool \
    libgnutls28-dev \
    libguestfs-tools \
    libncurses-dev \
    libpython3-dev \
    libsdl2-dev \
    libssl-dev \
    lz4 \
    lzma \
    lzma-alone \
    openssl \
    pkg-config \
    python3 \
    python3-asteval \
    python3-coverage \
    python3-filelock \
    python3-pkg-resources \
    python3-pycryptodome \
    python3-pyelftools \
    python3-pytest \
    python3-pytest-xdist \
    python3-sphinxcontrib.apidoc \
    python3-sphinx-rtd-theme \
    python3-subunit \
    python3-testtools \
    python3-virtualenv \
    swig \
    uuid-dev \
    && rm -rf /var/lib/apt/lists/*

FROM ubuntu:22.04 AS base-amd64

RUN touch unsupported_arch_amd64

FROM base-arm64 AS downloader-arm64

ARG U_BOOT_VERSION=v2924.04-rc4
ARG U_BOOT_SOURCE=https://source.denx.de/u-boot/u-boot/-/archive/${U_BOOT_VERSION}/u-boot-${U_BOOT_VERSION}.tar.gz
ARG RKBIN_SOURCE=https://github.com/rockchip-linux/rkbin/archive/refs/heads/master.tar.gz

RUN mkdir -p /u-boot/src && \
    mkdir -p /u-boot/rkbin && \
    curl -L ${U_BOOT_SOURCE} | tar -xz -C /u-boot/src --strip-components=1 && \
    curl -L ${RKBIN_SOURCE} | tar -xz -C /u-boot/rkbin --strip-components=1

FROM base-arm64 AS builder-arm64

ARG TARGET_ARCH=arm64

COPY --from=downloader-arm64 /u-boot/src /u-boot/src
COPY --from=downloader-arm64 /u-boot/rkbin /u-boot/rkbin

COPY ./patches /u-boot/patches

WORKDIR /u-boot/src
RUN find /u-boot/patches -name '*.patch' -type f | sort | while read patch; do patch -p1 < "$patch"; done

ENV ROCKCHIP_TPL=/u-boot/rkbin/bin/rk35/rk3588_ddr_lp4_2112MHz_lp5_2400MHz_v1.16.bin
ENV BL31=/u-boot/rkbin/bin/rk35/rk3588_bl31_v1.45.elf

WORKDIR /u-boot/src
RUN --mount=type=cache,target=/u-boot/build \
    make O=/u-boot/build -j$(nproc) mrproper && \
    make O=/u-boot/build -j$(nproc) orangepi-5-rk3588s_defconfig && \
    make O=/u-boot/build -j$(nproc) HOSTLDLIBS_mkimage="-lssl -lcrypto"

WORKDIR /u-boot
RUN --mount=type=cache,target=/u-boot/build \
  mkdir -p out && \
  cp -r build/u-boot-rockchip.bin out/ && \
  cp -r build/u-boot-rockchip-spi.bin out/

FROM scratch AS u-boot-arm64

COPY --from=builder-arm64 /u-boot/out/ /

FROM scratch AS u-boot-amd64

COPY --from=base-amd64 /unsupported_arch_amd64 /unsupported_arch_amd64

FROM u-boot-${TARGETARCH} AS u-boot

ARG U_BOOT_VERSION=v2924.04-rc4
ARG IMAGE_NAME="talos-orangepi5-u-boot"
ARG IMAGE_TITLE="Talos Orange Pi 5 U-Boot"
ARG IMAGE_DESCRIPTION=$IMAGE_TITLE
ARG IMAGE_SOURCE="https://github.com/si0ls/talos-orangepi5"
ARG IMAGE_AUTHORS="Louis S. <louis@schne.id>"
ARG IMAGE_VENDOR="Denx Software Engineering"
ARG IMAGE_VERSION=$U_BOOT_VERSION

LABEL org.opencontainers.image.name $IMAGE_NAME
LABEL org.opencontainers.image.title $IMAGE_TITLE
LABEL org.opencontainers.image.description $IMAGE_DESCRIPTION
LABEL org.opencontainers.image.source $IMAGE_SOURCE
LABEL org.opencontainers.image.authors $IMAGE_AUTHORS
LABEL org.opencontainers.image.vendor $IMAGE_VENDOR
LABEL org.opencontainers.image.version $IMAGE_VERSION


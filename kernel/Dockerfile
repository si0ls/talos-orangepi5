# syntax=docker/dockerfile:1

FROM ubuntu:22.04 AS base

RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install --no-install-recommends -y \
    bc \
    bison \
    build-essential \
    ca-certificates \
    curl \
    dwarves \
    flex \
    git \
    kmod \
    libbpf-dev \
    libelf-dev \
    liblz4-dev \
    liblz4-tool \
    libncurses-dev \
    libssl-dev \
    libzstd-dev \
    python3 \
    && rm -rf /var/lib/apt/lists/*

FROM base AS downloader

ARG KERNEL_VERSION=6.8.1
ARG KERNEL_SOURCE=https://git.kernel.org/stable/t/linux-${KERNEL_VERSION}.tar.gz

RUN mkdir -p /kernel/src && \
    curl -L $KERNEL_SOURCE | tar -xz -C /kernel/src --strip-components=1

FROM base AS builder

COPY --from=downloader /kernel/src /kernel/src

COPY ./patches /kernel/patches

WORKDIR /kernel/src
RUN find /kernel/patches -name '*.patch' -type f | sort | while read patch; do patch -p1 < "$patch"; done

COPY ./certs/* /kernel/certs/
COPY config /kernel/.config

ENV KBUILD_OUTPUT=/kernel/build
ENV ARCH=arm64

WORKDIR /kernel
RUN --mount=type=cache,target=/kernel/build \
    cp .config build/.config && \
    cp certs/x509.genkey src/certs/x509.genkey

WORKDIR /kernel/src
RUN --mount=type=cache,target=/kernel/build \
    make -j$(nproc) clean && \
    make -j$(nproc) olddefconfig && \
    make -j$(nproc) && \
    make -j$(nproc) modules && \
    make -j$(nproc) rockchip/rk3588s-orangepi-5.dtb rockchip/rk3588-orangepi-5-plus.dtb && \
    make -j$(nproc) rockchip/overlay/rockchip-rk3588-sata1.dtbo rockchip/overlay/rockchip-rk3588-sata2.dtbo
    #make -j$(nproc) dtbs

RUN --mount=type=cache,target=/kernel/build \
    mkdir -p /kernel/out/boot && \
    mkdir -p /kernel/out/dtb/rockchip/overlay && \
    mkdir -p /kernel/out/certs && \
    cp -r /kernel/build/certs/signing_key.x509 /kernel/out/certs/signing_key.x509 && \
    cp -r /kernel/build/arch/arm64/boot/Image /kernel/out/boot/vmlinuz && \
    cp -r /kernel/build/arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5.dtb /kernel/out/dtb/rockchip/rk3588s-orangepi-5.dtb && \
    cp -r /kernel/build/arch/arm64/boot/dts/rockchip/rk3588-orangepi-5-plus.dtb /kernel/out/dtb/rockchip/rk3588-orangepi-5-plus.dtb && \
    cp -r /kernel/build/arch/arm64/boot/dts/rockchip/overlay/rockchip-rk3588-sata1.dtbo /kernel/out/dtb/rockchip/overlay/rockchip-rk3588-sata1.dtbo && \
    cp -r /kernel/build/arch/arm64/boot/dts/rockchip/overlay/rockchip-rk3588-sata2.dtbo /kernel/out/dtb/rockchip/overlay/rockchip-rk3588-sata2.dtbo && \
    export KERNEL_RELEASE=$(cat /kernel/build/include/config/kernel.release) && \
    make -j$(nproc) modules_install INSTALL_MOD_PATH=/kernel/out INSTALL_MOD_STRIP=1 && \
    depmod -b /kernel/out $KERNEL_RELEASE && \
    unlink /kernel/out/lib/modules/$KERNEL_RELEASE/build

FROM scratch AS kernel

ARG KERNEL_VERSION=6.8
ARG IMAGE_NAME="talos-orangepi5-kernel"
ARG IMAGE_TITLE="Talos Orange Pi 5 Kernel"
ARG IMAGE_DESCRIPTION=$IMAGE_TITLE
ARG IMAGE_SOURCE="https://github.com/si0ls/talos-orangepi5"
ARG IMAGE_AUTHORS="Louis S. <louis@schne.id>"
ARG IMAGE_VENDOR="The Linux Foundation"
ARG IMAGE_VERSION=$KERNEL_VERSION

LABEL org.opencontainers.image.name $IMAGE_NAME
LABEL org.opencontainers.image.title $IMAGE_TITLE
LABEL org.opencontainers.image.description $IMAGE_DESCRIPTION
LABEL org.opencontainers.image.source $IMAGE_SOURCE
LABEL org.opencontainers.image.authors $IMAGE_AUTHORS
LABEL org.opencontainers.image.vendor $IMAGE_VENDOR
LABEL org.opencontainers.image.version $IMAGE_VERSION

COPY --from=builder /kernel/out/ /

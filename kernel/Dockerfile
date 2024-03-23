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

ARG KERNEL_VERSION=6.8
ARG KERNEL_SOURCE=https://git.kernel.org/torvalds/t/linux-${KERNEL_VERSION}.tar.gz

RUN mkdir -p /kernel/src && \
    curl -L https://git.kernel.org/torvalds/t/linux-${KERNEL_VERSION}.tar.gz | tar -xz -C /kernel/src --strip-components=1

FROM base AS builder

ARG TARGET_ARCH=arm64

COPY --from=downloader /kernel/src /kernel/src

COPY ./patches /kernel/patches

WORKDIR /kernel/src
RUN find /kernel/patches -name '*.patch' -type f | sort | while read patch; do patch -p1 < "$patch"; done

COPY ./certs/* /kernel/certs/
COPY config /kernel/.config

ENV KBUILD_OUTPUT=/kernel/build
ENV ARCH=${TARGET_ARCH}

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
    make -j$(nproc) rockchip/rk3588s-orangepi-5.dtb rockchip/rk3588-orangepi-5-plus.dtb
    #make -j$(nproc) dtbs

RUN --mount=type=cache,target=/kernel/build \
    mkdir -p /kernel/out/boot && \
    mkdir -p /kernel/out/dtb/rockchip && \
    mkdir -p /kernel/out/certs && \
    cp -r /kernel/build/certs/signing_key.x509 /kernel/out/certs/signing_key.x509 && \
    cp -r /kernel/build/arch/arm64/boot/Image /kernel/out/boot/vmlinuz && \
    cp -r /kernel/build/arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5.dtb /kernel/out/dtb/rockchip/rk3588s-orangepi-5.dtb && \
    cp -r /kernel/build/arch/arm64/boot/dts/rockchip/rk3588-orangepi-5-plus.dtb /kernel/out/dtb/rockchip/rk3588-orangepi-5-plus.dtb && \
    cp -r /kernel/build/arch/arm54/boot/dts/rockchip/overlay /kernel/out/dtb/rockchip/overlay && \
    export KERNEL_RELEASE=$(cat /kernel/build/include/config/kernel.release) && \
    make -j$(nproc) modules_install INSTALL_MOD_PATH=/kernel/out INSTALL_MOD_STRIP=1 && \
    depmod -b /kernel/out $KERNEL_RELEASE && \
    unlink /kernel/out/lib/modules/$KERNEL_RELEASE/build

FROM scratch AS kernel

COPY --from=builder /kernel/out/ /

ARG KERNEL

FROM ${KERNEL} AS kernel

FROM scratch AS extension

ARG VERSION
ARG IMAGE_NAME="talos-orangepi5-sata-extension"
ARG IMAGE_TITLE="Talos Orange Pi 5 SATA extension"
ARG IMAGE_DESCRIPTION=$IMAGE_TITLE
ARG IMAGE_SOURCE="https://github.com/si0ls/talos-orangepi5"
ARG IMAGE_AUTHORS="Louis S. <louis@schne.id>"
ARG IMAGE_VENDOR=$IMAGE_AUTHORS
ARG IMAGE_VERSION=$VERSION

LABEL org.opencontainers.image.name $IMAGE_NAME
LABEL org.opencontainers.image.title $IMAGE_TITLE
LABEL org.opencontainers.image.description $IMAGE_DESCRIPTION
LABEL org.opencontainers.image.source $IMAGE_SOURCE
LABEL org.opencontainers.image.authors $IMAGE_AUTHORS
LABEL org.opencontainers.image.vendor $IMAGE_VENDOR
LABEL org.opencontainers.image.version $IMAGE_VERSION

COPY manifest.yaml /manifest.yaml
COPY --from=kernel /dtb/rockchip/overlay/rk3588-ssd-sata0.dtbo /rootfs/dtb/overlay/rk3588-ssd-sata0.dtbo
COPY --from=kernel /dtb/rockchip/overlay/rk3588-ssd-sata1.dtbo /rootfs/dtb/overlay/rk3588-ssd-sata1.dtbo

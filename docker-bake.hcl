variable "TAG" {
  default = "$TAG"
}

variable "REGISTRY" {
  default = "$REGISTRY"
}

variable "USERNAME" {
  default = "$USERNAME"
}

variable "U_BOOT_VERSION" {
  default = "v2024.04-rc4"
}

variable "KERNEL_VERSION" {
  default = "6.8"
}

variable "TALOS_KERNEL_VERSION" {
  default = "6.8.0-talos"
}

variable "TALOS_VERSION" {
  default = "v1.7.0-alpha.1"
}

variable "SOURCE_DATE_EPOCH" {
  default = "$SOURCE_DATE_EPOCH"
}

group "system" {
  targets = ["u-boot", "kernel"]
}

group "talos" {
  targets = ["installer", "imager"]
}

target "u-boot" {
  context = "./u-boot"
  file = "./u-boot/Dockerfile"
  platform = "linux/arm64"
  tags = ["${REGISTRY}/${USERNAME}/talos-opi5-u-boot:${U_BOOT_VERSION}-${TAG}"]
  labels = {
    "u-boot.version" = "${U_BOOT_VERSION}"
    "org.opencontainers.image.title" = "Talos Orange Pi 5 U-Boot"
    "org.opencontainers.image.description" = "U-Boot for the Orange Pi 5"
    "org.opencontainers.image.author" = "Louis S. <louis@schne.id>"
    "org.opencontainers.image.vendor" = "DENX Software Engineering"
  }
  args = {
    U_BOOT_VERSION = "${U_BOOT_VERSION}"
  }
}

target "kernel" {
  context = "./kernel"
  file = "./kernel/Dockerfile"
  platform = "linux/arm64"
  tags = ["${REGISTRY}/${USERNAME}/talos-opi5-kernel:${KERNEL_VERSION}-${TAG}"]
  labels = {
    "kernel.version" = "${KERNEL_VERSION}"
    "org.opencontainers.image.title" = "Talos Orange Pi 5 Kernel"
    "org.opencontainers.image.description" = "Kernel for the Orange Pi 5"
    "org.opencontainers.image.author" = "Louis S. <louis@schne.id>"
    "org.opencontainers.image.vendor" = "The Linux Foundation"
  }
  args = {
    KERNEL_VERSION = "${KERNEL_VERSION}"
  }
}

target "installer" {
  context = "./installer"
  file = "./installer/Dockerfile"
  platform = "linux/arm64"
  contexts = {
    kernel = "target:kernel"
  }
  tags = ["${REGISTRY}/${USERNAME}/talos-opi5-installer:${TAG}"]
  labels = {
    "kernel.version" = "${KERNEL_VERSION}"
    "org.opencontainers.image.title" = "Talos Orange Pi 5 overlay installer"
    "org.opencontainers.image.description" = "Overlay installer for the Orange Pi 5"
    "org.opencontainers.image.author" = "Louis S. <louis@schne.id>"
    "org.opencontainers.image.vendor" = "Louis S. <louis@schne.id>"
  }
  args = {
    KERNEL = "${REGISTRY}/${USERNAME}/talos-opi5-kernel:${KERNEL_VERSION}-${TAG}"
  }
}

target "imager" {
  context = "./imager/talos"
  file = "./imager/talos/Dockerfile"
  platform = "linux/arm64"
  targets = ["imager"]
  contexts = {
    pkg-kernel = "target:kernel"
  }
  tags = ["${REGISTRY}/${USERNAME}/talos-opi5-imager:${TALOS_VERSION}-${TAG}"]
  labels = {
    "kernel.version" = "${KERNEL_VERSION}"
    "org.opencontainers.image.title" = "Talos Orange Pi 5 imager"
    "org.opencontainers.image.description" = "Imager for the Orange Pi 5"
    "org.opencontainers.image.author" = "Louis S. <louis@schne.id>"
    "org.opencontainers.image.vendor" = "Siderolabs Inc."
  }
  args = {
    PKG_KERNEL = "${REGISTRY}/${USERNAME}/talos-opi5-kernel:${KERNEL_VERSION}-${TAG}"
    KERNEL_VERSION = "${TALOS_KERNEL_VERSION}"

    TOOLS = "ghcr.io/siderolabs/tools:v1.7.0-alpha.0-12-gdfee984"
    PKGS = "v1.7.0-alpha.0-42-gb65c085"
    EXTRAS = "v1.7.0-alpha.0-3-g47bb718"
    GOFUMPT_VERSION = "v0.6.0"
    GOIMPORTS_VERSION = "v0.19.0"
    STRINGER_VERSION = "v0.19.0"
    ENUMER_VERSION = "v1.5.9"
    DEEPCOPY_GEN_VERSION = "v0.29.2"
    VTPROTOBUF_VERSION = "v0.6.0"
    IMPORTVET_VERSION = "v0.2.0"
    GOLANGCILINT_VERSION = "v1.56.2"
    DEEPCOPY_VERSION = "v0.5.6"
    MARKDOWNLINTCLI_VERSION = "0.39.0"
    TEXTLINT_VERSION = "13.4.1"
    TEXTLINT_FILTER_RULE_COMMENTS_VERSION = "1.2.2"
    TEXTLINT_RULE_ONE_SENTENCE_PER_LINE_VERSION = "2.0.0"
    TAG = "${TAG}"
    SOURCE_DATE_EPOCH = "${SOURCE_DATE_EPOCH}"
    ARTIFACTS = "_out"
    TESTPKGS = "github.com/siderolabs/talos/..."
    INSTALLER_ARCH = "targetarch"
    CGO_ENABLED = "0"
    GO_BUILDFLAGS = "-tags \"tcell_minimal,grpcnotrace\""
    GO_LDFLAGS = ""
    GOAMD64 = "v2"
    http_proxy = ""
    https_proxy = ""
    NAME = "Talos"
    SHA = "${TAG}"
    USERNAME = "${USERNAME}"
    REGISTRY = "ghcr.io"
    PKGS_PREFIX = "ghcr.io/siderolabs"
    ABBREV_TAG = "${TAG}"
    PKG_FHS = "ghcr.io/siderolabs/fhs:v1.7.0-alpha.0-42-gb65c085"
    PKG_CA_CERTIFICATES = "ghcr.io/siderolabs/ca-certificates:v1.7.0-alpha.0-42-gb65c085"
    PKG_CRYPTSETUP = "ghcr.io/siderolabs/cryptsetup:v1.7.0-alpha.0-42-gb65c085"
    PKG_CONTAINERD = "ghcr.io/siderolabs/containerd:v1.7.0-alpha.0-42-gb65c085"
    PKG_DOSFSTOOLS = "ghcr.io/siderolabs/dosfstools:v1.7.0-alpha.0-42-gb65c085"
    PKG_EUDEV = "ghcr.io/siderolabs/eudev:v1.7.0-alpha.0-42-gb65c085"
    PKG_GRUB = "ghcr.io/siderolabs/grub:v1.7.0-alpha.0-42-gb65c085"
    PKG_SD_BOOT = "ghcr.io/siderolabs/sd-boot:v1.7.0-alpha.0-42-gb65c085"
    PKG_IPTABLES = "ghcr.io/siderolabs/iptables:v1.7.0-alpha.0-42-gb65c085"
    PKG_IPXE = "ghcr.io/siderolabs/ipxe:v1.7.0-alpha.0-42-gb65c085"
    PKG_LIBINIH = "ghcr.io/siderolabs/libinih:v1.7.0-alpha.0-42-gb65c085"
    PKG_LIBJSON_C = "ghcr.io/siderolabs/libjson-c:v1.7.0-alpha.0-42-gb65c085"
    PKG_LIBPOPT = "ghcr.io/siderolabs/libpopt:v1.7.0-alpha.0-42-gb65c085"
    PKG_LIBURCU = "ghcr.io/siderolabs/liburcu:v1.7.0-alpha.0-42-gb65c085"
    PKG_OPENSSL = "ghcr.io/siderolabs/openssl:v1.7.0-alpha.0-42-gb65c085"
    PKG_LIBSECCOMP = "ghcr.io/siderolabs/libseccomp:v1.7.0-alpha.0-42-gb65c085"
    PKG_LINUX_FIRMWARE = "ghcr.io/siderolabs/linux-firmware:v1.7.0-alpha.0-42-gb65c085"
    PKG_LVM2 = "ghcr.io/siderolabs/lvm2:v1.7.0-alpha.0-42-gb65c085"
    PKG_LIBAIO = "ghcr.io/siderolabs/libaio:v1.7.0-alpha.0-42-gb65c085"
    PKG_MUSL = "ghcr.io/siderolabs/musl:v1.7.0-alpha.0-42-gb65c085"
    PKG_RUNC = "ghcr.io/siderolabs/runc:v1.7.0-alpha.0-42-gb65c085"
    PKG_XFSPROGS = "ghcr.io/siderolabs/xfsprogs:v1.7.0-alpha.0-42-gb65c085"
    PKG_UTIL_LINUX = "ghcr.io/siderolabs/util-linux:v1.7.0-alpha.0-42-gb65c085"
    PKG_KMOD = "ghcr.io/siderolabs/kmod:v1.7.0-alpha.0-42-gb65c085"
    PKG_TALOSCTL_CNI_BUNDLE_INSTALL = "ghcr.io/siderolabs/talosctl-cni-bundle-install:v1.7.0-alpha.0-3-g47bb718"
  }
}
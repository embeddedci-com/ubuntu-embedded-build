# Ubuntu 24.04 build image for: BusyBox + Linux kernel (arm64) + U-Boot + FAT image tooling
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Core build deps + cross toolchains + common utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    # basics
    ca-certificates \
    git \
    wget \
    curl \
    xz-utils \
    unzip \
    file \
    rsync \
    cpio \
    gzip \
    bzip2 \
    patch \
    diffutils \
    sed \
    gawk \
    # build toolchain
    build-essential \
    make \
    bc \
    bison \
    flex \
    pkg-config \
    # kernel/u-boot deps
    libssl-dev \
    libelf-dev \
    libncurses-dev \
    libgnutls28-dev \
    # helpful for kernel/U-Boot build scripts
    python3 \
    python3-pip \
    perl \
    # cross compilers (arm64 + armhf)
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    gcc-arm-linux-gnueabihf \
    g++-arm-linux-gnueabihf \
    # FAT image tooling (mkfs.vfat) and fs tools
    dosfstools \
    mtools \
    u-boot-tools \
    # editor (you used vim)
    vim \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Optional: keep the image usable without extra flags
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

CMD ["/bin/bash"]

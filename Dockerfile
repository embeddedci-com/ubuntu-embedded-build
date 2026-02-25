# Ubuntu 24.04 build image for: BusyBox + Linux kernel (arm64) + U-Boot + FAT image tooling
FROM ubuntu:24.04

ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]


# ---- arm64 variant: native aarch64 + musl wrapper ----
RUN if [ "$TARGETARCH" = "arm64" ]; then \
      apt-get update && apt-get install -y --no-install-recommends musl-dev && \
      rm -rf /var/lib/apt/lists/* ; \
    fi

# ---- amd64 variant: build aarch64-linux-musl toolchain ----
RUN if [ "$TARGETARCH" = "amd64" ]; then \
      apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates git build-essential wget \
        gawk bison flex texinfo \
        libgmp-dev libmpc-dev libmpfr-dev && \
      rm -rf /var/lib/apt/lists/* && \
      git clone https://github.com/richfelker/musl-cross-make.git /opt/musl-cross-make && \
      make -C /opt/musl-cross-make -j1 TARGET=aarch64-linux-musl && \
      make -C /opt/musl-cross-make TARGET=aarch64-linux-musl install && \
      ln -s /opt/musl-cross-make/output/aarch64-linux-musl/bin/aarch64-linux-musl-gcc /usr/local/bin/aarch64-linux-musl-gcc && \
      ln -s /opt/musl-cross-make/output/aarch64-linux-musl/bin/aarch64-linux-musl-ld /usr/local/bin/aarch64-linux-musl-ld && \
      true ; \
    fi

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
    parted \
    # editor (you used vim)
    vim \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Optional: keep the image usable without extra flags
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

CMD ["/bin/bash"]

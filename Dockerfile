# Ubuntu 24.04 build image for: BusyBox + Linux kernel (arm64) + U-Boot + FAT image tooling

FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

# build-time parameter with a default
ARG KERNEL_VER=6.12.74
ARG MUSL_CROSS_MAKE_REF=v0.9.11

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git wget ca-certificates \
    gawk bison flex texinfo \
    libgmp-dev libmpc-dev libmpfr-dev \
    rsync xz-utils \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /work
COPY toolchain/ toolchain/

# (optional) also expose it at runtime
#ENV KERNEL_VER=${KERNEL_VER}
#ENV MUSL_CROSS_MAKE_REF=${MUSL_CROSS_MAKE_REF}

RUN make -C toolchain toolchain KERNEL_VER="${KERNEL_VER}" MUSL_CROSS_MAKE_REF="${MUSL_CROSS_MAKE_REF}" && \
    make -C toolchain verify KERNEL_VER="${KERNEL_VER}" MUSL_CROSS_MAKE_REF="${MUSL_CROSS_MAKE_REF}" && \
    make -C toolchain clean KERNEL_VER="${KERNEL_VER}" MUSL_CROSS_MAKE_REF="${MUSL_CROSS_MAKE_REF}"

ENV PATH="/opt/toolchains/aarch64-linux-musl/bin:/opt/toolchains/arm-linux-musleabihf/bin:${PATH}"

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
    # editor
    vim \
    # fakeroot
    fakeroot \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Optional: keep the image usable without extra flags
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

CMD ["/bin/bash"]

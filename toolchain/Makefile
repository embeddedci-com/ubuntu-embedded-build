SHELL := /bin/bash

ifndef KERNEL_VER
$(error KERNEL_VER is not set. Pass KERNEL_VER=x.y.z)
endif

ifndef MUSL_CROSS_MAKE_REF
$(error MUSL_CROSS_MAKE_REF is not set. Pass MUSL_CROSS_MAKE_REF=vX.Y.Z)
endif

# ---- Paths ----
OUT      ?= /opt/toolchains
WORKDIR  ?= /tmp/toolchain-build
MCM_DIR  ?= $(WORKDIR)/musl-cross-make
KERN_TAR ?= $(WORKDIR)/linux-$(KERNEL_VER).tar.xz
KERN_DIR ?= $(WORKDIR)/linux-$(KERNEL_VER)

JOBS := $(shell nproc)

# ---- Architectures ----
ARCHES := arm arm64

# arm (armv7 hard-float)
TC_TRIPLE_arm  := arm-linux-musleabihf
KARCH_arm      := arm
LDNAME_arm     := ld-musl-armhf.so.1

# arm64 (aarch64)
TC_TRIPLE_arm64 := aarch64-linux-musl
KARCH_arm64     := arm64
LDNAME_arm64    := ld-musl-aarch64.so.1

# ---- Derived variables per arch ----
define DEF_ARCH_VARS
TC_PREFIX_$(1)  := $(OUT)/$$(TC_TRIPLE_$(1))
TC_SYSROOT_$(1) := $$(TC_PREFIX_$(1))/$$(TC_TRIPLE_$(1))/sysroot
TC_LIBDIR_$(1)  := $$(TC_PREFIX_$(1))/$$(TC_TRIPLE_$(1))/lib
TC_GCC_$(1)     := $$(TC_PREFIX_$(1))/bin/$$(TC_TRIPLE_$(1))-gcc
TC_LD_$(1)      := $$(TC_LIBDIR_$(1))/$$(LDNAME_$(1))
endef
$(foreach a,$(ARCHES),$(eval $(call DEF_ARCH_VARS,$(a))))

# ---- Public targets ----
.PHONY: all arm arm64 toolchain \
        verify verify-all verify-arm verify-arm64 \
        clean clean-all \
        $(foreach a,$(ARCHES),toolchain-$(a) musl-cross-make-$(a) kernel-headers-$(a) verify-$(a))

toolchain: all
all: $(foreach a,$(ARCHES),toolchain-$(a))
	@echo "Toolchains ready:"
	@$(foreach a,$(ARCHES),echo "  $($(strip TC_PREFIX_$(a)))";)

arm: toolchain-arm
arm64: toolchain-arm64

# ---- Per-arch rules ----
define ARCH_RULES

toolchain-$(1): musl-cross-make-$(1) kernel-headers-$(1)
	@echo "$(1) toolchain ready: $$(TC_PREFIX_$(1))"
	@echo "$(1) sysroot ready:  $$(TC_SYSROOT_$(1))"

musl-cross-make-$(1):
	mkdir -p $(WORKDIR) $(OUT)
	if [ ! -d "$(MCM_DIR)/.git" ]; then \
	  git clone https://github.com/richfelker/musl-cross-make.git "$(MCM_DIR)"; \
	fi
	cd "$(MCM_DIR)" && git fetch --all --tags
	cd "$(MCM_DIR)" && git checkout "$(MUSL_CROSS_MAKE_REF)"
	rm -f "$(MCM_DIR)/config.mak"
	cd "$(MCM_DIR)" && make -j$(JOBS) TARGET=$$(TC_TRIPLE_$(1))
	cd "$(MCM_DIR)" && make -j$(JOBS) TARGET=$$(TC_TRIPLE_$(1)) install
	rm -rf "$$(TC_PREFIX_$(1))"
	mkdir -p "$(OUT)"
	mv "$(MCM_DIR)/output" "$$(TC_PREFIX_$(1))"

kernel-headers-$(1):
	mkdir -p $(WORKDIR)
	if [ ! -f "$(KERN_TAR)" ]; then \
	  wget -O "$(KERN_TAR)" "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$(KERNEL_VER).tar.xz"; \
	fi
	rm -rf "$(KERN_DIR)"
	tar -C "$(WORKDIR)" -xf "$(KERN_TAR)"
	mkdir -p "$$(TC_SYSROOT_$(1))"
	$(MAKE) -C "$(KERN_DIR)" ARCH=$$(KARCH_$(1)) headers_install INSTALL_HDR_PATH="$$(TC_SYSROOT_$(1))/usr"

verify-$(1):
	@echo "=== Verifying $(1) toolchain ==="

	@echo "Checking gcc..."
	test -x "$$(TC_GCC_$(1))"

	@echo "Checking kernel headers..."
	test -f "$$(TC_SYSROOT_$(1))/usr/include/linux/version.h"

	@echo "Checking musl loader..."
	test -f "$$(TC_LD_$(1))" || test -L "$$(TC_LD_$(1))"

	@echo "Compiling hello world..."
	echo 'int main(){return 0;}' > /tmp/hello.c
	$$(TC_GCC_$(1)) /tmp/hello.c -o /tmp/hello-$(1)

	@echo "Checking ELF architecture..."
	readelf -h /tmp/hello-$(1) | grep "Machine:"

	rm -f /tmp/hello.c /tmp/hello-$(1)

	@echo "=== $(1) verification successful ==="

endef
$(foreach a,$(ARCHES),$(eval $(call ARCH_RULES,$(a))))

# ---- Aggregate helpers ----
verify: verify-all
verify-all: $(foreach a,$(ARCHES),verify-$(a))
	@echo "=== All toolchain verifications successful ==="

clean: clean-all
clean-all:
	rm -rf "$(WORKDIR)"

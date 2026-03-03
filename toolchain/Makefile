# toolchain/Makefile
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

JOBS     := $(shell nproc)

# ---- Toolchain targets (Option A) ----
# arm64 toolchain
TC_A64_TARGET := aarch64-linux-musl
TC_A64_PREFIX := $(OUT)/$(TC_A64_TARGET)
TC_A64_SYSROOT := $(TC_A64_PREFIX)/$(TC_A64_TARGET)/sysroot

# armv7 hard-float toolchain (generic for BBB + other armv7 boards)
# Note: This intentionally targets ARMv7-class armhf, like Ubuntu armhf.
TC_ARM_TARGET := arm-linux-musleabihf
TC_ARM_PREFIX := $(OUT)/$(TC_ARM_TARGET)
TC_ARM_SYSROOT := $(TC_ARM_PREFIX)/$(TC_ARM_TARGET)/sysroot

.PHONY: toolchain toolchain-aarch64 toolchain-armhf kernel-headers-aarch64 kernel-headers-armhf musl-cross-make-aarch64 musl-cross-make-armhf clean

toolchain: toolchain-aarch64 toolchain-armhf
	@echo "Toolchains ready:"
	@echo "  $(TC_A64_PREFIX)"
	@echo "  $(TC_ARM_PREFIX)"

# ---------- aarch64 ----------
toolchain-aarch64: musl-cross-make-aarch64 kernel-headers-aarch64
	@echo "aarch64 toolchain ready: $(TC_A64_PREFIX)"
	@echo "aarch64 sysroot ready:  $(TC_A64_SYSROOT)"

musl-cross-make-aarch64:
	mkdir -p $(WORKDIR) $(OUT)
	if [ ! -d "$(MCM_DIR)/.git" ]; then \
	  git clone https://github.com/richfelker/musl-cross-make.git "$(MCM_DIR)"; \
	fi
	cd "$(MCM_DIR)" && git fetch --all --tags
	cd "$(MCM_DIR)" && git checkout "$(MUSL_CROSS_MAKE_REF)"
	# Ensure no stale config
	rm -f "$(MCM_DIR)/config.mak"
	# Build + install for aarch64
	cd "$(MCM_DIR)" && make -j$(JOBS) TARGET=$(TC_A64_TARGET)
	cd "$(MCM_DIR)" && make -j$(JOBS) TARGET=$(TC_A64_TARGET) install
	rm -rf "$(TC_A64_PREFIX)"
	mkdir -p "$(OUT)"
	mv "$(MCM_DIR)/output" "$(TC_A64_PREFIX)"

kernel-headers-aarch64:
	mkdir -p $(WORKDIR)
	if [ ! -f "$(KERN_TAR)" ]; then \
	  wget -O "$(KERN_TAR)" "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$(KERNEL_VER).tar.xz"; \
	fi
	rm -rf "$(KERN_DIR)"
	tar -C "$(WORKDIR)" -xf "$(KERN_TAR)"
	mkdir -p "$(TC_A64_SYSROOT)"
	$(MAKE) -C "$(KERN_DIR)" ARCH=arm64 headers_install INSTALL_HDR_PATH="$(TC_A64_SYSROOT)/usr"

# ---------- armhf (armv7 hard-float) ----------
toolchain-armhf: musl-cross-make-armhf kernel-headers-armhf
	@echo "armhf toolchain ready: $(TC_ARM_PREFIX)"
	@echo "armhf sysroot ready:  $(TC_ARM_SYSROOT)"

musl-cross-make-armhf:
	mkdir -p $(WORKDIR) $(OUT)
	if [ ! -d "$(MCM_DIR)/.git" ]; then \
	  git clone https://github.com/richfelker/musl-cross-make.git "$(MCM_DIR)"; \
	fi
	cd "$(MCM_DIR)" && git fetch --all --tags
	cd "$(MCM_DIR)" && git checkout "$(MUSL_CROSS_MAKE_REF)"
	# Ensure no stale config
	rm -f "$(MCM_DIR)/config.mak"
	# Build + install for armhf (generic armv7 hard-float)
	cd "$(MCM_DIR)" && make -j$(JOBS) TARGET=$(TC_ARM_TARGET)
	cd "$(MCM_DIR)" && make -j$(JOBS) TARGET=$(TC_ARM_TARGET) install
	rm -rf "$(TC_ARM_PREFIX)"
	mkdir -p "$(OUT)"
	mv "$(MCM_DIR)/output" "$(TC_ARM_PREFIX)"

kernel-headers-armhf:
	mkdir -p $(WORKDIR)
	if [ ! -f "$(KERN_TAR)" ]; then \
	  wget -O "$(KERN_TAR)" "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$(KERNEL_VER).tar.xz"; \
	fi
	rm -rf "$(KERN_DIR)"
	tar -C "$(WORKDIR)" -xf "$(KERN_TAR)"
	mkdir -p "$(TC_ARM_SYSROOT)"
	$(MAKE) -C "$(KERN_DIR)" ARCH=arm headers_install INSTALL_HDR_PATH="$(TC_ARM_SYSROOT)/usr"

clean:
	rm -rf "$(WORKDIR)"

.PHONY: verify

verify:
	@echo "=== Verifying musl toolchains ==="

	@echo ""
	@echo "--- Checking aarch64 toolchain ---"
	@test -x "$(TC_A64_PREFIX)/bin/$(TC_A64_TARGET)-gcc" || { echo "Missing aarch64 gcc"; exit 1; }

	@echo "Compiler triple:"
	@$(TC_A64_PREFIX)/bin/$(TC_A64_TARGET)-gcc -dumpmachine | tee /tmp/a64.machine
	@grep -q "^aarch64-linux-musl$$" /tmp/a64.machine || { echo "aarch64 target mismatch"; exit 1; }

	@test -d "$(TC_A64_SYSROOT)" || { echo "Missing aarch64 sysroot"; exit 1; }
	@test -f "$(TC_A64_SYSROOT)/usr/include/linux/version.h" || { echo "Missing aarch64 kernel headers"; exit 1; }

	@A64_LIBDIR="$(TC_A64_PREFIX)/$(TC_A64_TARGET)/lib"; \
	echo "Checking aarch64 libdir: $$A64_LIBDIR"; \
	test -d "$$A64_LIBDIR" || { echo "Missing aarch64 libdir"; exit 1; }

	@test -f "$(TC_A64_PREFIX)/$(TC_A64_TARGET)/lib/libc.so" || { echo "Missing aarch64 libc.so"; exit 1; }

	@A64_LD="$(TC_A64_PREFIX)/$(TC_A64_TARGET)/lib/ld-musl-aarch64.so.1"; \
	echo "Expecting aarch64 loader at: $$A64_LD"; \
	if [ -L "$$A64_LD" ] || [ -f "$$A64_LD" ]; then \
	  echo "Found aarch64 loader (type=$$( [ -L "$$A64_LD" ] && echo symlink || echo file ))"; \
	  echo "Loader link target: $$(readlink "$$A64_LD" 2>/dev/null || echo '<not a symlink>')"; \
	else \
	  echo "Missing aarch64 musl loader"; \
	  ls -la "$$A64_LIBDIR"; \
	  exit 1; \
	fi

	@echo ""
	@echo "--- Checking armhf toolchain ---"
	@test -x "$(TC_ARM_PREFIX)/bin/$(TC_ARM_TARGET)-gcc" || { echo "Missing armhf gcc"; exit 1; }

	@echo "Compiler triple:"
	@$(TC_ARM_PREFIX)/bin/$(TC_ARM_TARGET)-gcc -dumpmachine | tee /tmp/arm.machine
	@grep -q "^arm-linux-musleabihf$$" /tmp/arm.machine || { echo "armhf target mismatch"; exit 1; }

	@test -d "$(TC_ARM_SYSROOT)" || { echo "Missing armhf sysroot"; exit 1; }
	@test -f "$(TC_ARM_SYSROOT)/usr/include/linux/version.h" || { echo "Missing armhf kernel headers"; exit 1; }

	@ARM_LIBDIR="$(TC_ARM_PREFIX)/$(TC_ARM_TARGET)/lib"; \
	echo "Checking armhf libdir: $$ARM_LIBDIR"; \
	test -d "$$ARM_LIBDIR" || { echo "Missing armhf libdir"; exit 1; }

	@test -f "$(TC_ARM_PREFIX)/$(TC_ARM_TARGET)/lib/libc.so" || { echo "Missing armhf libc.so"; exit 1; }

	@ARM_LD="$(TC_ARM_PREFIX)/$(TC_ARM_TARGET)/lib/ld-musl-armhf.so.1"; \
	echo "Expecting armhf loader at: $$ARM_LD"; \
	if [ -L "$$ARM_LD" ] || [ -f "$$ARM_LD" ]; then \
	  echo "Found armhf loader (type=$$( [ -L "$$ARM_LD" ] && echo symlink || echo file ))"; \
	  echo "Loader link target: $$(readlink "$$ARM_LD" 2>/dev/null || echo '<not a symlink>')"; \
	else \
	  echo "Missing armhf musl loader"; \
	  ls -la "$$ARM_LIBDIR"; \
	  exit 1; \
	fi

	@echo ""
	@echo "--- Compiling hello-world test binaries ---"
	@echo 'int main(){return 0;}' > /tmp/hello.c

	@$(TC_A64_PREFIX)/bin/$(TC_A64_TARGET)-gcc /tmp/hello.c -o /tmp/hello-aarch64
	@$(TC_ARM_PREFIX)/bin/$(TC_ARM_TARGET)-gcc /tmp/hello.c -o /tmp/hello-arm

	@echo "ELF check (aarch64):"
	@readelf -h /tmp/hello-aarch64 | grep "Machine:" | tee /tmp/a64.elf
	@grep -q "AArch64" /tmp/a64.elf || { echo "aarch64 ELF incorrect"; exit 1; }

	@echo "ELF check (armhf):"
	@readelf -h /tmp/hello-arm | grep "Machine:" | tee /tmp/arm.elf
	@grep -q "ARM" /tmp/arm.elf || { echo "armhf ELF incorrect"; exit 1; }

	@rm -f /tmp/hello.c /tmp/hello-aarch64 /tmp/hello-arm /tmp/*.machine /tmp/*.elf

	@echo ""
	@echo "=== Toolchain verification successful ==="

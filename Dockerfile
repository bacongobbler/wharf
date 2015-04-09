FROM ubuntu:14.04

RUN apt-get update && apt-get install -y \
    bc \
    build-essential \
    curl \
    mkisofs \
    xz-utils

ENV KERNEL_VERSION 3.18.10

RUN curl --retry 10 https://www.kernel.org/pub/linux/kernel/v3.x/linux-$KERNEL_VERSION.tar.xz | tar -C / -xJ && \
    mv /linux-$KERNEL_VERSION /tmp/kernel

COPY kernel_config /tmp/kernel/.config

# compile the kernel
RUN jobs=$(nproc); \
    cd /tmp/kernel && \
    make -j ${jobs} oldconfig && \
    make -j ${jobs} bzImage && \
    make -j ${jobs} modules

# post-kernel build process

ENV ROOTFS /rootfs

# prepare the ROOTFS
RUN mkdir -p $ROOTFS

# prepare the build directory
RUN mkdir -p /tmp/iso/boot/isolinux

# install kernel modules in $ROOTFS
RUN cd /tmp/kernel && \
    make INSTALL_MOD_PATH=$ROOTFS modules_install firmware_install

# remove useless kernel modules
RUN cd $ROOTFS/lib/modules && \
    rm -rf ./*/kernel/sound/* && \
    rm -rf ./*/kernel/drivers/gpu/* && \
    rm -rf ./*/kernel/drivers/infiniband/* && \
    rm -rf ./*/kernel/drivers/isdn/* && \
    rm -rf ./*/kernel/drivers/media/* && \
    rm -rf ./*/kernel/drivers/staging/lustre/* && \
    rm -rf ./*/kernel/drivers/staging/comedi/* && \
    rm -rf ./*/kernel/fs/ocfs2/* && \
    rm -rf ./*/kernel/net/bluetooth/* && \
    rm -rf ./*/kernel/net/mac80211/* && \
    rm -rf ./*/kernel/net/wireless/*

# prepare the build directory with the kernel
RUN cp /tmp/kernel/arch/x86_64/boot/bzImage /tmp/iso/boot/vmlinuz64

ENV BUSYBOX_VERSION 1.23.2
RUN curl http://www.busybox.net/downloads/busybox-$BUSYBOX_VERSION.tar.bz2 | tar -C / -xj && \
    mv /busybox-$BUSYBOX_VERSION /tmp/busybox

COPY busybox_config /tmp/busybox/.config
RUN cd /tmp/busybox && \
    make && \
    make install

# install bootloader
ENV SYSLINUX_VERSION 6.03
RUN mkdir -p $ROOTFS/boot/isolinux
RUN curl https://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-$SYSLINUX_VERSION.tar.xz | tar -C / -xJ && \
    mv syslinux-$SYSLINUX_VERSION/bios/core/isolinux.bin /tmp/iso/boot/isolinux/ && \
    mv syslinux-$SYSLINUX_VERSION/bios/com32/elflink/ldlinux/ldlinux.c32 /tmp/iso/boot/isolinux/

# install boot params
COPY isolinux /tmp/iso/boot/isolinux

# add our own custom ROOTFS
COPY rootfs $ROOTFS

COPY make_iso.sh /
RUN /make_iso.sh

CMD ["cat", "wharf.iso"]

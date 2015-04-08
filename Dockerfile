FROM ubuntu:14.04

RUN apt-get update && apt-get install -y \
    bc \
    build-essential \
    curl \
    xorriso \
    xz-utils

ENV KERNEL_VERSION 3.19.3

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
RUN mkdir -p /tmp/iso/boot

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
RUN cp -v /tmp/kernel/arch/x86_64/boot/bzImage /tmp/iso/boot/vmlinuz64

# create directories which the file systems will be mounted
RUN for i in dev proc sys run; do mkdir -p $ROOTFS/$i; done

# when the kernel boots the system, it requires the presence of a few device nodes,
# in particular the console and null devices. The device nodes must be created on
# the hard disk so that they are available before udevd has been started, and
# additionally when Linux is started with init=/bin/bash
RUN mknod -m 600 $ROOTFS/dev/console c 5 1
RUN mknod -m 666 $ROOTFS/dev/null c 1 3

# add our own custom ROOTFS
COPY rootfs $ROOTFS

COPY make_iso.sh /

RUN /make_iso.sh

CMD ["cat", "wharf.iso"]

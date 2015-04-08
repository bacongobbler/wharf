FROM ubuntu:14.04

RUN apt-get update && apt-get install -y curl \
                                         xz-utils

ENV KERNEL_VERSION 3.19.3

RUN curl --retry 10 https://www.kernel.org/pub/linux/kernel/v3.x/linux-$KERNEL_VERSION.tar.xz | tar -C / -xJ && \
    mv /linux-$KERNEL_VERSION /tmp/kernel

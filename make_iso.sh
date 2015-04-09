#!/bin/sh

# Setup /etc/os-release with some nice contents
version="$(cat $ROOTFS/etc/version)" # something like "1.1.0"
cat > $ROOTFS/etc/os-release <<-EOF
NAME=WharfOS
VERSION=$version
EOF

# Pack the rootfs
cd $ROOTFS
find | ( set -x; cpio -o -H newc | xz -9 --format=lzma --verbose --verbose ) > /tmp/iso/boot/initrd.img
cd -

# Make the ISO
xorriso  \
    -publisher "bacongobbler" \
    -as mkisofs \
    -l -J -R -V "WharfOS-v$(cat $ROOTFS/etc/version)" \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -o /wharf.iso /tmp/iso

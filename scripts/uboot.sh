#!/bin/bash

# build u-boot
cd $UBootPath
make O=$BuildDir/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- DEVICE_TREE=zynq-user-uboot -j$(nproc) && \
make O=$BuildDir/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- dtbs -j$(nproc)
cd -

# create and config petalinux project
if [ ! -d $BuildDir/peta ]; then
    mkdir -p $BuildDir && cd $BuildDir
    petalinux-create --type project --template zynq --name peta
    cd -
fi

cd $BuildDir/peta
petalinux-config --get-hw-description $XsaFile
cd -

# build BOOT.BIN
rm -rf $BuildDir/boot-bin && mkdir -p $BuildDir/boot-bin
cp -vf \
    $BuildDir/fsbl/executable.elf \
    $BuildDir/uboot/u-boot.elf \
    $BuildDir/uboot/arch/arm/dts/zynq-user-uboot.dtb \
    $BuildDir/boot-bin

cd $BuildDir/boot-bin
petalinux-package --boot --force \
    --project $BuildDir/peta \
    --fsbl    executable.elf \
    --u-boot  u-boot.elf \
    --dtb     zynq-user-uboot.dtb \
    -o        BOOT.BIN
cd -

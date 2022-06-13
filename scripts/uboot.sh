#!/bin/bash

# build u-boot
cd $UBootPath
make O=$BuildDir/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j16 && \
make O=$BuildDir/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- dtbs -j16 && \
make O=$BuildDir/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- u-boot.dtb -j16
cd -

# build BOOT.BIN
rm -rf $BuildDir/boot-bin && mkdir -p $BuildDir/boot-bin
cp -v \
    $SourcesDir/scripts/boot.scr \
    $BuildDir/fsbl/executable.elf \
    $BuildDir/uboot/u-boot.elf \
    $BuildDir/uboot/arch/arm/dts/u-boot.dtb \
    $BuildDir/boot-bin

cd $BuildDir/boot-bin
petalinux-package --boot --force \
    --project     $PetaLinuxPath \
    --fsbl        executable.elf \
    --u-boot      u-boot.elf \
    --dtb         u-boot.dtb \
    --boot-script boot.scr \
    --boot-device sd \
    -o            BOOT.BIN
cd -

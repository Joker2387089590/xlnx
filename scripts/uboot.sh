source scripts/env.sh

# build u-boot
cd $UBootPath
make O=../build/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- distclean
make O=../build/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zynq_ares_7020_uboot_defconfig
# make O=../build/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig
make O=../build/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j16
make O=../build/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- dtbs -j16
make O=../build/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- $DtsName.dtb -j16
cd -

# build BOOT.BIN
rm -rf build/boot-bin && mkdir -p build/boot-bin
cp \
    build/fsbl/executable.elf \
    build/hw/$XsaName.bit \
    build/uboot/u-boot.elf \
    build/uboot/arch/arm/dts/$DtsName.dtb \
    build/boot-bin

cd build/boot-bin
petalinux-package --boot --force -p $PetaLinuxPath \
    --fsbl        executable.elf \
    --fpga        $XsaName.bit \
    --u-boot      u-boot.elf \
    --dtb         $DtsName.dtb \
    --boot-device sd \
    -o            BOOT.BIN
cd -

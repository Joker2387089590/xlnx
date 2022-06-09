source scripts/env.sh

# build kernel
cd $KernelPath
make O=../build/kernel ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- distclean
make O=../build/kernel ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zynq_ares_7020_kernel_defconfig
make O=../build/kernel ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage -j16
make O=../build/kernel ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- dtbs -j16
make O=../build/kernel ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- $DtsName.dtb -j16
cd -

# put all products together
rm -rf build/product && mkdir -p build/product
cp build/kernel/arch/arm/boot/dts/$DtsName.dtb build/product/system.dtb
cp build/hw/$XsaName.bit build/product/system.bit
cp build/boot-bin/BOOT.BIN build/kernel/arch/arm/boot/zImage build/product

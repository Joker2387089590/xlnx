source scripts/env.sh

# build kernel
cd $KernelPath
make O=$BuildDir/kernel ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage -j16
make O=$BuildDir/kernel ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- dtbs -j16
cd -

# put all products together
rm -rf $BuildDir/product && mkdir -p $BuildDir/product
cp \
    $BuildDir/kernel/arch/arm/boot/dts/$DtsName.dtb \
    $BuildDir/product/system.dtb
cp \
    $BuildDir/hw/$XsaName.bit \
    $BuildDir/product/system.bit
cp \
    $BuildDir/boot-bin/BOOT.BIN \
    $BuildDir/kernel/arch/arm/boot/zImage \
    $BuildDir/product

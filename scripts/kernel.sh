# build kernel
cd $KernelPath
make O=$BuildDir/kernel ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage -j16 && \
make O=$BuildDir/kernel ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- dtbs -j16 && \
cd -

# put all products together
rm -rf $BuildDir/product && mkdir -p $BuildDir/product
cp -v \
    $BuildDir/kernel/arch/arm/boot/dts/$DtsName.dtb \
    $BuildDir/product/system.dtb
cp -v \
    $BuildDir/hw/$XsaName.bit \
    $BuildDir/product/system.bit
cp -v \
    $BuildDir/boot-bin/BOOT.BIN \
    $BuildDir/kernel/arch/arm/boot/zImage \
    $BuildDir/product

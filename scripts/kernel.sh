# build kernel
cd $KernelPath
# CROSS_COMPILE=arm-linux-gnueabihf-
make O=$BuildDir/kernel ARCH=arm LLVM=1 DEVICE_TREE=zynq-user-kernel -j16 && \
make O=$BuildDir/kernel ARCH=arm LLVM=1 dtbs -j16
cd -

# put all products together
rm -rfv $BuildDir/product && mkdir -p $BuildDir/product
cp -v \
    $BuildDir/kernel/arch/arm/boot/dts/zynq-user-kernel.dtb \
    $BuildDir/product/system.dtb
cp -v \
    $BuildDir/hw/$XsaName.bit \
    $BuildDir/product/system.bit
cp -v \
    $BuildDir/boot-bin/BOOT.BIN \
    $BuildDir/kernel/arch/arm/boot/zImage \
    $BuildDir/product

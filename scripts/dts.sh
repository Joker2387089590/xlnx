source scripts/env.sh

# rebuild dts
export DtsBuildDir=$(pwd)/build/dts
rm -r build/dts
mkdir -p build/dts
xsct scripts/dts.tcl

# copy kernel arch/arm/boot/dts, put dts files into, mount the copied directory
sudo umount $UBootPath/arch/arm/boot/dts
sudo umount $KernelPath/arch/arm/boot/dts
cp -n $KernelPath/arch/arm/boot/dts build/dts-copy
cp -f \
    $UserDtsFile \
    $DtsBuildDir/pcw.dtsi \
    $DtsBuildDir/zynq-7000.dtsi \
    build/dts-copy
sudo mount --bind --source build/dts-copy --target $UBootPath/arch/arm/boot/dts
sudo mount --bind --source build/dts-copy --target $KernelPath/arch/arm/boot/dts

# modify the Makefile
code $UBootPath/arch/arm/boot/dts/Makefile

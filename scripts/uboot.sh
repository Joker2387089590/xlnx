source scripts/env.sh
cd $UBootPath
make O=../build/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- distclean
make O=../build/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- xilinx_zynq_virt_defconfig
make O=../build/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- all -j16
make O=../build/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- dtbs -j16
cd -

# rebuild fsbl
export FsblBuildDir=$(pwd)/build/fsbl
rm -r build/fsbl
mkdir -p build/fsbl
xsct scripts/fsbl.tcl

cp -f build/uboot/u-boot.elf build/fsbl/u-boot.elf
cp -f build/uboot/arch/arm/dts/$(basename $UserDtsFile) build/fsbl/u-boot.dtb

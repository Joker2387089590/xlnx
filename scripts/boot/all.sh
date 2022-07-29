#!/bin/bash

# input
if [ ! -d $SourcesDir ]
then
    echo "[ERROR] SourcesDir is not set!!!"
    return 255
fi
export UserXsaFile=$SourcesDir/scripts/boot/ps.xsa
export BuildDir=$SourcesDir/build/boot

export XsaName=$(basename $UserXsaFile .xsa)
export XsaFile=$BuildDir/hw/$XsaName.xsa
export DtsName=zynq-user-uboot

export DeviceTreePath=$SourcesDir/device-tree-xlnx
export EmbeddedSW=$SourcesDir/embeddedsw
export UBootPath=$SourcesDir/u-boot-xlnx
export UBootDtsDir=$UBootPath/arch/arm/dts

# add scripts to PATH so that we can call them directly by 'xxx.sh'
export PATH=$PATH:$SourcesDir/scripts

# # copy xsa file
# rm -rf $BuildDir/hw && mkdir -p $BuildDir/hw
# cp -v $UserXsaFile $XsaFile

# # generate dts
# rm -rf $BuildDir/dts && mkdir -p $BuildDir/dts
# xsct $SourcesDir/scripts/boot/dts.tcl

# # generate fsbl
# rm -rf $BuildDir/fsbl && mkdir -p $BuildDir/fsbl
# xsct $SourcesDir/scripts/boot/fsbl.tcl

# copy custom content
export CustomDir=$SourcesDir/scripts/boot/user
[ -f $CustomDir/zynq_user_defconfig ] && cp -vf $CustomDir/zynq_user_defconfig $UBootPath/configs
[ -f $CustomDir/zynq-user.h ]         && cp -vf $CustomDir/zynq-user.h         $UBootPath/include/configs
[ -f $CustomDir/zynq-user-uboot.dts ] && cp -vf $CustomDir/zynq-user-uboot.dts $UBootDtsDir
rsync -K -a -v --no-perms --no-owner --no-group --no-times \
    $BuildDir/dts/zynq-7000.dtsi \
    $BuildDir/dts/pcw.dtsi \
    $SourcesDir/scripts/zynq-user-common.dtsi \
    $UBootDtsDir

cd $UBootPath
make O=$BuildDir/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- distclean

# config source
#   zynq_ares_7020_uboot_defconfig
#   xilinx_zynq_virt_defconfig
#   zynq_user_defconfig
make O=$BuildDir/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zynq_user_defconfig && \
make O=$BuildDir/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig

# build
make O=$BuildDir/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- DEVICE_TREE=zynq-user-uboot -j$(nproc) && \
make O=$BuildDir/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- dtbs -j$(nproc)
cd -

# create and config petalinux project
if [ ! -d $BuildDir/peta ]; then
    mkdir -p $BuildDir && cd $BuildDir
    petalinux-create --type project --template zynq --name peta
    cd -
    cd $BuildDir/peta
    petalinux-config --get-hw-description $XsaFile
    cd -
fi

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

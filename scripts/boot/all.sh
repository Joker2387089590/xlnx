#!/bin/bash

### input
if  echo "SourcesDir: $SourcesDir"                     && \
    [ -d "$SourcesDir" ]                               && \
    echo "PetaLinux Install Dir: $PetaLinuxInstallDir" && \
    [ -d "$PetaLinuxInstallDir" ]
then
    echo "Start build BOOT"
else
    echo "[ERROR] Invalid input!!!"
    exit
fi

export UserXsaFile=$SourcesDir/scripts/boot/system.xsa
export BuildDir=$SourcesDir/build/boot

export XsaName=$(basename $UserXsaFile .xsa)
export XsaFile=$BuildDir/hw/$XsaName.xsa
export DtsName=zynq-user-uboot

export DeviceTreePath=$SourcesDir/device-tree-xlnx
export EmbeddedSW=$SourcesDir/embeddedsw
export UBootPath=$SourcesDir/u-boot-xlnx
export UBootDtsDir=$UBootPath/arch/arm/dts

# since clang is not easily configured to compile uboot, 
# we use the GCC toolchain from PetaLinux tools to solve the problem.
export XsctDir=$PetaLinuxInstallDir/tools/xsct
export GccToolchain=$XsctDir/gnu/aarch32/lin/gcc-arm-none-eabi
export PATH=$XsctDir/bin:$GccToolchain/bin:$PATH

# add scripts to PATH so that we can call them directly by 'xxx.sh'
export PATH=$PATH:$SourcesDir/scripts

### start build.....

rm -rf $BuildDir && mkdir -p $BuildDir
source $PetaLinuxInstallDir/settings.sh

# # copy xsa file
mkdir -p $BuildDir/hw
cp -v $UserXsaFile $XsaFile

# # generate dts
mkdir -p $BuildDir/dts
xsct $SourcesDir/scripts/boot/dts.tcl

# # generate fsbl
mkdir -p $BuildDir/fsbl
xsct $SourcesDir/scripts/boot/fsbl.tcl

# copy custom content
cp -vf \
    $SourcesDir/scripts/boot/zynq_user_defconfig \
    $UBootPath/configs
cp -vf \
    $SourcesDir/scripts/zynq-user-common.dtsi \
    $BuildDir/dts/zynq-7000.dtsi \
    $BuildDir/dts/pcw.dtsi \
    $SourcesDir/scripts/boot/zynq-user-uboot.dts \
    $UBootDtsDir

cd $UBootPath

# config source
make O=$BuildDir/uboot zynq_user_defconfig

# build
make O=$BuildDir/uboot ARCH=arm CROSS_COMPILE=arm-none-eabi- DEVICE_TREE=zynq-user-uboot -j$(nproc)

cd -

# TODO: replace petalinux project
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

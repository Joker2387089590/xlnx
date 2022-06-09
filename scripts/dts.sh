#!/bin/bash
source scripts/env.sh

# copy xsa file
rm -rf build/hw && mkdir -p build/hw
cp $UserXsaFile $XsaFile

# rebuild dts
export DtsBuildDir=$(pwd)/build/dts
rm -rf $DtsBuildDir && mkdir -p $DtsBuildDir
xsct scripts/dts.tcl

# rebuild fsbl
export FsblBuildDir=$(pwd)/build/fsbl
rm -rf $FsblBuildDir && mkdir -p $FsblBuildDir
xsct scripts/fsbl.tcl

# copy original dts, put dts files into, mount the copied directory
copy-dts () {
    sudo umount -q $1
    cp -rnL $1 $2 && chmod -R ug+w+X $2
    cp -rf $DtsBuildDir/* $2
    cp -f $3 $2/$DtsName.dts
    sudo mount --bind $2 $1
}

copy-dts $UBootPath/arch/arm/dts       build/dts-uboot-copy  $UBootDtsFile
copy-dts $KernelPath/arch/arm/boot/dts build/dts-kernel-copy $KernelDtsFile

# modify the Makefile
code build/dts-uboot-copy/Makefile; code build/dts-kernel-copy/Makefile;

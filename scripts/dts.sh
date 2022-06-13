#!/bin/bash

# copy xsa file
rm -rf $BuildDir/hw && mkdir -p $BuildDir/hw
cp $UserXsaFile $XsaFile

# rebuild dts
rm -rf $BuildDir/dts && mkdir -p $BuildDir/dts
xsct $SourcesDir/scripts/dts.tcl

# rebuild fsbl
rm -rf $BuildDir/fsbl && mkdir -p $BuildDir/fsbl
xsct $SourcesDir/scripts/fsbl.tcl

# copy dts files to dts source directory
cp -rfv \
    $BuildDir/dts/* \
    $SourcesDir/scripts/zynq-user-common.dtsi \
    $SourcesDir/scripts/u-boot.dts \
    $UBootDtsDir
cp -rfv \
    $BuildDir/dts/* \
    $SourcesDir/scripts/zynq-user-common.dtsi \
    $UserDtsFile \
    $KernelDtsDir

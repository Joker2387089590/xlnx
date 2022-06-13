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

cp -rf $BuildDir/dts/*  $UBootDtsDir
cp -rf $BuildDir/dts/*  $KernelDtsDir
cp -f  $UBootDtsFile    $UBootDtsDir/$DtsName.dts
cp -f  $KernelDtsFile   $KernelDtsDir/$DtsName.dts

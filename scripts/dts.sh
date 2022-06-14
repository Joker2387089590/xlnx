#!/bin/bash

# copy xsa file
rm -rf $BuildDir/hw && mkdir -p $BuildDir/hw
cp -v $UserXsaFile $XsaFile

# rebuild dts
rm -rf $BuildDir/dts && mkdir -p $BuildDir/dts
xsct $SourcesDir/scripts/dts.tcl

# rebuild fsbl
rm -rf $BuildDir/fsbl && mkdir -p $BuildDir/fsbl
xsct $SourcesDir/scripts/fsbl.tcl

copy-dts

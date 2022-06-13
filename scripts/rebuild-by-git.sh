#!/bin/bash

# reset source dir by git, then copy all files into
#   $1: source directory
#   $2: dts directory
#   $3: user dts file
cd $1
git clean -f -d
git restore .
cp -rfL $DtsBuildDir/* $2
cp -f $3 $2/$DtsName.dts
cd -
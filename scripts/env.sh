# input:
#   PetaLinuxPath, UserXsaFile, UserDtsFile,
#   SourcesDir, BuildDir

# export PetaLinuxPath=$(realpath ../peta)

# export UserXsaFile=$(realpath ../vivado/ps_wrapper.xsa)
export XsaName=$(basename $UserXsaFile .xsa)
export DtsName=$(basename $UserDtsFile .dts)

# export AdditionDtsFiles=$(realpath zynq-user-common.dtsi)

# export SourcesDir=/home/peta-user/repo/xlnx-new
export DeviceTreePath=$SourcesDir/device-tree-xlnx
export EmbeddedSW=$SourcesDir/embeddedsw
export UBootPath=$SourcesDir/u-boot-xlnx
export KernelPath=$SourcesDir/linux-xlnx
export UBootDtsDir=$UBootPath/arch/arm/dts
export KernelDtsDir=$KernelPath/arch/arm/boot/dts
export PATH=$PATH:$SourcesDir/scripts

# export BuildDir=$(realpath build)
export XsaFile=$BuildDir/hw/$XsaName.xsa

echo "[Info] Setting up environment..."
if  echo "-- PetaLinuxPath: $PetaLinuxPath" && \
    [ -d $PetaLinuxPath ]                   && \
    echo "-- UserXsaFile:   $UserXsaFile"   && \
    [ -f $UserXsaFile ]                     && \
    echo "-- SourcesDir:    $SourcesDir"    && \
    [ -d $SourcesDir ]                      && \
    echo "-- UserDtsFile:   $UserDtsFile"   && \
    [ -f $UserDtsFile ]
then
    echo "[WARNING] Remember to mount-copy first."
else
    echo "[Error] Invalid input!!!"
    return 255
fi

# copy original dts, put dts files into, mount the copied directory
#   $1: dts directory
#   $2: dts copy directory
mount-copy-one () {
    sudo umount -q $1
    rm -rf $2 && cp -rL $1 $2 && chmod -R a+rwX $2
    sudo mount --bind $2 $1
}

mount-copy () {
    mount-copy-one $UBootDtsDir  $BuildDir/dts-uboot-copy && \
    mount-copy-one $KernelDtsDir $BuildDir/dts-kernel-copy
}

umount-copy () {
    sudo umount -q $UBootDtsDir $KernelDtsDir
}

config-source () {
    case $1 in
    uboot)
        code $UBootDtsDir/Makefile
        read -p "[Info] Press Enter to continue..."

        cd $UBootPath
        make O=$BuildDir/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- distclean && \
        make O=$BuildDir/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- xilinx_zynq_virt_defconfig && \
        make O=$BuildDir/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig
        cd -
    ;;
    kernel)
        code $KernelDtsDir/Makefile
        read -p "[Info] Press Enter to continue..."
        
        cd $KernelPath
        make O=$BuildDir/kernel ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- distclean && \
        make O=$BuildDir/kernel ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- xilinx_zynq_defconfig && \
        make O=$BuildDir/kernel ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig
        cd -
    ;;
    esac
}

build-xlnx () {
    case $1 in
    dts | uboot | kernel | deploy)
        $1.sh
    ;;
    all)
        dts.sh
        config-source uboot
        uboot.sh
        config-source kernel
        kernel.sh
        deploy.sh
    ;;
    esac
}

# rebuild () {
#     case $1 in
#     dts)
#         sudo umount -q $UBootDtsDir $KernelDtsDir
#         rm -rf $BuildDir && mkdir -p $BuildDir

#     ;;
#     esac
# }

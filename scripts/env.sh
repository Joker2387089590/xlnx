# input:
#   UserXsaFile, UserDtsFile, SourcesDir, BuildDir

export XsaName=$(basename $UserXsaFile .xsa)
export DtsName=$(basename $UserDtsFile .dts)
export XsaFile=$BuildDir/hw/$XsaName.xsa

export SourcesDir=$(realpath $(dirname $0)/..)
export DeviceTreePath=$SourcesDir/device-tree-xlnx
export EmbeddedSW=$SourcesDir/embeddedsw
export UBootPath=$SourcesDir/u-boot-xlnx
export KernelPath=$SourcesDir/linux-xlnx
export UBootDtsDir=$UBootPath/arch/arm/dts
export KernelDtsDir=$KernelPath/arch/arm/boot/dts
export PATH=$PATH:$SourcesDir/scripts

echo "[Info] Setting up environment..."
if  echo "-- UserXsaFile: $UserXsaFile" && \
    [ -f $UserXsaFile ]                 && \
    echo "-- UserDtsFile: $UserDtsFile" && \
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
    mkdir -p $BuildDir
    rm -rf $2 && cp -rL $1 $2 && chmod -R a+rwX $2
    sudo mount --bind $2 $1
}

mount-copy () {
    case $1 in
    uboot)
        mount-copy-one $UBootDtsDir  $BuildDir/dts-uboot-copy
    ;;
    kernel)
        mount-copy-one $KernelDtsDir $BuildDir/dts-kernel-copy
    ;;
    *)
        mount-copy-one $UBootDtsDir  $BuildDir/dts-uboot-copy && \
        mount-copy-one $KernelDtsDir $BuildDir/dts-kernel-copy
    esac
}

umount-copy () {
    sudo umount -q $UBootDtsDir $KernelDtsDir
}

# copy dts files to dts source directory
copy-dts () {
    case $1 in
    uboot)
        sudo cp -rfv \
            $BuildDir/dts/* \
            $SourcesDir/scripts/zynq-user-common.dtsi \
            $SourcesDir/scripts/zynq-user-uboot.dts \
            $UBootDtsDir
    ;;
    kernel)
        sudo cp -rfv \
            $BuildDir/dts/* \
            $SourcesDir/scripts/zynq-user-common.dtsi \
            $UserDtsFile \
            $KernelDtsDir
    ;;
    esac
}

config-source () {
    case $1 in
    uboot)
        code $UBootDtsDir/Makefile
        read -p "[Info] Press Enter to continue..."

        cd $UBootPath
        make O=$BuildDir/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- distclean && \
        make O=$BuildDir/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zynq_ares_7020_uboot_defconfig && \
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
        copy-dts uboot && copy-dts kernel
        config-source uboot
        uboot.sh
        config-source kernel
        kernel.sh
        deploy.sh
    ;;
    redo)
        dts.sh
        copy-dts uboot && copy-dts kernel
        uboot.sh
        kernel.sh
        deploy.sh
    ;;
    esac
}

dump-dtb () {
    local name=$(basename $1 .dtb)
    dtc -I dtb -O dts -o $name-dump.dts $1
}

clean-git () {
    cd $1
    git restore .
    git clean -f -d
    cd -
}

clean-all-sources () {
    clean-git $UBootPath
    clean-git $KernelPath
}

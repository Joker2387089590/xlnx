# input:
#   PetaLinuxPath, UserXsaFile, 
#   DtsName, AdditionDtsFiles
#   SourceDir, BuildDir
source input.sh

# export PetaLinuxPath=$(realpath ../peta)

# export UserXsaFile=$(realpath ../vivado/ps_wrapper.xsa)
export XsaName=$(basename $UserXsaFile .xsa)

# export DtsName=zynq-user
export UBootDtsFile=$(realpath $DtsName-uboot.dts)
export KernelDtsFile=$(realpath $DtsName-kernel.dts)

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

test-input() {
    local result=0
    if [ ! -d $PetaLinuxPath ]; then 
        echo "-- PetaLinuxPath: $PetaLinuxPath"
        result=1
    fi
    if [ ! -f $UserXsaFile ];   then
        echo "-- UserXsaFile:   $UserXsaFile"
        result=1
    fi
    if [ ! -d $SourcesDir ];    then
        echo "-- SourcesDir:    $SourcesDir"
        result=1
    fi
    if [ ! -f $UBootDtsFile ];  then
        echo "-- UBootDtsFile:  $UBootDtsFile"
        result=1
    fi
    if [ ! -f $KernelDtsFile ]; then
        echo "-- KernelDtsFile: $KernelDtsFile"
        result=1
    fi
    return $result
}

if $(test-input); then
    echo "[Info] Setting up environment..."
else
    echo "[Error] Invalid input!!!"
fi

config () {
    case $1 in
    uboot)
        cd $UBootPath
        make O=$BuildDir/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- distclean
        make O=$BuildDir/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zynq_ares_7020_uboot_defconfig
        make O=$BuildDir/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig
        cd -
    ;;
    kernel)
        cd $KernelPath
        make O=$BuildDir/kernel ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- distclean
        make O=$BuildDir/kernel ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zynq_ares_7020_kernel_defconfig
        make O=$BuildDir/kernel ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig
        cd -
    ;;
    esac
}

# copy original dts, put dts files into, mount the copied directory
#   $1: dts directory
#   $2: dts copy directory
mount-copy () {
    sudo umount -q $1
    rm -rf $2 && cp -rL $1 $2 && chmod -R ug+rwX $2
    sudo mount --bind $2 $1
}

mount-copy-all () {
    mount-copy $UBootDtsDir  $BuildDir/dts-uboot-copy
    mount-copy $KernelDtsDir $BuildDir/dts-kernel-copy
}

umount-copy () {
    sudo umount -q $UBootDtsDir $KernelDtsDir
}

build-xlnx () {
    case $1 in
    dts | uboot | kernel | deploy)
        $1.sh
    ;;
    makefile)
        code $UBootDtsDir/Makefile $KernelDtsDir/Makefile
    ;;
    all)
        dts.sh
        code $UBootDtsDir/Makefile $KernelDtsDir/Makefile
        read -p "[Info] Press Enter to continue..."
        uboot.sh
        kernel.sh
        deploy.sh
    ;;
    esac
}

rebuild () {
    case $1 in
    dts)
        sudo umount -q $UBootDtsDir $KernelDtsDir
        rm -rf $BuildDir && mkdir -p $BuildDir

    ;;
    esac
}

# check input
echo "[INFO] Setting up environment..."
if  echo "--- UserXsaFile: $UserXsaFile" && \
    [ -f $UserXsaFile ]                  && \
    echo "--- UserDtsFile: $UserDtsFile" && \
    [ -f $UserDtsFile ]                  && \
    echo "---  SourcesDir: $SourcesDir"  && \
    [ -d $SourcesDir ]
then
    echo "[INFO] Remember to source PetaLinux's settings.sh"
else
    echo "[ERROR]          ~~~~~~~~~~~~    Invalid input!!!"
    return 255
fi

# file name
export XsaName=$(basename $UserXsaFile .xsa)
export DtsName=$(basename $UserDtsFile .dts)
export XsaFile=$BuildDir/hw/$XsaName.xsa

# sources path
export DeviceTreePath=$SourcesDir/device-tree-xlnx
export EmbeddedSW=$SourcesDir/embeddedsw
export UBootPath=$SourcesDir/u-boot-xlnx
export KernelPath=$SourcesDir/linux-xlnx
export UBootDtsDir=$UBootPath/arch/arm/dts
export KernelDtsDir=$KernelPath/arch/arm/boot/dts

# add scripts to PATH so that we can call them directly by 'xxx.sh'
export PATH=$PATH:$SourcesDir/scripts

# setup sd card paritions
format-sdc () {
    read -p "[WARNING] formatting $1, press Enter to continue..."

    # -b: block device file
    [ -b $1 ] && \
    sudo sfdisk $1 < $SourcesDir/scripts/boot/sdc.sfdisk && \
    sudo mkfs.vfat -n BOOT   ${1}1 && \
    sudo mkfs.ext4 -L RootFS ${1}2
}

copy-uboot-config () {
    [ -f $1/zynq_user_defconfig ] && cp -v $1/zynq_user_defconfig $UBootPath/configs
    [ -f $1/zynq-user.h ]         && cp -v $1/zynq-user.h         $UBootPath/include/configs
    [ -f $1/zynq-user-uboot.dts ] && cp -v $1/zynq-user-uboot.dts $UBootDtsDir
}

# copy dts files to dts source directory, rsync can deal with the symbol link in target directory.
copy-dts () {
    case $1 in
    uboot)
        # $SourcesDir/scripts/boot/user/zynq-user-uboot.dts
        rsync -K -a -v \
            $BuildDir/dts/* \
            $SourcesDir/scripts/zynq-user-common.dtsi \
            $UBootDtsDir
    ;;
    kernel)
        rsync -K -a -v \
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

        # zynq_ares_7020_uboot_defconfig
        # xilinx_zynq_virt_defconfig
        cd $UBootPath
        make O=$BuildDir/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- distclean && \
        make O=$BuildDir/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- xilinx_zynq_virt_defconfig && \
        make O=$BuildDir/uboot ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig
        cd -
    ;;
    kernel)
        code $KernelDtsDir/Makefile
        read -p "[Info] Press Enter to continue..."
        
        # zynq_ares_7020_kernel_defconfig
        cd $KernelPath
        make O=$BuildDir/kernel ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- distclean && \
        make O=$BuildDir/kernel ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- xilinx_zynq_defconfig && \
        make O=$BuildDir/kernel ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig
        cd -
    ;;
    esac
}

# revert dtb to dts
dump-dtb () {
    local name=$(basename $1 .dtb)
    dtc -I dtb -O dts -o $name-dump.dts $1
}

# generate compile-command.json, which can be used by clangd
make-compile () {
    $SourcesDir/scripts/kernel/generate_compdb.py $1 $BuildDir/kernel -O $1
}

# clean source tree by git
clean-git () {
    cd $1
    git restore .
    git clean -f -d
    cd -
}

build-xlnx () {
    case $1 in
    dts | uboot | kernel | deploy)
        $1.sh
    ;;
    *)
        echo "[ERROR] No such build step!"
    ;;
    esac
}

rebuild-xlnx () {
    case $1 in
    uboot)
        dts.sh
        copy-dts uboot
        uboot.sh
    ;;
    kernel)
        dts.sh
        copy-dts kernel
        kernel.sh
    ;;
    esac
}

# check input
echo "[INFO] Setting up environment..."
if  echo "--- UserXsaFile: $UserXsaFile" && \
    [ -f "$UserXsaFile" ]                && \
    echo "--- UserDtsFile: $UserDtsFile" && \
    [ -f "$UserDtsFile" ]                && \
    echo "---  SourcesDir: $SourcesDir"  && \
    [ -d "$SourcesDir" ]
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

clean-dir () {
    cd $1 && rm -rfv $(ls -A) && cd -
}

set-dir-mode () {
    sudo chown joker:share-petalinux -R .
    sudo chmod -R ug+wrX .
}

# setup sd card paritions
format-sdc () {
    read -p "[WARNING] formatting $1, press Enter to continue..."

    # -b: block device file
    [ -b $1 ] && \
    sudo sfdisk $1 < $SourcesDir/scripts/boot/sdc.sfdisk && \
    sudo mkfs.vfat -n BOOT   ${1}1 && \
    sudo mkfs.ext4 -L RootFS ${1}2
}

uboot-do () {
    case $1 in
    copy)
        [ -f $1/zynq_user_defconfig ] && cp -vf $1/zynq_user_defconfig $UBootPath/configs
        [ -f $1/zynq-user.h ]         && cp -vf $1/zynq-user.h         $UBootPath/include/configs
        [ -f $1/zynq-user-uboot.dts ] && cp -vf $1/zynq-user-uboot.dts $UBootDtsDir
        rsync -K -a -v \
            $BuildDir/dts/* \
            $SourcesDir/scripts/zynq-user-common.dtsi \
            $UBootDtsDir
    ;;
    config)
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
    build)
        uboot.sh
    ;;
    *)
        echo "[ERROR] No such uboot task!"
    ;;
    esac
}

kernel-do () {
    case $1 in
    copy-dts)
        rsync -K -rl -v \
            $BuildDir/dts/* \
            $SourcesDir/scripts/zynq-user-common.dtsi \
            $UserDtsFile \
            $KernelDtsDir
    ;;
    config)
        # code $KernelDtsDir/Makefile
        # read -p "[Info] Press Enter to continue..."
        
        # append custom kernel config to xilinx_zynq_defconfig
        if [ -f "$UserKernelConfig" ]
        then
            export ConfigName=$(basename $UserKernelConfig)
            cd $KernelPath/arch/arm/configs
            cp -fv xilinx_zynq_defconfig $ConfigName
            cat $UserKernelConfig >> $ConfigName
            cd -
        else
            # zynq_ares_7020_kernel_defconfig
            export ConfigName=xilinx_zynq_defconfig
        fi

        echo "[INFO] using config: $ConfigName"
        cd $KernelPath
        make O=$BuildDir/kernel ARCH=arm LLVM=1 distclean && \
        make O=$BuildDir/kernel ARCH=arm LLVM=1 $ConfigName && \
        make O=$BuildDir/kernel ARCH=arm LLVM=1 menuconfig
        cd -
    ;;
    menuconfig)
        cd $KernelPath
        make O=$BuildDir/kernel ARCH=arm LLVM=1 menuconfig
        cd -
    ;;
    cdb)
        # generate compile-command.json, which can be used by clangd
        $SourcesDir/scripts/kernel/generate_compdb.py $BuildDir/kernel $2 -O $2
    ;;
    ko)
        cd $KernelPath
        make O=$BuildDir/kernel ARCH=arm LLVM=1 INSTALL_MOD_PATH=$2 modules_install
        cd -
    ;;
    esac
}

# copy dts files to dts source directory, rsync can deal with the symbol link in target directory.
copy-dts () {
    case $1 in
    uboot)
        uboot-do copy
    ;;
    kernel)
        kernel-do copy-dts
    ;;
    esac
}

config-source () {
    case $1 in
    uboot)
        uboot-do config
    ;;
    kernel)
        kernel-do config
    ;;
    esac
}

# revert dtb to dts
dump-dtb () {
    local name=$(basename $1 .dtb)
    dtc -I dtb -O dts -o $name-dump.dts $1
}

make-compile () {
    kernel-do cdb $1
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
        source $1.sh
    ;;
    *)
        echo "[ERROR] No such build step!"
    ;;
    esac
}

install-ko () {
    kernel-do ko $1
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

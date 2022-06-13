export PetaLinuxPath=/home/peta-user/repo/spi/peta
export UserXsaFile=/home/peta-user/repo/spi/vivado/ps_wrapper.xsa
export UBootDtsFile=/home/peta-user/repo/xlnx-new/scripts/zynq-user-uboot.dts
export KernelDtsFile=/home/peta-user/repo/xlnx-new/scripts/zynq-user-kernel.dts

export DtsName=zynq-user
export XsaName=$(basename $UserXsaFile .xsa)
export XsaFile=$(pwd)/build/hw/$XsaName.xsa

export SourcesDir=/home/peta-user/repo/xlnx-new
export DeviceTreePath=$SourcesDir/device-tree-xlnx
export UBootPath=$SourcesDir/u-boot-xlnx
export KernelPath=$SourcesDir/linux-xlnx
export EmbeddedSW=$SourcesDir/embeddedsw
export PATH=$PATH:$SourcesDir/scripts

# 通用 U-Boot 脚本

## 前期准备
1. Vivado 和 PetaLinux (版本 2022.1)
2. clone 本仓库，获取编译脚本（在 `scripts/` 下），以及 Xilinx 的 `u-boot-xlnx`、`linux-xlnx`、`device-tree-xlnx`、`embeddedsw` 源码
```shell
# git 获取
git clone http://139.9.88.116:3000/r/Joker/xlnx

# 其中的 submodule 以及选取的 tag，其他版本可在 submodule 目录下用 git tags 查看
git submodule add -b xlnx_rebase_v5.15_LTS_2022.1_update1 https://github.com/Xilinx/linux-xlnx.git
git submodule add -b xlnx_rebase_v2022.01_2022.1_update1  https://github.com/Xilinx/u-boot-xlnx.git
git submodule add -b xilinx_v2022.1_update1               https://github.com/Xilinx/device-tree-xlnx.git
git submodule add -b xilinx_v2022.1                       https://github.com/Xilinx/embeddedsw.git
```
3. 一个 Vivado 的 ZYNQ PS 工程

---

## 使用方法
### 1. Vivado 导出 xsa 文件
1. ZYNQ 工程执行 `Generate Bitstream`
2. 执行 `File > Export... > Export Hardware`，选择 `Include Bitstream`

### 2. 编写 input.sh 文件
```shell
export UserXsaFile=$(导出的 xsa 文件路径)
export UserDtsFile=$(内核的设备树文件)
export SourcesDir=$(编译脚本仓库所在目录)
export BuildDir=$(构建目录，需绝对路径)
source $SourcesDir/scripts/env.sh
```

### 3. 编译 DTS 和 FSBL
```shell
$ source $(PetaLinux 的 settings.sh)
$ source input.sh # 引入 scripts/env.sh 的脚本函数，仅在执行了的 shell 有效
$ build-xlnx dts  # 会在 $BuildDir 下生成 hw、dts、fsbl
```

### 4. 编写内核设备树文件 `$UserDtsFile`，参考 `$BuildDir/dts/system.dts`，但需做如下更改
```diff
- include <zynq-7000.dtsi>
- include <pcw.dtsi>
+ include <zynq-user-common.dtsi>
```

### 5. 复制设备树到 U-Boot 和 Linux Kernel 的源码中
```shell
$ copy-dts uboot && copy-dts kernel
```

### 6. 配置 U-Boot
1. 执行命令
    ```shell
    $ config-source uboot # 会调用 VSCode 打开 Makefile
    > [Info] Press Enter to continue...
    ```
2. 修改 Makefile，添加 `zynq-user-uboot.dtb` 到 `dtb-$(CONFIG_ARCH_ZYNQ)` 中
    ```diff
    dtb-$(CONFIG_ARCH_ZYNQ) += \
        bitmain-antminer-s9.dtb \
        ...
    -   zynq-zybo-z7.dtb
    +   zynq-zybo-z7.dtb \
    +   zynq-user-uboot.dtb
    ```
3. 修改好以后，回车继续，会打开 `menuconfig`，可手动修改配置

### 7. 编译 U-Boot 和 BOOT.BIN
```shell
$ build-xlnx uboot
```
期间会在 $BuildDir/peta 创建并配置一个 petalinux 项目，弹出配置界面时退出即可

### 8. 配置 Linux 内核
1. 执行命令
    ```shell
    $ config-source kernel # 会调用 VSCode 打开 Makefile
    > [Info] Press Enter to continue...
    ```
2. 修改 Makefile，添加 `$(内核设备树文件名).dtb` 到 `dtb-$(CONFIG_ARCH_ZYNQ)` 中
    ```diff
    dtb-$(CONFIG_ARCH_ZYNQ) += \
        bitmain-antminer-s9.dtb \
        ...
    -   zynq-zybo-z7.dtb
    +   zynq-zybo-z7.dtb \
    +   $(内核设备树文件名).dtb
    ```
3. 修改好以后，回车继续，会打开 `menuconfig`，可手动修改配置

### 9. 编译 Linux 内核
```shell
$ build-xlnx kernel
```
所有最终产物会复制到 `$BuildDir/product`

### 10. 格式化 SD 卡，然后复制 `$BuildDir/product` 下所有文件到 SD 卡的 FAT 分区
```shell
$ format-sdc /dev/$(sd 卡设备)
```

---

## 工作原理

### 1. `scripts/env.sh`
* 根据 `input.sh` 设置的变量（通过环境变量也可以），生成后续脚本需要的变量
* 提供的函数：build-xlnx、copy-dts、config-source、clean-all-sources、dump-dtb
* `build-xlnx $(work)` ：执行 `scripts/$(work).sh`，`$(work)` 可以是 `dts | uboot | kernel`
* `config-source uboot`：使用 `zynq_user_uboot_defconfig`
* `config-source kernel`：使用 `zynq_user_kernel_defconfig`
* `copy-dts`：将以下文件 **覆盖复制** 到源码的 dts 目录：
    1. `$BuildDir/dts` 下所有文件
    2. `scripts/zynq-user-common.dtsi`
    3. 自定义 dts：uboot 为 `scripts/zynq-user-uboot.dts`，kernel 为 `$UserDtsFile`
    > 注意：uboot 和 kernel 中设备树所在的目录，相对于源码的路径，是不同的:  
    > -- uboot: u-boot-xlnx/arch/arm/dts  
    > -- kernel: linux-xlnx/arch/arm/boot/dts  
* `clean-all-sources`：用 git 将所有对源码的修改恢复
    > 若要减少修改，可以在 u-boot-xlnx 和 linux-xlnx 中新建分支，添加修改后 commit
* `dump-dtb`：将编译好后的 dtb 文件解析为 dts，可用于检查设备树的问题

### 2. `scripts/dts.sh`
* 复制 xsa 文件到 `$BuildDir/hw`
* 调用 xsct 执行 scripts 下的 dts.tcl 和 fsbl.tcl，生成设备树和 fsbl 的 executable.elf

### 3. `scripts/uboot.sh`
* 编译 U-Boot 工程的 make 的命令行参数有：
    * `O=$BuildDir/uboot`: 指定编译输出路径
    * `DEVICE_TREE=zynq-user-uboot`: 选择设备树
    * `ARCH=arm`: 选择架构
    * `CROSS_COMPILE=arm-linux-gnueabihf-`: 设置交叉编译器前缀
* petalinux-package 在生成 BOOT.BIN 时，需要指定一个 PetaLinux 工程（这个工程不需要 petalinux-build），后续可改为 bootgen 和 mkimage 工具（可通过 apt 安装）生成

### 4. `scripts/kernel.sh`
* make 的命令行参数同 uboot.sh
* 复制 dtb 文件时，需要重命名为 `system.dtb`

## 部分 Bash 命令参考

```shell
$ basename dir/file_with.suffix .suffix # 获取文件名
> file_with

$ realpath ../.. # 获取绝对路径
> /absolute/path

# 条件语句（方括号周围的空格是必须的）
$ [ -f if_file_exist ] # 文件是否存在
$ [ -d if_dir_exist ] # 目录是否存在

$ some-func () { # 定义一个脚本函数
      echo $1 # $1 表示第一个参数
      echo $2 # $2 表示第二个参数，以此类推
      local var; # 函数内的局部变量
  } 
```

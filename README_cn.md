
# sd-fuse_rk3399
## 简介
sd-fuse 提供一些工具和脚本, 用于制作SD卡固件, 具体用途如下:

* 制作分区镜像文件, 例如将rootfs目录打包成rootfs.img
* 将多个分区镜像文件打包成可直接写SD卡的单一镜像文件
* 简化内核和uboot的编译, 一键编译内核、第三方驱动, 并更新rootfs.img中的内核模块
  
*其他语言版本: [English](README.md)*  
  
## 运行环境
* 在电脑主机端使用
* 推荐的操作系统: Ubuntu 20.04及以上64位操作系统
* 推荐运行此脚本初始化开发环境: https://github.com/friendlyarm/build-env-on-ubuntu-bionic
* Docker容器: https://github.com/friendlyarm/docker-cross-compiler-novnc

## 支持的内核版本
sd-fuse 使用不同的git分支来支持不同的内核版本, 当前支持的内核版本为:
* 6.1.y   
  
其他内核版本, 请切换到相应的git分支
## 支持的目标板OS

* friendlywrt23
* friendlywrt23-docker
* friendlywrt21
* friendlywrt21-docker
* debian-bookworm-core-arm64
* friendlycore-lite-focal-arm64
* openmediavault-arm64

  
这些OS名称是分区镜像文件存放的目录名, 在脚本内亦有严格定义, 所以不能改动, 例如要制作friendlycore-lite-focal的SD固件, 可使用如下命令:
```
./mk-sd-image.sh friendlycore-lite-focal-arm64
```
  
## 获得打包固件所需要的素材
制作固件所需要的素材有:
* 内核源代码: 在[网盘](https://download.friendlyelec.com/rk3399)的 "07_源代码" 目录中, 或者从[此github链接](https://github.com/friendlyarm/kernel-rockchip)下载, 分支为nanopi-r2-v6.1.y
* uboot源代码: 在[网盘](https://download.friendlyelec.com/rk3399)的 "07_源代码" 目录中, 或者从[此github链接](https://github.com/friendlyarm/uboot-rockchip)下载, 分支为nanopi4-v2017.09
* 分区镜像文件: 在[网盘](https://download.friendlyelec.com/rk3399)的 "03_分区镜像文件" 目录中, 或者从[此http链接](http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher)下载
* 文件系统压缩包: 在[网盘](https://download.friendlyelec.com/rk3399)的 "06_文件系统" 目录中, 或者从[此http链接](http://112.124.9.243/dvdfiles/rk3399/rootfs)下载
  
如果没有提前准备好文件, 脚本亦会使用wget命令从http server去下载, 不过因为http服务器带宽不足的关系, 速度可能会比较慢。

## 脚本功能
* fusing.sh: 将镜像烧写至SD卡
* mk-sd-image.sh: 制作SD卡镜像
* mk-emmc-image.sh: 制作eMMC卡刷固件(SD-to-eMMC)

* build-rootfs-img.sh: 将指定目录打包成文件系统镜像(rootfs.img)
* build-kernel.sh: 编译内核,或内核头文件
* build-uboot.sh: 编译uboot

## 如何使用
### 重新打包SD卡运行固件
*注: 这里以friendlycore-lite-focal系统为例进行说明*  
下载本仓库到本地, 然后下载并解压friendlycore-lite-focal系统的[分区镜像文件压缩包](http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher), 由于http服务器带宽的关系, wget命令可能会比较慢, 推荐从网盘上下载同名的文件:
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399 -b kernel-6.1.y --single-branch sd-fuse_rk3399-kernel6.1
cd sd-fuse_rk3399-kernel6.1
wget http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher/friendlycore-lite-focal-arm64-images.tgz
tar xvzf friendlycore-lite-focal-arm64-images.tgz
```
解压后, 会得到一个名为friendlycore-lite-focal-arm64的目录, 可以根据项目需要, 对目录里的文件进行修改, 例如把rootfs.img替换成自已修改过的文件系统镜像, 或者自已编译的内核和uboot等, 准备就绪后, 输入如下命令将系统映像写入到SD卡  (其中/dev/sdX是你的SD卡设备名):
```
sudo ./fusing.sh /dev/sdX friendlycore-lite-focal-arm64
```
或者, 打包成可用于SD卡烧写的单一镜像文件:
```
./mk-sd-image.sh friendlycore-lite-focal-arm64
```
命令执行成功后, 将生成以下文件, 此文件可烧写到SD卡运行:  
```
out/rk3399-sd-friendlycore-lite-focal-6.1-arm64-YYYYMMDD.img
```

#### 创建一个不使用OverlayFS的SD卡镜像
产品量产需要从SD卡导出根文件系统时, 需要提前禁用OverlayFS, 下面的命令将制作一个已禁用OverlayFS的SD卡镜像:
```
cp prebuilt/parameter-ext4.txt friendlycore-lite-focal-arm64/parameter.txt
./mk-sd-image.sh friendlycore-lite-focal-arm64
```
使用此SD卡镜像制作SD启动卡, 运行系统并进行量产所需的设置后, 将SD卡插入到Linux电脑并挂载, 使用cp或rsync命令拷贝最后一个分区的文件和目录, 即可得到完整的可用于量产的rootfs根文件系统, 最后[参考此处的内容](#从根文件系统制作一个可启动的SD卡)制作成可量产的SD卡镜像或eMMC镜像。


### 重新打包 SD-to-eMMC 卡刷固件
*注: 这里以friendlycore-lite-focal系统为例进行说明*  
下载本仓库到本地, 然后下载并解压[分区镜像文件压缩包](http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher), 这里需要下载friendlycore-lite-focal和eflasher系统的文件:
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399 -b kernel-6.1.y --single-branch sd-fuse_rk3399-kernel6.1
cd sd-fuse_rk3399-kernel6.1
wget http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher/friendlycore-lite-focal-arm64-images.tgz
tar xvzf friendlycore-lite-focal-arm64-images.tgz
wget http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher/emmc-flasher-images.tgz
tar xvzf emmc-flasher-images.tgz
```
再使用以下命令, 打包卡刷固件, autostart=yes参数表示使用此固件开机时,会自动进入烧写流程:
```
./mk-emmc-image.sh friendlycore-lite-focal-arm64 autostart=yes
```
命令执行成功后, 将生成以下文件, 此文件可烧写到SD卡运行:  
```
out/rk3399-eflasher-friendlycore-lite-focal-6.1-arm64-YYYYMMDD.img
```

### 备份文件系统并创建SD映像(将系统及应用复制到另一块开发板)
#### 备份根文件系统
开发板上执行以下命令，备份整个文件系统（包括OS与数据)：  
```
sudo passwd root
su root
cd /
tar --warning=no-file-changed -cvpzf /rootfs.tar.gz \
    --exclude=/rootfs.tar.gz --exclude=/var/lib/docker/runtimes \
    --exclude=/etc/firstuser --exclude=/etc/friendlyelec-release \
    --exclude=/usr/local/first_boot_flag --one-file-system /
```
#### 从根文件系统制作一个可启动的SD卡
*注: 这里以friendlycore-lite-focal系统为例进行说明*  
下载本仓库到本地, 然后下载并解压[分区镜像压缩包](http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher):
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399 -b kernel-6.1.y --single-branch sd-fuse_rk3399-kernel6.1
cd sd-fuse_rk3399-kernel6.1
wget http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher/friendlycore-lite-focal-arm64-images.tgz
tar xvzf friendlycore-lite-focal-arm64-images.tgz
```
解压上一章节导出的rootfs.tar.gz，或者从以下网址下载文件系统压缩包并解压, 需要使用root权限, 因此解压命令需要加上sudo:
```
wget http://112.124.9.243/dvdfiles/rk3399/rootfs/rootfs-friendlycore-lite-focal-arm64.tgz
sudo tar xzf rootfs-friendlycore-lite-focal-arm64.tgz
```
可以根据需要, 对文件系统目录进行更改, 例如:
```
sudo sh -c 'echo hello > friendlycore-lite-focal-arm64/rootfs/root/welcome.txt'
```
用以下命令将文件系统目录打包成 rootfs.img:
```
sudo ./build-rootfs-img.sh friendlycore-lite-focal-arm64/rootfs friendlycore-lite-focal-arm64
```
最后打包成SD卡镜像文件:
```
./mk-sd-image.sh friendlycore-lite-focal-arm64
```
或生成SD-to-eMMC卡刷固件:
```
./mk-emmc-image.sh friendlycore-lite-focal-arm64
```

### 编译内核
*注: 这里以friendlycore-lite-focal系统为例进行说明*  
下载本仓库到本地, 然后下载并解压[分区镜像压缩包](http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher):
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399 -b kernel-6.1.y --single-branch sd-fuse_rk3399-kernel6.1
cd sd-fuse_rk3399-kernel6.1
wget http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher/friendlycore-lite-focal-arm64-images.tgz
tar xvzf friendlycore-lite-focal-arm64-images.tgz
```
从github克隆内核源代码到本地, 用环境变量KERNEL_SRC来指定本地源代码目录:
```
export KERNEL_SRC=$PWD/kernel
git clone https://github.com/friendlyarm/kernel-rockchip -b nanopi-r2-v6.1.y --depth 1 ${KERNEL_SRC}
```
根据需要配置内核:
```
cd $KERNEL_SRC
touch .scmversion
make ARCH=arm64 nanopi4_linux_defconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- menuconfig     # 根据需要改动配置
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- savedefconfig
cp defconfig ./arch/arm64/configs/my_defconfig                  # 保存配置 my_defconfig
git add ./arch/arm64/configs/my_defconfig
cd -
```
使用KCFG环境变量指定内核的配置 (KERNEL_SRC指定源代码目录), 使用你的配置编译内核:
```
export KERNEL_SRC=$PWD/kernel
export KCFG=my_defconfig
./build-kernel.sh friendlycore-lite-focal-arm64
```

#### 编译内核头文件
设置环境变量MK_HEADERS_DEB为1, 将编译内核头文件:
```
MK_HEADERS_DEB=1 ./build-kernel.sh friendlycore-lite-focal-arm64
```
#### 其他
* 设置环境变量BUILD_THIRD_PARTY_DRIVER为0将跳过第三方驱动模块的编译

### 编译 u-boot
*注: 这里以friendlycore-lite-focal系统为例进行说明* 
下载本仓库到本地, 然后下载并解压[分区镜像压缩包](http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher):
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399 -b kernel-6.1.y --single-branch sd-fuse_rk3399-kernel6.1
cd sd-fuse_rk3399-kernel6.1
wget http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher/friendlycore-lite-focal-arm64-images.tgz
tar xvzf friendlycore-lite-focal-arm64-images.tgz
```
从github克隆与OS版本相匹配的u-boot源代码到本地, 环境变量UBOOT_SRC用于指定本地源代码目录:
```
export UBOOT_SRC=$PWD/uboot
git clone https://github.com/friendlyarm/uboot-rockchip -b nanopi4-v2017.09 --depth 1 ${UBOOT_SRC}
./build-uboot.sh friendlycore-lite-focal-arm64
```

## Tips: 如何查询SD卡的设备文件名
在未插入SD卡的情况下输入:
```
ls -1 /dev > ~/before.txt
```
插入SD卡,输入以下命令查询:
```
ls -1 /dev > ~/after.txt
diff ~/before.txt ~/after.txt
```



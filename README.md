
# sd-fuse_rk3399
## Introduction
This repository is a bunch of scripts to build bootable SD card images for FriendlyElec RK3399 boards, the main features are as follows:

* Create root ﬁlesystem image from a directory
* Build bootable SD card image
* Easy way to compile kernel、uboot and third-party driver
  
*Read this in other languages: [简体中文](README_cn.md)*  
  
## Requirements
* Supports x86_64 and aarch64 platforms
* Recommended Host OS: Ubuntu 20.04 LTS (Focal Fossa) 64-bit or Higher. Note: Build will fail on Ubuntu Bionic since package lz4 is required
* For x86_64 user, it is recommended to run this script to initialize the development environment: https://github.com/friendlyarm/build-env-on-ubuntu-bionic
* Docker container: https://github.com/friendlyarm/docker-cross-compiler-novnc

## Kernel Version Support
The sd-fuse use multiple git branches to support each version of the kernel, the current branche supported kernel version is as follows:
* 6.1.y   
  
For other kernel versions, please switch to the related git branch.
## Target board OS Supported
*Notes: The OS name is the same as the directory name, it is written in the script so it cannot be renamed.*

* friendlywrt23
* friendlywrt23-docker
* friendlywrt21
* friendlywrt21-docker
* debian-bullseye-core-arm64
* friendlycore-lite-noble-arm64
* openmediavault-arm64

  
To build an SD card image for friendlycore-lite-noble, for example like this:
```
./mk-sd-image.sh friendlycore-lite-noble-arm64
```
  
## Where to download files
The following files may be required to build SD card image:
* kernel source code: In the directory "07_Source codes" of [NetDrive](https://download.friendlyelec.com/rk3399), or download from [Github](https://github.com/friendlyarm/kernel-rockchip), the branch name is nanopi-r2-v6.1.y
* uboot source code: In the directory "07_Source codes" of [NetDrive](https://download.friendlyelec.com/rk3399), or download from [Github](https://github.com/friendlyarm/uboot-rockchip), the branch name is nanopi4-v2017.09
* pre-built partition image: In the directory "03_Partition image files" of [NetDrive](https://download.friendlyelec.com/rk3399), or download from [HTTP server](http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher)
* compressed root file system tar ball: In the directory "06_File systems" of [NetDrive](https://download.friendlyelec.com/rk3399), or download from [HTTP server](http://112.124.9.243/dvdfiles/rk3399/rootfs)
  
If the files are not prepared in advance, the script will automatically download the required files, but the speed may be slower due to the bandwidth of the http server.

## Script Functions
* fusing.sh: Flash the image to SD card
* mk-sd-image.sh: Build SD card image
* mk-emmc-image.sh: Build SD-to-eMMC image, used to install system to eMMC

* build-rootfs-img.sh: Create root ﬁlesystem image(rootfs.img) from a directory
* build-kernel.sh: Compile the kernel, or kernel headers
* build-uboot.sh: Compile uboot

## Usage
### Build your own SD card image
*Note: Here we use friendlycore-lite-noble system as an example*  
Clone this repository locally, then download and uncompress the [pre-built images](http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher), due to the bandwidth of the http server, we recommend downloading the file from the [NetDrive](https://download.friendlyelec.com/rk3399):
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399 -b kernel-6.1.y --single-branch sd-fuse_rk3399-kernel6.1
cd sd-fuse_rk3399-kernel6.1
wget http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher/friendlycore-lite-noble-arm64-images.tgz
tar xvzf friendlycore-lite-noble-arm64-images.tgz
```
After decompressing, you will get a directory named friendlycore-lite-noble-arm64, you can change the files in the directory as needed, for example, replace rootfs.img with your own modified version, or your own compiled kernel and uboot, finally, flash the image to the SD card by entering the following command (The below steps assume your SD card is device /dev/sdX):
```
sudo ./fusing.sh /dev/sdX friendlycore-lite-noble-arm64
```
Or, package it as an SD card image file:
```
./mk-sd-image.sh friendlycore-lite-noble-arm64
```
The following flashable image file will be generated, it is now ready to be used to boot the device into friendlycore-lite-noble:  
```
out/rk3399-sd-friendlycore-lite-noble-6.1-arm64-YYYYMMDD.img
```

#### Create an SD card image that does not use OverlayFS
The following command will create an SD card image with OverlayFS disabled:
```
cp prebuilt/parameter-ext4.txt friendlycore-lite-noble-arm64/parameter.txt
./mk-sd-image.sh friendlycore-lite-noble-arm64
```
Disabling overlayfs is useful for exporting root filesystem.


### Build your own SD-to-eMMC Image
*Note: Here we use friendlycore-lite-noble system as an example*  
Clone this repository locally, then download and uncompress the [pre-built images](http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher), here you need to download the friendlycore-lite-noble and eflasher [pre-built images](http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher):
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399 -b kernel-6.1.y --single-branch sd-fuse_rk3399-kernel6.1
cd sd-fuse_rk3399-kernel6.1
wget http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher/friendlycore-lite-noble-arm64-images.tgz
tar xvzf friendlycore-lite-noble-arm64-images.tgz
wget http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher/emmc-flasher-images.tgz
tar xvzf emmc-flasher-images.tgz
```
Then use the following command to build the SD-to-eMMC image, the autostart=yes parameter means it will automatically enter the flash process when booting:
```
./mk-emmc-image.sh friendlycore-lite-noble-arm64 autostart=yes
```
The following flashable image file will be generated, ready to be used to boot the device into eflasher system and then flash friendlycore-lite-noble system to eMMC: 
```
out/rk3399-eflasher-friendlycore-lite-noble-6.1-arm64-YYYYMMDD.img
```
### Backup rootfs and create custom SD image (to burn your application into other boards)
#### Backup rootfs
Run the following commands on your target board. These commands will back up the entire root partition:
```
sudo passwd root
su root
cd /
tar --warning=no-file-changed -cvpzf /rootfs.tar.gz \
    --exclude=/rootfs.tar.gz --exclude=/var/lib/docker/runtimes \
    --exclude=/etc/firstuser --exclude=/etc/friendlyelec-release \
    --exclude=/usr/local/first_boot_flag --one-file-system /
```
#### Making a bootable SD card from a root filesystem
*Note: Here we use friendlycore-lite-noble system as an example*  
Clone this repository locally, then download and uncompress the [pre-built images](http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher):
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399 -b kernel-6.1.y --single-branch sd-fuse_rk3399-kernel6.1
cd sd-fuse_rk3399-kernel6.1
wget http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher/friendlycore-lite-noble-arm64-images.tgz
tar xvzf friendlycore-lite-noble-arm64-images.tgz
```
Extract the rootfs.tar.gz exported in the previous section, the tar command requires root privileges, so you need put sudo in front of the command:
```
mkdir friendlycore-lite-noble-arm64/rootfs
./tools/extract-rootfs-tar.sh rootfs.tar.gz friendlycore-lite-noble-arm64/rootfs
```
or download the filesystem archive from the following URL and extract it:
```
wget http://112.124.9.243/dvdfiles/rk3399/rootfs/rootfs-friendlycore-lite-noble-arm64.tgz
./tools/extract-rootfs-tar.sh rootfs-friendlycore-lite-noble-arm64.tgz
```
Make rootfs to img:
```
sudo ./build-rootfs-img.sh friendlycore-lite-noble-arm64/rootfs friendlycore-lite-noble-arm64
```
Use the new rootfs.img to build SD card image:
```
./mk-sd-image.sh friendlycore-lite-noble-arm64
```
Or build SD-to-eMMC image:
```
./mk-emmc-image.sh friendlycore-lite-noble-arm64 autostart=yes
```
If the image path is too big to pack, you can use the RAW_SIZE_MB environment variable to set a new image size. for example, you can set it to 16GB:
```
RAW_SIZE_MB=16000 ./mk-sd-image.sh friendlycore-lite-noble-arm64
RAW_SIZE_MB=16000 ./mk-emmc-image.sh friendlycore-lite-noble-arm64
```
### Compiling the Kernel
*Note: Here we use friendlycore-lite-noble system as an example*  
Clone this repository locally, then download and uncompress the [pre-built images](http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher):
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399 -b kernel-6.1.y --single-branch sd-fuse_rk3399-kernel6.1
cd sd-fuse_rk3399-kernel6.1
wget http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher/friendlycore-lite-noble-arm64-images.tgz
tar xvzf friendlycore-lite-noble-arm64-images.tgz
```
Download the kernel source code from github:
```
git clone https://github.com/friendlyarm/kernel-rockchip -b nanopi-r2-v6.1.y --depth 1 kernel
```
Customize the kernel configuration:
```
cd kernel
touch .scmversion
make ARCH=arm64 nanopi4_linux_defconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- menuconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- savedefconfig
cp defconfig ./arch/arm64/configs/my_defconfig                  # Save the configuration as my_defconfig
git add ./arch/arm64/configs/my_defconfig
cd -
```
To compile the kernel, use the environment variables KERNEL_SRC and KCFG to set the source code folder and the defconfig file:
```
KERNEL_SRC=kernel KCFG=my_defconfig ./build-kernel.sh friendlycore-lite-noble-arm64
```

#### Compiling the kernel headers only
Set the environment variable MK_HEADERS_DEB to 1, which will compile the kernel headers:
```
MK_HEADERS_DEB=1 ./build-kernel.sh friendlycore-lite-noble-arm64
```
#### Environment Variables
* KERNEL_SRC is used to specify the local kernel source code dir.
* KCFG is used to specify the kernel defconfig (located in the arch/arm64/configs/ dir).
* Set BUILD_THIRD_PARTY_DRIVER to 0 to skip compiling third-party driver modules
* Set SKIP_DISTCLEAN to 1 to skip running distclean before compiling

### Compiling the u-boot
*Note: Here we use friendlycore-lite-noble system as an example* 
Clone this repository locally, then download and uncompress the [pre-built images](http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher)::
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399 -b kernel-6.1.y --single-branch sd-fuse_rk3399-kernel6.1
cd sd-fuse_rk3399-kernel6.1
wget http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher/friendlycore-lite-noble-arm64-images.tgz
tar xvzf friendlycore-lite-noble-arm64-images.tgz
```
Download the u-boot source code from github that matches the OS version, the environment variable UBOOT_SRC is used to specify the local source code directory:
```
git clone https://github.com/friendlyarm/uboot-rockchip -b nanopi4-v2017.09 --depth 1 uboot
UBOOT_SRC=uboot ./build-uboot.sh friendlycore-lite-noble-arm64
```


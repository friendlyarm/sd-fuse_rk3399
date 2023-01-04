
# sd-fuse_rk3399
## Introduction
This repository is a bunch of scripts to build bootable SD card images for FriendlyElec RK3399 boards, the main features are as follows:

* Create root ﬁlesystem image from a directory
* Build bootable SD card image
* Easy way to compile kernel、uboot and third-party driver
  
*Read this in other languages: [简体中文](README_cn.md)*  
  
## Requirements
* Recommended Host OS: Ubuntu 18.04 LTS (Bionic Beaver) 64-bit or Higher
* It is recommended to run this script to initialize the development environment: https://github.com/friendlyarm/build-env-on-ubuntu-bionic

## Kernel Version Support
The sd-fuse use multiple git branches to support each version of the kernel, the current branche supported kernel version is as follows:
* 4.4.y   
  
For other kernel versions, please switch to the related git branch.
## Target board OS Supported
*Notes: The OS name is the same as the directory name, it is written in the script so it cannot be renamed.*

* buildroot
* debian-buster-desktop-arm64
* debian-bullseye-desktop-arm64
* ubuntu-jammy-desktop-arm64
* ubuntu-jammy-minimal-arm64
* friendlywrt22
* friendlywrt22-docker
* friendlywrt21
* friendlywrt21-docker

  
To build an SD card image for debian-buster, for example like this:
```
./mk-sd-image.sh debian-buster-desktop-arm64
```
  
## Where to download files
The following files may be required to build SD card image:
* kernel source code: In the directory "07_Source codes" of [NetDrive](https://download.friendlyelec.com/rk3399), or download from [Github](https://github.com/friendlyarm/linux), the branch name is sunxi-4.14.y
* uboot source code: In the directory "07_Source codes" of [NetDrive](https://download.friendlyelec.com/rk3399), or download from [Github](https://github.com/friendlyarm/u-boot), the branch name is sunxi-v2017.x
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
*Note: Here we use debian-buster system as an example*  
Clone this repository locally, then download and uncompress the [pre-built images](http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher), due to the bandwidth of the http server, we recommend downloading the file from the [NetDrive](https://download.friendlyelec.com/rk3399):
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399 -b master sd-fuse_rk3399-kernel4.4
cd sd-fuse_rk3399-kernel4.4
wget http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher/debian-buster-desktop-arm64-images.tgz
tar xvzf debian-buster-desktop-arm64-images.tgz
```
After decompressing, you will get a directory named debian-buster-desktop-arm64, you can change the files in the directory as needed, for example, replace rootfs.img with your own modified version, or your own compiled kernel and uboot, finally, flash the image to the SD card by entering the following command (The below steps assume your SD card is device /dev/sdX):
```
sudo ./fusing.sh /dev/sdX debian-buster-desktop-arm64
```
Or, package it as an SD card image file:
```
./mk-sd-image.sh debian-buster-desktop-arm64
```
The following flashable image file will be generated, it is now ready to be used to boot the device into debian-buster:  
```
out/h3-sd-debian-buster-desktop-5.10-arm64-YYYYMMDD.img
```


### Build your own SD-to-eMMC Image
*Note: Here we use debian-buster system as an example*  
Clone this repository locally, then download and uncompress the [pre-built images](http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher), here you need to download the debian-buster and eflasher [pre-built images](http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher):
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399 -b master sd-fuse_rk3399-kernel4.4
cd sd-fuse_rk3399-kernel4.4
wget http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher/debian-buster-desktop-arm64-images.tgz
tar xvzf debian-buster-desktop-arm64-images.tgz
wget http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher/eflasher.tgz
tar xvzf eflasher.tgz
```
Then use the following command to build the SD-to-eMMC image, the autostart=yes parameter means it will automatically enter the flash process when booting:
```
./mk-emmc-image.sh debian-buster-desktop-arm64 autostart=yes
```
The following flashable image file will be generated, ready to be used to boot the device into eflasher system and then flash debian-buster system to eMMC: 
```
out/h3-eflasher-debian-buster-desktop-5.10-arm64-YYYYMMDD.img
```

### Build your own root filesystem image
*Note: Here we use debian-buster system as an example*  
Clone this repository locally, then download and uncompress the [pre-built images](http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher):
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399 -b master sd-fuse_rk3399-kernel4.4
cd sd-fuse_rk3399-kernel4.4
wget http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher/debian-buster-desktop-arm64-images.tgz
tar xvzf debian-buster-desktop-arm64-images.tgz
```
Download the compressed root file system tar ball and unzip it, the unzip command requires root privileges, so you need put sudo in front of the command:
```
wget http://112.124.9.243/dvdfiles/rk3399/rootfs/rootfs-debian-buster-desktop-arm64.tgz
sudo tar xzf rootfs-debian-buster-desktop-arm64.tgz
```
Change something:
```
sudo sh -c 'echo hello > debian-buster-desktop-arm64/rootfs/root/welcome.txt'
```
Make rootfs to img:
```
sudo ./build-rootfs-img.sh debian-buster-desktop-arm64/rootfs debian-buster-desktop-arm64
```
Use the new rootfs.img to build SD card image:
```
./mk-sd-image.sh debian-buster-desktop-arm64
```
Or build SD-to-eMMC image:
```
./mk-emmc-image.sh debian-buster-desktop-arm64
```
#### Tips

* Using the debootstrap tool, you can customize the file system, pre-install packages, etc.


### Compiling the Kernel
*Note: Here we use debian-buster system as an example*  
Clone this repository locally, then download and uncompress the [pre-built images](http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher):
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399 -b master sd-fuse_rk3399-kernel4.4
cd sd-fuse_rk3399-kernel4.4
wget http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher/debian-buster-desktop-arm64-images.tgz
tar xvzf debian-buster-desktop-arm64-images.tgz
```
Download the kernel source code from github, using the environment variable KERNEL_SRC to specify the local source code directory:
```
export KERNEL_SRC=$PWD/kernel
git clone https://github.com/friendlyarm/linux -b sunxi-4.14.y --depth 1 ${KERNEL_SRC}
```
Customize the kernel configuration:
```
cd $KERNEL_SRC
touch .scmversion
make ARCH=arm sunxi_defconfig
make ARCH=arm CROSS_COMPILE=arm-linux- menuconfig
make ARCH=arm CROSS_COMPILE=arm-linux- savedefconfig
cp defconfig ./arch/arm/configs/my_defconfig                  # Save the configuration as my_defconfig
git add ./arch/arm/configs/my_defconfig
cd -
```
Specify the configuration of the kernel using the KCFG environment variable (KERNEL_SRC specifies the source directory), and compile the kernel with your configuration:
```
export KERNEL_SRC=$PWD/kernel
export KCFG=my_defconfig
./build-kernel.sh debian-buster-desktop-arm64
```

#### Compiling the kernel headers
Set the environment variable MK_HEADERS_DEB to 1, which will compile the kernel headers:
```
MK_HEADERS_DEB=1 ./build-kernel.sh debian-buster-desktop-arm64
```
#### Other
* Set the environment variable BUILD_THIRD_PARTY_DRIVER to 0 will skip the compilation of third-party driver modules

### Compiling the u-boot
*Note: Here we use debian-buster system as an example* 
Clone this repository locally, then download and uncompress the [pre-built images](http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher)::
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399 -b master sd-fuse_rk3399-kernel4.4
cd sd-fuse_rk3399-kernel4.4
wget http://112.124.9.243/dvdfiles/rk3399/images-for-eflasher/debian-buster-desktop-arm64-images.tgz
tar xvzf debian-buster-desktop-arm64-images.tgz
```
Download the u-boot source code from github that matches the OS version, the environment variable UBOOT_SRC is used to specify the local source code directory:
```
export UBOOT_SRC=$PWD/uboot
git clone https://github.com/friendlyarm/u-boot -b sunxi-v2017.x --depth 1 ${UBOOT_SRC}
./build-uboot.sh debian-buster-desktop-arm64
```


# sd-fuse_rk3399 for kernel-5.10.y
Create bootable SD card for NanoPC T4/NanoPi R4S/NanoPi M4/Som-RK3399/NanoPi NEO4  
  
***Note: Since RK3399 contains multiple different versions of kernel and uboot, please refer to the table below to switch this repo to the specified branch according to the OS***  
| OS                                     | branch          | image directory name                  |
| -------------------------------------- | --------------- | ------------------------------------- |
| [*]friendlywrt                         | kernel-5.10.y   | friendlywrt                           |
| [ ]friendlywrt-kernel4                 | kernel-4.19     | friendlywrt-kernel4                   |
| [ ]friendlycore focal                  | kernel-4.19     | friendlycore-focal-arm64              |
| [*]friendlycore lite focal (kernel5.x) | kernel-5.10.y   | friendlycore-lite-focal-kernel5-arm64 |
| [ ]friendlycore lite focal (kernel4.x) | kernel-4.19     | friendlycore-lite-focal-kernel4-arm64 |
| [ ]android10                           | kernel-4.19     | android10                             |
| [ ]friendlydesktop bionic              | master          | friendlydesktop-arm64                 |
| [ ]friendlycore bionic                 | master          | friendlycore-arm64                    |
| [ ]lubuntu xenial                      | master          | lubuntu                               |
| [ ]eflasher                            | master          | eflasher                              |
| [ ]android8                            | master          | android8                              |
| [ ]android7                            | master          | android7                              |

  
## How to find the /dev name of my SD Card
Unplug all usb devices:
```
ls -1 /dev > ~/before.txt
```
plug it in, then
```
ls -1 /dev > ~/after.txt
diff ~/before.txt ~/after.txt
```

## Build friendlywrt bootable SD card
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399.git -b kernel-5.10.y
cd sd-fuse_rk3399
sudo ./fusing.sh /dev/sdX friendlywrt
```
Notes:  
fusing.sh will check the local directory for a directory with the same name as OS, if it does not exist fusing.sh will go to download it from network.  
So you can download from the netdisk in advance, on netdisk, the images files are stored in a directory called images-for-eflasher, for example:
```
cd sd-fuse_rk3399
tar xvzf /path/to/NETDISK/images-for-eflasher/friendlywrt-images.tgz
sudo ./fusing.sh /dev/sdX friendlywrt
```

## Build an sd card image
First, download and unpack:
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399.git -b kernel-5.10.y
cd sd-fuse_rk3399
wget http://112.124.9.243/dvdfiles/RK3399/images-for-eflasher/friendlywrt-images.tgz
tar xvzf friendlywrt-images.tgz
```
Now,  Change something under the friendlywrt directory, 
for example, replace the file you compiled, then build friendlywrt bootable SD card: 
```
sudo ./fusing.sh /dev/sdX friendlywrt
```
or build an sd card image:
```
./mk-sd-image.sh friendlywrt
```
The following file will be generated:  
```
out/rk3399-sd-friendlywrt-5.10-arm64-yyyymmdd.img
```
You can use dd to burn this file into an sd card:
```
dd if=out/rk3399-sd-friendlywrt-5.10-arm64-yyyymmdd.img of=/dev/sdX bs=1M
```
## Build an sdcard-to-emmc image (eflasher rom)
Enable exFAT file system support on Ubuntu:
```
sudo apt-get install exfat-fuse exfat-utils
```
Generate the eflasher raw image, and put friendlycore image files into eflasher:
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399.git -b kernel-5.10.y
cd sd-fuse_rk3399
wget http://112.124.9.243/dvdfiles/RK3399/images-for-eflasher/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz
wget http://112.124.9.243/dvdfiles/RK3399/images-for-eflasher/friendlywrt-images.tgz
tar xzf friendlywrt-images.tgz
sudo ./mk-emmc-image.sh friendlywrt
```
The following file will be generated:  
```
out/rk3399-eflasher-friendlywrt-5.10-yyyymmdd.img
```
You can use dd to burn this file into an sd card:
```
dd if=out/rk3399-eflasher-friendlywrt-5.10-yyyymmdd.img of=/dev/sdX bs=1M
```

## Replace the file you compiled

### Install cross compiler and tools

Install the package:
```
apt install liblz4-tool android-tools-fsutils
```
Install Cross Compiler:
```
git clone https://github.com/friendlyarm/prebuilts.git
sudo mkdir -p /opt/FriendlyARM/toolchain
sudo tar xf prebuilts/gcc-x64/aarch64-cortexa53-linux-gnu-6.4.tar.xz -C /opt/FriendlyARM/toolchain/
```

### Build U-boot and Kernel for FriendlyWrt
Download image files:
```
cd sd-fuse_rk3399
wget http://112.124.9.243/dvdfiles/RK3399/images-for-eflasher/lubuntu-desktop-images.tgz
tar xzf lubuntu-desktop-images.tgz
wget http://112.124.9.243/dvdfiles/RK3399/images-for-eflasher/friendlywrt-images.tgz
tar xzf friendlywrt-images.tgz
wget http://112.124.9.243/dvdfiles/RK3399/images-for-eflasher/friendlydesktop-arm64-images.tgz
tar xzf friendlydesktop-arm64-images.tgz
```
Build kernel:
```
cd sd-fuse_rk3399
git clone https://github.com/friendlyarm/kernel-rockchip --depth 1 -b nanopi-r2-v5.10.y out/kernel-rk3399
KERNEL_SRC=$PWD/out/kernel-rk3399 ./build-kernel.sh friendlywrt
./mk-sd-image.sh friendlywrt

```
Build uboot:
```
cd sd-fuse_rk3399
git clone https://github.com/friendlyarm/uboot-rockchip --depth 1 -b nanopi4-v2017.09 uboot-rk3399
UBOOT_SRC=$PWD/uboot-rk3399 ./build-uboot.sh friendlywrt
./mk-sd-image.sh friendlywrt

```

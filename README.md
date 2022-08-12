# sd-fuse_rk3399 for kernel-5.10.y
Create bootable SD card for NanoPC T4/NanoPi R4S/NanoPi M4/Som-RK3399/NanoPi NEO4  
  
***Note: Since RK3399 contains multiple different versions of kernel and uboot, please refer to the table below to switch this repo to the specified branch according to the OS***  
| OS                                     | branch          | image directory name                  |
| -------------------------------------- | --------------- | ------------------------------------- |
| [ ]friendlywrt                         | kernel-5.15.y   | friendlywrt                           |
| [ ]buildroot                           | kernel-4.19     | buildroot                             |
| [ ]friendlywrt-kernel4                 | kernel-4.19     | friendlywrt-kernel4                   |
| [ ]friendlycore focal                  | kernel-4.19     | friendlycore-focal-arm64              |
| [ ]debian buster                       | kernel-4.19     | debian-buster-desktop-arm64           |
| [*]debian buster                       | kernel-5.10.y   | debian-buster-desktop-arm64           |
| [ ]friendlycore lite focal (kernel5.x) | kernel-5.15.y   | friendlycore-lite-focal-kernel5-arm64 |
| [ ]friendlycore lite focal (kernel4.x) | kernel-4.19     | friendlycore-lite-focal-kernel4-arm64 |
| [ ]android10                           | kernel-4.19     | android10                             |
| [ ]android11                           | kernel-4.19     | android11                             |
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

## Build debian-buster-desktop bootable SD card
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399.git -b kernel-5.10.y
cd sd-fuse_rk3399
sudo ./fusing.sh /dev/sdX debian-buster-desktop-arm64
```
Notes:  
fusing.sh will check the local directory for a directory with the same name as OS, if it does not exist fusing.sh will go to download it from network.  
So you can download from the netdisk in advance, on netdisk, the images files are stored in a directory called images-for-eflasher, for example:
```
cd sd-fuse_rk3399
tar xvzf /path/to/NETDISK/images-for-eflasher/debian-buster-desktop-arm64-images.tgz
sudo ./fusing.sh /dev/sdX debian-buster-desktop-arm64
```

## Build an sd card image
First, download and unpack:
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399.git -b kernel-5.10.y
cd sd-fuse_rk3399
wget http://112.124.9.243/dvdfiles/RK3399/images-for-eflasher/debian-buster-desktop-arm64-images.tgz
tar xvzf debian-buster-desktop-arm64-images.tgz
```
Now,  Change something under the debian-buster-desktop-arm64 directory, 
for example, replace the file you compiled, then build debian-buster-desktop-arm64 bootable SD card: 
```
sudo ./fusing.sh /dev/sdX debian-buster-desktop-arm64
```
or build an sd card image:
```
./mk-sd-image.sh debian-buster-desktop-arm64
```
The following file will be generated:  
```
out/rk3399-sd-debian-buster-desktop-5.10-arm64-yyyymmdd.img
```
You can use dd to burn this file into an sd card:
```
dd if=out/rk3399-sd-debian-buster-desktop-5.10-arm64-yyyymmdd.img of=/dev/sdX bs=1M
```
## Build an sdcard-to-emmc image (eflasher rom)
Enable exFAT file system support on Ubuntu:
```
sudo apt-get install exfat-fuse exfat-utils
```
Generate the eflasher raw image, and put debian-buster-desktop image files into eflasher:
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399.git -b kernel-5.10.y
cd sd-fuse_rk3399
wget http://112.124.9.243/dvdfiles/RK3399/images-for-eflasher/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz
wget http://112.124.9.243/dvdfiles/RK3399/images-for-eflasher/debian-buster-desktop-arm64-images.tgz
tar xzf debian-buster-desktop-arm64-images.tgz
sudo ./mk-emmc-image.sh debian-buster-desktop-arm64
```
The following file will be generated:  
```
out/rk3399-eflasher-debian-buster-desktop-arm64-yyyymmdd.img
```
You can use dd to burn this file into an sd card:
```
dd if=out/rk3399-eflasher-debian-buster-desktop-arm64-yyyymmdd.img of=/dev/sdX bs=1M
```

## Replace the file you compiled

### Install cross compiler and tools

Install the package:
```
sudo apt install liblz4-tool
sudo apt install android-tools-fsutils
sudo apt install swig
sudo apt install python-dev python3-dev
```
Install Cross Compiler:
```
git clone https://github.com/friendlyarm/prebuilts.git -b master --depth 1 friendlyelec-toolchain
(cd friendlyelec-toolchain/gcc-x64 && cat toolchain-6.4-aarch64.tar.gz* | sudo tar xz -C /)
```

### Build U-boot and Kernel for debian-buster-desktop
Download image files:
```
cd sd-fuse_rk3399
wget http://112.124.9.243/dvdfiles/RK3399/images-for-eflasher/debian-buster-desktop-arm64-images.tgz
tar xzf debian-buster-desktop-arm64-images.tgz
```
Build kernel for debian-buster-desktop, the relevant image files in the images directory will be automatically updated, including the kernel modules in the file system:
```
git clone https://github.com/friendlyarm/kernel-rockchip --depth 1 -b nanopi5-v5.10.y_opt kernel-rk3399
KERNEL_SRC=$PWD/kernel-rk3399 ./build-kernel.sh debian-buster-desktop-arm64
```
Build uboot for debian-buster-desktop, the relevant image files in the images directory will be automatically updated:
```
git clone https://github.com/friendlyarm/uboot-rockchip --depth 1 -b nanopi4-v2017.09
UBOOT_SRC=$PWD/uboot-rockchip ./build-uboot.sh debian-buster-desktop-arm64
```
re-generate new firmware:
```
./mk-sd-image.sh debian-buster-desktop-arm64
```

### Custom rootfs for debian-buster-desktop
Use debian-buster-desktop as an example:
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399.git -b kernel-5.10.y
cd sd-fuse_rk3399

wget http://112.124.9.243/dvdfiles/RK3399/rootfs/rootfs-debian-buster-desktop-arm64.tgz
tar xzf rootfs-debian-buster-desktop-arm64.tgz
```
Now,  change something under rootfs directory, like this:
```
echo hello > debian-buster-desktop-arm64/rootfs/root/welcome.txt
```
Re-make rootfs.img:
```
./build-rootfs-img.sh debian-buster-desktop-arm64/rootfs debian-buster-desktop-arm64
```
Make sdboot image:
```
./mk-sd-image.sh debian-buster-desktop-arm64
```
or make sd-to-emmc image (eflasher rom):
```
./mk-emmc-image.sh debian-buster-desktop-arm64
```


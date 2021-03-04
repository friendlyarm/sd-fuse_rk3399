# sd-fuse_rk3399 for kernel-4.4.y
Create bootable SD card for NanoPC T4/NanoPi R4S/NanoPi M4/Som-RK3399/NanoPi NEO4  
  
***Note: Since RK3399 contains multiple different versions of kernel and uboot, please refer to the table below to switch this repo to the specified branch according to the OS***  
| OS                        | branch          |
| ------------------------- | --------------- |
| [ ]friendlywrt            | kernel-5.10.y   |
| [ ]friendlycore focal     | kernel-4.19     |
| [ ]android10              | kernel-4.19     |
| [*]friendlydesktop bionic | master          |
| [*]friendlycore bionic    | master          |
| [*]lubuntu xenial         | master          |
| [*]eflasher               | master          |
| [ ]android8               | --unsupported-- |
| [ ]android7               | --unsupported-- |
  
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

## Build friendlycore bootable SD card
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399.git -b master
cd sd-fuse_rk3399
sudo ./fusing.sh /dev/sdX friendlycore-arm64
```
You can build the following OS: friendlycore-arm64, friendlydesktop-arm64, lubuntu, eflasher.  
Because the android system has to run on the emmc, so you need to make eflasher img to install Android.  

Notes:  
fusing.sh will check the local directory for a directory with the same name as OS, if it does not exist fusing.sh will go to download it from network.  
So you can download from the netdisk in advance, on netdisk, the images files are stored in a directory called images-for-eflasher, for example:
```
cd sd-fuse_rk3399
tar xvzf /path/to/NETDISK/images-for-eflasher/friendlycore-arm64-images.tgz
sudo ./fusing.sh /dev/sdX friendlycore-arm64
```

## Build an sd card image
First, download and unpack:
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399.git -b master
cd sd-fuse_rk3399
wget http://112.124.9.243/dvdfiles/RK3399/images-for-eflasher/friendlycore-arm64-images.tgz
tar xvzf friendlycore-arm64-images.tgz
```
Now,  Change something under the friendlycore-arm64 directory, 
for example, replace the file you compiled, then build friendlycore-arm64 bootable SD card: 
```
sudo ./fusing.sh /dev/sdX friendlycore-arm64
```
or build an sd card image:
```
sudo ./mk-sd-image.sh friendlycore-arm64
```
The following file will be generated:  
```
out/rk3399-sd-friendlycore-bionic-4.4-arm64-yyyymmdd.img
```
You can use dd to burn this file into an sd card:
```
dd if=out/rk3399-sd-friendlycore-bionic-4.4-arm64-20181112.img of=/dev/sdX bs=1M
```
## Build an sdcard-to-emmc image (eflasher rom)
Enable exFAT file system support on Ubuntu:
```
sudo apt-get install exfat-fuse exfat-utils
```
Generate the eflasher raw image, and put friendlycore image files into eflasher:
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399.git
cd sd-fuse_rk3399
wget http://112.124.9.243/dvdfiles/RK3399/images-for-eflasher/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz
wget http://112.124.9.243/dvdfiles/RK3399/images-for-eflasher/friendlycore-arm64-images.tgz
tar xzf friendlycore-arm64-images.tgz
sudo ./mk-emmc-image.sh friendlycore-arm64
```
The following file will be generated:  
```
out/rk3399-eflasher-friendlycore-bionic-4.4-arm64-yyyymmdd.img
```
You can use dd to burn this file into an sd card:
```
dd if=out/rk3399-eflasher-friendlycore-bionic-4.4-arm64-20181112.img of=/dev/sdX bs=1M
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

### Build U-boot and Kernel for Lubuntu, FriendlyCore and FriendlyDesktop
Download image files:
```
cd sd-fuse_rk3399
wget http://112.124.9.243/dvdfiles/RK3399/images-for-eflasher/lubuntu-desktop-images.tgz
tar xzf lubuntu-desktop-images.tgz
wget http://112.124.9.243/dvdfiles/RK3399/images-for-eflasher/friendlycore-arm64-images.tgz
tar xzf friendlycore-arm64-images.tgz
wget http://112.124.9.243/dvdfiles/RK3399/images-for-eflasher/friendlydesktop-arm64-images.tgz
tar xzf friendlydesktop-arm64-images.tgz
```
Build kernel, the relevant image files in the images directory will be automatically updated, including the kernel modules in the file system:
```
cd sd-fuse_rk3399
git clone https://github.com/friendlyarm/kernel-rockchip --depth 1 -b nanopi4-linux-v4.4.y out/kernel-rk3399
# lubuntu
KERNEL_SRC=$PWD/out/kernel-rk3399 ./build-kernel.sh lubuntu

# friendlycore-arm64
KERNEL_SRC=$PWD/out/kernel-rk3399 ./build-kernel.sh friendlycore-arm64

# friendlydesktop-arm64
KERNEL_SRC=$PWD/out/kernel-rk3399 ./build-kernel.sh friendlydesktop-arm64
```
Build uboot:
```
cd sd-fuse_rk3399
git clone https://github.com/friendlyarm/uboot-rockchip --depth 1 -b nanopi4-v2014.10_oreo uboot-rk3399
UBOOT_SRC=$PWD/uboot-rk3399 ./build-uboot.sh lubuntu
UBOOT_SRC=$PWD/uboot-rk3399 ./build-uboot.sh friendlycore-arm64
UBOOT_SRC=$PWD/uboot-rk3399 ./build-uboot.sh friendlydesktop-arm64
```

### Custom rootfs for Lubuntu, FriendlyCore and FriendlyDesktop
#### Custom rootfs in the bootable SD card
Use FriendlyCore as an example:
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399.git
cd sd-fuse_rk3399

wget http://112.124.9.243/dvdfiles/RK3399/rootfs/rootfs-friendlycore-arm64.tgz
tar xzf rootfs-friendlycore-arm64.tgz
```
Now,  change something under rootfs directory, like this:
```
echo hello > friendlycore-arm64/rootfs/root/welcome.txt  
```
Remake rootfs.img:
```
./build-rootfs-img.sh friendlycore-arm64/rootfs friendlycore-arm64
```
Make sdboot image:
```
./mk-sd-image.sh friendlycore-arm64
```
or make sd-to-emmc image (eflasher rom):
```
./mk-emmc-image.sh friendlycore-arm64
```

### Build Android8
```
git clone https://gitlab.com/friendlyelec/rk3399-android-8.1 --depth 1 -b master
cd rk3399-android-8.1
./build-nanopc-t4.sh -F -M
wget http://112.124.9.243/dvdfiles/RK3399/images-for-eflasher/android-oreo-images.tgz
tar xzf android-oreo-images.tgz
cp rockdev/Image-nanopc_t4/* android8
```
Copy the new image files to the exfat partition of the eflasher sd card:
```
cp -af android8 /mnt/exfat/
```

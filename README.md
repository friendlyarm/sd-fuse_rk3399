# sd-fuse_rk3399
Create bootable SD card for NanoPC T4/NanoPi M4/NanoPi NEO4

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
git clone https://github.com/friendlyarm/sd-fuse_rk3399.git
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
tar xvzf ../images-for-eflasher/friendlycore-arm64-images.tgz
sudo ./fusing.sh /dev/sdX friendlycore-arm64
```

## Build an sd card image
First, download and unpack:
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399.git
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
apt install liblz4-tool android-tools-fsutils
```
Install Cross Compiler:
```
git clone https://github.com/friendlyarm/prebuilts.git
sudo mkdir -p /opt/FriendlyARM/toolchain
sudo tar xf prebuilts/gcc-x64/aarch64-cortexa53-linux-gnu-6.4.tar.xz -C /opt/FriendlyARM/toolchain/
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
Build kernel:
```
cd sd-fuse_rk3399
git clone https://github.com/friendlyarm/kernel-rockchip --depth 1 -b nanopi4-linux-v4.4.y out/kernel-rk3399
# lubuntu
./build-kernel.sh lubuntu

# friendlycore-arm64
./build-kernel.sh friendlycore-arm64

# friendlydesktop-arm64
./build-kernel.sh friendlydesktop-arm64
```
Build uboot:
```
cd sd-fuse_rk3399
git clone https://github.com/friendlyarm/uboot-rockchip --depth 1 -b nanopi4-v2014.10_oreo
cd uboot-rockchip
make CROSS_COMPILE=aarch64-linux- rk3399_defconfig
export PATH=/opt/FriendlyARM/toolchain/6.4-aarch64/bin/:$PATH
make CROSS_COMPILE=aarch64-linux-
cp uboot.img trust.img ../lubuntu
cp uboot.img trust.img ../friendlycore-arm64
cp uboot.img trust.img ../friendlydesktop-arm64
cp rk3399_loader_v1.22.119.bin ../lubuntu/MiniLoaderAll.bin
cp rk3399_loader_v1.22.119.bin ../friendlycore-arm64/MiniLoaderAll.bin
cp rk3399_loader_v1.22.119.bin ../friendlydesktop-arm64/MiniLoaderAll.bin
```

### Custom rootfs for Lubuntu, FriendlyCore and FriendlyDesktop
#### Custom rootfs in the bootable SD card
Use FriendlyCore as an example:
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399.git
cd sd-fuse_rk3399

wget http://112.124.9.243/dvdfiles/RK3399/rootfs/rootfs-friendlycore-arm64-YYMMDD.tgz
tar xzf rootfs-friendlycore-arm64-YYMMDD.tgz
```
Now,  change something under rootfs directory, like this:
```
echo hello > friendlycore/rootfs/root/welcome.txt  
```
Remake rootfs.img:
```
./build-rootfs-img.sh friendlycore/rootfs friendlycore/rootfs.img
```
Make sdboot image:
```
sudo ./mk-sd-image.sh friendlycore
```
or make sd-to-emmc image (eflasher rom):
```
sudo ./mk-emmc-image.sh friendlycore
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

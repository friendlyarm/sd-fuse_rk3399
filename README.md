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

## Build friendlycore-focal bootable SD card
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399.git
cd sd-fuse_rk3399
sudo ./fusing.sh /dev/sdX friendlycore-focal-arm64
```
Notes:  
fusing.sh will check the local directory for a directory with the same name as OS, if it does not exist fusing.sh will go to download it from network.  
So you can download from the netdisk in advance, on netdisk, the images files are stored in a directory called images-for-eflasher, for example:
```
cd sd-fuse_rk3399
tar xvzf ../images-for-eflasher/friendlycore-focal-arm64-images.tgz
sudo ./fusing.sh /dev/sdX friendlycore-focal-arm64
```

## Build an sd card image
First, download and unpack:
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399.git
cd sd-fuse_rk3399
wget http://112.124.9.243/dvdfiles/RK3399/images-for-eflasher/friendlycore-focal-arm64-images.tgz
tar xvzf friendlycore-focal-arm64-images.tgz
```
Now,  Change something under the friendlycore-focal-arm64 directory, 
for example, replace the file you compiled, then build friendlycore-focal-arm64 bootable SD card: 
```
sudo ./fusing.sh /dev/sdX friendlycore-focal-arm64
```
or build an sd card image:
```
sudo ./mk-sd-image.sh friendlycore-focal-arm64
```
The following file will be generated:  
```
out/rk3399-sd-friendlycore-bionic-4.4-arm64-yyyymmdd.img
```
You can use dd to burn this file into an sd card:
```
dd if=out/rk3399-sd-friendlycore-bionic-4.4-arm64-20181112.img of=/dev/sdX bs=1M
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

### Build U-boot and Kernel for friendlycore-focal
Download image files:
```
cd sd-fuse_rk3399
wget http://112.124.9.243/dvdfiles/RK3399/images-for-eflasher/friendlycore-focal-arm64-images.tgz
tar xzf friendlycore-focal-arm64-images.tgz
```
Build kernel for friendlycore-focal and regenerate sd-raw file:
```
git clone https://github.com/friendlyarm/kernel-rockchip --depth 1 -b nanopi4-v4.19.y kernel-rk3399
KERNEL_SRC=$PWDkernel-rk3399 ./build-kernel.sh friendlycore-focal-arm64
./mk-sd-image.sh friendlycore-focal-arm64
```
Build uboot for friendlycore-focal and regenerate sd-raw file:
```
git clone https://github.com/friendlyarm/rkbin
(cd rkbin && git reset 25de1a8bffb1e971f1a69d1aa4bc4f9e3d352ea3 --hard)
git clone https://github.com/friendlyarm/uboot-rockchip --depth 1 -b nanopi4-v2017.09
UBOOT_SRC=$PWD/uboot-rockchip ./build-uboot.sh friendlycore-focal-arm64
./mk-sd-image.sh friendlycore-focal-arm64
```

### Custom rootfs for friendlycore-focal
#### Custom rootfs in the bootable SD card
Use FriendlyCore as an example:
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399.git
cd sd-fuse_rk3399

wget http://112.124.9.243/dvdfiles/RK3399/rootfs/rootfs-friendlycore-focal-arm64.tgz
tar xzf rootfs-friendlycore-focal-arm64.tgz
```
Now,  change something under rootfs directory, like this:
```
echo hello > friendlycore-focal-arm64/rootfs/root/welcome.txt  
```
Remake rootfs.img:
```
./build-rootfs-img.sh friendlycore-focal-arm64/rootfs friendlycore-focal-arm64
```
Make sdboot image:
```
sudo ./mk-sd-image.sh friendlycore-focal-arm64
```

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
sudo ./mkimage.sh friendlycore-arm64
```
The following file will be generated:  
```
rk3399-sd-friendlycore-bionic-4.4-arm64-yyyymmdd.img
```
You can use dd to burn this file into an sd card:
```
dd if=rk3399-sd-friendlycore-bionic-4.4-arm64-20181112.img of=/dev/sdX bs=1M
```

## Build a package similar to rk3399-eflasher-friendlycore-bionic-4.4-arm64-YYYYMMDD.img
Enable exFAT file system support on Ubuntu:
```
sudo apt-get install exfat-fuse exfat-utils
```
Generate the eflasher raw image, and put friendlycore image files into eflasher:
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399.git
cd sd-fuse_rk3399
sudo ./mkimage.sh eflasher
DEV=`losetup -f`
losetup ${DEV} rk3399-eflasher-YYYYMMDD.img
partprobe ${DEV}
sudo mkfs.exfat ${DEV}p1 -n FriendlyARM
mkdir -p /mnt/exfat
mount -t exfat ${DEV}p1 /mnt/exfat
wget http://112.124.9.243/dvdfiles/RK3399/images-for-eflasher/friendlycore-arm64-images.tgz
tar xzf friendlycore-arm64-images.tgz -C /mnt/exfat
umount /mnt/exfat
losetup -d ${DEV}
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
git clone https://github.com/friendlyarm/kernel-rockchip --depth 1 -b nanopi4-linux-v4.4.y kernel-rockchip
cd kernel-rockchip
make ARCH=arm64 nanopi4_linux_defconfig
export PATH=/opt/FriendlyARM/toolchain/6.4-aarch64/bin/:$PATH
make ARCH=arm64 nanopi4-images
cp kernel.img resource.img ../lubuntu/
cp kernel.img resource.img ../friendlycore-arm64/
cp kernel.img resource.img ../friendlydesktop-arm64/
```
Build uboot:
```
cd sd-fuse_rk3399
git clone https://gitlab.com/friendlyelec/rk3399-nougat --depth 1 -b nanopc-t4-nougat
cd rk3399-nougat/u-boot
make CROSS_COMPILE=aarch64-linux- rk3399_defconfig
export PATH=/opt/FriendlyARM/toolchain/6.4-aarch64/bin/:$PATH
make CROSS_COMPILE=aarch64-linux-
cp uboot.img trust.img ../../lubuntu
cp uboot.img trust.img ../../friendlycore-arm64
cp uboot.img trust.img ../../friendlydesktop-arm64
cp rk3399_loader_v1.12.109.bin ../../lubuntu/MiniLoaderAll.bin
cp rk3399_loader_v1.12.109.bin ../../friendlycore-arm64/MiniLoaderAll.bin
cp rk3399_loader_v1.12.109.bin ../../friendlydesktop-arm64/MiniLoaderAll.bin
```

### Custom rootfs for Lubuntu, FriendlyCore and FriendlyDesktop
#### Custom rootfs in the bootable SD card
Use FriendlyCore as an example:
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399.git
cd sd-fuse_rk3399
sudo ./mkimage.sh friendlycore-arm64
DEV=`losetup -f`
losetup ${DEV} rk3399-sd-friendlycore-bionic-4.4-arm64-YYYYMMDD.img
partprobe ${DEV}
mkdir -p /mnt/rootfs
mount -t ext4 ${DEV}p1 /mnt/rootfs
```
Now,  Change something under /mnt/rootfs directory, like this:
```
echo hello > /mnt/rootfs/root/welcome.txt
```
Save and release resources:
```
umount /mnt/rootfs
losetup -d ${DEV}
```
burn to sd card:
```
dd if=rk3399-sd-friendlycore-bionic-4.4-arm64-YYYYMMDD.img of=/dev/sdX bs=1M
```
#### Custom rootfs for eMMC
Use FriendlyCore as an example, extract rootfs from rootfs.img:
```
git clone https://github.com/friendlyarm/sd-fuse_rk3399.git
cd sd-fuse_rk3399
wget http://112.124.9.243/dvdfiles/RK3399/images-for-eflasher/friendlycore-arm64-images.tgz
tar xzf friendlycore-arm64-images.tgz
simg2img friendlycore-arm64/rootfs.img friendlycore-arm64/r.img
mkdir -p /mnt/rootfs
mount -t ext4 -o loop friendlycore-arm64/r.img /mnt/rootfs
mkdir rootfs
cp -af /mnt/rootfs/* rootfs
umount /mnt/rootfs
rm friendlycore-arm64/r.img
```
Now,  change something under rootfs directory, like this:
```
echo hello > rootfs/root/welcome.txt  
```
Remake rootfs.img  with the make_ext4fs utility:
```
./tools/make_ext4fs -s -l 5368709120 -a root -L rootfs rootfs.img rootfs
cp rootfs.img friendlycore-arm64/
```
One thing you should be aware of is that the size of the .img file needs to be larger than the rootfs directory size, 
below are the image size values for each system we've provided:  
eflasher: 1604321280  
friendlycore: 5368709120  
lubuntu: 5368709120  
friendlydesktop: 7000000000  
  
### Build Android7
```
git clone https://gitlab.com/friendlyelec/rk3399-nougat --depth 1 -b nanopc-t4-nougat
cd rk3399-nougat
./build-nanopc-t4.sh -F -M
wget http://112.124.9.243/dvdfiles/RK3399/images-for-eflasher/android-nougat-images.tgz
tar xzf android-nougat-images.tgz
cp rockdev/Image-nanopc_t4/* android7
```
Copy the new image files to the exfat partition of the eflasher sd card:
```
cp -af android7 /mnt/exfat/
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

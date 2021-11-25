#!/bin/bash



LOCALPATH=$(pwd)
OUT=${LOCALPATH}/out
TOOLPATH=${LOCALPATH}/rkbin/tools
BOARD=$1

PATH=$PATH:$TOOLPATH

finish() {
	echo -e "\e[31m MAKE UBOOT IMAGE FAILED.\e[0m"
	exit -1
}
trap finish ERR

[ ! -d ${OUT} ] && mkdir ${OUT}
[ ! -d ${OUT}/u-boot ] && mkdir ${OUT}/u-boot
[ ! -d ${OUT}/u-boot/spi ] && mkdir ${OUT}/u-boot/spi

#source $LOCALPATH/build/board_configs.sh $BOARD
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
BOARD="rockpi4b"
DEFCONFIG=rockchip_linux_defconfig
DEFCONFIG_MAINLINE=defconfig
UBOOT_DEFCONFIG=rock-pi-4b-rk3399_defconfig
DTB=rk3399-rock-pi-4b.dtb
DTB_MAINLINE=rk3399-rock-pi-4.dtb
KERNELIMAGE=""
CHIP="rk3399"


if [ $? -ne 0 ]; then
	exit
fi

echo -e "\e[36m Building U-boot for ${BOARD} board! \e[0m"
echo -e "\e[36m Using ${UBOOT_DEFCONFIG} \e[0m"

cd ${LOCALPATH}/u-boot
make ${UBOOT_DEFCONFIG} all


$TOOLPATH/loaderimage --pack --uboot ./u-boot-dtb.bin uboot.img 0x200000 --size 1024 1

tools/mkimage -n rk3399 -T rksd -d ../rkbin/bin/rk33/rk3399_ddr_800MHz_v1.20.bin idbloader.img
cat ../rkbin/bin/rk33/rk3399_miniloader_v1.19.bin >> idbloader.img
cp idbloader.img ${OUT}/u-boot/

tools/mkimage -n rk3399 -T rkspi -d ../rkbin/bin/rk33/rk3399_ddr_800MHz_v1.20.bin idbloader-spi.img
cat ../rkbin/bin/rk33/rk3399_miniloader_spinor_v1.14.bin >> idbloader-spi.img
cp idbloader-spi.img ${OUT}/u-boot/spi

cp ../rkbin/bin/rk33/rk3399_loader_v1.20.119.bin ${OUT}/u-boot/
cp ../rkbin/bin/rk33/rk3399_loader_spinor_v1.20.126.bin ${OUT}/u-boot/spi

cat >trust.ini <<EOF
[VERSION]
MAJOR=1
MINOR=0
[BL30_OPTION]
SEC=0
[BL31_OPTION]
SEC=1
PATH=../rkbin/bin/rk33/rk3399_bl31_v1.26.elf
ADDR=0x10000
[BL32_OPTION]
SEC=0
[BL33_OPTION]
SEC=0
[OUTPUT]
PATH=trust.img
EOF

$TOOLPATH/trust_merger --size 1024 1 trust.ini

cp uboot.img ${OUT}/u-boot/
cp trust.img ${OUT}/u-boot/

cat > spi.ini <<EOF
[System]
FwVersion=18.08.03
BLANK_GAP=1
FILL_BYTE=0
[UserPart1]
Name=IDBlock
Flag=0
Type=2
File=../rkbin/bin/rk33/rk3399_ddr_800MHz_v1.20.bin,../rkbin/bin/rk33/rk3399_miniloader_spinor_v1.14.bin
PartOffset=0x40
PartSize=0x7C0
[UserPart2]
Name=uboot
Type=0x20
Flag=0
File=./uboot.img
PartOffset=0x1000
PartSize=0x800
[UserPart3]
Name=trust
Type=0x10
Flag=0
File=./trust.img
PartOffset=0x1800
PartSize=0x800
EOF
$TOOLPATH/firmwareMerger -P spi.ini ${OUT}/u-boot/spi
mv ${OUT}/u-boot/spi/Firmware.img ${OUT}/u-boot/spi/uboot-trust-spi.img
mv ${OUT}/u-boot/spi/Firmware.md5 ${OUT}/u-boot/spi/uboot-trust-spi.img.md5

echo -e "\e[36m U-boot IMAGE READY! \e[0m"

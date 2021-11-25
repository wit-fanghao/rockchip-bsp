#!/bin/bash -e

LOCALPATH=$(pwd)
OUT=${LOCALPATH}/out
EXTLINUXPATH=${LOCALPATH}/build/extlinux

version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }

finish() {
	echo -e "\e[31m MAKE KERNEL IMAGE FAILED.\e[0m"
	exit -1
}
trap finish ERR

[ ! -d ${OUT} ] && mkdir ${OUT}
[ ! -d ${OUT}/kernel ] && mkdir ${OUT}/kernel

#source $LOCALPATH/build/board_configs.sh $BOARD
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
BOARD="rockpi4b"
DEFCONFIG=rockchip_linux_defconfig
UBOOT_DEFCONFIG=rock-pi-4b-rk3399_defconfig
DTB=rk3399-rock-pi-4b.dtb
KERNELIMAGE=""
CHIP="rk3399"

if [ $? -ne 0 ]; then
	exit
fi

echo -e "\e[36m Building kernel for ${BOARD} board! \e[0m"

KERNEL_VERSION=$(cd ${LOCALPATH}/kernel && make kernelversion)
echo $KERNEL_VERSION

cd ${LOCALPATH}/kernel
[ ! -e .config ] && echo -e "\e[36m Using ${DEFCONFIG} \e[0m" && make ${DEFCONFIG}

make -j8
cd ${LOCALPATH}

cp ${LOCALPATH}/kernel/arch/arm64/boot/Image ${OUT}/kernel/
cp ${LOCALPATH}/kernel/arch/arm64/boot/dts/rockchip/${DTB} ${OUT}/kernel/

# Change extlinux.conf according board
sed -e "s,fdt .*,fdt /$DTB,g" \
	-i ${EXTLINUXPATH}/${CHIP}.conf

./build/mk-image.sh -t boot

echo -e "\e[36m Kernel build success! \e[0m"

#!/bin/bash

if [ "$1" == "-o" ]; then
	target_="Oreo"
	git apply ./oreo_firmware.patch || exit 1
else
	target_="Pie"
fi

echo "Build for ${target_} firmware"

yellow='\033[0;33m'
white='\033[0m'
red='\033[0;31m'
gre='\e[0;32m'
ZIMG=./out/arch/arm64/boot/Image.gz-dtb

export LOCALVERSION=-v2.9
export LOCALVERSION="-"${target_}${LOCALVERSION}

rm -f $ZIMG
Start=$(date +"%s")

export ARCH=arm64
export SUBARCH=arm64
export HEADER_ARCH=arm64
export CLANG_PATH=/home/pzqqt/bin/android_prebuilts_clang_host_linux-x86_clang-9.0.8
export KBUILD_COMPILER_STRING=$($CLANG_PATH/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')

export KBUILD_BUILD_HOST="lenovo"
export KBUILD_BUILD_USER="pzqqt"

make mrproper O=out && \
make whyred-perf_defconfig O=out && \
make -j6 \
	O=out \
	CC="ccache $CLANG_PATH/bin/clang" \
	CLANG_TRIPLE=aarch64-linux-gnu- \
	CROSS_COMPILE=/home/pzqqt/bin/gcc-arm-8.3-2019.03-x86_64-aarch64-linux-gnu/bin/aarch64-linux-gnu- \
	CROSS_COMPILE_ARM32=/home/pzqqt/bin/gcc-arm-8.3-2019.03-x86_64-arm-linux-gnueabi/bin/arm-linux-gnueabi-

End=$(date +"%s")
Diff=$(($End - $Start))
if [ -f $ZIMG ]; then
	echo -e "$gre << Build completed in $(($Diff / 60)) minutes and $(($Diff % 60)) seconds >> \n $white"
else
	echo -e "$red << Failed to compile zImage, fix the errors first >>$white"
fi

if [ "$1" == "-o" ]; then
	git apply -R ./oreo_firmware.patch || exit 1
fi

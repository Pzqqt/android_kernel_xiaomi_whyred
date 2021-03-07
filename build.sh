#!/bin/bash

yellow='\033[0;33m'
white='\033[0m'
red='\033[0;31m'
gre='\e[0;32m'
ZIMG=./out/arch/arm64/boot/Image.gz-dtb

disable_mkclean=false
mkdtbs=false
oc_flag=false
more_uv_flag=false
campatch_flag=false

for arg in $@; do
	case $arg in
		"--noclean") disable_mkclean=true;;
		"--dtbs") mkdtbs=true;;
		"-oc") oc_flag=true;;
		"-80uv") more_uv_flag=true;;
		"-campatch") campatch_flag=true;;
		*) {
			cat <<EOF
Usage: $0 <operate>
operate:
    --noclean   : build without run "make mrproper"
    --dtbs      : build dtbs only
    -oc         : build with apply Overclock patch
    -80uv       : build with apply 80mv UV patch
    -campatch   : build with apply camera fix patch
EOF
			exit 1
		};;
	esac
done

local_version="v8.7"

# Add two lines of comment text
# to avoid code conflicts when "git cherry-pick" or "git merge".

export LOCALVERSION="-${local_version}-eas"

rm -f $ZIMG

export ARCH=arm64
export SUBARCH=arm64
export HEADER_ARCH=arm64
export CLANG_PATH=/home/pzqqt/build_toolchain/clang-r412851-12.0.3
export KBUILD_COMPILER_STRING=$($CLANG_PATH/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')

export KBUILD_BUILD_HOST="manjaro"
export KBUILD_BUILD_USER="pzqqt"

ccache_=`which ccache`

$oc_flag && { git apply ./oc.patch || exit 1; }
$more_uv_flag && { git apply ./80mv_uv.patch || exit 1; }
$campatch_flag && { git apply ./campatch.patch || exit 1; }

$disable_mkclean || make mrproper O=out || exit 1
make whyred-perf_defconfig O=out || exit 1

Start=$(date +"%s")

$mkdtbs && make_flag="dtbs" || make_flag=""

make $make_flag -j6 \
	O=out \
	CC="${ccache_} ${CLANG_PATH}/bin/clang" \
	CLANG_TRIPLE=aarch64-linux-gnu- \
	CROSS_COMPILE="/home/pzqqt/build_toolchain/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-" \
	CROSS_COMPILE_ARM32="/home/pzqqt/build_toolchain/gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf/bin/arm-none-linux-gnueabihf-"

exit_code=$?
End=$(date +"%s")
Diff=$(($End - $Start))

$oc_flag && { git apply -R ./oc.patch || exit 1; }
$more_uv_flag && { git apply -R ./80mv_uv.patch || exit 1; }
$campatch_flag && { git apply -R ./campatch.patch || exit 1; }

if $mkdtbs; then
	if [ $exit_code -eq 0 ]; then
		echo -e "$gre << Build completed >> \n $white"
	else
		echo -e "$red << Failed to compile dtbs, fix the errors first >>$white"
		exit $exit_code
	fi
else
	if [ -f $ZIMG ]; then
		echo -e "$gre << Build completed in $(($Diff / 60)) minutes and $(($Diff % 60)) seconds >> \n $white"
	else
		echo -e "$red << Failed to compile Image.gz-dtb, fix the errors first >>$white"
		exit $exit_code
	fi
fi

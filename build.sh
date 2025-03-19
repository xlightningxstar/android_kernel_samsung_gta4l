#!/bin/bash

# Ensure the script exits on error
set -e

# Build Environment Setup
clear
make clean
rm -rf out
rm -rf anykernel
TOOLCHAIN_PATH=$(pwd)/tc/bin
MAKE_ARGS="ARCH=arm64 O=out CC=clang LLVM=1 LLVM_IAS=1 CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip"

if [ ! -d $TOOLCHAIN_PATH ]; then
    echo "TOOLCHAIN_PATH [$TOOLCHAIN_PATH] does not exist."
    echo "Please ensure the toolchain is there, or change TOOLCHAIN_PATH in the script to your toolchain path."
    exit 1
fi

echo "TOOLCHAIN_PATH: [$TOOLCHAIN_PATH]"
export PATH="$TOOLCHAIN_PATH:$PATH"

if ! command -v aarch64-linux-gnu-ld >/dev/null 2>&1; then
    echo "[aarch64-linux-gnu-ld] does not exist, please check your environment."
    exit 1
fi

if ! command -v arm-linux-gnueabi-ld >/dev/null 2>&1; then
    echo "[arm-linux-gnueabi-ld] does not exist, please check your environment."
    exit 1
fi

if ! command -v clang >/dev/null 2>&1; then
    echo "[clang] does not exist, please check your environment."
    exit 1
fi

# Check clang is existing.
echo "[clang --version]:"
clang --version

# Export variables
export KBUILD_BUILD_USER="aryan"
export KBUILD_BUILD_HOST="stormvault"

# Enable ccache for speed up compiling
export CCACHE_DIR="$HOME/.cache/ccache_samkernel"
export CC="ccache gcc"
export CXX="ccache g++"
export PATH="/usr/lib/ccache:$PATH"
echo "CCACHE_DIR: [$CCACHE_DIR]"

# Anykernel3
echo "Clone AnyKernel3 for packing kernel"
git clone https://github.com/CuriousNom/AnyKernel3.git -b gta4l-nbr --single-branch --depth=1 anykernel

# Build for gta4l series
echo "Building kernel for Samsung Galaxy Tab A7......"
make $MAKE_ARGS gta4l_eur_open_defconfig
make $MAKE_ARGS -j$(nproc --all) 2> >(tee -a error.txt >&2)

if [ -f "out/arch/arm64/boot/Image.gz-dtb" ]; then
        echo "The file [out/arch/arm64/boot/Image.gz-dtb] exists. Kernel Build successfully."
        else
        echo "The file [out/arch/arm64/boot/Image.gz-dtb] does not exist. Seems Kernel build failed."
        exit 1
fi

echo "Generating [out/arch/arm64/boot/dtb]......"
find out/arch/arm64/boot/dts -name '*.dtb' -exec cat {} + >out/arch/arm64/boot/dtb

cp out/arch/arm64/boot/Image.gz-dtb anykernel/
cp out/arch/arm64/boot/dtb anykernel/

cd anykernel
ZIP_FILENAME=Kernel_${TARGET_DEVICE}_$(date +'%Y%m%d_%H%M%S')_anykernel3_${GIT_COMMIT_ID}.zip
zip -r9 $ZIP_FILENAME ./* -x .git out/ ./*.zip
mv $ZIP_FILENAME ../
cd ..

echo "Build for Samsung Galaxy Tab A7 finished !"

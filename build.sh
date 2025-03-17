#!/bin/bash

clear
make clean
rm -rf out
TOOLCHAIN_PATH=$(pwd)/tc/bin
MAKE_ARGS="ARCH=arm64 O=out CC=clang LLVM=1 LLVM_IAS=1 CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip"
make $MAKE_ARGS gta4l_eur_open_defconfig
make $MAKE_ARGS -j$(nproc --all) 2> >(tee -a error.txt >&2)

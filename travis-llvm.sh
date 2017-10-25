#!/bin/bash

# This script makes travis use newer llvm than the defaultly installed one
# Make sure to add sources to .travis.yml from this site: https://apt.llvm.org/

if [ $# -eq 0 ]; then
    echo "Usage: `basename $0` [llvm version] [-src]"
    exit 1
fi

llvm_ver=$1
add_src=$2

# this is useful for testing in docker.
# on real travis, it is recommended to use .travis.yml to add sources automatically
if [[ $add_src == "-src" ]]; then
    # add deb source
    echo "deb http://apt.llvm.org/trusty/ llvm-toolchain-trusty-${llvm_ver} main" | sudo tee -a /etc/apt/sources.list
    echo "deb-src http://apt.llvm.org/trusty/ llvm-toolchain-trusty-${llvm_ver} main" | sudo tee -a /etc/apt/sources.list
    # add LLVM key
    wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key|sudo apt-key add -
fi

# get rid of LLVM inside clang-3.5
export PATH=`echo $PATH | sed -E 's/\/usr\/local\/clang-?(\w.)+//g'`
sudo rm -rf /usr/local/clang*

# delete all present LLVMs
sudo apt-get remove llvm* libllvm*

# update package index
sudo apt-get update

# install LLVM and clang
sudo apt-get install llvm-${llvm_ver}* clang-${llvm_ver}

# symlink /usr/bin/ scripts containing llvm version number
llvm_packages=`dpkg -l | grep llvm-${llvm_ver} | awk '{print $2;}'`
# test scripts also need clang symlink
llvm_packages="$llvm_packages clang-${llvm_ver}"
for pkg in $llvm_packages; do
    executables=`dpkg -L $pkg | grep /usr/bin/`
    libraries=`dpkg -L $pkg | grep -e '\.a' -e '\.so' -e '\.so.1'`
    for exe in $executables; do
        sudo ln -s $exe ${exe%-$llvm_ver}
    done

    for lib in $libraries; do
        sudo ln -s $lib /usr/lib
    done

done
if [ -x "version_specific/llvm-$llvm_ver" ]; then
    . version_specific/llvm-$llvm_ver
fi

# print llvm-config version
llvm-config --version
clang --version

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
    echo "deb http://apt.llvm.org/trusty/ llvm-toolchain-trusty-${LLVM_VERSION} main" | sudo tee -a /etc/apt/sources.list
    echo "deb-src http://apt.llvm.org/trusty/ llvm-toolchain-trusty-${LLVM_VERSION} main" | sudo tee -a /etc/apt/sources.list
    # add LLVM key
    wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key|sudo apt-key add -
fi

# get rid of LLVM inside clang-3.5
export PATH=`echo $PATH | sed -E 's/\/usr\/local\/clang-?(\w.)+//g'`
sudo rm -rf /usr/local/clang*

# delete all present LLVMs
sudo apt remove llvm* libllvm*

# update package index
sudo apt update

# install LLVM and clang
sudo apt install llvm-${LLVM_VERSION}* libllvm${LLVM_VERSION} clang-${LLVM_VERSION}

# symlink /usr/bin/ scripts containing llvm version number
llvm_packages=`dpkg -l | grep llvm-${LLVM_VERSION} | awk '{print $2;}'`
# test scripts also need clang symlink
llvm_packages="$llvm_packages clang-${LLVM_VERSION}"
for pkg in $llvm_packages; do
    files=`dpkg -L $pkg | grep /usr/bin/`
    for file in $files; do
        sudo ln -s $file ${file%-$LLVM_VERSION}
    done
done

# print llvm-config version
llvm-config --version
clang --version

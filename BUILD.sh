# Copyright (c) 2020, 2igosha

#Redistribution and use in source and binary forms, with or without
#modification, are permitted provided that the following conditions are met:

#1. Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#2. Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.

#THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
#ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
#ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

ARCH=${ARCH:-x86_64} # or i686
PREFIX=${PREFIX:-$HOME/${ARCH}_mingw}

OSNAME=`uname`
if [ $OSNAME == "Darwin" ]
then
	MAKE=make
elif [ $OSNAME == "FreeBSD" ]
then
	MAKE=gmake
elif [ $OSNAME == "Linux" ]
then
	MAKE=make
else
	echo Unsupported platform
fi

echo Using arch: $ARCH on OS $OSNAME with make $MAKE and prefix $PREFIX
sleep 1

rm -rf ./build_binutils/*
rm -rf ./build_headers/*
rm -rf ./build_mpfr/*
rm -rf ./build_gmp/*
rm -rf ./build_gcc/*
rm -rf ./build_crt/*
rm -rf ./build_winpthreads/*

mkdir -p ./build_binutils
mkdir -p  ./build_headers
mkdir -p  ./build_mpfr
mkdir -p  ./build_gmp
mkdir -p  ./build_gcc
mkdir -p  ./build_crt
mkdir -p  ./build_winpthreads



echo All clear
sleep 1

tar -xf binutils-2.34.tar.xz

export CFLAGS=-w
export CXXFLAGS=-w
cd ./build_binutils
../binutils-2.34/configure --target=$ARCH-w64-mingw32 --disable-multilib --prefix=$PREFIX  --with-sysroot=$PREFIX --enable-64-bit-bfd || exit 1
rm -f ../binutils-2.34/gprof/flat_bl.m 
rm -f ../binutils-2.34/gprof/bsd_callg_bl.m
rm -f ../binutils-2.34/gprof/fsf_callg_bl.m
$MAKE || exit 1
$MAKE install || exit 1

unset CFLAGS
unset CXXFLAGS

export PATH=$PATH:$PREFIX/bin

if [ $OSNAME == "FreeBSD" ]
then
	export SED=gsed
fi

cd ..
tar -xf mingw-w64-v7.0.0.tar.bz2
cd ./build_headers
../mingw-w64-v7.0.0/mingw-w64-headers/configure --host=$ARCH-w64-mingw32 --prefix=$PREFIX/$ARCH-w64-mingw32 || exit 1
$MAKE install || exit 1

ln -s $PREFIX/$ARCH-w64-mingw32 $PREFIX/mingw
mkdir -p $PREFIX/$ARCH-w64-mingw32/lib
if [ $ARCH == "x86_64" ]
then
	ln -s $PREFIX/$ARCH-w64-mingw32/lib $PREFIX/$ARCH-w64-mingw32/lib64
else
	ln -s $PREFIX/$ARCH-w64-mingw32/lib $PREFIX/$ARCH-w64-mingw32/lib32
fi

cd ..
tar -xf mpfr-4.0.2.tar.xz
cd ./build_mpfr
../mpfr-4.0.2/configure  --disable-multilib --target=$ARCH-w64-mingw32 --prefix=$PREFIX || exit 1
$MAKE || exit 1
$MAKE install || exit 1

cd ..
tar -xf gmp-6.2.0.tar.xz
cd ./build_gmp
../gmp-6.2.0/configure   --disable-multilib --prefix=$PREFIX || exit 1
$MAKE || exit 1
$MAKE install || exit 1

cd ..
tar -xf gcc-9.3.0.tar.xz
tar -xf isl-0.22.tar.xz

unlink ./gcc-9.3.0/isl
ln -s ./isl-0.22 ./gcc-9.3.0/isl

cd ./build_gcc
../gcc-9.3.0/configure --target=$ARCH-w64-mingw32 --disable-multilib --prefix=$PREFIX --with-gmp=../build_gmp --with-mpfr=../build_mpfr --enable-threads=posix  || exit 1
#../gcc-6.1.0/configure --target=$ARCH-w64-mingw32 --disable-multilib --enable-targets=$ARCH-w64-mingw32 --prefix=$PREFIX --with-gmp=../build_gmp --with-mpfr=../build_mpfr -enable-threads=posix  || exit 1
$MAKE all-gcc -j8 || exit 1
$MAKE install-gcc || exit 1

# CFLAGS=-w without -O2 break crt and it can't work with GCC then (inline functions broken)
cd ../build_crt
 ../mingw-w64-v7.0.0/mingw-w64-crt/configure --host=$ARCH-w64-mingw32 --prefix=$PREFIX/$ARCH-w64-mingw32  ${CRT_FLAG} || exit 1
$MAKE || exit 1
$MAKE install || exit 1

cd ../build_winpthreads
../mingw-w64-v7.0.0/mingw-w64-libraries/winpthreads/configure  --host=$ARCH-w64-mingw32   --prefix=$PREFIX/$ARCH-w64-mingw32 || exit 1
$MAKE || exit 1
$MAKE install

cd ../build_gcc
$MAKE -j8 || exit 1
$MAKE install || exit 1

cd ..
tar -xf openssl-1.1.1e.tar.gz
cd ./openssl-1.1.1e
if [ $ARCH == "x86_64" ]
then
	OPENSSL_ARCH=mingw64
else
	OPENSSL_ARCH=mingw
fi
../openssl-1.1.1e/Configure  $OPENSSL_ARCH shared --cross-compile-prefix=$ARCH-w64-mingw32- --prefix=$PREFIX --openssldir=$PREFIX/openssl || exit 1
$MAKE clean
$MAKE depend || exit 1
$MAKE || echo Misc OpenSSL errors...
$MAKE install || exit 1


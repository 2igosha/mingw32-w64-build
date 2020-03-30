# mingw-w64 linux/BSD/mac cross build setup

Download all the files in the same directory, then run BUILD.sh.
Set ARCH to i686 to build 32-bit toolchain (otherwise it will be x86_64).
Set PREFIX to specify the destination directory, otherwise it will be $HOME/$ARCH_mingw

You will get GCC 9.3.0, mingw-w64 7.0.0 with pthreads, openssl 1.1.1e.

set -x


THIS=$(pwd)
host_root=$(pwd)/host_root
target_root=$host_root/riscv64_target_root

wget https://mirrors.tuna.tsinghua.edu.cn/kernel/v5.x/linux-5.18.17.tar.gz
tar -xf linux-5.18.17.tar.gz &
wget https://mirrors.tuna.tsinghua.edu.cn/gnu/binutils/binutils-2.39.tar.gz
tar -xf binutils-2.39.tar.gz &
wget https://mirrors.tuna.tsinghua.edu.cn/gnu/glibc/glibc-2.35.tar.gz
tar -xf glibc-2.35.tar.gz &
wget https://mirrors.tuna.tsinghua.edu.cn/gnu/gcc/gcc-11.3.0/gcc-11.3.0.tar.gz
tar -xf gcc-11.3.0.tar.gz &
wget https://mirrors.tuna.tsinghua.edu.cn/gnu/gdb/gdb-12.1.tar.gz
tar -xf gdb-12.1.tar.gz &

wait

sudo apt install gcc g++ make texinfo
sudo apt install gawk bison flex
sudo apt install libgmp-dev libmpfr-dev libmpc-dev libelf-dev

rm -rf ${host_root}

mkdir gdb_build
cd gdb_build
rm -rf *
../gdb-12.1/configure \
	--prefix=${host_root}/usr \
	--target=riscv64-linux-gnu \
	--disable-sim
make -j12
make install -j12
cd ..


mkdir binutils_build
cd binutils_build
rm -rf *
../binutils-2.39/configure \
	--prefix=${host_root}/usr \
	--target=riscv64-linux-gnu \
	--disable-sim
make -j12
make install -j12
cd ..


mkdir gcc_stage1
cd gcc_stage1

rm -rf *
../gcc-11.3.0/configure \
	--prefix=${host_root}/usr \
	--target=riscv64-linux-gnu \
	--with-arch=rv64ima \
	--with-abi=lp64 \
	--enable-languages=c \
	--disable-multilib \
	--disable-threads \
	--disable-bootstrap \
	--disable-libada \
	--disable-libsanitizer \
	--disable-libssp \
	--disable-libquadmath \
	--disable-libquadmath-support \
	--disable-libgomp \
	--disable-libvtv \
	--disable-libatomic \
	--disable-shared \
	--with-build-time-tools=$host_root/usr/bin



make -j12
make install -j12
cd ..


cd linux-5.18.17
make headers_install ARCH=riscv INSTALL_HDR_PATH=$target_root/usr -j12
cd ..


mkdir glibc_build
cd glibc_build
rm -rf *

CC="$host_root/usr/bin/riscv64-linux-gnu-gcc -march=rv64ima -mabi=lp64" \
CXX="$host_root/usr/bin/riscv64-linux-gnu-g++ -march=rv64ima -mabi=lp64" \
../glibc-2.35/configure \
	--prefix=/usr \
	--host=riscv64-linux-gnu \
	--disable-werror \
	--with-headers=$target_root/usr/include

make -j12
make install DESTDIR=$target_root -j12

cd ..



mkdir gcc_stage2
cd gcc_stage2

rm -rf *

../gcc-11.3.0/configure \
	--prefix=$host_root/usr \
	--target=riscv64-linux-gnu \
	--with-arch=rv64ima \
	--with-abi=lp64 \
	--enable-languages=c,c++ \
	--disable-multilib \
	--disable-bootstrap \
	--with-sysroot=$host_root/usr/../riscv64_target_root \
	--with-build-time-tools=$host_root/usr/bin




make -j12
make install -j12
cd ..

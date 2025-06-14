#!/bin/bash

set -eu

declare -r revision="$(git rev-parse --short HEAD)"

declare -r workdir="${PWD}"

declare -r toolchain_directory='/tmp/sil'
declare -r share_directory="${toolchain_directory}/usr/local/share/sil"

declare -r gmp_tarball='/tmp/gmp.tar.xz'
declare -r gmp_directory='/tmp/gmp-6.3.0'

declare -r mpfr_tarball='/tmp/mpfr.tar.xz'
declare -r mpfr_directory='/tmp/mpfr-4.2.2'

declare -r mpc_tarball='/tmp/mpc.tar.gz'
declare -r mpc_directory='/tmp/mpc-1.3.1'

declare -r isl_tarball='/tmp/isl.tar.xz'
declare -r isl_directory='/tmp/isl-0.27'

declare -r binutils_tarball='/tmp/binutils.tar.xz'
declare -r binutils_directory='/tmp/binutils-with-gold-2.44'

declare -r zstd_tarball='/tmp/zstd.tar.gz'
declare -r zstd_directory='/tmp/zstd-dev'

declare -r gcc_tarball='/tmp/gcc.tar.gz'
declare -r gcc_directory='/tmp/gcc-releases-gcc-13'

declare -r max_jobs='40'

declare -r pieflags='-fPIE'
declare -r optflags='-w -O2 -Xlinker --allow-multiple-definition'
declare -r linkflags='-Xlinker -s'

declare -ra triplets=(
	'x86_64-unknown-haiku'
	'i586-unknown-haiku'
)

declare build_type="${1}"

if [ -z "${build_type}" ]; then
	build_type='native'
fi

declare is_native='0'

if [ "${build_type}" = 'native' ]; then
	is_native='1'
fi

declare CROSS_COMPILE_TRIPLET=''

if ! (( is_native )); then
	source "./submodules/obggcc/toolchains/${build_type}.sh"
fi

declare -r \
	build_type \
	is_native

if ! [ -f "${gmp_tarball}" ]; then
	curl \
		--url 'https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz' \
		--retry '30' \
		--retry-all-errors \
		--retry-delay '0' \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${gmp_tarball}"
	
	tar \
		--directory="$(dirname "${gmp_directory}")" \
		--extract \
		--file="${gmp_tarball}"
fi

if ! [ -f "${mpfr_tarball}" ]; then
	curl \
		--url 'https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.2.tar.xz' \
		--retry '30' \
		--retry-all-errors \
		--retry-delay '0' \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${mpfr_tarball}"
	
	tar \
		--directory="$(dirname "${mpfr_directory}")" \
		--extract \
		--file="${mpfr_tarball}"
fi

if ! [ -f "${mpc_tarball}" ]; then
	curl \
		--url 'https://ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz' \
		--retry '30' \
		--retry-all-errors \
		--retry-delay '0' \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${mpc_tarball}"
	
	tar \
		--directory="$(dirname "${mpc_directory}")" \
		--extract \
		--file="${mpc_tarball}"
fi

if ! [ -f "${isl_tarball}" ]; then
	curl \
		--url 'https://libisl.sourceforge.io/isl-0.27.tar.xz' \
		--retry '30' \
		--retry-all-errors \
		--retry-delay '0' \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${isl_tarball}"
	
	tar \
		--directory="$(dirname "${isl_directory}")" \
		--extract \
		--file="${isl_tarball}"
fi

if ! [ -f "${binutils_tarball}" ]; then
	curl \
		--url 'https://ftp.gnu.org/gnu/binutils/binutils-with-gold-2.44.tar.xz' \
		--retry '30' \
		--retry-all-errors \
		--retry-delay '0' \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${binutils_tarball}"
	
	tar \
		--directory="$(dirname "${binutils_directory}")" \
		--extract \
		--file="${binutils_tarball}"
	
	patch --directory="${binutils_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Revert-gold-Use-char16_t-char32_t-instead-of-uint16_.patch"
	patch --directory="${binutils_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Disable-annoying-linker-warnings.patch"
fi

if ! [ -f "${zstd_tarball}" ]; then
	curl \
		--url 'https://github.com/facebook/zstd/archive/refs/heads/dev.tar.gz' \
		--retry '30' \
		--retry-all-errors \
		--retry-delay '0' \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${zstd_tarball}"
	
	tar \
		--directory="$(dirname "${zstd_directory}")" \
		--extract \
		--file="${zstd_tarball}"
fi

if ! [ -f "${gcc_tarball}" ]; then
	curl \
		--url 'https://github.com/gcc-mirror/gcc/archive/refs/heads/releases/gcc-13.tar.gz' \
		--retry '30' \
		--retry-all-errors \
		--retry-delay '0' \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${gcc_tarball}"
	
	tar \
		--directory="$(dirname "${gcc_directory}")" \
		--extract \
		--file="${gcc_tarball}"
	
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/haikuports/sys-devel/gcc/patches/gcc-13.3.0_2023_08_10.patchset" || true
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/patches/no_hardcoded_paths.patch"
fi

[ -d "${gmp_directory}/build" ] || mkdir "${gmp_directory}/build"

cd "${gmp_directory}/build"
rm --force --recursive ./*

../configure \
	--host="${CROSS_COMPILE_TRIPLET}" \
	--prefix="${toolchain_directory}" \
	--enable-shared \
	--disable-static \
	CFLAGS="${optflags}" \
	CXXFLAGS="${optflags}" \
	LDFLAGS="${linkflags}"

make all --jobs
make install

[ -d "${mpfr_directory}/build" ] || mkdir "${mpfr_directory}/build"

cd "${mpfr_directory}/build"
rm --force --recursive ./*

../configure \
	--host="${CROSS_COMPILE_TRIPLET}" \
	--prefix="${toolchain_directory}" \
	--with-gmp="${toolchain_directory}" \
	--enable-shared \
	--disable-static \
	CFLAGS="${optflags}" \
	CXXFLAGS="${optflags}" \
	LDFLAGS="${linkflags}"

make all --jobs
make install

[ -d "${mpc_directory}/build" ] || mkdir "${mpc_directory}/build"

cd "${mpc_directory}/build"
rm --force --recursive ./*

../configure \
	--host="${CROSS_COMPILE_TRIPLET}" \
	--prefix="${toolchain_directory}" \
	--with-gmp="${toolchain_directory}" \
	--enable-shared \
	--disable-static \
	CFLAGS="${optflags}" \
	CXXFLAGS="${optflags}" \
	LDFLAGS="${linkflags}"

make all --jobs
make install

[ -d "${isl_directory}/build" ] || mkdir "${isl_directory}/build"

cd "${isl_directory}/build"
rm --force --recursive ./*

../configure \
	--host="${CROSS_COMPILE_TRIPLET}" \
	--prefix="${toolchain_directory}" \
	--with-gmp-prefix="${toolchain_directory}" \
	--enable-shared \
	--disable-static \
	CFLAGS="${pieflags} ${optflags}" \
	CXXFLAGS="${pieflags} ${optflags}" \
	LDFLAGS="-Xlinker -rpath-link -Xlinker ${toolchain_directory}/lib ${linkflags}"

make all --jobs
make install

[ -d "${zstd_directory}/.build" ] || mkdir "${zstd_directory}/.build"

cd "${zstd_directory}/.build"
rm --force --recursive ./*

cmake \
	-S "${zstd_directory}/build/cmake" \
	-B "${PWD}" \
	-DCMAKE_C_FLAGS="-DZDICT_QSORT=ZDICT_QSORT_MIN ${optflags}" \
	-DCMAKE_INSTALL_PREFIX="${toolchain_directory}" \
	-DBUILD_SHARED_LIBS=ON \
	-DZSTD_BUILD_PROGRAMS=OFF \
	-DZSTD_BUILD_TESTS=OFF \
	-DZSTD_BUILD_STATIC=OFF

cmake --build "${PWD}"
cmake --install "${PWD}" --strip

for triplet in "${triplets[@]}"; do
	[ -d "${binutils_directory}/build" ] || mkdir "${binutils_directory}/build"
	
	cd "${binutils_directory}/build"
	rm --force --recursive ./*
	
	../configure \
		--host="${CROSS_COMPILE_TRIPLET}" \
		--target="${triplet}" \
		--prefix="${toolchain_directory}" \
		--enable-gold \
		--enable-ld \
		--enable-lto \
		--disable-gprofng \
		--with-static-standard-libraries \
		--with-sysroot="${toolchain_directory}/${triplet}" \
		--with-zstd="${toolchain_directory}" \
		CFLAGS="${optflags} -I${toolchain_directory}/include" \
		CXXFLAGS="${optflags} -I${toolchain_directory}/include" \
		LDFLAGS="${linkflags}"
	
	make all --jobs="${max_jobs}"
	make install
	
	declare cinclude_flags="$(
		cat <<- flags | tr '\n' ' '
			-I${toolchain_directory}/${triplet}/include/os
			-I${toolchain_directory}/${triplet}/include/os/app
			-I${toolchain_directory}/${triplet}/include/os/device
			-I${toolchain_directory}/${triplet}/include/os/drivers
			-I${toolchain_directory}/${triplet}/include/os/game
			-I${toolchain_directory}/${triplet}/include/os/interface
			-I${toolchain_directory}/${triplet}/include/os/kernel
			-I${toolchain_directory}/${triplet}/include/os/locale
			-I${toolchain_directory}/${triplet}/include/os/mail
			-I${toolchain_directory}/${triplet}/include/os/media
			-I${toolchain_directory}/${triplet}/include/os/midi
			-I${toolchain_directory}/${triplet}/include/os/midi2
			-I${toolchain_directory}/${triplet}/include/os/net
			-I${toolchain_directory}/${triplet}/include/os/opengl
			-I${toolchain_directory}/${triplet}/include/os/storage
			-I${toolchain_directory}/${triplet}/include/os/support
			-I${toolchain_directory}/${triplet}/include/os/translation
			-I${toolchain_directory}/${triplet}/include/os/add-ons/graphics
			-I${toolchain_directory}/${triplet}/include/os/add-ons/input_server
			-I${toolchain_directory}/${triplet}/include/os/add-ons/mail_daemon
			-I${toolchain_directory}/${triplet}/include/os/add-ons/registrar
			-I${toolchain_directory}/${triplet}/include/os/add-ons/screen_saver
			-I${toolchain_directory}/${triplet}/include/os/add-ons/tracker
			-I${toolchain_directory}/${triplet}/include/os/be_apps/Deskbar
			-I${toolchain_directory}/${triplet}/include/os/be_apps/NetPositive
			-I${toolchain_directory}/${triplet}/include/os/be_apps/Tracker
			-I${toolchain_directory}/${triplet}/include/3rdparty
			-I${toolchain_directory}/${triplet}/include/bsd
			-I${toolchain_directory}/${triplet}/include/glibc
			-I${toolchain_directory}/${triplet}/include/gnu
			-I${toolchain_directory}/${triplet}/include/posix
			-I${toolchain_directory}/${triplet}/include
		flags
	)"
	
	declare sysroot="https://github.com/AmanoTeam/haiku-sysroot/releases/download/0.1/${triplet}.tar.xz"
	declare sysroot_file="/tmp/${triplet}.tar.xz"
	declare sysroot_directory="/tmp/${triplet}"
	
	curl \
		--url "${sysroot}" \
		--retry '30' \
		--retry-all-errors \
		--retry-delay '0' \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${sysroot_file}"
	
	tar \
		--directory="$(dirname "${sysroot_directory}")" \
		--extract \
		--file="${sysroot_file}"
	
	[ -d "${toolchain_directory}/${triplet}/include" ] || mkdir "${toolchain_directory}/${triplet}/include"
	[ -d "${toolchain_directory}/${triplet}/lib" ] || mkdir "${toolchain_directory}/${triplet}/lib"
	
	cp --no-dereference "${sysroot_directory}/system/lib/"* "${toolchain_directory}/${triplet}/lib"
	
	while read filename; do
		declare name="$(basename "${filename}")"
		declare target="${toolchain_directory}/${triplet}/lib/${name}"
		
		if [ -f "${target}" ]; then
			continue
		fi
		
		cp --no-dereference "${filename}" "${target}"
	done <<< "$(ls "${sysroot_directory}/system/develop/lib/"*)"
	
	cp --no-dereference --recursive "${sysroot_directory}/system/develop/headers/"* "${toolchain_directory}/${triplet}/include"
	
	sed --in-place 's/__GNUC__ <= 12/__GNUC__ <= 13/g' "${toolchain_directory}/${triplet}/include/os/BeBuild.h"
	
	[ -d "${gcc_directory}/build" ] || mkdir "${gcc_directory}/build"
	
	cd "${gcc_directory}/build"
	rm --force --recursive ./*
	
	../configure \
		--host="${CROSS_COMPILE_TRIPLET}" \
		--target="${triplet}" \
		--prefix="${toolchain_directory}" \
		--with-linker-hash-style='sysv' \
		--with-gmp="${toolchain_directory}" \
		--with-mpc="${toolchain_directory}" \
		--with-mpfr="${toolchain_directory}" \
		--with-isl="${toolchain_directory}" \
		--with-zstd="${toolchain_directory}" \
		--with-bugurl='https://github.com/AmanoTeam/Sil/issues' \
		--with-gcc-major-version-only \
		--with-pkgversion="Sil v0.7-${revision}" \
		--with-sysroot="${toolchain_directory}/${triplet}" \
		--with-native-system-header-dir='/include' \
		--with-default-libstdcxx-abi='gcc4-compatible' \
		--includedir="${toolchain_directory}/${triplet}/include" \
		--enable-__cxa_atexit \
		--enable-cet='auto' \
		--enable-checking='release' \
		--enable-default-pie \
		--enable-default-ssp \
		--enable-gnu-indirect-function \
		--enable-gnu-unique-object \
		--enable-libstdcxx-backtrace \
		--enable-libstdcxx-filesystem-ts \
		--enable-libstdcxx-static-eh-pool \
		--with-libstdcxx-zoneinfo='static' \
		--with-libstdcxx-lock-policy='auto' \
		--enable-link-serialization='1' \
		--enable-linker-build-id \
		--enable-lto \
		--enable-shared \
		--enable-threads='posix' \
		--enable-libstdcxx-threads \
		--enable-libssp \
		--enable-languages='c,c++' \
		--enable-ld \
		--enable-gold \
		--enable-frame-pointer \
		--enable-plugin \
		--enable-cxx-flags="${linkflags}" \
		--enable-host-pie \
		--enable-host-shared \
		--with-specs='%{!fno-plt:%{!fplt:-fno-plt}}' \
		--disable-libsanitizer \
		--disable-bootstrap \
		--disable-libatomic \
		--disable-libgomp \
		--disable-libstdcxx-pch \
		--disable-werror \
		--disable-multilib \
		--disable-nls \
		--without-headers \
		CFLAGS="${optflags}" \
		CXXFLAGS="${optflags}" \
		LDFLAGS="${linkflags}"
	
	LD_LIBRARY_PATH="${toolchain_directory}/lib" PATH="${PATH}:${toolchain_directory}/bin" make \
		CFLAGS_FOR_TARGET="${optflags} ${linkflags} ${cinclude_flags}" \
		CXXFLAGS_FOR_TARGET="${optflags} ${linkflags} ${cinclude_flags}" \
		all --jobs="${max_jobs}"
	make install
	
	cd "${toolchain_directory}/lib/bfd-plugins"
	
	if ! [ -f './liblto_plugin.so' ]; then
		ln --symbolic "../../libexec/gcc/${triplet}/"*'/liblto_plugin.so' './'
	fi
	
	rm --recursive "${toolchain_directory}/share"
	
	patchelf --add-rpath '$ORIGIN/../../../../lib' "${toolchain_directory}/libexec/gcc/${triplet}/"*"/cc1"
	patchelf --add-rpath '$ORIGIN/../../../../lib' "${toolchain_directory}/libexec/gcc/${triplet}/"*"/cc1plus"
	patchelf --add-rpath '$ORIGIN/../../../../lib' "${toolchain_directory}/libexec/gcc/${triplet}/"*"/lto1"
done

mkdir --parent "${share_directory}"

cp --recursive "${workdir}/tools/dev/"* "${share_directory}"

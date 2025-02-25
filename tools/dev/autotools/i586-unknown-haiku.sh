#/bin/bash

set -e

if [ -z "${SIL_HOME}" ]; then
	SIL_HOME="$(realpath "$(dirname "${0}")")/../../../../.."
fi

set -u

CROSS_COMPILE_SYSTEM='haiku'
CROSS_COMPILE_ARCHITECTURE='i586'
CROSS_COMPILE_TRIPLET="${CROSS_COMPILE_ARCHITECTURE}-unknown-${CROSS_COMPILE_SYSTEM}"
CROSS_COMPILE_SYSROOT="${SIL_HOME}/${CROSS_COMPILE_TRIPLET}"

CC="${SIL_HOME}/bin/${CROSS_COMPILE_TRIPLET}-gcc"
CXX="${SIL_HOME}/bin/${CROSS_COMPILE_TRIPLET}-g++"
AR="${SIL_HOME}/bin/${CROSS_COMPILE_TRIPLET}-ar"
AS="${SIL_HOME}/bin/${CROSS_COMPILE_TRIPLET}-as"
LD="${SIL_HOME}/bin/${CROSS_COMPILE_TRIPLET}-ld"
NM="${SIL_HOME}/bin/${CROSS_COMPILE_TRIPLET}-nm"
RANLIB="${SIL_HOME}/bin/${CROSS_COMPILE_TRIPLET}-ranlib"
STRIP="${SIL_HOME}/bin/${CROSS_COMPILE_TRIPLET}-strip"
OBJCOPY="${SIL_HOME}/bin/${CROSS_COMPILE_TRIPLET}-objcopy"
READELF="${SIL_HOME}/bin/${CROSS_COMPILE_TRIPLET}-readelf"

export \
	CROSS_COMPILE_TRIPLET \
	CROSS_COMPILE_SYSTEM \
	CROSS_COMPILE_ARCHITECTURE \
	CROSS_COMPILE_SYSROOT \
	CC \
	CXX \
	AR \
	AS \
	LD \
	NM \
	RANLIB \
	STRIP \
	OBJCOPY \
	READELF

set +eu

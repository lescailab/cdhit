#!/bin/bash
set -euo pipefail

# cdhit-common.c++ calls std::sort without including <algorithm>; GCC's libstdc++
# pulls it in transitively, conda-forge's libc++ on macOS does not.
if [[ "${target_platform}" == osx-* ]]; then
    export CXXFLAGS="${CXXFLAGS} -include algorithm"
fi

# The Makefile hardcodes CC = g++; point it at the conda compiler. CPPFLAGS,
# CXXFLAGS and LDFLAGS come from the environment and the Makefile appends to them.
make CC="${CXX}" openmp=yes zlib=yes -j"${CPU_COUNT}"

mkdir -p "${PREFIX}/bin"
make install PREFIX="${PREFIX}/bin"

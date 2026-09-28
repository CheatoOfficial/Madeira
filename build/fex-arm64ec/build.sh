#!/bin/bash
# Configure (first time) and build the ARM64EC FEX module (libarm64ecfex.dll,
# shipped as xtajit64.dll). Options mirror the development build's CMakeCache.
set -eu
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export PATH="$R/toolchains/llvm-mingw-20260922-ucrt-macos-universal/bin:$PATH"
B="$R/FEX/build-arm64ec"
if [ -f "$B/CMakeCache.txt" ] && { \
    ! grep -q '^TUNE_CPU:STRING=generic$' "$B/CMakeCache.txt" || \
    ! grep -q '^MINGW_TRIPLE:STRING=arm64ec-w64-mingw32$' "$B/CMakeCache.txt" || \
    ! grep -q '^FEX_IOS_HOST_BUILD:BOOL=ON$' "$B/CMakeCache.txt" || \
    ! grep -q '^CMAKE_C_FLAGS:STRING=-DFEX_IOS_HOST$' "$B/CMakeCache.txt" || \
    ! grep -q '^CMAKE_CXX_FLAGS:STRING=-DFEX_IOS_HOST$' "$B/CMakeCache.txt" || \
    ! grep -q 'llvm-mingw-20260922-ucrt-macos-universal/bin/arm64ec-w64-mingw32-clang' "$B/CMakeCache.txt" || \
    ! grep -q '^CMAKE_DISABLE_FIND_PACKAGE_fmt:BOOL=TRUE$' "$B/CMakeCache.txt"; \
}; then
    rm -rf "$B"
fi
if [ ! -f "$B/CMakeCache.txt" ]; then
    cmake -S "$R/FEX" -B "$B" -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_TOOLCHAIN_FILE="$R/FEX/Data/CMake/toolchain_mingw.cmake" \
        -DMINGW_TRIPLE=arm64ec-w64-mingw32 \
        -DFEX_IOS_HOST_BUILD=ON \
        -DCMAKE_C_FLAGS=-DFEX_IOS_HOST \
        -DCMAKE_CXX_FLAGS=-DFEX_IOS_HOST \
        -DTUNE_CPU=generic \
        -DCMAKE_DISABLE_FIND_PACKAGE_fmt=TRUE \
        -DENABLE_FEX_ALLOCATOR=ON -DENABLE_JEMALLOC_GLIBC_ALLOC=ON -DENABLE_OFFLINE_RUNTIME=ON \
        -DBUILD_FEXCONFIG=ON -DENABLE_CLANG_THUNKS=ON -DENABLE_CCACHE=ON \
        -DBUILD_TESTING=OFF -DBUILD_THUNKS=OFF -DENABLE_ASSERTIONS=OFF
fi
EC_CXX="$R/toolchains/llvm-mingw-20260922-ucrt-macos-universal/bin/arm64ec-w64-mingw32-clang++"
LLVM_NM="$R/toolchains/llvm-mingw-20260922-ucrt-macos-universal/bin/llvm-nm"
"$EC_CXX" --version
for runtime in libc++.a libc++abi.a libunwind.a; do
    archive="$("$EC_CXX" -print-file-name="$runtime")"
    printf 'ARM64EC runtime %s: %s\n' "$runtime" "$archive"
    if [ -f "$archive" ]; then
        "$LLVM_NM" --demangle --defined-only "$archive" | grep -E -m 8 'recursive_mutex::lock|__gxx_personality_seh0|__shared_mutex_base::lock' || true
    fi
done
cat "$B/Source/Windows/ARM64EC/CMakeFiles/arm64ecfex.dir/linkLibs.rsp"
cmake --build "$B" --target arm64ecfex --verbose
cp "$B/Bin/libarm64ecfex.dll" "$R/app/Madeira/arm64ec-windows/xtajit64.dll" && ls -l "$R/app/Madeira/arm64ec-windows/xtajit64.dll"

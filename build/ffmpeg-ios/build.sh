#!/bin/bash
# Build the LGPL-only FFmpeg subset used by Madeira's Wine audio parser.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD="$ROOT/build/ffmpeg-ios"
SRC="$BUILD/src/ffmpeg-7.1.1"
PREFIX="$ROOT/toolchains/ffmpeg-ios"
ARCHIVE="$BUILD/src/ffmpeg-7.1.1.tar.xz"
SHA256=733984395e0dbbe5c046abda2dc49a5544e7e0e1e2366bba849222ae9e3a03b1
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
CLANG="$(xcrun --sdk iphoneos -f clang)"
AR="$(xcrun --sdk iphoneos -f ar)"
RANLIB="$(xcrun --sdk iphoneos -f ranlib)"
STRIP="$(xcrun --sdk iphoneos -f strip)"
MIN="-arch arm64 -isysroot $SDK -miphoneos-version-min=17.0"

mkdir -p "$BUILD/src" "$PREFIX"
if [[ ! -f "$ARCHIVE" ]]; then
  curl -fL --retry 3 https://ffmpeg.org/releases/ffmpeg-7.1.1.tar.xz -o "$ARCHIVE"
fi
echo "$SHA256  $ARCHIVE" | shasum -a 256 -c -
if [[ ! -d "$SRC" ]]; then tar -xJf "$ARCHIVE" -C "$BUILD/src"; fi

if [[ ! -f "$PREFIX/lib/libavcodec.a" ]]; then
  cd "$SRC"
  ./configure --prefix="$PREFIX" --arch=aarch64 --target-os=darwin \
    --enable-cross-compile --cc="$CLANG $MIN" --ar="$AR" --ranlib="$RANLIB" --strip="$STRIP" \
    --extra-cflags="$MIN -O2" --extra-ldflags="$MIN" --enable-pic \
    --disable-shared --enable-static --disable-programs --disable-doc \
    --disable-autodetect --disable-everything --disable-network \
    --disable-gpl --disable-nonfree --disable-version3 \
    --enable-avcodec --enable-avformat --enable-swresample \
    --enable-demuxer=mp3,wav,mov --enable-parser=mpegaudio \
    --enable-decoder=wmav1,wmav2,wmapro,wmalossless,xma1,xma2,mp1,mp2,mp3,pcm_u8,pcm_s16le,pcm_s24le,pcm_s32le,pcm_f32le,pcm_f64le
  make -j"$(sysctl -n hw.ncpu)"
  make install-libs install-headers
fi
for lib in avformat avcodec avutil swresample; do test -s "$PREFIX/lib/lib$lib.a"; done
echo "FFmpeg iOS libraries and headers: $PREFIX"

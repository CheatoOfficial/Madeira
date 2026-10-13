#!/bin/bash
# Wine makedep scans conditional includes even when WINE_IOS is not enabled.
# Make the existing Madeira headers visible without adding system shim paths
# to the PE or macOS compiler's include search order.
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE="$R/build/ntdll-unix/shims"
DEST="$R/wine/dlls/ntdll/unix"
test -d "$DEST"
for name in ios_srv_stats.h ios_spin_hist.h ios_frame_stats.h ios_fastsync.h ios_late_wake.h; do
    test -f "$SOURCE/$name"
    if [[ -e "$DEST/$name" || -L "$DEST/$name" ]]; then
        cmp "$SOURCE/$name" "$DEST/$name" || {
            echo "Refusing to replace a different Wine header: $DEST/$name" >&2
            exit 1
        }
    else
        cp "$SOURCE/$name" "$DEST/$name"
    fi
done

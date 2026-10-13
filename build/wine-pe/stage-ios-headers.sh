#!/bin/bash
# Wine makedep scans conditional includes even when WINE_IOS is not enabled.
# Make the existing Madeira headers visible without adding system shim paths
# to the PE or macOS compiler's include search order.
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE="$R/build/ntdll-unix/shims"
stage_header() {
    local name="$1" dest="$2"
    test -d "$dest"
    test -f "$SOURCE/$name"
    if [[ -e "$dest/$name" || -L "$dest/$name" ]]; then
        cmp "$SOURCE/$name" "$dest/$name" || {
            echo "Refusing to replace a different Wine header: $dest/$name" >&2
            exit 1
        }
    else
        cp "$SOURCE/$name" "$dest/$name"
    fi
}
for name in ios_srv_stats.h ios_spin_hist.h ios_frame_stats.h ios_fastsync.h ios_late_wake.h; do
    stage_header "$name" "$R/wine/dlls/ntdll/unix"
done
# event.c, semaphore.c and inproc_sync.c also include this shared definition.
stage_header ios_fastsync.h "$R/wine/server"

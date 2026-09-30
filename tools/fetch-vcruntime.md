# Obtaining the Microsoft Visual C++ runtime DLLs

Games built with MSVC need the Visual C++ runtime. Those DLLs are authored by
Microsoft and are **not** redistributable under this project's license, so they
are not committed to the repository or included in public build artifacts.

Twelve files are expected in `app/Madeira/x86_64-vcruntime/`:

```
concrt140.dll              msvcp140_codecvt_ids.dll   vcruntime140.dll
msvcp140.dll               vcamp140.dll               vcruntime140_1.dll
msvcp140_1.dll             vccorlib140.dll            vcruntime140_threads.dll
msvcp140_2.dll             vcomp140.dll
msvcp140_atomic_wait.dll
```

## How to get them

Download the pinned official x64 redistributable from Microsoft. Its version,
download URL, EXE SHA-256, and expected DLL SHA-256 values are recorded in
`vc-runtime-provenance.json`. The extraction script scans the embedded CABs,
selects the twelve expected x64 files, and rejects any file with a different
hash:

```sh
brew install p7zip
python3 tools/extract-vcruntime.py \
  --installer VC_redist.x64.exe \
  --provenance vc-runtime-provenance.json \
  --destination app/Madeira/x86_64-vcruntime
```

The public macOS workflow downloads that same pinned installer and stages its
contents only on the temporary runner to compile and validate the app. The IPA
is not attached to the public Actions artifact because it contains these DLLs.
For local builds, keep the files byte-for-byte as Microsoft shipped them and
leave them untracked.

## Do not modify them

Microsoft's redistribution permission covers the eligible files *unmodified*.
In particular, do not strip Authenticode signatures. You can check that a file
still carries its signature payload:

```sh
python3 - app/Madeira/x86_64-vcruntime/*.dll <<'EOF'
import struct, sys
for path in sys.argv[1:]:
    d = open(path, 'rb').read()
    pe = struct.unpack_from('<I', d, 0x3c)[0]
    off, size = struct.unpack_from('<II', d, pe + 24 + 112 + 4*8)
    ok = size and off + size <= len(d)
    print(('signed  ' if ok else 'UNSIGNED'), path)
EOF
```

A file whose certificate offset equals its own length has had the signature
truncated off and is no longer an unmodified Microsoft binary.

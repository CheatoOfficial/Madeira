# Madeira iOS build blockers

## Current result

No complete IPA has been produced. Do not install or distribute an IPA from
these attempts. The source is the head of `integration/upstream-0926`,
`1550c82114b6a94bd4157633c16fec9ac7cd1ad8`; the requested commit
`25f36e1cec7e3b1f9ee9072f90aa860f4829ec7e` is in its history. The checked out
head also includes the later `ml2014`–`ml2016` commits present on that branch.
No unrelated `pr/*`, `pr2/*`, or `wip/*` branches were merged.

The requested destination is the public fork
[CheatoOfficial/Madeira](https://github.com/CheatoOfficial/Madeira). Its current
`main` is an ancestor of the requested source branch. The public update must not
expose Microsoft's VC++ runtime binaries.

## Microsoft runtime distribution boundary

The Xcode Resources phase requires these twelve Microsoft files in
`app/Madeira/x86_64-vcruntime/`:

```text
concrt140.dll
msvcp140.dll
msvcp140_1.dll
msvcp140_2.dll
msvcp140_atomic_wait.dll
msvcp140_codecvt_ids.dll
vcamp140.dll
vccorlib140.dll
vcomp140.dll
vcruntime140.dll
vcruntime140_1.dll
vcruntime140_threads.dll
```

The project policy in `tools/fetch-vcruntime.md` says these Microsoft-authored
DLLs are not distributable under the project license and must be supplied by
the user. Therefore no public repository commit or downloadable IPA artifact
will contain them. A complete app build needs the user-supplied, unmodified
files extracted from Microsoft's official `VC_redist.x64.exe`, with their
Authenticode signatures intact. Do not omit them from an IPA silently.

## macOS build status

The Windows workspace has no Xcode, and no complete IPA exists. Public macOS
run [36436248487](https://github.com/CheatoOfficial/Madeira/actions/runs/36436248487)
allocated a runner, checked out recursive submodules, and recorded macOS 15.7.9,
Xcode 16.4 (16F6), and iPhoneOS SDK 18.5. Its readiness audit found 23 missing
inputs: the eleven generated linker archives and the twelve user-supplied
Microsoft DLLs listed above. It stopped before any native build, as intended.
The current toolchain fix still needs a real link attempt after all required
inputs are supplied. The user declined extra Actions spending; this public
standard-runner job did start without the previous private-repository billing
block.

## Previous private-repository runner failures

GitHub did not start the latest workflow job. Its check-run annotation says:

> The job was not started because recent account payments have failed or your spending limit needs to be increased. Please check the 'Billing & plans' section in your settings

Runs [36432170346](https://github.com/CheatoOfficial/GTASanAndreas3DS/actions/runs/36432170346)
and [36432537267](https://github.com/CheatoOfficial/GTASanAndreas3DS/actions/runs/36432537267)
failed before runner allocation (`runner_id` 0; no steps or build log). These
were runs in the previous private destination. The user declined to spend on
Actions billing. The current workflow uses
the official LLVM-MinGW `20260922` toolchain, pinned by the published SHA-256;
that toolchain has not yet run because of this account-level block.

## Last actual macOS build failure

Run [36429453349](https://github.com/CheatoOfficial/GTASanAndreas3DS/actions/runs/36429453349)
used macOS 15.7.9, Xcode 16.4 (16F6), and iPhoneOS SDK 18.5. Recursive
submodules, the readiness step, and the redistributable helper-library step
completed. FEX's iOS archives compiled. The first unresolved build error was
the ARM64EC FEX DLL link using LLVM-MinGW 20260616 / Clang 22.1.8:

```text
ld.lld: error: undefined symbol: __gxx_personality_seh0 (EC symbol)
ld.lld: error: undefined symbol: std::__1::recursive_mutex::lock() (EC symbol)
ld.lld: error: undefined symbol: std::__1::mutex::lock() (EC symbol)
clang: error: linker command failed with exit code 1
```

The workflow now pins official LLVM-MinGW `20260922` (archive SHA-256
`52e5f5a7b131021d0c39a37a38fa380a1da7885cd04bd61afd0cd4ecfb8bc1f3`). I
downloaded that exact archive and verified its checksum locally. Its libc++ and
libc++abi archives contain ARM64EC alias members for the missing C++ mutex and
exception-personality symbols. This is a promising, source-backed fix, but it
still needs an actual macOS link run to confirm the toolchain selects and links
those members correctly.

The complete evidence artifact for that run is `madeira-macos-build-evidence`;
the run also uploaded `fex-arm64ec-build.log`. The workflow is updated to use
the current official toolchain and logs the runtime archive symbols before
linking, but a new macOS run is needed to determine whether that resolves the
failure. Later Wine PE, DXMT, native Wine archive, Xcode, packaging, and IPA
validation stages have not completed on this revision.

## Readiness audit

Before native builds, the readiness audit reported these 11 missing generated
linker inputs:

- `FEX/build-ios/FEXCore/Source/libFEXCore.a`
- `FEX/build-ios/FEXCore/Source/libFEXCore_Base.a`
- `FEX/build-ios/FEXCore/Source/libJemallocLibs.a`
- `FEX/build-ios/External/fmt/libfmt.a`
- `FEX/build-ios/External/cephes/libcephes_128bit.a`
- `FEX/build-ios/External/xxhash/cmake_unofficial/libxxhash.a`
- `FEX/build-ios/External/SoftFloat-3e/libsoftfloat_3e.a`
- `app/Madeira/libntdll_unix.a`
- `app/Madeira/libwineserver.a`
- `app/Madeira/libwin32u_unix.a`
- `app/Madeira/libdxmt_combined.a`

These are expected build outputs. On run 364294 the workflow generated the
FEX iOS archives and GnuTLS, FreeType, and FFmpeg helper libraries before
stopping at ARM64EC FEX. Wine ntdll, wineserver, win32u, DXMT, and Xcode have
not yet run to completion. The current workflow builds dependencies in their
required order and does not package an incomplete app.

Recursive submodules were initialized at their pinned gitlinks. Root pins:

- FEX `7b528d8a57cb12b794c589dd7e42fff813fc9abd`
- Wine `65fab17629dd768de44711082c7cfa5e199278b1`
- DXMT `550735c32c1a2faa68fa4fe504ac827e0f341831`

Nested pins are listed in `build-manifest.json` and in the macOS environment
log.

## Runtime limitation

GTA V has not been verified on a physical iPhone. Madeira currently lacks
Rockstar Games Launcher/Social Club support, which retail GTA V normally
requires. A direct `GTA5.exe` launch is diagnostic only. This remains a known
runtime blocker, not an iOS build failure.
